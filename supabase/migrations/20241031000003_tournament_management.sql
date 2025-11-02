-- Tournament Management Schema
-- Adds comprehensive tournament functionality with tournaments, divisions, and enhanced match tracking

-- Create tournaments table
CREATE TABLE IF NOT EXISTS tournaments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    description TEXT,
    status TEXT NOT NULL DEFAULT 'setup' CHECK (status IN ('setup', 'active', 'finished')),
    -- Match duration configuration
    quarters_count INTEGER NOT NULL DEFAULT 4,
    quarter_duration_minutes INTEGER NOT NULL DEFAULT 15,
    break_duration_minutes INTEGER NOT NULL DEFAULT 2,
    halftime_duration_minutes INTEGER NOT NULL DEFAULT 10,
    -- Match scheduling configuration
    tournament_start_time TIME DEFAULT '09:00:00',
    match_gap_minutes INTEGER NOT NULL DEFAULT 15,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create tournament divisions table
CREATE TABLE IF NOT EXISTS tournament_divisions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('group', 'knockout')),
    order_index INTEGER NOT NULL DEFAULT 0,
    settings JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT unique_tournament_division_name UNIQUE (tournament_id, name),
    CONSTRAINT unique_tournament_division_order UNIQUE (tournament_id, order_index)
);

-- Create tournament groups table (for group phase divisions)
CREATE TABLE IF NOT EXISTS tournament_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    division_id UUID NOT NULL REFERENCES tournament_divisions(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    order_index INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT unique_division_group_name UNIQUE (division_id, name),
    CONSTRAINT unique_division_group_order UNIQUE (division_id, order_index)
);

-- Create tournament team participations table
CREATE TABLE IF NOT EXISTS tournament_team_participations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    group_id UUID REFERENCES tournament_groups(id) ON DELETE SET NULL,
    position_in_group INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT unique_tournament_team UNIQUE (tournament_id, team_id),
    CONSTRAINT unique_group_position UNIQUE (group_id, position_in_group)
);

-- Add tournament context to matches table
ALTER TABLE matches 
ADD COLUMN IF NOT EXISTS tournament_id UUID REFERENCES tournaments(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS division_id UUID REFERENCES tournament_divisions(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS group_id UUID REFERENCES tournament_groups(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS match_type TEXT DEFAULT 'friendly' CHECK (match_type IN ('friendly', 'group', 'knockout')),
ADD COLUMN IF NOT EXISTS round_number INTEGER DEFAULT 1,
ADD COLUMN IF NOT EXISTS match_order INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS penalty_shootout JSONB DEFAULT NULL; -- For knockout ties: {"team_a": [goals], "team_b": [goals]}

-- Create tournament standings view for group phases
CREATE OR REPLACE VIEW tournament_group_standings AS
WITH match_results AS (
    SELECT 
        m.tournament_id,
        m.group_id,
        m.team_a as team_id,
        CASE 
            WHEN m.status = 'finished' AND m.score_a > m.score_b THEN 3
            WHEN m.status = 'finished' AND m.score_a = m.score_b THEN 1
            ELSE 0
        END as points,
        CASE WHEN m.status = 'finished' THEN m.score_a ELSE 0 END as goals_for,
        CASE WHEN m.status = 'finished' THEN m.score_b ELSE 0 END as goals_against,
        CASE WHEN m.status = 'finished' THEN 1 ELSE 0 END as games_played,
        CASE 
            WHEN m.status = 'finished' AND m.score_a > m.score_b THEN 1
            ELSE 0
        END as wins,
        CASE 
            WHEN m.status = 'finished' AND m.score_a = m.score_b THEN 1
            ELSE 0
        END as draws,
        CASE 
            WHEN m.status = 'finished' AND m.score_a < m.score_b THEN 1
            ELSE 0
        END as losses
    FROM matches m
    WHERE m.match_type = 'group' AND m.group_id IS NOT NULL
    
    UNION ALL
    
    SELECT 
        m.tournament_id,
        m.group_id,
        m.team_b as team_id,
        CASE 
            WHEN m.status = 'finished' AND m.score_b > m.score_a THEN 3
            WHEN m.status = 'finished' AND m.score_b = m.score_a THEN 1
            ELSE 0
        END as points,
        CASE WHEN m.status = 'finished' THEN m.score_b ELSE 0 END as goals_for,
        CASE WHEN m.status = 'finished' THEN m.score_a ELSE 0 END as goals_against,
        CASE WHEN m.status = 'finished' THEN 1 ELSE 0 END as games_played,
        CASE 
            WHEN m.status = 'finished' AND m.score_b > m.score_a THEN 1
            ELSE 0
        END as wins,
        CASE 
            WHEN m.status = 'finished' AND m.score_b = m.score_a THEN 1
            ELSE 0
        END as draws,
        CASE 
            WHEN m.status = 'finished' AND m.score_b < m.score_a THEN 1
            ELSE 0
        END as losses
    FROM matches m
    WHERE m.match_type = 'group' AND m.group_id IS NOT NULL
)
SELECT 
    mr.tournament_id,
    mr.group_id,
    mr.team_id,
    t.name as team_name,
    tg.name as group_name,
    SUM(mr.points) as points,
    SUM(mr.games_played) as games_played,
    SUM(mr.wins) as wins,
    SUM(mr.draws) as draws,
    SUM(mr.losses) as losses,
    SUM(mr.goals_for) as goals_for,
    SUM(mr.goals_against) as goals_against,
    (SUM(mr.goals_for) - SUM(mr.goals_against)) as goal_difference,
    ROW_NUMBER() OVER (
        PARTITION BY mr.group_id 
        ORDER BY 
            SUM(mr.points) DESC,
            (SUM(mr.goals_for) - SUM(mr.goals_against)) DESC,
            SUM(mr.goals_for) DESC,
            t.name ASC
    ) as position
FROM match_results mr
JOIN teams t ON t.id = mr.team_id
JOIN tournament_groups tg ON tg.id = mr.group_id
GROUP BY mr.tournament_id, mr.group_id, mr.team_id, t.name, tg.name;

-- Create function to auto-generate group phase matches
CREATE OR REPLACE FUNCTION generate_group_matches(group_uuid UUID)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    team_record RECORD;
    team_a_record RECORD;
    team_b_record RECORD;
    division_record RECORD;
    tournament_record RECORD;
    match_counter INTEGER := 1;
BEGIN
    -- Get division and tournament info
    SELECT td.*, t.id as tournament_id 
    INTO division_record 
    FROM tournament_divisions td
    JOIN tournaments t ON t.id = td.tournament_id
    JOIN tournament_groups tg ON tg.division_id = td.id
    WHERE tg.id = group_uuid;
    
    -- Generate round-robin matches for all teams in the group
    FOR team_a_record IN 
        SELECT ttp.team_id, ttp.position_in_group
        FROM tournament_team_participations ttp
        WHERE ttp.group_id = group_uuid
        ORDER BY ttp.position_in_group
    LOOP
        FOR team_b_record IN 
            SELECT ttp.team_id, ttp.position_in_group
            FROM tournament_team_participations ttp
            WHERE ttp.group_id = group_uuid 
            AND ttp.position_in_group > team_a_record.position_in_group
            ORDER BY ttp.position_in_group
        LOOP
            INSERT INTO matches (
                tournament_id, 
                division_id, 
                group_id, 
                team_a, 
                team_b, 
                match_type, 
                round_number, 
                match_order,
                status
            ) VALUES (
                division_record.tournament_id,
                division_record.id,
                group_uuid,
                team_a_record.team_id,
                team_b_record.team_id,
                'group',
                1,
                match_counter,
                'pending'
            );
            
            match_counter := match_counter + 1;
        END LOOP;
    END LOOP;
END;
$$;

-- Create function to auto-generate knockout matches
CREATE OR REPLACE FUNCTION generate_knockout_matches(division_uuid UUID, team_ids UUID[])
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    tournament_record RECORD;
    team_count INTEGER;
    round_num INTEGER := 1;
    match_counter INTEGER := 1;
    i INTEGER;
BEGIN
    -- Get tournament info
    SELECT t.* 
    INTO tournament_record 
    FROM tournaments t
    JOIN tournament_divisions td ON td.tournament_id = t.id
    WHERE td.id = division_uuid;
    
    team_count := array_length(team_ids, 1);
    
    -- Generate first round matches
    FOR i IN 1..team_count BY 2 LOOP
        IF i + 1 <= team_count THEN
            INSERT INTO matches (
                tournament_id, 
                division_id, 
                team_a, 
                team_b, 
                match_type, 
                round_number, 
                match_order,
                status
            ) VALUES (
                tournament_record.id,
                division_uuid,
                team_ids[i],
                team_ids[i + 1],
                'knockout',
                round_num,
                match_counter,
                'pending'
            );
            
            match_counter := match_counter + 1;
        END IF;
    END LOOP;
END;
$$;

-- Add RLS policies for new tables
ALTER TABLE tournaments ENABLE ROW LEVEL SECURITY;
ALTER TABLE tournament_divisions ENABLE ROW LEVEL SECURITY;
ALTER TABLE tournament_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE tournament_team_participations ENABLE ROW LEVEL SECURITY;

-- Tournaments policies
CREATE POLICY "Anyone can view tournaments" ON tournaments
    FOR SELECT TO authenticated, anon USING (true);

CREATE POLICY "Admins can manage tournaments" ON tournaments
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Tournament divisions policies
CREATE POLICY "Anyone can view tournament divisions" ON tournament_divisions
    FOR SELECT TO authenticated, anon USING (true);

CREATE POLICY "Admins can manage tournament divisions" ON tournament_divisions
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Tournament groups policies
CREATE POLICY "Anyone can view tournament groups" ON tournament_groups
    FOR SELECT TO authenticated, anon USING (true);

CREATE POLICY "Admins can manage tournament groups" ON tournament_groups
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Tournament team participations policies
CREATE POLICY "Anyone can view tournament participations" ON tournament_team_participations
    FOR SELECT TO authenticated, anon USING (true);

CREATE POLICY "Admins can manage tournament participations" ON tournament_team_participations
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Add tournament tables to realtime publication
ALTER PUBLICATION supabase_realtime ADD TABLE tournaments;
ALTER PUBLICATION supabase_realtime ADD TABLE tournament_divisions;
ALTER PUBLICATION supabase_realtime ADD TABLE tournament_groups;
ALTER PUBLICATION supabase_realtime ADD TABLE tournament_team_participations;

-- Add updated_at trigger for tournaments
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_tournaments_updated_at 
    BEFORE UPDATE ON tournaments 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();