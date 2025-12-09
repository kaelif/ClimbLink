-- Create swipes table to track user interactions
-- Run this in your Supabase SQL Editor

CREATE TABLE IF NOT EXISTS swipes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    swiper_device_id TEXT NOT NULL, -- Device ID of the user who swiped
    swiped_profile_id INTEGER NOT NULL, -- ID of the profile that was swiped on
    action TEXT NOT NULL CHECK (action IN ('like', 'pass')), -- 'like' or 'pass'
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Ensure one swipe per user-profile combination
    UNIQUE(swiper_device_id, swiped_profile_id)
);

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_swipes_swiper_device_id ON swipes(swiper_device_id);
CREATE INDEX IF NOT EXISTS idx_swipes_swiped_profile_id ON swipes(swiped_profile_id);
CREATE INDEX IF NOT EXISTS idx_swipes_action ON swipes(action);

-- Add foreign key constraint (optional, but good practice)
-- Note: This assumes profiles.id is the foreign key
-- ALTER TABLE swipes 
-- ADD CONSTRAINT fk_swipes_profile 
-- FOREIGN KEY (swiped_profile_id) REFERENCES profiles(id) ON DELETE CASCADE;

COMMENT ON TABLE swipes IS 'Tracks user swipe actions (like/pass) on profiles';
COMMENT ON COLUMN swipes.swiper_device_id IS 'Device ID of the user who performed the swipe';
COMMENT ON COLUMN swipes.swiped_profile_id IS 'ID of the profile that was swiped on';
COMMENT ON COLUMN swipes.action IS 'Type of swipe: like or pass';

