-- ================================
-- MESSAGE REQUEST SYSTEM SCHEMA
-- ================================
-- Run this in your Supabase SQL editor to add message request functionality

-- 1. Create message_requests table
CREATE TABLE IF NOT EXISTS message_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    sender_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    recipient_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    message_content TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(sender_id, recipient_id)
);

-- 2. Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_message_requests_recipient_id ON message_requests(recipient_id);
CREATE INDEX IF NOT EXISTS idx_message_requests_sender_id ON message_requests(sender_id);
CREATE INDEX IF NOT EXISTS idx_message_requests_status ON message_requests(status);
CREATE INDEX IF NOT EXISTS idx_message_requests_created_at ON message_requests(created_at DESC);

-- Composite index for common queries
CREATE INDEX IF NOT EXISTS idx_message_requests_recipient_status ON message_requests(recipient_id, status);

-- 3. Create RLS (Row Level Security) policies
ALTER TABLE message_requests ENABLE ROW LEVEL SECURITY;

-- Users can view message requests where they are sender or recipient
CREATE POLICY "Users can view their message requests" ON message_requests
    FOR SELECT USING (
        auth.uid()::text = sender_id OR 
        auth.uid()::text = recipient_id
    );

-- Users can create message requests where they are the sender
CREATE POLICY "Users can create message requests" ON message_requests
    FOR INSERT WITH CHECK (auth.uid()::text = sender_id);

-- Users can update message requests where they are the recipient (for accepting/declining)
CREATE POLICY "Recipients can update message requests" ON message_requests
    FOR UPDATE USING (auth.uid()::text = recipient_id);

-- Users can delete their own message requests
CREATE POLICY "Users can delete their message requests" ON message_requests
    FOR DELETE USING (auth.uid()::text = sender_id);

-- 4. Create updated_at trigger
CREATE OR REPLACE FUNCTION update_message_requests_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_message_requests_updated_at 
    BEFORE UPDATE ON message_requests 
    FOR EACH ROW 
    EXECUTE FUNCTION update_message_requests_updated_at();

-- 5. Create helper functions

-- Get message request count for a user
CREATE OR REPLACE FUNCTION get_message_request_count(user_id TEXT)
RETURNS INTEGER AS $$
BEGIN
    RETURN (
        SELECT COUNT(*)::INTEGER 
        FROM message_requests 
        WHERE recipient_id = user_id 
        AND status = 'pending'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Comments on tables for documentation
COMMENT ON TABLE message_requests IS 'Stores message requests between users';
COMMENT ON COLUMN message_requests.sender_id IS 'User who sent the message request';
COMMENT ON COLUMN message_requests.recipient_id IS 'User who received the message request';
COMMENT ON COLUMN message_requests.message_content IS 'Content of the initial message request';
COMMENT ON COLUMN message_requests.status IS 'Status: pending, accepted, or declined';

-- ================================
-- VERIFICATION QUERIES
-- ================================
-- Run these to verify the schema was created correctly:

-- Check if table exists
-- SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'message_requests';

-- Check if indexes exist  
-- SELECT indexname FROM pg_indexes WHERE tablename = 'message_requests';

-- Check if RLS is enabled
-- SELECT schemaname, tablename, rowsecurity FROM pg_tables WHERE tablename = 'message_requests';

-- Test message request creation (replace UUIDs with real user IDs)
-- INSERT INTO message_requests (sender_id, recipient_id, message_content, status) 
-- VALUES ('sender-user-id', 'recipient-user-id', 'Hello! I would like to message you.', 'pending');