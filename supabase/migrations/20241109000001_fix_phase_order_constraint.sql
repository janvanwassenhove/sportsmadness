-- Fix Phase Order Constraint
-- Updates the unique constraint to use phase_order instead of order_index

-- Drop the old constraint that uses order_index
ALTER TABLE tournament_divisions 
DROP CONSTRAINT IF EXISTS unique_tournament_division_order;

-- Add new constraint using phase_order
ALTER TABLE tournament_divisions 
ADD CONSTRAINT unique_tournament_division_phase_order 
UNIQUE (tournament_id, phase_order);

-- Also make sure we have a default value for phase_order for existing records
UPDATE tournament_divisions 
SET phase_order = COALESCE(phase_order, order_index)
WHERE phase_order IS NULL OR phase_order = 0;

-- Comment for documentation
COMMENT ON CONSTRAINT unique_tournament_division_phase_order ON tournament_divisions 
IS 'Ensures unique phase ordering within each tournament';