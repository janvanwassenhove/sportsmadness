-- Create boosters table
CREATE TABLE IF NOT EXISTS boosters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    icon TEXT, -- URL to icon or emoji
    picture TEXT, -- URL to picture
    has_countdown BOOLEAN NOT NULL DEFAULT true,
    duration INTEGER NOT NULL DEFAULT 60, -- duration in seconds, default 1 minute
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create maddies table
CREATE TABLE IF NOT EXISTS maddies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    icon TEXT, -- URL to icon or emoji
    picture TEXT, -- URL to picture
    duration INTEGER NOT NULL DEFAULT 60, -- duration in seconds, default 1 minute
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE boosters ENABLE ROW LEVEL SECURITY;
ALTER TABLE maddies ENABLE ROW LEVEL SECURITY;

-- Boosters policies
CREATE POLICY "Anyone can view boosters" ON boosters
    FOR SELECT TO authenticated, anon USING (true);

CREATE POLICY "Admins can manage boosters" ON boosters
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Maddies policies  
CREATE POLICY "Anyone can view maddies" ON maddies
    FOR SELECT TO authenticated, anon USING (true);

CREATE POLICY "Admins can manage maddies" ON maddies
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Add tables to realtime publication
ALTER PUBLICATION supabase_realtime ADD TABLE boosters;
ALTER PUBLICATION supabase_realtime ADD TABLE maddies;

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_boosters_updated_at BEFORE UPDATE ON boosters
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_maddies_updated_at BEFORE UPDATE ON maddies
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert some default boosters
INSERT INTO boosters (title, description, icon, has_countdown, duration) VALUES
    ('Power Play', 'Double scoring opportunities for 1 minute', '⚡', true, 60),
    ('Speed Boost', 'Increased movement speed', '🚀', true, 30),
    ('Lucky Shot', 'Next goal counts double', '🍀', false, 0),
    ('Coach Stroke', 'Strategic timeout - stops game clock', '🧠', false, 0),
    ('Penalty Shield', 'Immune to next penalty', '🛡️', true, 45);

-- Insert some default maddies
INSERT INTO maddies (title, description, icon, duration) VALUES
    ('Maddie Magic', 'Random positive effect for the team', '✨', 60),
    ('Maddie Mayhem', 'Chaos mode - unpredictable gameplay', '🌪️', 30),
    ('Maddie Momentum', 'Increased scoring chances', '🔥', 45),
    ('Maddie Shield', 'Temporary protection from penalties', '🔮', 60),
    ('Maddie Boost', 'All team abilities enhanced', '💫', 90);