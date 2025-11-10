-- Add penalty corner columns to matches table
ALTER TABLE matches 
ADD COLUMN IF NOT EXISTS pc_a INTEGER NOT NULL DEFAULT 0,
ADD COLUMN IF NOT EXISTS pc_b INTEGER NOT NULL DEFAULT 0;

-- Add comment for clarity
COMMENT ON COLUMN matches.pc_a IS 'Penalty corners count for team A';
COMMENT ON COLUMN matches.pc_b IS 'Penalty corners count for team B';