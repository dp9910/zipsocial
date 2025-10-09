-- Chat system migration for Zip Social
-- Run this script in your Supabase SQL Editor

-- Create conversations table
CREATE TABLE IF NOT EXISTS conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_message_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_message TEXT,
  last_message_sender_id TEXT
);

-- Create conversation_participants table
CREATE TABLE IF NOT EXISTS conversation_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
  user_id TEXT REFERENCES users(id) ON DELETE CASCADE,
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_read_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(conversation_id, user_id)
);

-- Create messages table
CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id TEXT REFERENCES users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  message_type TEXT DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'file')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  is_edited BOOLEAN DEFAULT false,
  is_deleted BOOLEAN DEFAULT false
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_conversations_updated_at ON conversations(updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_conversation_participants_user_id ON conversation_participants(user_id);
CREATE INDEX IF NOT EXISTS idx_conversation_participants_conversation_id ON conversation_participants(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON messages(conversation_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON messages(sender_id);

-- Enable RLS for all chat tables
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversation_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- RLS Policies for conversations
CREATE POLICY "Users can read conversations they participate in" ON conversations
  FOR SELECT USING (
    id IN (
      SELECT conversation_id 
      FROM conversation_participants 
      WHERE user_id = auth.uid()::TEXT
    )
  );

CREATE POLICY "Users can update conversations they participate in" ON conversations
  FOR UPDATE USING (
    id IN (
      SELECT conversation_id 
      FROM conversation_participants 
      WHERE user_id = auth.uid()::TEXT
    )
  );

-- RLS Policies for conversation_participants
CREATE POLICY "Users can read participants in their conversations" ON conversation_participants
  FOR SELECT USING (
    conversation_id IN (
      SELECT conversation_id 
      FROM conversation_participants 
      WHERE user_id = auth.uid()::TEXT
    )
  );

CREATE POLICY "Users can join conversations" ON conversation_participants
  FOR INSERT WITH CHECK (auth.uid()::TEXT = user_id);

CREATE POLICY "Users can update their participation" ON conversation_participants
  FOR UPDATE USING (auth.uid()::TEXT = user_id);

-- RLS Policies for messages
CREATE POLICY "Users can read messages in their conversations" ON messages
  FOR SELECT USING (
    conversation_id IN (
      SELECT conversation_id 
      FROM conversation_participants 
      WHERE user_id = auth.uid()::TEXT
    )
  );

CREATE POLICY "Users can send messages to their conversations" ON messages
  FOR INSERT WITH CHECK (
    auth.uid()::TEXT = sender_id AND
    conversation_id IN (
      SELECT conversation_id 
      FROM conversation_participants 
      WHERE user_id = auth.uid()::TEXT
    )
  );

CREATE POLICY "Users can update their own messages" ON messages
  FOR UPDATE USING (auth.uid()::TEXT = sender_id);

-- Function to create or get a conversation between two users
CREATE OR REPLACE FUNCTION get_or_create_conversation(user1_id TEXT, user2_id TEXT)
RETURNS UUID AS $$
DECLARE
  conv_id UUID;
BEGIN
  -- Check if conversation already exists between these two users
  SELECT c.id INTO conv_id
  FROM conversations c
  WHERE c.id IN (
    SELECT cp1.conversation_id
    FROM conversation_participants cp1
    JOIN conversation_participants cp2 ON cp1.conversation_id = cp2.conversation_id
    WHERE cp1.user_id = user1_id AND cp2.user_id = user2_id
    AND cp1.user_id != cp2.user_id
  );

  -- If conversation doesn't exist, create it
  IF conv_id IS NULL THEN
    INSERT INTO conversations (created_at, updated_at, last_message_at)
    VALUES (NOW(), NOW(), NOW())
    RETURNING id INTO conv_id;

    -- Add both users as participants
    INSERT INTO conversation_participants (conversation_id, user_id, joined_at, last_read_at)
    VALUES 
      (conv_id, user1_id, NOW(), NOW()),
      (conv_id, user2_id, NOW(), NOW());
  END IF;

  RETURN conv_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update conversation when a new message is sent
CREATE OR REPLACE FUNCTION update_conversation_on_message()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE conversations
  SET 
    updated_at = NEW.created_at,
    last_message_at = NEW.created_at,
    last_message = NEW.content,
    last_message_sender_id = NEW.sender_id
  WHERE id = NEW.conversation_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to update conversation when message is inserted
DROP TRIGGER IF EXISTS update_conversation_on_message_trigger ON messages;
CREATE TRIGGER update_conversation_on_message_trigger
  AFTER INSERT ON messages
  FOR EACH ROW
  EXECUTE FUNCTION update_conversation_on_message();

-- Function to mark messages as read
CREATE OR REPLACE FUNCTION mark_conversation_as_read(conv_id UUID, user_id TEXT)
RETURNS void AS $$
BEGIN
  UPDATE conversation_participants
  SET last_read_at = NOW()
  WHERE conversation_id = conv_id AND user_id = user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;