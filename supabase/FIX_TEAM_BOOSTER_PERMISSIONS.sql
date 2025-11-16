-- ============================================================================
-- EMERGENCY FIX: Allow team members to update booster data
-- ============================================================================
-- Run this in Supabase SQL Editor to immediately fix the permission issue
-- preventing team members from activating boosters in Match Center View
-- ============================================================================

-- Step 1: Drop the overly restrictive policy
DROP POLICY IF EXISTS "Admins can manage matches" ON matches;

-- Step 2: Create granular policies for matches table

-- SELECT: Anyone can view matches (already exists, but recreating for safety)
DROP POLICY IF EXISTS "Anyone can view matches" ON matches;
CREATE POLICY "Anyone can view matches" ON matches
    FOR SELECT TO authenticated, anon USING (true);

-- INSERT: Only admins can create matches
CREATE POLICY "Admins can insert matches" ON matches
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- DELETE: Only admins can delete matches
CREATE POLICY "Admins can delete matches" ON matches
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- UPDATE: Admins can update everything
CREATE POLICY "Admins can update matches" ON matches
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- UPDATE: Team members can update matches they're assigned to
-- This allows team members to update boosters in their team's matches
CREATE POLICY "Team members can update their matches" ON matches
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() 
            AND role = 'team'
            AND (assigned_team_id = matches.team_a OR assigned_team_id = matches.team_b)
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() 
            AND role = 'team'
            AND (assigned_team_id = matches.team_a OR assigned_team_id = matches.team_b)
        )
    );

-- ============================================================================
-- Verification Query (run this after the above)
-- ============================================================================
-- SELECT 
--   schemaname, 
--   tablename, 
--   policyname, 
--   permissive, 
--   roles, 
--   cmd, 
--   qual, 
--   with_check
-- FROM pg_policies
-- WHERE tablename = 'matches'
-- ORDER BY policyname;
-- ============================================================================
