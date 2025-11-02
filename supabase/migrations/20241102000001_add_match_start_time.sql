-- Add start_time column to matches table for tournament scheduling

ALTER TABLE matches 
ADD COLUMN IF NOT EXISTS start_time TIME DEFAULT '09:00:00';

-- Update existing matches to have a default start time
UPDATE matches 
SET start_time = '09:00:00'
WHERE start_time IS NULL;

-- Add comment to document the column
COMMENT ON COLUMN matches.start_time IS 'Scheduled start time for the match (time only, date is managed separately)';