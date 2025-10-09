-- Fix chat system policies and functions
-- Run this script in your Supabase SQL Editor to fix the issues

-- Drop problematic policies
DROP POLICY IF EXISTS "Users can read conversations they participate in" ON conversations;
DROP POLICY IF EXISTS "Users can update conversations they participate in" ON conversations;
DROP POLICY IF EXISTS "Users can read participants in their conversations" ON conversation_participants;

-- Create fixed RLS policies for conversations
CREATE POLICY "Users can read their conversations" ON conversations
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM conversation_participants cp 
      WHERE cp.conversation_id = conversations.id 
      AND cp.user_id = auth.uid()::TEXT
    )
  );

CREATE POLICY "Users can update their conversations" ON conversations
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM conversation_participants cp 
      WHERE cp.conversation_id = conversations.id 
      AND cp.user_id = auth.uid()::TEXT
    )
  );

-- Create fixed RLS policy for conversation_participants  
CREATE POLICY "Users can read conversation participants" ON conversation_participants
  FOR SELECT USING (
    user_id = auth.uid()::TEXT OR 
    conversation_id IN (
      SELECT cp2.conversation_id 
      FROM conversation_participants cp2 
      WHERE cp2.user_id = auth.uid()::TEXT
    )
  );

-- Fix the mark_conversation_as_read function with proper parameter naming
CREATE OR REPLACE FUNCTION mark_conversation_as_read(conv_id UUID, p_user_id TEXT)
RETURNS void AS $$
BEGIN
  UPDATE conversation_participants
  SET last_read_at = NOW()
  WHERE conversation_id = conv_id AND user_id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Also create a simpler policy for messages to avoid recursion
DROP POLICY IF EXISTS "Users can read messages in their conversations" ON messages;
CREATE POLICY "Users can read messages in their conversations" ON messages
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM conversation_participants cp 
      WHERE cp.conversation_id = messages.conversation_id 
      AND cp.user_id = auth.uid()::TEXT
    )
  );

DROP POLICY IF EXISTS "Users can send messages to their conversations" ON messages;
CREATE POLICY "Users can send messages to their conversations" ON messages
  FOR INSERT WITH CHECK (
    sender_id = auth.uid()::TEXT AND
    EXISTS (
      SELECT 1 FROM conversation_participants cp 
      WHERE cp.conversation_id = messages.conversation_id 
      AND cp.user_id = auth.uid()::TEXT
    )
  );