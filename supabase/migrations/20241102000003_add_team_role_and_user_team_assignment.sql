-- Add 'team' role to users table and team assignment
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check;
ALTER TABLE users ADD CONSTRAINT users_role_check CHECK (role IN ('admin', 'user', 'team'));

-- Add team assignment column
ALTER TABLE users ADD COLUMN assigned_team_id UUID REFERENCES teams(id) ON DELETE SET NULL;

-- Update existing users policies to handle team role
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Admins can view all users" ON users;

-- Users can view own profile
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (auth.uid() = id);

-- Admins can view and manage all users
CREATE POLICY "Admins can view all users" ON users
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

CREATE POLICY "Admins can update all users" ON users
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

CREATE POLICY "Admins can insert new users" ON users
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

CREATE POLICY "Admins can delete users" ON users
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Users can update their own profile (limited fields)
CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (auth.uid() = id)
    WITH CHECK (
        auth.uid() = id AND 
        -- Users cannot change their own role or team assignment
        role = (SELECT role FROM users WHERE id = auth.uid()) AND
        assigned_team_id = (SELECT assigned_team_id FROM users WHERE id = auth.uid())
    );

-- Users assigned to teams can view their assigned team details
CREATE POLICY "Assigned users can view their team" ON teams
    FOR SELECT USING (
        id IN (
            SELECT assigned_team_id FROM users 
            WHERE id = auth.uid() AND assigned_team_id IS NOT NULL
        )
    );

-- Add index for better performance
CREATE INDEX IF NOT EXISTS idx_users_assigned_team_id ON users(assigned_team_id);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);

-- Create function to handle user deletion from auth
CREATE OR REPLACE FUNCTION handle_auth_user_deleted()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
    DELETE FROM public.users WHERE id = OLD.id;
    RETURN OLD;
END;
$$;

-- Trigger to clean up users table when auth user is deleted
CREATE TRIGGER on_auth_user_deleted
    AFTER DELETE ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_auth_user_deleted();