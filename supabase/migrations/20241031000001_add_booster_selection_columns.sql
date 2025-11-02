-- Add booster selection columns to matches table
ALTER TABLE matches 
ADD COLUMN IF NOT EXISTS booster_selection_active BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN IF NOT EXISTS booster_selection_phase TEXT DEFAULT NULL,
ADD COLUMN IF NOT EXISTS current_boosters JSONB DEFAULT NULL;

-- Add comment for documentation
COMMENT ON COLUMN matches.booster_selection_active IS 'Whether booster selection is currently active for this match';
COMMENT ON COLUMN matches.booster_selection_phase IS 'Current phase of booster selection (ready, team-a-first, team-a-second, team-b-first, team-b-second, complete)';
COMMENT ON COLUMN matches.current_boosters IS 'Currently selected boosters during the selection process';