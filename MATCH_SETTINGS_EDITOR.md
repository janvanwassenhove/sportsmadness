# Match Settings Editor Feature

## Overview
Added the ability to edit match-specific settings for quarters, quarter length, break time, and halftime duration. These settings can be customized per match while inheriting sensible defaults from tournament configuration.

## Features Added

### 1. Match Settings Interface
- **Quarters Count**: Number of quarters (default: 2)
- **Quarter Length**: Duration in minutes (default: 15min)
- **Break Time**: Between quarters in minutes (default: 2min)
- **Halftime**: Duration in minutes (default: 10min)

### 2. Smart Defaults System
- **Tournament Matches**: Inherit settings from tournament configuration
- **Standalone Matches**: Use standard hockey defaults (2 quarters, 15min each, 2min breaks, 10min halftime)

### 3. Edit Match Modal
- Clean, user-friendly interface for editing match settings
- Shows current match info (teams, match type)
- Indicates settings source (tournament vs. standalone)
- Reset to defaults functionality
- Real-time validation

### 4. Database Integration
- Match settings stored in database per match
- Optional overrides of tournament defaults
- Proper migration for new columns

## User Interface

### Edit Button
- ⚙️ **Edit Settings** button appears for matches during setup phase
- Located next to existing Control (🎮) and Delete (🗑️) buttons

### Modal Features
- **Match Info Display**: Shows teams and match type
- **Input Fields**: Number inputs with min/max validation
- **Default Values**: Shows current defaults in help text
- **Source Indicator**: Shows if using tournament or standalone defaults
- **Actions**: Reset to Defaults and Save Settings buttons

### Settings Display
- Settings are applied when generating matches
- Total match time calculated from quarters × quarter length
- Settings persist and can be modified later

## Technical Implementation

### Database Schema
```sql
-- Added to matches table
ALTER TABLE matches 
ADD COLUMN IF NOT EXISTS quarters_count INTEGER,
ADD COLUMN IF NOT EXISTS quarter_duration_minutes INTEGER,
ADD COLUMN IF NOT EXISTS break_duration_minutes INTEGER,
ADD COLUMN IF NOT EXISTS halftime_duration_minutes INTEGER;
```

### Default Logic
1. **Tournament Match**: Uses tournament.quarters_count, quarter_duration_minutes, etc.
2. **Standalone Match**: Uses hardcoded defaults (2, 15, 2, 10)
3. **Custom Override**: Match-specific settings override both above

### Key Functions
- `editMatch(match)`: Opens edit modal with current/default values
- `getDefaultMatchSettings(match)`: Returns appropriate defaults based on context
- `saveMatchSettings()`: Updates database and local state
- `resetToDefaults()`: Restores original default values

## User Workflow

### Setup Phase
1. **Generate Matches**: Creates matches with tournament defaults
2. **Edit Individual Matches**: Click ⚙️ to customize specific match settings
3. **View Settings**: Modal shows current values and source
4. **Modify & Save**: Adjust settings and save to database

### During Tournament
- Settings are locked during active tournament
- Edit button only appears during setup phase
- Match control uses saved settings for timing

## Database Migration Required

Run this SQL to add the new columns:
```sql
ALTER TABLE matches 
ADD COLUMN IF NOT EXISTS quarters_count INTEGER,
ADD COLUMN IF NOT EXISTS quarter_duration_minutes INTEGER,
ADD COLUMN IF NOT EXISTS break_duration_minutes INTEGER,
ADD COLUMN IF NOT EXISTS halftime_duration_minutes INTEGER;
```

## Benefits
- **Flexibility**: Customize timing per match while maintaining tournament structure
- **User-Friendly**: Intuitive interface with clear defaults and validation
- **Smart Inheritance**: Automatic use of tournament settings with override capability
- **Consistency**: Maintains tournament-wide settings while allowing exceptions
- **Future-Proof**: Database structure supports advanced match scheduling features