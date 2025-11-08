# Scoreboard Match Selection Implementation

## Overview
Enhanced the scoreboard functionality to support match-specific navigation and intelligent match selection when multiple matches are running simultaneously.

## Features Implemented

### 1. Match-Specific Scoreboard URLs
- **New Route**: `/scoreboard/:id` - Display scoreboard for a specific match
- **Existing Route**: `/scoreboard` - Auto-select appropriate match or show selector

### 2. Intelligent Match Selection Logic
When accessing `/scoreboard` without a specific match ID:

1. **Single Active/Paused Match**: Automatically display that match
2. **Multiple Active/Paused Matches**: Show match selector modal
3. **Single Initialized Pending Match**: Automatically display that match  
4. **Multiple Initialized Pending Matches**: Show match selector modal
5. **Multiple Pending Matches**: Show match selector modal
6. **Single Pending Match**: Display as fallback

### 3. Match Control Integration
- **Enhanced Navigation**: MatchControlView now links to `/scoreboard/{matchId}` 
- **Direct Link**: Opens scoreboard for the specific match being controlled
- **Target Blank**: Opens in new tab to maintain match control workflow

### 4. Match Selector Modal
- **Responsive Design**: Clean modal with match information
- **Match Details**: Shows team names, scores, time left, and status
- **Status Indicators**: Color-coded badges (LIVE, PAUSED, READY, FINISHED)
- **Interactive Selection**: Click to select match
- **Multilingual Support**: Full translation support

### 5. URL Management
- **Automatic Updates**: URL updates when match is selected via modal
- **Direct Access**: Support for bookmarking specific match scoreboards
- **Error Handling**: Graceful fallback if specific match ID is invalid

## Technical Implementation

### Router Changes
```typescript
// Added new route with match ID parameter
{
  path: '/scoreboard/:id',
  name: 'scoreboard-match', 
  component: () => import('../views/ScoreboardView.vue'),
  props: true,
}
```

### ScoreboardView Enhancements
- **Props Support**: Accepts optional `id` parameter for specific match
- **Enhanced Logic**: `loadCurrentMatch()` function with intelligent selection
- **Match Selector**: Modal component for multi-match scenarios
- **Helper Functions**: Match display name formatting and status handling

### MatchControlView Updates
- **Dynamic Link**: RouterLink uses `to="/scoreboard/${match.id}"`
- **Maintains Workflow**: Opens in new tab to preserve match control interface

### Translation Support
Added new translation keys in all languages (EN, NL, FR):
- `scoreboard.selectMatch`: "Select Match" 
- `scoreboard.multipleMatchesFound`: Instructions for match selection
- `scoreboard.time`: "Time" (for match selector)

## User Experience

### From Match Control
1. Admin clicks "📺 Open Scoreboard" button
2. Scoreboard opens in new tab showing the specific match
3. Admin maintains match control workflow
4. Scoreboard stays synchronized with the controlled match

### From Navigation Menu
1. User clicks "Scoreboard" in navigation
2. **If single match running**: Displays immediately
3. **If multiple matches**: Shows selection modal with:
   - Team names for each match
   - Current scores
   - Time remaining  
   - Match status badges
4. User clicks desired match
5. Scoreboard displays selected match
6. URL updates to include match ID for bookmarking

### Direct URL Access
- **Specific Match**: `/scoreboard/match-id-123` - Shows that match directly
- **Invalid Match**: Gracefully falls back to match selector or auto-selection
- **Bookmarkable**: URLs can be saved and shared

## Error Handling
- **Invalid Match ID**: Falls back to available matches selector
- **No Matches**: Shows "No Active Match" message
- **Database Errors**: Graceful error logging and user feedback
- **Network Issues**: Maintains loading states and retry capability

## Benefits
1. **Admin Efficiency**: Direct access from match control to relevant scoreboard
2. **Multi-Match Support**: Clean interface when multiple games run simultaneously  
3. **Flexible Navigation**: Works from both specific match control and general navigation
4. **Bookmarkable**: URLs can be saved for specific match scoreboards
5. **Multilingual**: Full internationalization support
6. **Responsive**: Works across all device sizes

## Future Enhancements
- **Match History**: Could extend to show finished matches
- **Tournament View**: Multiple scoreboards in split-screen mode
- **Auto-Refresh**: Periodic check for new matches
- **Match Filtering**: Filter by tournament, status, or teams