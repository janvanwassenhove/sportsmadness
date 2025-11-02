# Tournament Admin - Match Settings Editor Implementation

## Overview
Added edit functionality to Tournament Admin view for configuring match settings (quarters, quarter length, break time, halftime) for tournament matches.

## Changes Made

### 1. Added Edit Button to Match Preview
- Added ⚙️ edit button next to delete button in match preview section
- Button appears only when tournament status is 'setup'
- Positioned between match status and delete button for intuitive workflow

### 2. Enhanced Match Interface
Extended the Match interface to include match duration columns:
```typescript
interface Match {
  // ... existing fields
  quarters_count?: number
  quarter_duration_minutes?: number
  break_duration_minutes?: number
  halftime_duration_minutes?: number
}
```

### 3. Added Edit Match Modal System
- **Modal State**: `showEditMatchModal` reactive boolean
- **Edit Data**: `editMatchData` reactive object to hold form values
- **Smart Defaults**: Inherits tournament settings when available, falls back to system defaults

### 4. Implemented Edit Functions

#### `editMatch(match: Match)`
- Opens modal with current match settings or smart defaults
- Prioritizes tournament defaults over system defaults
- Populates form with existing match values if they exist

#### `saveMatchSettings()`
- Updates match in Supabase database
- Synchronizes local state across multiple arrays:
  - Main `matches` array
  - Division-specific `divisionMatches` arrays
- Provides user feedback on success/failure

### 5. Match Settings Modal UI
- **Responsive Layout**: 2-column grid for compact form
- **Real-time Calculation**: Shows total match time as user adjusts settings
- **Validation**: Enforced min/max values for all duration fields
- **Consistent Styling**: Matches existing modal design patterns

## Smart Default Logic
1. **Tournament Context**: Uses tournament's default settings as primary source
2. **System Fallbacks**: Falls back to system defaults (4 quarters, 15min each, 2min breaks, 10min halftime)
3. **Match Preservation**: Preserves existing match settings if already configured

## User Workflow
1. Navigate to Tournament Admin → Select tournament
2. View division matches in preview section
3. Click ⚙️ button on any match during 'setup' phase
4. Adjust quarters, quarter length, break time, halftime in modal
5. Save settings to apply to specific match
6. Settings persist in database and sync across views

## Database Integration
- Utilizes existing match duration columns from migration `20241102000002_add_match_duration_columns.sql`
- Updates are atomic and immediately reflected in UI
- Maintains data consistency across tournament management views

## Technical Implementation
- **Vue 3 Composition API**: Reactive state management with proper TypeScript typing
- **Modal Pattern**: Consistent with existing create/edit tournament modals
- **Error Handling**: Comprehensive error handling with user feedback
- **State Management**: Local state updates ensure immediate UI feedback

## Benefits
- **Per-Match Customization**: Each tournament match can have unique timing settings
- **Tournament Integration**: Seamlessly inherits tournament defaults while allowing overrides
- **Consistent UX**: Same edit pattern as DivisionManagementView for familiar user experience
- **Administrative Control**: Flexible match configuration during tournament setup phase