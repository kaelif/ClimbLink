-- Migration: Add device_id column to profiles table
-- Run this in your Supabase SQL Editor to add device_id support

-- Add device_id column if it doesn't exist
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS device_id TEXT UNIQUE;

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_profiles_device_id ON profiles(device_id);

-- Add comment
COMMENT ON COLUMN profiles.device_id IS 'Unique device identifier for mobile app users';

-- Note: If you get an error about the column already existing, that's fine.
-- The IF NOT EXISTS clause should handle it, but some databases may still error.
-- In that case, you can remove the IF NOT EXISTS clause and run it again.
