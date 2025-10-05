-- Migration to add post count functionality
-- Run this script in your Supabase SQL Editor

-- Add post_count column to users table
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS post_count INTEGER DEFAULT 0;

-- Function to increment post count
CREATE OR REPLACE FUNCTION increment_post_count(user_id TEXT)
RETURNS void AS $$
BEGIN
  UPDATE users 
  SET post_count = post_count + 1 
  WHERE id = user_id;
END;
$$ LANGUAGE plpgsql;

-- Function to decrement post count (for when posts are deleted)
CREATE OR REPLACE FUNCTION decrement_post_count(user_id TEXT)
RETURNS void AS $$
BEGIN
  UPDATE users 
  SET post_count = GREATEST(post_count - 1, 0) 
  WHERE id = user_id;
END;
$$ LANGUAGE plpgsql;

-- Update existing users to have post_count = 0 if null
UPDATE users SET post_count = 0 WHERE post_count IS NULL;