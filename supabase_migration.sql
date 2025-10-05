-- Migration script to add new user profile fields and follow system
-- Run this script in your Supabase SQL Editor

-- Add new columns to users table
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS nickname TEXT,
ADD COLUMN IF NOT EXISTS bio TEXT,
ADD COLUMN IF NOT EXISTS follower_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS following_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS is_profile_complete BOOLEAN DEFAULT false;

-- Create followers table for follow relationships
CREATE TABLE IF NOT EXISTS followers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  follower_id UUID REFERENCES users(id) ON DELETE CASCADE,
  following_id UUID REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(follower_id, following_id)
);

-- Create indexes for followers table
CREATE INDEX IF NOT EXISTS idx_followers_follower_id ON followers(follower_id);
CREATE INDEX IF NOT EXISTS idx_followers_following_id ON followers(following_id);

-- Enable RLS for followers table
ALTER TABLE followers ENABLE ROW LEVEL SECURITY;

-- RLS Policies for followers table
CREATE POLICY "Users can read all follow relationships" ON followers
  FOR SELECT USING (true);

CREATE POLICY "Users can create own follows" ON followers
  FOR INSERT WITH CHECK (auth.uid() = follower_id);

CREATE POLICY "Users can delete own follows" ON followers
  FOR DELETE USING (auth.uid() = follower_id);

-- Function to increment follower count
CREATE OR REPLACE FUNCTION increment_follower_count(user_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE users 
  SET follower_count = follower_count + 1 
  WHERE id = user_id;
END;
$$ LANGUAGE plpgsql;

-- Function to decrement follower count
CREATE OR REPLACE FUNCTION decrement_follower_count(user_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE users 
  SET follower_count = GREATEST(follower_count - 1, 0) 
  WHERE id = user_id;
END;
$$ LANGUAGE plpgsql;

-- Function to increment following count
CREATE OR REPLACE FUNCTION increment_following_count(user_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE users 
  SET following_count = following_count + 1 
  WHERE id = user_id;
END;
$$ LANGUAGE plpgsql;

-- Function to decrement following count
CREATE OR REPLACE FUNCTION decrement_following_count(user_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE users 
  SET following_count = GREATEST(following_count - 1, 0) 
  WHERE id = user_id;
END;
$$ LANGUAGE plpgsql;

-- Update RLS policies to allow reading other users' public profile info
CREATE POLICY "Anyone can read public user profiles" ON users
  FOR SELECT USING (true);

-- Drop the old restrictive policy if it exists
DROP POLICY IF EXISTS "Users can read own profile" ON users;

-- Create new policy for own profile reads (more specific)
CREATE POLICY "Users can read own full profile" ON users
  FOR SELECT USING (auth.uid() = id);