-- Fix user ID column to handle Firebase user IDs (which are not UUIDs)
-- Run this script in your Supabase SQL Editor

-- First, drop the foreign key constraints that reference users.id
ALTER TABLE posts DROP CONSTRAINT IF EXISTS posts_user_id_fkey;
ALTER TABLE post_interactions DROP CONSTRAINT IF EXISTS post_interactions_user_id_fkey;
ALTER TABLE followers DROP CONSTRAINT IF EXISTS followers_follower_id_fkey;
ALTER TABLE followers DROP CONSTRAINT IF EXISTS followers_following_id_fkey;

-- Change the users.id column from UUID to TEXT to handle Firebase user IDs
ALTER TABLE users ALTER COLUMN id TYPE TEXT;

-- Also update related tables to use TEXT for user_id references
ALTER TABLE posts ALTER COLUMN user_id TYPE TEXT;
ALTER TABLE post_interactions ALTER COLUMN user_id TYPE TEXT;
ALTER TABLE followers ALTER COLUMN follower_id TYPE TEXT;
ALTER TABLE followers ALTER COLUMN following_id TYPE TEXT;

-- Recreate the foreign key constraints with TEXT type
ALTER TABLE posts 
ADD CONSTRAINT posts_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE post_interactions 
ADD CONSTRAINT post_interactions_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE followers 
ADD CONSTRAINT followers_follower_id_fkey 
FOREIGN KEY (follower_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE followers 
ADD CONSTRAINT followers_following_id_fkey 
FOREIGN KEY (following_id) REFERENCES users(id) ON DELETE CASCADE;

-- Update the functions to use TEXT instead of UUID
CREATE OR REPLACE FUNCTION increment_follower_count(user_id TEXT)
RETURNS void AS $$
BEGIN
  UPDATE users 
  SET follower_count = follower_count + 1 
  WHERE id = user_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION decrement_follower_count(user_id TEXT)
RETURNS void AS $$
BEGIN
  UPDATE users 
  SET follower_count = GREATEST(follower_count - 1, 0) 
  WHERE id = user_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION increment_following_count(user_id TEXT)
RETURNS void AS $$
BEGIN
  UPDATE users 
  SET following_count = following_count + 1 
  WHERE id = user_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION decrement_following_count(user_id TEXT)
RETURNS void AS $$
BEGIN
  UPDATE users 
  SET following_count = GREATEST(following_count - 1, 0) 
  WHERE id = user_id;
END;
$$ LANGUAGE plpgsql;