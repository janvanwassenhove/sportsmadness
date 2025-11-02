-- Add max_teams_per_group to tournaments table
ALTER TABLE tournaments 
ADD COLUMN IF NOT EXISTS max_teams_per_group INTEGER NOT NULL DEFAULT 4;