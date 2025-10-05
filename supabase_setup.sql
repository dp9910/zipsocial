-- Create users table
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT auth.uid(),
  custom_user_id TEXT UNIQUE NOT NULL,
  phone_number TEXT,
  google_email TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  default_zipcode TEXT
);

-- Create posts table
CREATE TABLE posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  username TEXT NOT NULL,
  zipcode TEXT NOT NULL,
  content TEXT NOT NULL,
  tag TEXT CHECK (tag IN ('news', 'fun_facts', 'events', 'random')) NOT NULL,
  event_details JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  report_count INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true
);

-- Create post_interactions table
CREATE TABLE post_interactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  vote TEXT CHECK (vote IN ('up', 'down')),
  is_saved BOOLEAN DEFAULT false,
  is_reported BOOLEAN DEFAULT false,
  time_spent_seconds INTEGER,
  interacted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(post_id, user_id)
);

-- Create indexes for performance
CREATE INDEX idx_posts_zipcode_created_at ON posts(zipcode, created_at DESC);
CREATE INDEX idx_posts_zipcode_tag_created_at ON posts(zipcode, tag, created_at DESC);
CREATE INDEX idx_posts_user_id_created_at ON posts(user_id, created_at DESC);
CREATE INDEX idx_post_interactions_user_id_saved ON post_interactions(user_id, is_saved);
CREATE INDEX idx_post_interactions_post_id ON post_interactions(post_id);

-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_interactions ENABLE ROW LEVEL SECURITY;

-- RLS Policies for users table
CREATE POLICY "Users can read own profile" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON users
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON users
  FOR INSERT WITH CHECK (auth.uid() = id);

-- RLS Policies for posts table
CREATE POLICY "Anyone can read active posts" ON posts
  FOR SELECT USING (is_active = true);

CREATE POLICY "Users can insert own posts" ON posts
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own posts" ON posts
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own posts" ON posts
  FOR DELETE USING (auth.uid() = user_id);

-- RLS Policies for post_interactions table
CREATE POLICY "Users can read own interactions" ON post_interactions
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own interactions" ON post_interactions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own interactions" ON post_interactions
  FOR UPDATE USING (auth.uid() = user_id);

-- Function to increment report count and disable post if threshold reached
CREATE OR REPLACE FUNCTION handle_post_report()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.is_reported = true AND (OLD.is_reported IS NULL OR OLD.is_reported = false) THEN
    UPDATE posts 
    SET report_count = report_count + 1,
        is_active = CASE WHEN report_count + 1 >= 10 THEN false ELSE is_active END
    WHERE id = NEW.post_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for report handling
CREATE TRIGGER trigger_handle_post_report
  AFTER INSERT OR UPDATE ON post_interactions
  FOR EACH ROW
  EXECUTE FUNCTION handle_post_report();