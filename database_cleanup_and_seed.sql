-- Database Cleanup and Demo Data Seeding for Zip Social
-- Run this script in your Supabase SQL Editor to reset and populate with demo data

-- ============================
-- STEP 1: CLEANUP EXISTING DATA
-- ============================

-- Clean up existing data (preserving structure)
TRUNCATE TABLE followers CASCADE;
TRUNCATE TABLE conversations CASCADE;
TRUNCATE TABLE conversation_participants CASCADE;
TRUNCATE TABLE messages CASCADE;
TRUNCATE TABLE comments CASCADE;
TRUNCATE TABLE post_interactions CASCADE;
TRUNCATE TABLE posts CASCADE;
TRUNCATE TABLE users CASCADE;

-- Reset sequences if they exist
ALTER SEQUENCE IF EXISTS users_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS posts_id_seq RESTART WITH 1;

-- ============================
-- STEP 2: CREATE DEMO USERS
-- ============================

-- Note: These are demo users for screenshots. In production, users would be created via auth.
INSERT INTO users (id, email, custom_user_id, nickname, bio, zipcode, preferred_zipcode, follower_count, following_count, is_profile_complete, created_at) VALUES 
-- Los Angeles Area (90210)
('11111111-1111-1111-1111-111111111111', 'alex.martinez@demo.com', 'alex.martinez', 'Alex Martinez', 'Coffee enthusiast ☕ | Love exploring LA neighborhoods | Always down for hiking', '90210', '90210', 15, 8, true, NOW() - INTERVAL '30 days'),
('22222222-2222-2222-2222-222222222222', 'sarah.chen@demo.com', 'sarah.chen', 'Sarah Chen', 'Food blogger 🍜 | Sharing the best eats in Beverly Hills | DM for restaurant recs!', '90210', '90210', 23, 12, true, NOW() - INTERVAL '25 days'),
('33333333-3333-3333-3333-333333333333', 'mike.johnson@demo.com', 'mike.johnson', 'Mike Johnson', 'Local photographer 📸 | Capturing LA vibes | Available for events', '90210', '90210', 31, 19, true, NOW() - INTERVAL '20 days'),

-- San Francisco Area (94102)
('44444444-4444-4444-4444-444444444444', 'emma.watson@demo.com', 'emma.watson', 'Emma Watson', 'Tech startup founder 💻 | Love SF coffee culture | Always networking', '94102', '94102', 42, 28, true, NOW() - INTERVAL '18 days'),
('55555555-5555-5555-5555-555555555555', 'david.park@demo.com', 'david.park', 'David Park', 'SF Giants fanatic ⚾ | Weekend warrior | Mission District explorer', '94102', '94102', 18, 15, true, NOW() - INTERVAL '15 days'),

-- Miami Area (33101)
('66666666-6666-6666-6666-666666666666', 'sofia.rodriguez@demo.com', 'sofia.rodriguez', 'Sofia Rodriguez', 'Beach lover 🏖️ | Fitness instructor | Spreading good vibes in Miami', '33101', '33101', 27, 21, true, NOW() - INTERVAL '12 days'),
('77777777-7777-7777-7777-777777777777', 'james.williams@demo.com', 'james.williams', 'James Williams', 'Local event organizer 🎉 | Know all the best spots in downtown Miami', '33101', '33101', 35, 25, true, NOW() - INTERVAL '10 days'),

-- Austin Area (78701)
('88888888-8888-8888-8888-888888888888', 'taylor.brown@demo.com', 'taylor.brown', 'Taylor Brown', 'Music lover 🎵 | SXSW regular | Keep Austin weird!', '78701', '78701', 29, 22, true, NOW() - INTERVAL '8 days'),

-- New User for onboarding demo
('99999999-9999-9999-9999-999999999999', 'new.user@demo.com', 'new.user', 'Demo User', 'Just joined the community!', '90210', '90210', 0, 0, true, NOW() - INTERVAL '1 day');

-- ============================
-- STEP 3: CREATE FOLLOW RELATIONSHIPS
-- ============================

INSERT INTO followers (follower_id, following_id, created_at) VALUES
-- Alex follows Sarah and Mike (both in LA)
('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', NOW() - INTERVAL '15 days'),
('11111111-1111-1111-1111-111111111111', '33333333-3333-3333-3333-333333333333', NOW() - INTERVAL '12 days'),

-- Sarah follows Alex, Mike, and Emma
('22222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111', NOW() - INTERVAL '14 days'),
('22222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333333', NOW() - INTERVAL '10 days'),
('22222222-2222-2222-2222-222222222222', '44444444-4444-4444-4444-444444444444', NOW() - INTERVAL '8 days'),

-- Mike follows everyone (social butterfly)
('33333333-3333-3333-3333-333333333333', '11111111-1111-1111-1111-111111111111', NOW() - INTERVAL '13 days'),
('33333333-3333-3333-3333-333333333333', '22222222-2222-2222-2222-222222222222', NOW() - INTERVAL '11 days'),
('33333333-3333-3333-3333-333333333333', '44444444-4444-4444-4444-444444444444', NOW() - INTERVAL '9 days'),
('33333333-3333-3333-3333-333333333333', '55555555-5555-5555-5555-555555555555', NOW() - INTERVAL '7 days'),

-- Emma follows tech-minded people
('44444444-4444-4444-4444-444444444444', '33333333-3333-3333-3333-333333333333', NOW() - INTERVAL '6 days'),
('44444444-4444-4444-4444-444444444444', '55555555-5555-5555-5555-555555555555', NOW() - INTERVAL '5 days'),

-- Create more realistic follow networks
('55555555-5555-5555-5555-555555555555', '44444444-4444-4444-4444-444444444444', NOW() - INTERVAL '4 days'),
('66666666-6666-6666-6666-666666666666', '77777777-7777-7777-7777-777777777777', NOW() - INTERVAL '3 days'),
('77777777-7777-7777-7777-777777777777', '66666666-6666-6666-6666-666666666666', NOW() - INTERVAL '2 days'),
('88888888-8888-8888-8888-888888888888', '44444444-4444-4444-4444-444444444444', NOW() - INTERVAL '1 day');

-- ============================
-- STEP 4: CREATE DIVERSE POSTS
-- ============================

INSERT INTO posts (id, user_id, username, content, zipcode, tag, like_count, comment_count, is_active, created_at) VALUES

-- Los Angeles Area Posts (90210)
('10000001-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'alex.martinez',
'Just discovered this amazing coffee shop on Rodeo Drive! ☕ The barista makes incredible latte art and they have the best pastries. Perfect spot for a morning pick-me-up before shopping. Who else loves finding hidden gems in our neighborhood?', 
'90210', 'random', 12, 3, true, NOW() - INTERVAL '2 hours'),

('10000001-0000-0000-0000-000000000002', '22222222-2222-2222-2222-222222222222', 'sarah.chen',
'🍕 FOOD ALERT: Tried the new Italian place on Beverly Drive and I''m obsessed! Their truffle pizza is absolutely divine. They''re doing 20% off for locals this week. Tag someone who needs to try this with you!', 
'90210', 'news', 18, 5, true, NOW() - INTERVAL '4 hours'),

('10000001-0000-0000-0000-000000000003', '33333333-3333-3333-3333-333333333333', 'mike.johnson',
'Caught the most incredible sunset over the Hollywood Hills tonight 🌅 The colors were absolutely magical! Sometimes I forget how beautiful our city can be. Anyone else catch this amazing show?', 
'90210', 'random', 25, 7, true, NOW() - INTERVAL '1 day'),

('10000001-0000-0000-0000-000000000004', '22222222-2222-2222-2222-222222222222', 'sarah.chen',
'📅 COMMUNITY EVENT: Local farmers market is expanding! Starting next Saturday, they''ll have live music, more vendor booths, and a kids play area. Runs 8am-2pm every weekend at Beverly Gardens Park. Let''s support our local businesses!', 
'90210', 'events', 31, 8, true, NOW() - INTERVAL '1 day 6 hours'),

-- San Francisco Posts (94102)
('10000001-0000-0000-0000-000000000005', '44444444-4444-4444-4444-444444444444', 'emma.watson',
'💡 Fun Fact Friday: Did you know the famous "crookedest street" Lombard Street was designed in 1922 to reduce the hill''s natural 27% grade? The eight sharp turns make it manageable for cars. I drive it every day and still marvel at the engineering!', 
'94102', 'funFacts', 22, 4, true, NOW() - INTERVAL '2 days'),

('10000001-0000-0000-0000-000000000006', '55555555-5555-5555-5555-555555555555', 'david.park',
'⚾ GIANTS UPDATE: What a game last night! That home run in the 9th inning had everyone at Oracle Park going crazy! 🎉 Already planning to catch the next home series. Anyone want to join for some garlic fries and baseball?', 
'94102', 'news', 19, 6, true, NOW() - INTERVAL '2 days 12 hours'),

-- Miami Posts (33101)
('10000001-0000-0000-0000-000000000007', '66666666-6666-6666-6666-666666666666', 'sofia.rodriguez',
'🏖️ Beach workout session this morning was incredible! Nothing beats exercising with the ocean breeze and sunrise. Started a small group that meets every Tuesday and Thursday at 7am near South Beach. All fitness levels welcome! DM me for details.', 
'33101', 'events', 28, 9, true, NOW() - INTERVAL '3 days'),

('10000001-0000-0000-0000-000000000008', '77777777-7777-7777-7777-777777777777', 'james.williams',
'🎊 Planning an amazing rooftop party for next Friday! Bringing together local artists, musicians, and creators for a night of networking and fun. Amazing views of Biscayne Bay guaranteed. Limited spots available - comment if interested!', 
'33101', 'events', 35, 12, true, NOW() - INTERVAL '3 days 8 hours'),

-- Austin Posts (78701)
('10000001-0000-0000-0000-000000000009', '88888888-8888-8888-8888-888888888888', 'taylor.brown',
'🎵 Music discovery: Found this incredible local band playing at a small venue on 6th Street last night. They have this amazing indie-folk sound that gives me chills. Austin''s music scene never stops surprising me! Check out "Midnight Revival" if you can.', 
'78701', 'random', 16, 4, true, NOW() - INTERVAL '4 days'),

('10000001-0000-0000-0000-000000000010', '88888888-8888-8888-8888-888888888888', 'taylor.brown',
'📰 Local News: The city is installing new bike lanes throughout downtown! Construction starts Monday and should wrap up in 3 weeks. Great to see Austin becoming even more bike-friendly. Time to dust off the old bicycle! 🚴‍♂️', 
'78701', 'news', 21, 5, true, NOW() - INTERVAL '5 days');

-- ============================
-- STEP 5: CREATE REALISTIC INTERACTIONS
-- ============================

INSERT INTO post_interactions (user_id, post_id, vote, created_at) VALUES
-- Likes on Alex's coffee post
('22222222-2222-2222-2222-222222222222', '10000001-0000-0000-0000-000000000001', 'up', NOW() - INTERVAL '1 hour 45 minutes'),
('33333333-3333-3333-3333-333333333333', '10000001-0000-0000-0000-000000000001', 'up', NOW() - INTERVAL '1 hour 30 minutes'),
('44444444-4444-4444-4444-444444444444', '10000001-0000-0000-0000-000000000001', 'up', NOW() - INTERVAL '1 hour'),

-- Likes on Sarah's food post
('11111111-1111-1111-1111-111111111111', '10000001-0000-0000-0000-000000000002', 'up', NOW() - INTERVAL '3 hours 30 minutes'),
('33333333-3333-3333-3333-333333333333', '10000001-0000-0000-0000-000000000002', 'up', NOW() - INTERVAL '3 hours'),
('77777777-7777-7777-7777-777777777777', '10000001-0000-0000-0000-000000000002', 'up', NOW() - INTERVAL '2 hours'),

-- More diverse interactions
('55555555-5555-5555-5555-555555555555', '10000001-0000-0000-0000-000000000005', 'up', NOW() - INTERVAL '2 days 2 hours'),
('66666666-6666-6666-6666-666666666666', '10000001-0000-0000-0000-000000000007', 'up', NOW() - INTERVAL '3 days 2 hours'),
('88888888-8888-8888-8888-888888888888', '10000001-0000-0000-0000-000000000009', 'up', NOW() - INTERVAL '4 days 2 hours');

-- ============================
-- STEP 6: CREATE ENGAGING COMMENTS
-- ============================

INSERT INTO comments (id, post_id, user_id, content, created_at) VALUES
-- Comments on Alex's coffee post
('20000001-0000-0000-0000-000000000001', '10000001-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', 
'Yes! I love that place too! Their lavender latte is my go-to ☕', NOW() - INTERVAL '1 hour 20 minutes'),

('20000001-0000-0000-0000-000000000002', '10000001-0000-0000-0000-000000000001', '33333333-3333-3333-3333-333333333333', 
'Great shot of the coffee art! Mind if I feature this spot in my neighborhood photography series?', NOW() - INTERVAL '45 minutes'),

-- Comments on Sarah's food post
('20000001-0000-0000-0000-000000000003', '10000001-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', 
'Thanks for the rec! Definitely checking this out this weekend 🍕', NOW() - INTERVAL '3 hours 15 minutes'),

('20000001-0000-0000-0000-000000000004', '10000001-0000-0000-0000-000000000002', '33333333-3333-3333-3333-333333333333', 
'Just called and made a reservation for tonight! You''re the best food guide in the area', NOW() - INTERVAL '2 hours 30 minutes'),

-- Comments on Mike's sunset post
('20000001-0000-0000-0000-000000000005', '10000001-0000-0000-0000-000000000003', '11111111-1111-1111-1111-111111111111', 
'Incredible capture! The colors are absolutely stunning 🌅', NOW() - INTERVAL '23 hours'),

('20000001-0000-0000-0000-000000000006', '10000001-0000-0000-0000-000000000003', '22222222-2222-2222-2222-222222222222', 
'I saw this too! Was walking my dog and had to stop and just appreciate the moment', NOW() - INTERVAL '22 hours');

-- ============================
-- STEP 7: CREATE CONVERSATION DEMOS
-- ============================

-- Create conversations
INSERT INTO conversations (id, last_message, last_message_at, last_message_sender_id, created_at) VALUES
('30000001-0000-0000-0000-000000000001', 'Sounds great! See you at 2pm ☕', NOW() - INTERVAL '15 minutes', '22222222-2222-2222-2222-222222222222', NOW() - INTERVAL '2 days'),
('30000001-0000-0000-0000-000000000002', 'Perfect! I''ll bring my camera 📸', NOW() - INTERVAL '1 hour', '33333333-3333-3333-3333-333333333333', NOW() - INTERVAL '1 day'),
('30000001-0000-0000-0000-000000000003', 'Thanks for the recommendation!', NOW() - INTERVAL '3 hours', '44444444-4444-4444-4444-444444444444', NOW() - INTERVAL '6 hours');

-- Add participants to conversations
INSERT INTO conversation_participants (conversation_id, user_id, nickname, custom_user_id, joined_at) VALUES
-- Conversation 1: Alex and Sarah
('30000001-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'Alex Martinez', 'alex.martinez', NOW() - INTERVAL '2 days'),
('30000001-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', 'Sarah Chen', 'sarah.chen', NOW() - INTERVAL '2 days'),

-- Conversation 2: Alex and Mike
('30000001-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', 'Alex Martinez', 'alex.martinez', NOW() - INTERVAL '1 day'),
('30000001-0000-0000-0000-000000000002', '33333333-3333-3333-3333-333333333333', 'Mike Johnson', 'mike.johnson', NOW() - INTERVAL '1 day'),

-- Conversation 3: Sarah and Emma
('30000001-0000-0000-0000-000000000003', '22222222-2222-2222-2222-222222222222', 'Sarah Chen', 'sarah.chen', NOW() - INTERVAL '6 hours'),
('30000001-0000-0000-0000-000000000003', '44444444-4444-4444-4444-444444444444', 'Emma Watson', 'emma.watson', NOW() - INTERVAL '6 hours');

-- Add messages to conversations
INSERT INTO messages (id, conversation_id, sender_id, content, created_at) VALUES
-- Conversation 1 messages
('40000001-0000-0000-0000-000000000001', '30000001-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 
'Hey! Want to check out that new coffee place together?', NOW() - INTERVAL '2 days'),
('40000001-0000-0000-0000-000000000002', '30000001-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', 
'Absolutely! I heard they have amazing pastries too', NOW() - INTERVAL '2 days' + INTERVAL '5 minutes'),
('40000001-0000-0000-0000-000000000003', '30000001-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 
'Perfect! How about tomorrow around 2pm?', NOW() - INTERVAL '2 days' + INTERVAL '10 minutes'),
('40000001-0000-0000-0000-000000000004', '30000001-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', 
'Sounds great! See you at 2pm ☕', NOW() - INTERVAL '15 minutes'),

-- Conversation 2 messages  
('40000001-0000-0000-0000-000000000005', '30000001-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', 
'The sunset tonight is going to be incredible! Want to shoot some photos together?', NOW() - INTERVAL '1 day'),
('40000001-0000-0000-0000-000000000006', '30000001-0000-0000-0000-000000000002', '33333333-3333-3333-3333-333333333333', 
'Perfect! I''ll bring my camera 📸', NOW() - INTERVAL '1 hour');

-- Update conversation unread counts for demo
UPDATE conversation_participants SET unread_count = 1 
WHERE conversation_id = '30000001-0000-0000-0000-000000000001' 
AND user_id = '11111111-1111-1111-1111-111111111111';

UPDATE conversation_participants SET unread_count = 2 
WHERE conversation_id = '30000001-0000-0000-0000-000000000002' 
AND user_id = '11111111-1111-1111-1111-111111111111';

-- ============================
-- REFRESH MATERIALIZED VIEWS & FUNCTIONS
-- ============================

-- Update follower/following counts to match our data
UPDATE users SET 
  follower_count = (SELECT COUNT(*) FROM followers WHERE following_id = users.id),
  following_count = (SELECT COUNT(*) FROM followers WHERE follower_id = users.id);

-- Update post interaction counts
UPDATE posts SET 
  like_count = (SELECT COUNT(*) FROM post_interactions WHERE post_id = posts.id AND vote = 'up'),
  comment_count = (SELECT COUNT(*) FROM comments WHERE post_id = posts.id);

-- Success message
SELECT 'Database successfully cleaned and seeded with demo data!' as status;