# 🔧 URGENT FIX: Booster Activation Not Working

## Root Cause
The database Row-Level Security (RLS) policy is **blocking team members from updating matches**. Only admins can update the matches table, which prevents team users in Match Center from saving booster activations to the database.

## The Problem in Your Logs
```
📝 MatchCenter: Supabase update result: {status: 204}  ← Supabase says "success"
📊 POLLING: New database boosters: {"activated": false} ← But data wasn't saved!
```

Supabase returns HTTP 204 (success) because the request was valid, but the RLS policy **silently rejected the update**, so the data never persisted.

## The Fix

### Option 1: Run SQL in Supabase Dashboard (FASTEST - 2 minutes)

1. Go to your Supabase project dashboard
2. Click **SQL Editor** in the left sidebar
3. Click **New Query**
4. Copy the entire contents of `supabase/FIX_TEAM_BOOSTER_PERMISSIONS.sql`
5. Paste into the editor
6. Click **RUN** (or press Ctrl+Enter)
7. You should see: "Success. No rows returned"

### Option 2: Apply Migration (if using local Supabase)

```bash
cd supabase
npx supabase db reset
```

## Verify the Fix

Run this query in Supabase SQL Editor to check policies:

```sql
SELECT 
  policyname, 
  cmd, 
  roles
FROM pg_policies
WHERE tablename = 'matches'
ORDER BY policyname;
```

You should see 5 policies:
- ✅ "Admins can delete matches" (DELETE)
- ✅ "Admins can insert matches" (INSERT)
- ✅ "Admins can update matches" (UPDATE)
- ✅ "Anyone can view matches" (SELECT)
- ✅ **"Team members can update their matches" (UPDATE)** ← NEW!

## What Changed

**Before:**
```sql
-- Only admins could do ANYTHING
CREATE POLICY "Admins can manage matches" ON matches
    FOR ALL USING (role = 'admin');
```

**After:**
```sql
-- Admins can update everything
CREATE POLICY "Admins can update matches" ON matches
    FOR UPDATE USING (role = 'admin');

-- Team members can update THEIR team's matches
CREATE POLICY "Team members can update their matches" ON matches
    FOR UPDATE USING (
        role = 'team' AND 
        (assigned_team_id = team_a OR assigned_team_id = team_b)
    );
```

## Test After Fix

1. Open Match Center View as a team member
2. Click a booster button
3. Wait 7 seconds for countdown
4. Check **Match Control View** and **Scoreboard View**
5. ✅ You should now see the activated booster!

## Technical Details

The RLS policy checks:
- User has `role = 'team'` 
- User's `assigned_team_id` matches either `team_a` OR `team_b` in the match
- This allows team members to update boosters but prevents them from:
  - Updating matches they're not assigned to
  - Changing scores (requires admin)
  - Changing match status (requires admin)
  - Modifying other teams' data

## Next Steps After Fix

Once this is applied:
1. The merge strategy will work as designed
2. Match Center will successfully save booster activations
3. Supabase will broadcast changes via real-time
4. Match Control and Scoreboard will receive updates immediately
5. The protection window will preserve countdown state locally while still broadcasting to other clients
