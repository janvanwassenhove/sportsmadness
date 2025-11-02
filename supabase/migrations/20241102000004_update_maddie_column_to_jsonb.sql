-- Update maddie column from boolean to jsonb to support countdown functionality
-- This migration maintains backward compatibility by handling both boolean and object formats

-- First, add a temporary column
ALTER TABLE matches ADD COLUMN maddie_new JSONB;

-- Migrate existing boolean data to new format
UPDATE matches 
SET maddie_new = CASE 
    WHEN maddie = true THEN 'true'::jsonb
    WHEN maddie = false THEN 'false'::jsonb
    ELSE 'false'::jsonb
END;

-- Drop the old column and rename the new one
ALTER TABLE matches DROP COLUMN maddie;
ALTER TABLE matches RENAME COLUMN maddie_new TO maddie;

-- Set default value
ALTER TABLE matches ALTER COLUMN maddie SET DEFAULT 'false'::jsonb;
ALTER TABLE matches ALTER COLUMN maddie SET NOT NULL;

-- Add comment explaining the new format
COMMENT ON COLUMN matches.maddie IS 'Can be boolean (legacy) or object with {id, name, countdown, activated, etc.} properties for new maddie system';