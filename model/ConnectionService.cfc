component {

    function getByUser(required numeric userId) {
        return queryExecute(
            "SELECT c.connection_id, c.user_id_1, c.user_id_2, c.status, c.invited_email,
                    c.invited_display_name, c.initiated_by, c.created_at, c.is_hidden,
                    u1.display_name AS user1_name, u1.email AS user1_email, u1.avatar_url AS user1_avatar,
                    u2.display_name AS user2_name, u2.email AS user2_email, u2.avatar_url AS user2_avatar,
                    dp.nickname, dp.avatar_override, dp.calendar_color
             FROM polyculy.dbo.connections c
             LEFT JOIN users u1 ON c.user_id_1 = u1.user_id
             LEFT JOIN users u2 ON c.user_id_2 = u2.user_id
             LEFT JOIN connection_display_prefs dp ON dp.user_id = :uid
                AND dp.target_user_id = CASE WHEN c.user_id_1 = :uid THEN c.user_id_2 ELSE c.user_id_1 END
             WHERE (c.user_id_1 = :uid OR c.user_id_2 = :uid)
             ORDER BY c.status, c.created_at DESC",
            { uid: { value: arguments.userId, cfsqltype: "cf_sql_integer" } }
        );
    }

    function getConnectedUsers(required numeric userId) {
        return queryExecute(
            "SELECT CASE WHEN c.user_id_1 = :uid THEN c.user_id_2 ELSE c.user_id_1 END AS other_user_id,
                    CASE WHEN c.user_id_1 = :uid THEN u2.display_name ELSE u1.display_name END AS display_name,
                    CASE WHEN c.user_id_1 = :uid THEN u2.email ELSE u1.email END AS email,
                    dp.calendar_color, dp.nickname
             FROM polyculy.dbo.connections c
             LEFT JOIN users u1 ON c.user_id_1 = u1.user_id
             LEFT JOIN users u2 ON c.user_id_2 = u2.user_id
             LEFT JOIN connection_display_prefs dp ON dp.user_id = :uid
                AND dp.target_user_id = CASE WHEN c.user_id_1 = :uid THEN c.user_id_2 ELSE c.user_id_1 END
             WHERE (c.user_id_1 = :uid OR c.user_id_2 = :uid) AND c.status = 'connected'
             ORDER BY display_name",
            { uid: { value: arguments.userId, cfsqltype: "cf_sql_integer" } }
        );
    }

    function getPolyculeMembers(required numeric userId) {
        return queryExecute(
            "SELECT c.connection_id,
                    CASE WHEN c.user_id_1 = :uid THEN c.user_id_2 ELSE c.user_id_1 END AS other_user_id,
                    CASE WHEN c.user_id_1 = :uid THEN u2.display_name ELSE u1.display_name END AS display_name,
                    CASE WHEN c.user_id_1 = :uid THEN u2.email ELSE u1.email END AS email,
                    c.status, c.invited_display_name, c.invited_email, c.is_hidden,
                    dp.calendar_color, dp.nickname, dp.avatar_override
             FROM polyculy.dbo.connections c
             LEFT JOIN polyculy.dbo.users u1 ON c.user_id_1 = u1.user_id
             LEFT JOIN polyculy.dbo.users u2 ON c.user_id_2 = u2.user_id
             LEFT JOIN polyculy.dbo.connection_display_prefs dp ON dp.user_id = :uid
                AND dp.target_user_id = CASE WHEN c.user_id_1 = :uid THEN c.user_id_2 ELSE c.user_id_1 END
             WHERE (c.user_id_1 = :uid OR c.user_id_2 = :uid)
                AND (isNull(c.is_hidden,0) = 0 OR c.status != 'revoked')
             ORDER BY
                CASE c.status
                    WHEN 'connected' THEN 1
                    WHEN 'awaiting_confirmation' THEN 2
                    WHEN 'licence_gifted_awaiting_signup' THEN 3
                    WHEN 'awaiting_signup' THEN 4
                    WHEN 'revoked' THEN 5
                END",
            { uid: { value: arguments.userId, cfsqltype: "cf_sql_integer" } }
        );
    }

    function sendRequest(required numeric fromUserId, required string toEmail, required string displayName) {
        // Check if user exists on platform
        var existingUser = queryExecute(
            "SELECT polyculy.dbo.user_id FROM users WHERE email = :email",
            { email: { value: arguments.toEmail, cfsqltype: "cf_sql_varchar" } }
        );

        // Check if connection already exists
        if (existingUser.recordCount > 0) {
            var toUserId = existingUser.user_id;
            var existing = queryExecute(
                "SELECT connection_id, status FROM polyculy.dbo.connections
                 WHERE (user_id_1 = :u1 AND user_id_2 = :u2) OR (user_id_1 = :u2 AND user_id_2 = :u1)",
                {
                    u1: { value: arguments.fromUserId, cfsqltype: "cf_sql_integer" },
                    u2: { value: toUserId, cfsqltype: "cf_sql_integer" }
                }
            );
            if (existing.recordCount > 0 && existing.status != "revoked") {
                return { success: false, message: "A connection already exists with this person." };
            }

            var uid1 = min(arguments.fromUserId, toUserId);
            var uid2 = max(arguments.fromUserId, toUserId);

            if (existing.recordCount > 0 && existing.status == "revoked") {
                // Reconnect
                queryExecute(
                    "UPDATE polyculy.dbo.connections SET status = 'awaiting_confirmation', updated_at = CURRENT_TIMESTAMP
                     WHERE connection_id = :cid",
                    { cid: { value: existing.connection_id, cfsqltype: "cf_sql_integer" } }
                );
            } else {
                queryExecute(
                    "INSERT INTO polyculy.dbo.connections (user_id_1, user_id_2, status, initiated_by)
                     VALUES (:u1, :u2, 'awaiting_confirmation', :init)",
                    {
                        u1: { value: uid1, cfsqltype: "cf_sql_integer" },
                        u2: { value: uid2, cfsqltype: "cf_sql_integer" },
                        init: { value: arguments.fromUserId, cfsqltype: "cf_sql_integer" }
                    }
                );
            }
            return { success: true, message: "Connection request sent.", status: "awaiting_confirmation" };
        } else {
            // User not on platform yet
            var uid1 = arguments.fromUserId;
            queryExecute(
                "INSERT INTO polyculy.dbo.connections (user_id_1, status, invited_email, invited_display_name, initiated_by)
                 VALUES (:u1, 'awaiting_signup', :email, :name, :init)",
                {
                    u1: { value: uid1, cfsqltype: "cf_sql_integer" },
                    email: { value: arguments.toEmail, cfsqltype: "cf_sql_varchar" },
                    name: { value: arguments.displayName, cfsqltype: "cf_sql_varchar" },
                    init: { value: arguments.fromUserId, cfsqltype: "cf_sql_integer" }
                }
            );
            return { success: true, message: "Invitation sent.", status: "awaiting_signup" };
        }
    }

    function confirmConnection(required numeric connectionId, required numeric userId) {
        queryExecute(
            "UPDATE polyculy.dbo.connections SET status = 'connected', updated_at = CURRENT_TIMESTAMP
             WHERE connection_id = :cid AND status = 'awaiting_confirmation'
             AND (user_id_1 = :uid OR user_id_2 = :uid)",
            {
                cid: { value: arguments.connectionId, cfsqltype: "cf_sql_integer" },
                uid: { value: arguments.userId, cfsqltype: "cf_sql_integer" }
            }
        );
    }

    function revokeConnection(required numeric connectionId, required numeric userId) {
        queryExecute(
            "UPDATE polyculy.dbo.connections SET status = 'revoked', updated_at = CURRENT_TIMESTAMP
             WHERE connection_id = :cid AND (user_id_1 = :uid OR user_id_2 = :uid)",
            {
                cid: { value: arguments.connectionId, cfsqltype: "cf_sql_integer" },
                uid: { value: arguments.userId, cfsqltype: "cf_sql_integer" }
            }
        );
    }

    function hideConnection(required numeric connectionId) {
        queryExecute(
            "UPDATE polyculy.dbo.connections SET is_hidden = TRUE WHERE connection_id = :cid",
            { cid: { value: arguments.connectionId, cfsqltype: "cf_sql_integer" } }
        );
    }

    function getConnectionBetween(required numeric userId1, required numeric userId2) {
        return queryExecute(
            "SELECT polyculy.dbo.connection_id, status FROM connections
             WHERE (user_id_1 = :u1 AND user_id_2 = :u2) OR (user_id_1 = :u2 AND user_id_2 = :u1)",
            {
                u1: { value: arguments.userId1, cfsqltype: "cf_sql_integer" },
                u2: { value: arguments.userId2, cfsqltype: "cf_sql_integer" }
            }
        );
    }

    function updateDisplayPrefs(required numeric userId, required numeric targetUserId, string nickname = "", string avatarOverride = "", string calendarColor = "") {
        var existing = queryExecute(
            "SELECT polyculy.dbo.pref_id FROM connection_display_prefs WHERE user_id = :uid AND target_user_id = :tid",
            {
                uid: { value: arguments.userId, cfsqltype: "cf_sql_integer" },
                tid: { value: arguments.targetUserId, cfsqltype: "cf_sql_integer" }
            }
        );
        if (existing.recordCount > 0) {
            queryExecute(
                "UPDATE polyculy.dbo.connection_display_prefs SET nickname = :nick, avatar_override = :avatar, calendar_color = :color
                 WHERE user_id = :uid AND target_user_id = :tid",
                {
                    uid: { value: arguments.userId, cfsqltype: "cf_sql_integer" },
                    tid: { value: arguments.targetUserId, cfsqltype: "cf_sql_integer" },
                    nick: { value: arguments.nickname, cfsqltype: "cf_sql_varchar", null: !len(arguments.nickname) },
                    avatar: { value: arguments.avatarOverride, cfsqltype: "cf_sql_varchar", null: !len(arguments.avatarOverride) },
                    color: { value: len(arguments.calendarColor) ? arguments.calendarColor : "##7C3AED", cfsqltype: "cf_sql_varchar" }
                }
            );
        } else {
            queryExecute(
                "INSERT INTO polyculy.dbo.connection_display_prefs (user_id, target_user_id, nickname, avatar_override, calendar_color)
                 VALUES (:uid, :tid, :nick, :avatar, :color)",
                {
                    uid: { value: arguments.userId, cfsqltype: "cf_sql_integer" },
                    tid: { value: arguments.targetUserId, cfsqltype: "cf_sql_integer" },
                    nick: { value: arguments.nickname, cfsqltype: "cf_sql_varchar", null: !len(arguments.nickname) },
                    avatar: { value: arguments.avatarOverride, cfsqltype: "cf_sql_varchar", null: !len(arguments.avatarOverride) },
                    color: { value: len(arguments.calendarColor) ? arguments.calendarColor : "##7C3AED", cfsqltype: "cf_sql_varchar" }
                }
            );
        }
    }

    function upgradeToGifted(required numeric connectionId) {
        queryExecute(
            "UPDATE polyculy.dbo.connections SET status = 'licence_gifted_awaiting_signup', updated_at = CURRENT_TIMESTAMP
             WHERE connection_id = :cid AND status = 'awaiting_signup'",
            { cid: { value: arguments.connectionId, cfsqltype: "cf_sql_integer" } }
        );
    }

}
