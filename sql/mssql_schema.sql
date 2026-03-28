use polyculy
-- Polyculy Database Schema (H2 / MSSQLServer mode)
-- ============================================================


IF (OBJECT_ID('dbo.fk_lic_owner', 'F') IS NOT NULL)
BEGIN
    ALTER TABLE dbo.licences DROP CONSTRAINT fk_lic_owner,fk_lic_gifted_by, fk_lic_redeemed

	ALTER TABLE dbo.connections DROP CONSTRAINT fk_conn_u1 , fk_conn_u2, fk_conn_init
	ALTER TABLE dbo.connection_display_prefs DROP CONSTRAINT fk_cdp_user , fk_cdp_target
ALTER TABLE dbo.personal_events DROP CONSTRAINT fk_pe_owner
ALTER TABLE dbo.personal_event_visibility DROP CONSTRAINT fk_pev_event , fk_pev_target
ALTER TABLE dbo.shared_events DROP CONSTRAINT fk_se_organizer
ALTER TABLE dbo.shared_event_participants DROP CONSTRAINT fk_sep_event , fk_sep_user, fk_sep_link
ALTER TABLE dbo.proposals DROP CONSTRAINT fk_prop_event , fk_prop_user
ALTER TABLE dbo.notifications DROP CONSTRAINT fk_notif_user
ALTER TABLE dbo.notification_preferences DROP CONSTRAINT fk_np_user
ALTER TABLE dbo.audit_log DROP CONSTRAINT fk_audit_actor
ALTER TABLE dbo.informational_emails DROP CONSTRAINT fk_ie_event,fk_ie_sender,fk_ie_claimed
ALTER TABLE dbo.calendar_toggle_state DROP CONSTRAINT fk_cts_user,fk_cts_target


END


-- Users
DROP TABLE IF EXISTS dbo.[users];
CREATE TABLE  users (
    user_id [int] IDENTITY(1,1) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    display_name VARCHAR(100) NOT NULL,
    avatar_url VARCHAR(500),
    timezone_id VARCHAR(100) NOT NULL DEFAULT 'America/New_York',
    calendar_created bit NOT NULL DEFAULT 0,
    is_active bit NOT NULL DEFAULT 1,
    created_at datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
 CONSTRAINT [PK_users] PRIMARY KEY CLUSTERED 
(
	[user_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

-- Licences
DROP TABLE IF EXISTS dbo.[Licences];
CREATE TABLE licences (
    licence_id INT IDENTITY(1,1) NOT NULL,
    licence_code VARCHAR(50) NOT NULL UNIQUE,
    licence_type VARCHAR(20) NOT NULL DEFAULT 'purchased',
    pack_id INT,
    owner_user_id INT,
    gifted_to_email VARCHAR(255),
    gifted_by_user_id INT,
    redeemed_by_user_id INT,
    status VARCHAR(20) NOT NULL DEFAULT 'available',
    created_at datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
    redeemed_at datetime,
    CONSTRAINT fk_lic_owner FOREIGN KEY (owner_user_id) REFERENCES users(user_id),
    CONSTRAINT fk_lic_gifted_by FOREIGN KEY (gifted_by_user_id) REFERENCES users(user_id),
    CONSTRAINT fk_lic_redeemed FOREIGN KEY (redeemed_by_user_id) REFERENCES users(user_id),
 CONSTRAINT [PK_licences] PRIMARY KEY CLUSTERED 
(
	[licence_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]





-- Connections
DROP TABLE IF EXISTS dbo.[connections];
CREATE TABLE connections (
    connection_id INT IDENTITY(1,1) NOT NULL,
    user_id_1 INT,
    user_id_2 INT,
    status VARCHAR(40) NOT NULL DEFAULT 'awaiting_signup',
    invited_email VARCHAR(255),
    invited_display_name VARCHAR(100),
    initiated_by INT,
    created_at datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_hidden bit NOT NULL DEFAULT 0,
    CONSTRAINT fk_conn_u1 FOREIGN KEY (user_id_1) REFERENCES users(user_id),
    CONSTRAINT fk_conn_u2 FOREIGN KEY (user_id_2) REFERENCES users(user_id),
    CONSTRAINT fk_conn_init FOREIGN KEY (initiated_by) REFERENCES users(user_id)
,
 CONSTRAINT [PK_connection_id] PRIMARY KEY CLUSTERED 
(
	[connection_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

-- Connection Display Preferences
DROP TABLE IF EXISTS dbo.[connection_display_prefs];
CREATE TABLE connection_display_prefs (
    pref_id INT IDENTITY(1,1) NOT NULL,
    user_id INT NOT NULL,
    target_user_id INT NOT NULL,
    nickname VARCHAR(100),
    avatar_override VARCHAR(500),
    calendar_color VARCHAR(7) NOT NULL DEFAULT '#7C3AED',
    CONSTRAINT fk_cdp_user FOREIGN KEY (user_id) REFERENCES users(user_id),
    CONSTRAINT fk_cdp_target FOREIGN KEY (target_user_id) REFERENCES users(user_id)
,
 CONSTRAINT [PK_connection_display_prefs] PRIMARY KEY CLUSTERED 
(
	[pref_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

-- Personal Events
DROP TABLE IF EXISTS dbo.[personal_events];
CREATE TABLE  personal_events (
    event_id INT IDENTITY(1,1) NOT NULL,
    owner_user_id INT NOT NULL,
    title VARCHAR(300) NOT NULL,
    start_time datetime NOT NULL,
    end_time datetime,
    all_day bit NOT NULL DEFAULT 0,
    timezone_id VARCHAR(100) NOT NULL DEFAULT 'America/New_York',
    event_details NVARCHAR(MAX),
    address VARCHAR(500),
    reminder_minutes INT,
    visibility_tier VARCHAR(20) NOT NULL DEFAULT 'invisible',
    is_cancelled bit NOT NULL DEFAULT 0,
    created_at datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pe_owner FOREIGN KEY (owner_user_id) REFERENCES users(user_id)
,
 CONSTRAINT [PK_personal_events] PRIMARY KEY CLUSTERED 
(
	[event_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

-- Personal Event Visibility
DROP TABLE IF EXISTS dbo.[personal_event_visibility];
CREATE TABLE  personal_event_visibility (
    visibility_id INT IDENTITY(1,1) NOT NULL,
    event_id INT NOT NULL,
    target_user_id INT NOT NULL,
    visibility_type VARCHAR(20) NOT NULL,
    snapshot_at datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pev_event FOREIGN KEY (event_id) REFERENCES personal_events(event_id),
    CONSTRAINT fk_pev_target FOREIGN KEY (target_user_id) REFERENCES users(user_id)
,
 CONSTRAINT [PK_personal_event_visibility] PRIMARY KEY CLUSTERED 
(
	[visibility_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

-- Shared Events
DROP TABLE IF EXISTS dbo.[shared_events];
CREATE TABLE  shared_events (
    shared_event_id INT IDENTITY(1,1) NOT NULL,
    organizer_user_id INT NOT NULL,
    title VARCHAR(300) NOT NULL,
    start_time datetime NOT NULL,
    end_time datetime,
    all_day bit NOT NULL DEFAULT 0,
    timezone_id VARCHAR(100) NOT NULL DEFAULT 'America/New_York',
    event_details NVARCHAR(MAX),
    address VARCHAR(500),
    reminder_minutes INT,
    reminder_scope VARCHAR(5) NOT NULL DEFAULT 'me',
    participant_visibility VARCHAR(10) NOT NULL DEFAULT 'visible',
    global_state VARCHAR(20) NOT NULL DEFAULT 'tentative',
    cancellation_reason VARCHAR(50),
    ownership_transfer_active bit NOT NULL DEFAULT 0,
    ownership_transfer_deadline datetime,
    created_at datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_se_organizer FOREIGN KEY (organizer_user_id) REFERENCES users(user_id)
,
 CONSTRAINT [PK_shared_events] PRIMARY KEY CLUSTERED 
(
	[shared_event_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

-- Shared Event Participants
DROP TABLE IF EXISTS dbo.[shared_event_participants];
CREATE TABLE  shared_event_participants (
    participant_id INT IDENTITY(1,1) NOT NULL,
    shared_event_id INT NOT NULL,
    user_id INT NOT NULL,
    attendance_type VARCHAR(10) NOT NULL DEFAULT 'required',
    response_status VARCHAR(20) NOT NULL DEFAULT 'pending',
    is_one_hop bit NOT NULL DEFAULT 0,
    link_person_user_id INT,
    one_hop_consent_given bit NOT NULL DEFAULT 0,
    one_hop_activated bit NOT NULL DEFAULT 0,
    is_removed bit NOT NULL DEFAULT 0,
    created_at datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_sep_event FOREIGN KEY (shared_event_id) REFERENCES shared_events(shared_event_id),
    CONSTRAINT fk_sep_user FOREIGN KEY (user_id) REFERENCES users(user_id),
    CONSTRAINT fk_sep_link FOREIGN KEY (link_person_user_id) REFERENCES users(user_id)
,
 CONSTRAINT [PK_shared_event_participants] PRIMARY KEY CLUSTERED 
(
	[participant_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

-- Proposals
DROP TABLE IF EXISTS dbo.[proposals];
CREATE TABLE  proposals (
    proposal_id INT IDENTITY(1,1) NOT NULL,
    shared_event_id INT NOT NULL,
    proposer_user_id INT NOT NULL,
    proposed_start datetime NOT NULL,
    proposed_end datetime NOT NULL,
    message NVARCHAR(MAX),
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    created_at datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_prop_event FOREIGN KEY (shared_event_id) REFERENCES shared_events(shared_event_id),
    CONSTRAINT fk_prop_user FOREIGN KEY (proposer_user_id) REFERENCES users(user_id)
,
 CONSTRAINT [PK_proposals] PRIMARY KEY CLUSTERED 
(
	[proposal_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

-- Notifications
DROP TABLE IF EXISTS dbo.[notifications];
CREATE TABLE  notifications (
    notification_id INT IDENTITY(1,1) NOT NULL,
    user_id INT NOT NULL,
    notification_type VARCHAR(50) NOT NULL,
    title VARCHAR(300) NOT NULL,
    message NVARCHAR(MAX),
    related_entity_type VARCHAR(30),
    related_entity_id INT,
    is_read bit NOT NULL DEFAULT 0,
    created_at datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_notif_user FOREIGN KEY (user_id) REFERENCES users(user_id)
,
 CONSTRAINT [PK_notifications] PRIMARY KEY CLUSTERED 
(
	[notification_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

-- Notification Preferences
DROP TABLE IF EXISTS dbo.[notification_preferences];
CREATE TABLE  notification_preferences (
    pref_id INT IDENTITY(1,1) NOT NULL,
    user_id INT NOT NULL,
    notification_type VARCHAR(50) NOT NULL,
    is_enabled bit NOT NULL DEFAULT 1,
    delivery_mode VARCHAR(10) NOT NULL DEFAULT 'instant',
    quiet_hours_start VARCHAR(5),
    quiet_hours_end VARCHAR(5),
    CONSTRAINT fk_np_user FOREIGN KEY (user_id) REFERENCES users(user_id)
,
 CONSTRAINT [PK_notification_preferences] PRIMARY KEY CLUSTERED 
(
	[pref_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, 
ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

-- Audit Log
DROP TABLE IF EXISTS dbo.[audit_log];
CREATE TABLE  audit_log (
    audit_id INT IDENTITY(1,1) NOT NULL,
    actor_user_id INT,
    action_type VARCHAR(50) NOT NULL,
    entity_type VARCHAR(30) NOT NULL,
    entity_id INT,
    details NVARCHAR(MAX),
    created_at datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_audit_actor FOREIGN KEY (actor_user_id) REFERENCES users(user_id)
,
 CONSTRAINT [PK_audit_log] PRIMARY KEY CLUSTERED 
(
	[audit_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

-- Informational Emails
DROP TABLE IF EXISTS dbo.[informational_emails];
CREATE TABLE  informational_emails (
    info_email_id INT IDENTITY(1,1) NOT NULL,
    shared_event_id INT NOT NULL,
    sender_user_id INT NOT NULL,
    recipient_email VARCHAR(255) NOT NULL,
    recipient_name VARCHAR(100),
    message_note NVARCHAR(MAX),
    is_claimed bit NOT NULL DEFAULT 0,
    claimed_by_user_id INT,
    created_at datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_ie_event FOREIGN KEY (shared_event_id) REFERENCES shared_events(shared_event_id),
    CONSTRAINT fk_ie_sender FOREIGN KEY (sender_user_id) REFERENCES users(user_id),
    CONSTRAINT fk_ie_claimed FOREIGN KEY (claimed_by_user_id) REFERENCES users(user_id)
,
 CONSTRAINT [PK_informational_emails] PRIMARY KEY CLUSTERED 
(
	[info_email_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

-- CSRF Tokens
DROP TABLE IF EXISTS dbo.[csrf_tokens];
CREATE TABLE  csrf_tokens (
    token_id INT IDENTITY(1,1) NOT NULL,
    session_id VARCHAR(100) NOT NULL,
    token VARCHAR(100) NOT NULL,
    created_at datetime NOT NULL DEFAULT CURRENT_TIMESTAMP
,
 CONSTRAINT [PK_csrf_tokens] PRIMARY KEY CLUSTERED 
(
	[token_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

-- Calendar Toggle State (for Mine/Our persistence)
DROP TABLE IF EXISTS dbo.[calendar_toggle_state];
CREATE TABLE  calendar_toggle_state (
    toggle_id INT IDENTITY(1,1) NOT NULL,
    user_id INT NOT NULL,
    target_user_id INT NOT NULL,
    is_visible bit NOT NULL DEFAULT 1,
    CONSTRAINT fk_cts_user FOREIGN KEY (user_id) REFERENCES users(user_id),
    CONSTRAINT fk_cts_target FOREIGN KEY (target_user_id) REFERENCES users(user_id)
,
 CONSTRAINT [PK_calendar_toggle_state] PRIMARY KEY CLUSTERED 
(
	[toggle_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

-- Indexes

DROP INDEX IF EXISTS [ix_conn_u1] ON dbo.connections
DROP INDEX IF EXISTS [ix_conn_u2] ON dbo.connections
DROP INDEX IF EXISTS [ix_conn_status] ON dbo.connections
DROP INDEX IF EXISTS [ix_conn_email] ON dbo.connections
DROP INDEX IF EXISTS [ix_pe_owner] ON dbo.personal_events
DROP INDEX IF EXISTS [ix_pe_start] ON dbo.personal_events
DROP INDEX IF EXISTS [ix_pev_event] ON dbo.personal_event_visibility
DROP INDEX IF EXISTS [ix_se_organizer] ON dbo.shared_events
DROP INDEX IF EXISTS [ix_se_state] ON dbo.shared_events
DROP INDEX IF EXISTS [ix_sep_event] ON dbo.shared_event_participants
DROP INDEX IF EXISTS [ix_sep_user] ON dbo.shared_event_participants
DROP INDEX IF EXISTS [ix_prop_event] ON dbo.proposals
DROP INDEX IF EXISTS [ix_notif_user] ON dbo.notifications
DROP INDEX IF EXISTS [ix_notif_read] ON dbo.notifications
DROP INDEX IF EXISTS [ix_audit_entity] ON dbo.audit_log
DROP INDEX IF EXISTS [ix_audit_date] ON dbo.audit_log
DROP INDEX IF EXISTS [ix_lic_code] ON dbo.licences
DROP INDEX IF EXISTS [ix_lic_status] ON dbo.licences


CREATE INDEX ix_conn_u1 ON connections(user_id_1);
CREATE INDEX ix_conn_u2 ON connections(user_id_2);
CREATE INDEX ix_conn_status ON connections(status);
CREATE INDEX ix_conn_email ON connections(invited_email);
CREATE INDEX ix_pe_owner ON personal_events(owner_user_id);
CREATE INDEX ix_pe_start ON personal_events(start_time);
CREATE INDEX ix_pev_event ON personal_event_visibility(event_id);
CREATE INDEX ix_se_organizer ON shared_events(organizer_user_id);
CREATE INDEX ix_se_state ON shared_events(global_state);
CREATE INDEX ix_sep_event ON shared_event_participants(shared_event_id);
CREATE INDEX ix_sep_user ON shared_event_participants(user_id);
CREATE INDEX ix_prop_event ON proposals(shared_event_id);
CREATE INDEX ix_notif_user ON notifications(user_id);
CREATE INDEX ix_notif_read ON notifications(is_read);
CREATE INDEX ix_audit_entity ON audit_log(entity_type, entity_id);
CREATE INDEX ix_audit_date ON audit_log(created_at);
CREATE INDEX ix_lic_code ON licences(licence_code);
CREATE INDEX ix_lic_status ON licences(status);
