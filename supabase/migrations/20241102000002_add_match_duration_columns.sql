-- Add match duration columns to matches table

ALTER TABLE matches 
ADD COLUMN IF NOT EXISTS quarters_count INTEGER,
ADD COLUMN IF NOT EXISTS quarter_duration_minutes INTEGER,
ADD COLUMN IF NOT EXISTS break_duration_minutes INTEGER,
ADD COLUMN IF NOT EXISTS halftime_duration_minutes INTEGER;

-- Add comments to document the columns
COMMENT ON COLUMN matches.quarters_count IS 'Number of quarters for this match (overrides tournament default if set)';
COMMENT ON COLUMN matches.quarter_duration_minutes IS 'Duration of each quarter in minutes (overrides tournament default if set)';
COMMENT ON COLUMN matches.break_duration_minutes IS 'Break time between quarters in minutes (overrides tournament default if set)';
COMMENT ON COLUMN matches.halftime_duration_minutes IS 'Halftime duration in minutes (overrides tournament default if set)';