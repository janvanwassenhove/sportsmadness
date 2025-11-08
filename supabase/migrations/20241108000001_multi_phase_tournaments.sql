-- Multi-Phase Tournament Support
-- Enhances tournaments to support complex multi-phase configurations

-- Add tournament type and phases configuration to tournaments table
ALTER TABLE tournaments 
ADD COLUMN IF NOT EXISTS tournament_type TEXT DEFAULT 'simple' CHECK (tournament_type IN ('simple', 'group', 'mixed', 'knockout'));

ALTER TABLE tournaments 
ADD COLUMN IF NOT EXISTS phases JSONB DEFAULT '[]'::jsonb;

-- Add phase configuration to divisions
ALTER TABLE tournament_divisions 
ADD COLUMN IF NOT EXISTS phase_order INTEGER DEFAULT 0;

ALTER TABLE tournament_divisions 
ADD COLUMN IF NOT EXISTS phase_config JSONB DEFAULT '{}'::jsonb;

-- Update the type constraint to include standalone
ALTER TABLE tournament_divisions 
DROP CONSTRAINT IF EXISTS tournament_divisions_type_check;

ALTER TABLE tournament_divisions 
ADD CONSTRAINT tournament_divisions_type_check 
CHECK (type IN ('group', 'knockout', 'standalone'));

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_tournaments_type ON tournaments(tournament_type);
CREATE INDEX IF NOT EXISTS idx_divisions_phase_order ON tournament_divisions(tournament_id, phase_order);

-- Comments for documentation
COMMENT ON COLUMN tournaments.tournament_type IS 'Type of tournament structure: simple (traditional), group (group phase only), mixed (group + knockout), knockout (knockout only)';
COMMENT ON COLUMN tournaments.phases IS 'Array of phase configurations for multi-phase tournaments';
COMMENT ON COLUMN tournament_divisions.phase_order IS 'Order of this division within the tournament phases';
COMMENT ON COLUMN tournament_divisions.phase_config IS 'Phase-specific configuration (groups, participants, match types, etc.)';