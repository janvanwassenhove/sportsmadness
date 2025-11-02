# Player-Level Cards Implementation

## Overview
I've implemented a comprehensive player-level card system for the Hockey Madness tournament management application. This system replaces the previous team-level cards with individual player penalties and countdown timers.

## Features Implemented

### 🏒 Player-Level Card System
- **Yellow Card**: 5-minute penalty
- **Green Card**: 2-minute penalty  
- **Red Card**: Out for the entire game

### ⏱️ Countdown Timers
- Real-time countdown for yellow and green cards
- Red cards show "GAME" (no countdown, permanent exclusion)
- Automatic penalty expiration and cleanup

### 🎮 Match Control Interface
- Card buttons directly on each player's row
- Visual penalty status display with countdown
- Real-time updates during active matches

### 📺 Scoreboard Display
- Shows active player penalties with countdown timers
- Color-coded penalty indicators
- Player number and name identification

### 🎰 Casino Booster System
- **Pre-Match Only**: Can only be activated when match status is 'pending'
- **Slot Machine Animation**: 2-second spinning casino-style selection
- **Random Assignment**: Each team gets 2 different boosters
- **Visual Effects**: Glowing animations and casino-themed UI

### Available Boosters
1. **🥅 Goalie Timeout** (1 min): Other team loses goalkeeper for one minute
2. **🎯 Coach Stroke**: The coach gets to set a stroke (instant effect)  
3. **⚡ Double Goal** (1 min): Next goal scored counts double
4. **👑 Drop the MVP** (1 min): Choose opponent player (not keeper) to leave field
5. **🧱 Loose the Wall** (1 min): Other team can't use boarding

## Technical Implementation

### Database Schema Changes
```sql
-- New columns added to matches table
ALTER TABLE matches ADD COLUMN player_cards JSONB NOT NULL DEFAULT '{}'::jsonb;
ALTER TABLE matches ADD COLUMN player_penalties JSONB NOT NULL DEFAULT '{}'::jsonb;
```

**Data Structure:**
- `player_cards`: Historical record of all cards issued
- `player_penalties`: Active penalties with expiration timestamps

### Vue.js Components Updated

#### MatchControlView.vue
- Added player-level card functions (`addCardToPlayer`)
- Implemented penalty countdown logic (`startPenaltyTimer`)
- Updated UI to show card buttons on each player
- Added real-time penalty status display

#### ScoreboardView.vue  
- Added `getActivePenalties` function
- Updated template to display active player penalties
- Added penalty countdown formatting

### Key Functions

#### Card Assignment
```javascript
async function addCardToPlayer(team: 'a' | 'b', player: Player, cardType: 'yellow' | 'green' | 'red') {
  // Calculate penalty duration
  const penaltyDuration = cardType === 'yellow' ? 5*60*1000 : 
                         cardType === 'green' ? 2*60*1000 : 0;
  
  // Create penalty record with expiration
  const penalty = {
    type: cardType,
    expires_at: cardType === 'red' ? 'never' : new Date(Date.now() + penaltyDuration).toISOString()
  };
  
  // Update database with new penalty
  await updateMatch({ player_penalties: updatedPenalties });
}
```

#### Penalty Countdown
```javascript
function startPenaltyTimer() {
  penaltyTimer.value = setInterval(async () => {
    // Check for expired penalties every second
    // Automatically remove expired penalties from database
  }, 1000);
}
```

## Demo Implementation

I've created a working demo at `/public/player-cards-demo.html` that showcases:

- **Interactive Player Cards**: Click Y/G/R buttons to assign cards
- **Live Countdown**: Watch penalties count down in real-time
- **Scoreboard Integration**: See how penalties appear on the public scoreboard
- **Automatic Expiration**: Penalties automatically disappear when time is up

## Benefits

### For Tournament Administrators
- ✅ Precise penalty tracking per player
- ✅ Automatic timing management
- ✅ Visual confirmation of penalty status
- ✅ Historical record of all cards issued

### For Spectators
- ✅ Clear visibility of active penalties
- ✅ Real-time countdown information
- ✅ Player identification (#number + name)
- ✅ Color-coded penalty types

### For System Reliability
- ✅ Automatic cleanup of expired penalties
- ✅ Database triggers for consistency
- ✅ Real-time synchronization across views
- ✅ Backward compatibility with existing team cards

## Usage Instructions

### Booster Selection (Pre-Match)
1. **Before Match Starts**: Click "🎰 Spin Casino Boosters" button
2. **Spin the Slots**: Click to start the 2-second animation
3. **Review Results**: Each team gets 2 random boosters
4. **Confirm or Re-spin**: Confirm selection or cancel to try again
5. **Locked In**: Once confirmed, boosters are assigned to the match

### During Match Control
1. Navigate to Match Control view for active game
2. Find the player in the team roster
3. Click the appropriate card button (Y/G/R)
4. Penalty immediately appears with countdown
5. Timer automatically decreases until expiration
6. **Use Boosters**: Click "Use" button on any unused booster during active match

### On Public Scoreboard
1. Active penalties display below team scores
2. Shows player number, name, and time remaining
3. Updates in real-time as penalties expire
4. Color-coded by penalty type

## Future Enhancements

### Potential Additions
- **Penalty Appeal System**: Allow removing cards before expiration
- **Multiple Penalties**: Handle multiple cards per player
- **Penalty Statistics**: Track penalty patterns per player/team
- **Sound Notifications**: Audio alerts for card issuance/expiration
- **Mobile Optimization**: Touch-friendly card assignment

### Integration Opportunities
- **Player Substitution**: Automatically handle penalized player substitutions
- **Team Strategy**: Show team composition considering active penalties
- **Tournament Statistics**: Aggregate penalty data across matches

## Files Modified

### Core Application
- `apps/frontend/src/views/MatchControlView.vue` - Main control interface
- `apps/frontend/src/views/ScoreboardView.vue` - Public display
- `supabase/migrations/20241030000002_player_cards.sql` - Database schema

### Demo Files
- `apps/frontend/public/player-cards-demo.html` - Interactive demonstration

The implementation is production-ready and maintains full backward compatibility with the existing system while adding the requested player-level penalty functionality with countdown timers.