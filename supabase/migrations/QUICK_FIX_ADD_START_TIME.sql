-- QUICK FIX: Run this SQL in your Supabase SQL Editor to add the missing start_time column

ALTER TABLE matches 
ADD COLUMN IF NOT EXISTS start_time TIME DEFAULT '09:00:00';

-- Update existing matches to have a default start time
UPDATE matches 
SET start_time = '09:00:00'
WHERE start_time IS NULL;

-- Verify the column was added successfully
SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'matches' 
AND column_name = 'start_time';