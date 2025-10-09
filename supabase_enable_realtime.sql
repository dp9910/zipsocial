-- Enable realtime for chat tables
-- Run this in your Supabase SQL Editor

-- Enable realtime replication for chat tables
ALTER publication supabase_realtime ADD TABLE conversations;
ALTER publication supabase_realtime ADD TABLE messages;
ALTER publication supabase_realtime ADD TABLE conversation_participants;

-- Verify realtime is enabled (optional check)
SELECT tablename 
FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime' 
AND tablename IN ('conversations', 'messages', 'conversation_participants');