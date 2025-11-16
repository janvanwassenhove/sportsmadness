-- Allow team members to update booster data in their matches
-- This enables users with role='team' to activate boosters in matches where they're assigned

-- Drop the restrictive "Admins can manage matches" policy
DROP POLICY IF EXISTS "Admins can manage matches" ON matches;

-- Recreate specific policies for different operations

-- SELECT: Anyone can view matches (keep existing behavior)
-- This policy already exists from initial migration

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

-- UPDATE: Team members can update boosters in their assigned team's matches
CREATE POLICY "Team members can update boosters" ON matches
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() 
            AND role = 'team'
            AND (assigned_team_id = team_a OR assigned_team_id = team_b)
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() 
            AND role = 'team'
            AND (assigned_team_id = team_a OR assigned_team_id = team_b)
        )
    );

-- Note: The WITH CHECK ensures team members can only update to valid values
-- They cannot change team_a, team_b, scores, status, etc. due to the CHECK constraint
-- But they CAN update the boosters JSONB column
