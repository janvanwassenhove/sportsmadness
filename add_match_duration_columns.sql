-- Add match duration and scheduling columns to existing tournaments table
-- Run this SQL in your Supabase SQL Editor

ALTER TABLE tournaments 
ADD COLUMN IF NOT EXISTS quarters_count INTEGER NOT NULL DEFAULT 4,
ADD COLUMN IF NOT EXISTS quarter_duration_minutes INTEGER NOT NULL DEFAULT 15,
ADD COLUMN IF NOT EXISTS break_duration_minutes INTEGER NOT NULL DEFAULT 2,
ADD COLUMN IF NOT EXISTS halftime_duration_minutes INTEGER NOT NULL DEFAULT 10,
ADD COLUMN IF NOT EXISTS tournament_start_time TIME DEFAULT '09:00:00',
ADD COLUMN IF NOT EXISTS match_gap_minutes INTEGER NOT NULL DEFAULT 15;

-- Update existing tournaments to have default values (if any exist)
UPDATE tournaments 
SET 
    quarters_count = COALESCE(quarters_count, 4),
    quarter_duration_minutes = COALESCE(quarter_duration_minutes, 15),
    break_duration_minutes = COALESCE(break_duration_minutes, 2),
    halftime_duration_minutes = COALESCE(halftime_duration_minutes, 10),
    tournament_start_time = COALESCE(tournament_start_time, '09:00:00'::TIME),
    match_gap_minutes = COALESCE(match_gap_minutes, 15)
WHERE 
    quarters_count IS NULL 
    OR quarter_duration_minutes IS NULL 
    OR break_duration_minutes IS NULL 
    OR halftime_duration_minutes IS NULL
    OR tournament_start_time IS NULL
    OR match_gap_minutes IS NULL;