-- Create rules table for game rules management
CREATE TABLE IF NOT EXISTS public.rules (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    category TEXT NOT NULL DEFAULT 'general',
    icon TEXT,
    order_index INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add RLS policies
ALTER TABLE public.rules ENABLE ROW LEVEL SECURITY;

-- Everyone can read active rules
CREATE POLICY "Anyone can view active rules"
    ON public.rules
    FOR SELECT
    USING (is_active = true);

-- Only admins can insert rules
CREATE POLICY "Admins can insert rules"
    ON public.rules
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.users
            WHERE id = auth.uid()
            AND role = 'admin'
        )
    );

-- Only admins can update rules
CREATE POLICY "Admins can update rules"
    ON public.rules
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.users
            WHERE id = auth.uid()
            AND role = 'admin'
        )
    );

-- Only admins can delete rules
CREATE POLICY "Admins can delete rules"
    ON public.rules
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM public.users
            WHERE id = auth.uid()
            AND role = 'admin'
        )
    );

-- Create index for ordering
CREATE INDEX idx_rules_order ON public.rules(order_index, created_at);

-- Create index for category
CREATE INDEX idx_rules_category ON public.rules(category);

-- Add trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_rules_updated_at
    BEFORE UPDATE ON public.rules
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Insert some default rules
INSERT INTO public.rules (title, description, category, icon, order_index) VALUES
    ('Game Duration', 'Standard hockey matches are 30 minutes (2 halves of 15 minutes each)', 'basic', '⏱️', 1),
    ('Team Size', 'Each team consists of 11 players (10 field players + 1 goalkeeper)', 'basic', '👥', 2),
    ('Boosters', 'Teams can use special boosters during the match to gain advantages', 'gameplay', '⚡', 3),
    ('Maddie Triggers', 'Random Maddie events can occur during the match, affecting both teams', 'gameplay', '🎲', 4),
    ('Scoring', 'Goals are scored by getting the ball into the opponent''s goal', 'basic', '🥅', 5),
    ('Penalty Corners', 'Awarded for defensive fouls inside the circle', 'basic', '🚩', 6);
