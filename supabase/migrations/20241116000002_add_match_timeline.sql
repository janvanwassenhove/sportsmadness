-- Add timeline column to matches table for tracking all match events
ALTER TABLE matches 
ADD COLUMN IF NOT EXISTS timeline JSONB NOT NULL DEFAULT '[]'::jsonb;

-- Add comment explaining the timeline structure
COMMENT ON COLUMN matches.timeline IS 'Array of timestamped events: goals, boosters, maddies, cards, etc.';

-- Example timeline event structure:
-- {
--   "type": "goal" | "booster_activated" | "maddie_activated" | "card_issued" | "match_started" | "match_paused" | "match_finished",
--   "timestamp": "2024-11-16T10:30:00Z",
--   "team": "a" | "b" | null,
--   "details": {
--     // Type-specific details
--     // For goals: { "score_a": 1, "score_b": 0, "pc": false }
--     // For boosters: { "booster_name": "Double the Ball", "booster_icon": "⚡", "duration": 2 }
--     // For maddies: { "maddie_name": "Frozen Field", "maddie_icon": "❄️", "duration": 3 }
--     // For cards: { "card_type": "yellow" | "green" | "red", "player_name": "John Doe", "player_number": 10, "duration": 120 }
--   }
-- }
