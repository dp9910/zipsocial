-- ================================
-- NOTIFICATION SYSTEM SCHEMA
-- ================================
-- This file contains the complete database schema needed for the notification system
-- Run this in your Supabase SQL editor

-- 1. Create notifications table
CREATE TABLE IF NOT EXISTS notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    recipient_user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    actor_user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    action_type TEXT NOT NULL,
    target_id TEXT NULL, -- post_id, message_id, etc.
    target_content TEXT NULL, -- post content preview, message preview, etc.
    metadata JSONB NULL, -- additional context data
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_notifications_recipient_user_id ON notifications(recipient_user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_actor_user_id ON notifications(actor_user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_action_type ON notifications(action_type);
CREATE INDEX IF NOT EXISTS idx_notifications_target_id ON notifications(target_id);

-- Composite index for common queries
CREATE INDEX IF NOT EXISTS idx_notifications_recipient_read_created ON notifications(recipient_user_id, is_read, created_at DESC);

-- 3. Create RLS (Row Level Security) policies
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Users can only see notifications where they are the recipient
CREATE POLICY "Users can view their own notifications" ON notifications
    FOR SELECT USING (auth.uid()::text = recipient_user_id);

-- Users can only update their own notifications (marking as read)
CREATE POLICY "Users can update their own notifications" ON notifications
    FOR UPDATE USING (auth.uid()::text = recipient_user_id);

-- System can insert notifications (this allows the notification service to work)
CREATE POLICY "Allow notification creation" ON notifications
    FOR INSERT WITH CHECK (true);

-- Users can delete their own notifications
CREATE POLICY "Users can delete their own notifications" ON notifications
    FOR DELETE USING (auth.uid()::text = recipient_user_id);

-- 4. Create updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_notifications_updated_at 
    BEFORE UPDATE ON notifications 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- 5. Create blocked_users table if it doesn't exist (needed for notification filtering)
CREATE TABLE IF NOT EXISTS blocked_users (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    blocker_user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    blocked_user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(blocker_user_id, blocked_user_id)
);

-- Index for blocked users
CREATE INDEX IF NOT EXISTS idx_blocked_users_blocker ON blocked_users(blocker_user_id);
CREATE INDEX IF NOT EXISTS idx_blocked_users_blocked ON blocked_users(blocked_user_id);

-- RLS for blocked_users
ALTER TABLE blocked_users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own blocks" ON blocked_users
    FOR ALL USING (auth.uid()::text = blocker_user_id);

-- 6. Validation constraints
ALTER TABLE notifications ADD CONSTRAINT valid_action_type 
CHECK (action_type IN (
    'user_followed_you',
    'user_unfollowed_you', 
    'user_blocked_you',
    'user_saved_your_post',
    'user_sent_message',
    'user_created_post',
    'your_post_reported',
    'your_post_deleted',
    'user_commented_on_post',
    'user_liked_your_post'
));

-- Prevent self-notifications
ALTER TABLE notifications ADD CONSTRAINT no_self_notifications 
CHECK (recipient_user_id != actor_user_id);

-- 7. Clean up old notifications function (optional - for maintenance)
CREATE OR REPLACE FUNCTION cleanup_old_notifications(days_to_keep INTEGER DEFAULT 30)
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM notifications 
    WHERE created_at < NOW() - INTERVAL '1 day' * days_to_keep;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. Function to get unread notification count (performance optimized)
CREATE OR REPLACE FUNCTION get_unread_notification_count(user_id TEXT)
RETURNS INTEGER AS $$
BEGIN
    RETURN (
        SELECT COUNT(*)::INTEGER 
        FROM notifications 
        WHERE recipient_user_id = user_id 
        AND is_read = false
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. Function to mark all notifications as read
CREATE OR REPLACE FUNCTION mark_all_notifications_read(user_id TEXT)
RETURNS INTEGER AS $$
DECLARE
    updated_count INTEGER;
BEGIN
    UPDATE notifications 
    SET is_read = true, updated_at = NOW()
    WHERE recipient_user_id = user_id 
    AND is_read = false;
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RETURN updated_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 10. Comments on tables for documentation
COMMENT ON TABLE notifications IS 'Stores all user notifications with rich context';
COMMENT ON COLUMN notifications.action_type IS 'Type of notification (follow, like, comment, etc.)';
COMMENT ON COLUMN notifications.target_id IS 'ID of the target object (post, message, etc.)';
COMMENT ON COLUMN notifications.target_content IS 'Preview of target content for rich notifications';
COMMENT ON COLUMN notifications.metadata IS 'Additional context data stored as JSON';

-- ================================
-- VERIFICATION QUERIES
-- ================================
-- Run these to verify the schema was created correctly:

-- Check if tables exist
-- SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_name IN ('notifications', 'blocked_users');

-- Check if indexes exist  
-- SELECT indexname FROM pg_indexes WHERE tablename = 'notifications';

-- Check if RLS is enabled
-- SELECT schemaname, tablename, rowsecurity FROM pg_tables WHERE tablename IN ('notifications', 'blocked_users');

-- Test notification creation (replace UUIDs with real user IDs from your users table)
-- INSERT INTO notifications (recipient_user_id, actor_user_id, action_type, target_content) 
-- VALUES ('your-user-id', 'another-user-id', 'user_followed_you', null);