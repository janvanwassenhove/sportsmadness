# Generate Schedule Error Fixes

## Error Summary
1. **Vue Lifecycle Error**: `onBeforeUnmount` was called inside an async function
2. **Database Error**: Missing `start_time` column in the `matches` table
3. **Schema Mismatch**: Using invalid status value `'scheduled'` instead of allowed values

## Fixes Applied

### 1. Fixed Vue Lifecycle Error ✅
**Problem**: `onBeforeUnmount` was called inside `onMounted` callback, which is not allowed.

**Fix**: Moved the visibility change handler and `onBeforeUnmount` outside the `onMounted` callback to the correct scope.

### 2. Fixed Schema Mismatches ✅
**Problem**: Using invalid values for database columns.

**Fixes**:
- Changed `status: 'scheduled'` to `status: 'pending'` (valid enum value)
- Changed `maddie: null` to `maddie: false` (boolean field requirement)

### 3. Fixed Missing `start_time` Column 🔧
**Problem**: The `matches` table doesn't have a `start_time` column.

**Immediate Fix**: Modified code to temporarily exclude `start_time` field
**Permanent Fix**: Run the SQL script to add the column

## Required Database Update

Run this SQL in your Supabase SQL Editor:

```sql
-- Add the missing start_time column
ALTER TABLE matches 
ADD COLUMN IF NOT EXISTS start_time TIME DEFAULT '09:00:00';

-- Update existing matches
UPDATE matches 
SET start_time = '09:00:00'
WHERE start_time IS NULL;
```

## After Running the SQL

Once you've added the `start_time` column, uncomment these lines in `TournamentAdminView.vue`:

```typescript
// Line ~1498: Uncomment this line
matchData.start_time = matchStartTime

// Line ~1528: Uncomment this line  
matchData.start_time = matchStartTime
```

## Current Status

✅ **Works Now**: Generate Schedule will work without start_time field
⏳ **After SQL**: Full functionality with match scheduling times

## Testing Steps

1. Select a tournament
2. Create divisions and assign teams
3. Click "Generate Schedule" - should work without errors
4. Run the SQL script 
5. Uncomment the start_time lines
6. Generate schedule again - should include start times

## Files Modified

- `TournamentAdminView.vue` - Fixed lifecycle and schema issues
- `QUICK_FIX_ADD_START_TIME.sql` - Database schema update
- `supabase/migrations/20241102000001_add_match_start_time.sql` - Proper migration file