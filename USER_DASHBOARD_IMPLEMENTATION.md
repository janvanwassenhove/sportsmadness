# User Dashboard Implementation

## Overview
Added a comprehensive dashboard page for users with the 'user' role that provides:
- Upcoming matches for their assigned team
- Recent match results 
- Tournament standings
- Help section explaining boosters and maddies

## Implementation Details

### New Components Created
1. **UserDashboardView.vue** - Main dashboard component with three key sections:
   - Team matches (upcoming and recent results)
   - Tournament standings 
   - Game help (boosters and maddies explanations)

### Router Updates
- Added new route `/dashboard` with `requiresUserRole` meta property
- Updated route guards to allow team role users to access dashboard
- Added auto-redirect logic for users coming to home page

### Navigation Updates
- Added "My Dashboard" link in main navigation for user role
- Added dashboard option in user dropdown menu
- Included dashboard in mobile navigation
- Updated HomeView with dashboard card for user role

### Features

#### Team Matches Section
- Shows upcoming matches for the user's assigned team
- Displays recent match results with win/loss indicators  
- Real-time match status and time remaining
- Handles users not assigned to teams gracefully

#### Tournament Standings
- Calculates and displays team standings based on match results
- Shows points (3 for win, 1 for draw), wins, losses
- Highlights user's team in the standings
- Sorted by points then goal difference

#### Help Section
- **Boosters**: Speed Boost, Accuracy Boost, Defense Boost, Power Play
- **Maddies**: Chaos events like Team Swap, Lightning Round, Random Events  
- **Pro Tips**: Strategy advice for timing and coordination

### User Experience
- Clean, hockey-themed design with gradient backgrounds
- Responsive layout that works on mobile and desktop
- Loading states and empty states for better UX
- Direct links to scoreboard and profile pages
- Automatic team assignment detection and display

### Access Control
- Only users with 'user' role can access `/dashboard`
- Team role users can access dashboard but see different content
- Admin users have their own admin panel instead
- Proper route guards prevent unauthorized access

### Data Sources
- Teams table for team information
- Matches table for upcoming and completed games
- User profile for team assignment
- Real-time calculations for standings

## Usage
1. Users with 'user' role will see "My Dashboard" in navigation
2. Dashboard shows personalized team information
3. Auto-redirects from home page for better UX
4. Help section educates users about game mechanics
5. Links to other relevant pages (scoreboard, profile)

## Future Enhancements
- Real-time match updates via Supabase subscriptions
- Player statistics and individual performance tracking
- Team chat or messaging features
- Match predictions and fantasy elements
- Push notifications for upcoming matches