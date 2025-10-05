-- Add comment_count to posts table
ALTER TABLE posts
ADD COLUMN comment_count INT NOT NULL DEFAULT 0;

-- Create the comments table
CREATE TABLE comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE, -- Changed to TEXT
    username TEXT NOT NULL,
    content TEXT NOT NULL CHECK (char_length(content) <= 150),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Add indexes for performance
CREATE INDEX idx_comments_post_id ON comments(post_id);
CREATE INDEX idx_comments_user_id ON comments(user_id);

-- Enable Row Level Security
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;

-- RLS Policies for comments table
-- 1. Allow users to view all comments
CREATE POLICY "Allow read access to all users"
ON comments
FOR SELECT
USING (true);

-- 2. Allow users to insert their own comments
CREATE POLICY "Allow users to insert their own comments"
ON comments
FOR INSERT
WITH CHECK (auth.uid()::text = user_id);

-- 3. Allow users to update their own comments
CREATE POLICY "Allow users to update their own comments"
ON comments
FOR UPDATE
USING (auth.uid()::text = user_id)
WITH CHECK (auth.uid()::text = user_id);

-- 4. Allow users to delete their own comments
CREATE POLICY "Allow users to delete their own comments"
ON comments
FOR DELETE
USING (auth.uid()::text = user_id);

-- Function to increment comment_count on the posts table
CREATE OR REPLACE FUNCTION increment_comment_count()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE posts
  SET comment_count = comment_count + 1
  WHERE id = NEW.post_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to call the function when a new comment is inserted
CREATE TRIGGER on_comment_created
  AFTER INSERT ON comments
  FOR EACH ROW
  EXECUTE FUNCTION increment_comment_count();

-- Function to decrement comment_count on the posts table
CREATE OR REPLACE FUNCTION decrement_comment_count()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE posts
  SET comment_count = comment_count - 1
  WHERE id = OLD.post_id;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Trigger to call the function when a comment is deleted
CREATE TRIGGER on_comment_deleted
  AFTER DELETE ON comments
  FOR EACH ROW
  EXECUTE FUNCTION decrement_comment_count();
