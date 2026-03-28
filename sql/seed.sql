-- Polyculy Seed Data
-- All demo passwords: demo123 (SHA-256 hashed via Lucee hash() function)
-- Hash of 'demo123': D3AD9315B7BE5DD53B31A273B3B3ABA5DEFE700808305AA16A3062B76658A791

-- Users
INSERT INTO users (email, password_hash, display_name, avatar_url, timezone_id, calendar_created)
VALUES ('you@polyculy.demo', 'D3AD9315B7BE5DD53B31A273B3B3ABA5DEFE700808305AA16A3062B76658A791', 'You', NULL, 'America/Los_Angeles', TRUE);

INSERT INTO users (email, password_hash, display_name, avatar_url, timezone_id, calendar_created)
VALUES ('riley@polyculy.demo', 'D3AD9315B7BE5DD53B31A273B3B3ABA5DEFE700808305AA16A3062B76658A791', 'Riley', NULL, 'America/New_York', TRUE);

INSERT INTO users (email, password_hash, display_name, avatar_url, timezone_id, calendar_created)
VALUES ('jamie@polyculy.demo', 'D3AD9315B7BE5DD53B31A273B3B3ABA5DEFE700808305AA16A3062B76658A791', 'Jamie', NULL, 'America/Chicago', TRUE);

INSERT INTO users (email, password_hash, display_name, avatar_url, timezone_id, calendar_created)
VALUES ('alex@polyculy.demo', 'D3AD9315B7BE5DD53B31A273B3B3ABA5DEFE700808305AA16A3062B76658A791', 'Alex', NULL, 'America/Denver', TRUE);

INSERT INTO users (email, password_hash, display_name, avatar_url, timezone_id, calendar_created)
VALUES ('casey@polyculy.demo', 'D3AD9315B7BE5DD53B31A273B3B3ABA5DEFE700808305AA16A3062B76658A791', 'Casey', NULL, 'America/Los_Angeles', FALSE);

INSERT INTO users (email, password_hash, display_name, avatar_url, timezone_id, calendar_created)
VALUES ('morgan@polyculy.demo', 'D3AD9315B7BE5DD53B31A273B3B3ABA5DEFE700808305AA16A3062B76658A791', 'Morgan', NULL, 'America/Los_Angeles', FALSE);

INSERT INTO users (email, password_hash, display_name, avatar_url, timezone_id, calendar_created)
VALUES ('sam@polyculy.demo', 'D3AD9315B7BE5DD53B31A273B3B3ABA5DEFE700808305AA16A3062B76658A791', 'Sam', NULL, 'America/Los_Angeles', TRUE);

-- License Codes
INSERT INTO licences (licence_code, licence_type, redeemed_by_user_id, status, redeemed_at)
VALUES ('ALPHA-001-FREE', 'alpha', 1, 'redeemed', CURRENT_TIMESTAMP);

INSERT INTO licences (licence_code, licence_type, redeemed_by_user_id, status, redeemed_at)
VALUES ('ALPHA-002-FREE', 'alpha', 2, 'redeemed', CURRENT_TIMESTAMP);

INSERT INTO licences (licence_code, licence_type, redeemed_by_user_id, status, redeemed_at)
VALUES ('ALPHA-003-FREE', 'alpha', 3, 'redeemed', CURRENT_TIMESTAMP);

INSERT INTO licences (licence_code, licence_type, redeemed_by_user_id, status, redeemed_at)
VALUES ('ALPHA-004-FREE', 'alpha', 4, 'redeemed', CURRENT_TIMESTAMP);

INSERT INTO licences (licence_code, licence_type, gifted_to_email, gifted_by_user_id, status)
VALUES ('GIFT-005-CASEY', 'gifted', 'casey@polyculy.demo', 1, 'gifted_pending');

INSERT INTO licences (licence_code, licence_type, redeemed_by_user_id, status, redeemed_at)
VALUES ('ALPHA-006-FREE', 'alpha', 7, 'redeemed', CURRENT_TIMESTAMP);

INSERT INTO licences (licence_code, licence_type, status)
VALUES ('BETA-007-FREE', 'beta', 'available');

INSERT INTO licences (licence_code, licence_type, status)
VALUES ('BETA-008-FREE', 'beta', 'available');

INSERT INTO licences (licence_code, licence_type, status)
VALUES ('PROMO-009-FREE', 'purchased', 'available');

INSERT INTO licences (licence_code, licence_type, status)
VALUES ('PROMO-010-FREE', 'purchased', 'available');

-- Connections (user_id_1 = lower id by convention)
-- You (1) ↔ Riley (2): Connected
INSERT INTO connections (user_id_1, user_id_2, status, initiated_by)
VALUES (1, 2, 'connected', 1);

-- You (1) ↔ Jamie (3): Awaiting Confirmation
INSERT INTO connections (user_id_1, user_id_2, status, initiated_by)
VALUES (1, 3, 'awaiting_confirmation', 1);

-- You (1) ↔ Alex (4): Awaiting Confirmation
INSERT INTO connections (user_id_1, user_id_2, status, initiated_by)
VALUES (1, 4, 'awaiting_confirmation', 1);

-- You (1) ↔ Casey (5): Licence Gifted Awaiting Signup (Casey not fully onboarded)
INSERT INTO connections (user_id_1, user_id_2, status, invited_email, invited_display_name, initiated_by)
VALUES (1, 5, 'licence_gifted_awaiting_signup', 'casey@polyculy.demo', 'Casey', 1);

-- You (1) ↔ Morgan (6): Awaiting Signup
INSERT INTO connections (user_id_1, user_id_2, status, invited_email, invited_display_name, initiated_by)
VALUES (1, 6, 'awaiting_signup', 'morgan@polyculy.demo', 'Morgan', 1);

-- You (1) ↔ Sam (7): Revoked
INSERT INTO connections (user_id_1, user_id_2, status, initiated_by)
VALUES (1, 7, 'revoked', 1);

-- Riley (2) ↔ Alex (4): Connected
INSERT INTO connections (user_id_1, user_id_2, status, initiated_by)
VALUES (2, 4, 'connected', 2);

-- Connection Display Preferences
INSERT INTO connection_display_prefs (user_id, target_user_id, calendar_color) VALUES (1, 2, '#22C55E');
INSERT INTO connection_display_prefs (user_id, target_user_id, calendar_color) VALUES (1, 3, '#3B82F6');
INSERT INTO connection_display_prefs (user_id, target_user_id, calendar_color) VALUES (1, 4, '#F97316');
INSERT INTO connection_display_prefs (user_id, target_user_id, calendar_color) VALUES (1, 5, '#A855F7');
INSERT INTO connection_display_prefs (user_id, target_user_id, calendar_color) VALUES (1, 6, '#EAB308');
INSERT INTO connection_display_prefs (user_id, target_user_id, calendar_color) VALUES (1, 7, '#6B7280');

-- Personal Events (owner = You, user_id 1)
INSERT INTO personal_events (owner_user_id, title, start_time, end_time, timezone_id, event_details, address, reminder_minutes, visibility_tier)
VALUES (1, 'Doctor''s appointment', TIMESTAMP '2026-04-12 09:00:00', TIMESTAMP '2026-04-12 10:00:00', 'America/Los_Angeles', 'Annual checkup', '123 Medical Center Dr', 30, 'full_details');

INSERT INTO personal_events (owner_user_id, title, start_time, end_time, timezone_id, event_details, visibility_tier)
VALUES (1, 'Yoga Class', TIMESTAMP '2026-04-15 07:00:00', TIMESTAMP '2026-04-15 08:00:00', 'America/Los_Angeles', 'Morning flow', 'invisible');

INSERT INTO personal_events (owner_user_id, title, start_time, end_time, timezone_id, event_details, visibility_tier)
VALUES (1, 'Work Meeting', TIMESTAMP '2026-04-16 14:00:00', TIMESTAMP '2026-04-16 15:00:00', 'America/Los_Angeles', 'Sprint planning', 'full_details');

-- Personal Event Visibility (for Doctor's appointment - shared with Riley as full_details)
INSERT INTO personal_event_visibility (event_id, target_user_id, visibility_type) VALUES (1, 2, 'full_details');

-- Personal Event Visibility (for Work Meeting - shared as busy block with Riley)
INSERT INTO personal_event_visibility (event_id, target_user_id, visibility_type) VALUES (3, 2, 'busy_block');

-- Riley's personal events
INSERT INTO personal_events (owner_user_id, title, start_time, end_time, timezone_id, event_details, visibility_tier)
VALUES (2, 'Book Club', TIMESTAMP '2026-04-17 19:00:00', TIMESTAMP '2026-04-17 21:00:00', 'America/New_York', 'Monthly meeting', 'full_details');

INSERT INTO personal_event_visibility (event_id, target_user_id, visibility_type) VALUES (4, 1, 'full_details');

-- Shared Events
-- Dinner with Casey (organizer=You, tentative since no non-organizer accepted)
INSERT INTO shared_events (organizer_user_id, title, start_time, end_time, timezone_id, event_details, address, reminder_minutes, reminder_scope, participant_visibility, global_state)
VALUES (1, 'Dinner with Casey', TIMESTAMP '2026-04-19 19:30:00', TIMESTAMP '2026-04-19 21:00:00', 'America/Los_Angeles', 'Dinner at the new Italian place', '456 Restaurant Row', 15, 'all', 'visible', 'tentative');

-- Participants for Dinner with Casey
INSERT INTO shared_event_participants (shared_event_id, user_id, attendance_type, response_status)
VALUES (1, 2, 'required', 'pending');

-- Lunch with Alex (organizer=You, active since Alex accepted)
INSERT INTO shared_events (organizer_user_id, title, start_time, end_time, timezone_id, event_details, address, reminder_minutes, reminder_scope, participant_visibility, global_state)
VALUES (1, 'Lunch with Alex', TIMESTAMP '2026-04-22 13:00:00', TIMESTAMP '2026-04-22 14:00:00', 'America/Los_Angeles', 'Catch up over lunch', '789 Cafe Blvd', 15, 'me', 'visible', 'active');

INSERT INTO shared_event_participants (shared_event_id, user_id, attendance_type, response_status)
VALUES (2, 4, 'required', 'accepted');

-- Gym with Jamie (organizer=You, tentative)
INSERT INTO shared_events (organizer_user_id, title, start_time, end_time, timezone_id, event_details, address, reminder_minutes, reminder_scope, participant_visibility, global_state)
VALUES (1, 'Gym with Jamie', TIMESTAMP '2026-04-29 18:00:00', TIMESTAMP '2026-04-29 19:00:00', 'America/Los_Angeles', 'Workout session', 'FitLife Gym', 30, 'me', 'visible', 'tentative');

INSERT INTO shared_event_participants (shared_event_id, user_id, attendance_type, response_status)
VALUES (3, 3, 'required', 'pending');

-- Movie Night with Riley (organizer=Riley, active, multi-person)
INSERT INTO shared_events (organizer_user_id, title, start_time, end_time, timezone_id, event_details, address, reminder_minutes, reminder_scope, participant_visibility, global_state)
VALUES (2, 'Movie Night with Riley', TIMESTAMP '2026-04-26 20:00:00', TIMESTAMP '2026-04-26 23:00:00', 'America/New_York', 'Watching the new sci-fi film', 'Riley''s Place', 60, 'all', 'visible', 'active');

INSERT INTO shared_event_participants (shared_event_id, user_id, attendance_type, response_status)
VALUES (4, 1, 'required', 'accepted');

INSERT INTO shared_event_participants (shared_event_id, user_id, attendance_type, response_status)
VALUES (4, 4, 'optional', 'maybe');

-- Notifications
INSERT INTO notifications (user_id, notification_type, title, message, related_entity_type, related_entity_id)
VALUES (1, 'connection_request', 'Connection Request', 'Jamie wants to connect with you.', 'connection', 2);

INSERT INTO notifications (user_id, notification_type, title, message, related_entity_type, related_entity_id)
VALUES (1, 'shared_event_invitation', 'Event Invitation', 'Riley invited you to Movie Night with Riley.', 'shared_event', 4);

INSERT INTO notifications (user_id, notification_type, title, message, related_entity_type, related_entity_id, is_read)
VALUES (1, 'shared_event_accepted', 'Event Accepted', 'Alex accepted your invitation to Lunch with Alex.', 'shared_event', 2, TRUE);

-- Audit Log
INSERT INTO audit_log (actor_user_id, action_type, entity_type, entity_id, details)
VALUES (1, 'connection_request', 'connection', 1, 'You sent a connection request to Riley');

INSERT INTO audit_log (actor_user_id, action_type, entity_type, entity_id, details)
VALUES (2, 'connection_confirmed', 'connection', 1, 'Riley confirmed the connection');

INSERT INTO audit_log (actor_user_id, action_type, entity_type, entity_id, details)
VALUES (1, 'event_created', 'shared_event', 1, 'Created shared event: Dinner with Casey');

INSERT INTO audit_log (actor_user_id, action_type, entity_type, entity_id, details)
VALUES (1, 'event_created', 'shared_event', 2, 'Created shared event: Lunch with Alex');

INSERT INTO audit_log (actor_user_id, action_type, entity_type, entity_id, details)
VALUES (4, 'event_accepted', 'shared_event', 2, 'Alex accepted invitation to Lunch with Alex');

INSERT INTO audit_log (actor_user_id, action_type, entity_type, entity_id, details)
VALUES (1, 'licence_gifted', 'licence', 5, 'You gifted a licence to casey@polyculy.demo');

INSERT INTO audit_log (actor_user_id, action_type, entity_type, entity_id, details)
VALUES (1, 'connection_revoked', 'connection', 6, 'You revoked connection with Sam');
