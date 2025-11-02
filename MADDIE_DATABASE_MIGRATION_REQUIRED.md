# Database Schema Update Required for Maddie Countdown System

## Problem
The current database schema has the `maddie` column defined as `BOOLEAN`, but the new countdown system requires it to be `JSONB` to store object data with countdown and activation information.

## Error Details
```
PATCH https://hfwehsnejieymucgcaem.supabase.co/rest/v1/matches?id=eq.90498667-8365-452d-88af-0cf70e775b89 400 (Bad Request)
Error: invalid input syntax for type boolean: "{"id":"a56...","countdownStartedAt":"2025-11-02T20:49:51.041Z"}"
```

## Current Temporary Fix
The code has been updated to use the legacy boolean system for maddies until the database schema is updated:
- ✅ Maddie selection UI works
- ✅ Maddie activation works (boolean true/false)
- ✅ Sound effects work
- ✅ 5-second auto-reset works
- ❌ 7-second countdown system disabled (requires JSONB column)
- ❌ Detailed maddie information disabled (requires JSONB column)

## Required Database Migration

### Step 1: Run This SQL in Your Supabase Dashboard

Go to your Supabase project → SQL Editor → New query, and run:

```sql
-- Update maddie column from boolean to jsonb to support countdown functionality
-- This migration maintains backward compatibility by handling both boolean and object formats

-- First, add a temporary column
ALTER TABLE matches ADD COLUMN maddie_new JSONB;

-- Migrate existing boolean data to new format
UPDATE matches 
SET maddie_new = CASE 
    WHEN maddie = true THEN 'true'::jsonb
    WHEN maddie = false THEN 'false'::jsonb
    ELSE 'false'::jsonb
END;

-- Drop the old column and rename the new one
ALTER TABLE matches DROP COLUMN maddie;
ALTER TABLE matches RENAME COLUMN maddie_new TO maddie;

-- Set default value
ALTER TABLE matches ALTER COLUMN maddie SET DEFAULT 'false'::jsonb;
ALTER TABLE matches ALTER COLUMN maddie SET NOT NULL;

-- Add comment explaining the new format
COMMENT ON COLUMN matches.maddie IS 'Can be boolean (legacy) or object with {id, name, countdown, activated, etc.} properties for new maddie system';
```

### Step 2: Enable the New Countdown System

After running the migration, uncomment the following sections in the code:

#### In `MatchControlView.vue`:
- Uncomment the "NEW SYSTEM" code block in `triggerMaddie()` function
- Comment out the "legacy boolean system" temporary code

#### In `ScoreboardView.vue`:
- Uncomment the "NEW OBJECT SYSTEM" code block in `detectMaddieActivation()` function

### Step 3: Test the Enhanced System

After the migration and code updates:
- ✅ 7-second countdown before maddie activation
- ✅ Visual countdown overlay on scoreboard
- ✅ Detailed maddie information storage
- ✅ Backward compatibility with existing boolean values
- ✅ Enhanced match control interface

## Schema Details

### Before (Current)
```sql
maddie BOOLEAN NOT NULL DEFAULT false
```

### After (Required)
```sql
maddie JSONB NOT NULL DEFAULT 'false'::jsonb
```

### Data Format Examples

**Legacy Format (still supported):**
```json
true  // or false
```

**New Format:**
```json
{
  "id": "a56b789c-def0-1234-5678-9abcdef01234",
  "name": "Freeze the Field",
  "description": "All players freeze for 10 seconds",
  "duration": 10000,
  "color": "#8B5CF6",
  "countdown": false,
  "activated": true,
  "activatedAt": "2025-11-02T20:49:58.041Z",
  "countdownStartedAt": "2025-11-02T20:49:51.041Z"
}
```

## Safety Notes
- ✅ Migration preserves all existing data
- ✅ Backward compatibility maintained
- ✅ No data loss during transition
- ✅ Default values properly set

Run the migration when convenient - the app works in legacy mode until then!