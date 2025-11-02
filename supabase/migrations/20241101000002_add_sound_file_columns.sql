-- Add sound_file columns to boosters and maddies tables
ALTER TABLE boosters ADD COLUMN IF NOT EXISTS sound_file TEXT;
ALTER TABLE maddies ADD COLUMN IF NOT EXISTS sound_file TEXT;

-- Add comments to describe the sound_file column
COMMENT ON COLUMN boosters.sound_file IS 'Filename for sound file (either default from /sounds/boosters/ or custom_filename for uploaded files)';
COMMENT ON COLUMN maddies.sound_file IS 'Filename for sound file (either default from /sounds/maddies/ or custom_filename for uploaded files)';