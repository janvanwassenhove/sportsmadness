-- Add player_cards column to matches table for tracking individual player penalties
-- Structure: { "team_a": { "player_id": { "yellow": [timestamps], "green": [timestamps], "red": [timestamps] } }, "team_b": { ... } }
-- Each penalty has start timestamp for countdown calculation

ALTER TABLE matches ADD COLUMN IF NOT EXISTS player_cards JSONB NOT NULL DEFAULT '{}'::jsonb;

-- Add player_penalties column for active penalties with countdown timers
-- Structure: { "team_a": { "player_id": { "type": "yellow/green/red", "expires_at": timestamp } }, "team_b": { ... } }
ALTER TABLE matches ADD COLUMN IF NOT EXISTS player_penalties JSONB NOT NULL DEFAULT '{}'::jsonb;

-- Create function to cleanup expired penalties
CREATE OR REPLACE FUNCTION cleanup_expired_penalties()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    team_key text;
    player_key text;
    penalty_data jsonb;
    updated_penalties jsonb := NEW.player_penalties;
    current_time timestamptz := NOW();
BEGIN
    -- Loop through teams
    FOR team_key IN SELECT jsonb_object_keys(NEW.player_penalties)
    LOOP
        -- Loop through players in each team
        FOR player_key IN SELECT jsonb_object_keys(NEW.player_penalties -> team_key)
        LOOP
            penalty_data := NEW.player_penalties -> team_key -> player_key;
            
            -- Check if penalty has expired
            IF penalty_data ->> 'expires_at' IS NOT NULL AND 
               (penalty_data ->> 'expires_at')::timestamptz <= current_time THEN
                -- Remove expired penalty
                updated_penalties := jsonb_set(
                    updated_penalties, 
                    ARRAY[team_key, player_key], 
                    'null'::jsonb
                );
            END IF;
        END LOOP;
    LOOP;
    
    -- Clean up null entries
    NEW.player_penalties := updated_penalties;
    
    RETURN NEW;
END;
$$;

-- Create trigger to automatically cleanup expired penalties on updates
DROP TRIGGER IF EXISTS cleanup_penalties_trigger ON matches;
CREATE TRIGGER cleanup_penalties_trigger
    BEFORE UPDATE ON matches
    FOR EACH ROW
    WHEN (OLD.player_penalties IS DISTINCT FROM NEW.player_penalties)
    EXECUTE FUNCTION cleanup_expired_penalties();

-- Update realtime publication to include new columns
ALTER PUBLICATION supabase_realtime SET (publish = 'insert, update, delete');