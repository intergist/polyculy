component {

    function create(required struct data) {
        queryExecute(
            "INSERT INTO polyculy.dbo.shared_events (organizer_user_id, title, start_time, end_time, all_day, timezone_id, event_details, address, reminder_minutes, reminder_scope, participant_visibility, global_state)
             VALUES (:org, :title, :startTime, :endTime, :allDay, :tz, :details, :addr, :reminder, :scope, :pv, 'tentative')",
            {
                org: { value: data.organizerId, cfsqltype: "cf_sql_integer" },
                title: { value: data.title, cfsqltype: "cf_sql_varchar" },
                startTime: { value: data.startTime, cfsqltype: "cf_sql_timestamp" },
                endTime: { value: data.endTime, cfsqltype: "cf_sql_timestamp", null: !len(data.endTime ?: "") },
                allDay: { value: data.allDay ?: false, cfsqltype: "cf_sql_bit" },
                tz: { value: data.timezoneId ?: "America/New_York", cfsqltype: "cf_sql_varchar" },
                details: { value: data.eventDetails ?: "", cfsqltype: "cf_sql_varchar" },
                addr: { value: data.address ?: "", cfsqltype: "cf_sql_varchar" },
                reminder: { value: data.reminderMinutes ?: "", cfsqltype: "cf_sql_integer", null: !len(data.reminderMinutes ?: "") },
                scope: { value: data.reminderScope ?: "me", cfsqltype: "cf_sql_varchar" },
                pv: { value: data.participantVisibility ?: "visible", cfsqltype: "cf_sql_varchar" }
            },
            { result: "qResult" }
        );
        return listFirst(qResult.generatedKey);
    }

    function addParticipant(required numeric eventId, required numeric userId, string attendanceType = "required", boolean isOneHop = false, numeric linkPersonUserId = 0) {
        queryExecute(
            "INSERT INTO polyculy.dbo.shared_event_participants (shared_event_id, user_id, attendance_type, is_one_hop, link_person_user_id)
             VALUES (:eid, :uid, :atype, :hop, :link)",
            {
                eid: { value: arguments.eventId, cfsqltype: "cf_sql_integer" },
                uid: { value: arguments.userId, cfsqltype: "cf_sql_integer" },
                atype: { value: arguments.attendanceType, cfsqltype: "cf_sql_varchar" },
                hop: { value: arguments.isOneHop, cfsqltype: "cf_sql_bit" },
                link: { value: arguments.linkPersonUserId, cfsqltype: "cf_sql_integer", null: arguments.linkPersonUserId == 0 }
            }
        );
    }

    function getById(required numeric eventId) {
        return queryExecute(
            "SELECT se.*, u.display_name AS organizer_name, u.email AS organizer_email
             FROM polyculy.dbo.shared_events se JOIN users u ON se.organizer_user_id = u.user_id
             WHERE se.shared_event_id = :eid",
            { eid: { value: arguments.eventId, cfsqltype: "cf_sql_integer" } }
        );
    }

    function getParticipants(required numeric eventId) {
        return queryExecute(
            "SELECT sep.*, u.display_name, u.email, u.avatar_url,
                    dp.calendar_color, dp.nickname
             FROM polyculy.dbo.shared_event_participants sep
             JOIN polyculy.dbo.users u ON sep.user_id = u.user_id
             LEFT JOIN polyculy.dbo.connection_display_prefs dp ON dp.target_user_id = sep.user_id
             WHERE sep.shared_event_id = :eid AND sep.is_removed = FALSE
             ORDER BY sep.attendance_type, u.display_name",
            { eid: { value: arguments.eventId, cfsqltype: "cf_sql_integer" } }
        );
    }

    function respondToInvitation(required numeric eventId, required numeric userId, required string response) {
        queryExecute(
            "UPDATE polyculy.dbo.shared_event_participants SET response_status = :resp, updated_at = CURRENT_TIMESTAMP
             WHERE shared_event_id = :eid AND user_id = :uid AND is_removed = FALSE",
            {
                eid: { value: arguments.eventId, cfsqltype: "cf_sql_integer" },
                uid: { value: arguments.userId, cfsqltype: "cf_sql_integer" },
                resp: { value: arguments.response, cfsqltype: "cf_sql_varchar" }
            }
        );
        // Recalculate global state
        recalculateState(arguments.eventId);
    }

    function recalculateState(required numeric eventId) {
        var event = getById(arguments.eventId);
        if (!event.recordCount || event.global_state == "cancelled") return;

        var q = queryExecute(
            "SELECT COUNT(*) AS cnt FROM polyculy.dbo.shared_event_participants
             WHERE shared_event_id = :eid AND user_id != :org AND response_status = 'accepted' AND is_removed = FALSE",
            {
                eid: { value: arguments.eventId, cfsqltype: "cf_sql_integer" },
                org: { value: event.organizer_user_id, cfsqltype: "cf_sql_integer" }
            }
        );
        var newState = (q.cnt > 0) ? "active" : "tentative";
        queryExecute(
            "UPDATE polyculy.dbo.shared_events SET global_state = :state, updated_at = CURRENT_TIMESTAMP WHERE shared_event_id = :eid",
            {
                eid: { value: arguments.eventId, cfsqltype: "cf_sql_integer" },
                state: { value: newState, cfsqltype: "cf_sql_varchar" }
            }
        );
    }

    function updateEvent(required numeric eventId, required struct data, required numeric organizerId) {
        // Determine if edit is material (time or location changed)
        var current = getById(arguments.eventId);
        if (!current.recordCount || current.organizer_user_id != arguments.organizerId) return { success: false, message: "Not authorized" };

        var isMaterialEdit = false;
        if (current.start_time != data.startTime || (current.end_time ?: "") != (data.endTime ?: "")) isMaterialEdit = true;
        if ((current.address ?: "") != (data.address ?: "")) isMaterialEdit = true;

        queryExecute(
            "UPDATE polyculy.dbo.shared_events SET title = :title, start_time = :startTime, end_time = :endTime,
             all_day = :allDay, event_details = :details, address = :addr,
             reminder_minutes = :reminder, reminder_scope = :scope,
             participant_visibility = :pv, updated_at = CURRENT_TIMESTAMP
             WHERE shared_event_id = :eid",
            {
                eid: { value: arguments.eventId, cfsqltype: "cf_sql_integer" },
                title: { value: data.title, cfsqltype: "cf_sql_varchar" },
                startTime: { value: data.startTime, cfsqltype: "cf_sql_timestamp" },
                endTime: { value: data.endTime, cfsqltype: "cf_sql_timestamp", null: !len(data.endTime ?: "") },
                allDay: { value: data.allDay ?: false, cfsqltype: "cf_sql_bit" },
                details: { value: data.eventDetails ?: "", cfsqltype: "cf_sql_varchar" },
                addr: { value: data.address ?: "", cfsqltype: "cf_sql_varchar" },
                reminder: { value: data.reminderMinutes ?: "", cfsqltype: "cf_sql_integer", null: !len(data.reminderMinutes ?: "") },
                scope: { value: data.reminderScope ?: "me", cfsqltype: "cf_sql_varchar" },
                pv: { value: data.participantVisibility ?: "visible", cfsqltype: "cf_sql_varchar" }
            }
        );

        if (isMaterialEdit) {
            // Reset all acceptances to pending
            queryExecute(
                "UPDATE polyculy.dbo.shared_event_participants SET response_status = 'pending', updated_at = CURRENT_TIMESTAMP
                 WHERE shared_event_id = :eid AND is_removed = FALSE",
                { eid: { value: arguments.eventId, cfsqltype: "cf_sql_integer" } }
            );
            recalculateState(arguments.eventId);
        }

        return { success: true, isMaterialEdit: isMaterialEdit };
    }

    function cancelEvent(required numeric eventId, required string reason) {
        queryExecute(
            "UPDATE polyculy.dbo.shared_events SET global_state = 'cancelled', cancellation_reason = :reason, updated_at = CURRENT_TIMESTAMP
             WHERE shared_event_id = :eid",
            {
                eid: { value: arguments.eventId, cfsqltype: "cf_sql_integer" },
                reason: { value: arguments.reason, cfsqltype: "cf_sql_varchar" }
            }
        );
    }

    function removeParticipant(required numeric eventId, required numeric userId) {
        queryExecute(
            "UPDATE polyculy.dbo.shared_event_participants SET is_removed = TRUE, updated_at = CURRENT_TIMESTAMP
             WHERE shared_event_id = :eid AND user_id = :uid",
            {
                eid: { value: arguments.eventId, cfsqltype: "cf_sql_integer" },
                uid: { value: arguments.userId, cfsqltype: "cf_sql_integer" }
            }
        );
        recalculateState(arguments.eventId);
    }

    function getEventsForUser(required numeric userId, string startDate = "", string endDate = "") {
        var sql = "SELECT se.*, u.display_name AS organizer_name,
                          sep.response_status, sep.attendance_type, sep.is_one_hop,
                          (SELECT COUNT(*) FROM polyculy.dbo.shared_event_participants sp2
                           WHERE sp2.shared_event_id = se.shared_event_id AND sp2.is_removed = FALSE) AS participant_count
                   FROM polyculy.dbo.shared_events se
                   JOIN polyculy.dbo.shared_event_participants sep ON se.shared_event_id = sep.shared_event_id
                   JOIN polyculy.dbo.users u ON se.organizer_user_id = u.user_id
                   WHERE sep.user_id = :uid AND sep.is_removed = FALSE AND se.global_state != 'cancelled'";
        var params = { uid: { value: arguments.userId, cfsqltype: "cf_sql_integer" } };

        if (len(arguments.startDate)) {
            sql &= " AND se.start_time >= :sd";
            params["sd"] = { value: arguments.startDate, cfsqltype: "cf_sql_timestamp" };
        }
        if (len(arguments.endDate)) {
            sql &= " AND se.start_time <= :ed";
            params["ed"] = { value: arguments.endDate, cfsqltype: "cf_sql_timestamp" };
        }

        // Also include events where user is organizer
        sql &= " UNION SELECT se2.*, u2.display_name AS organizer_name,
                 'organizer' AS response_status, 'required' AS attendance_type, FALSE AS is_one_hop,
                 (SELECT COUNT(*) FROM polyculy.dbo.shared_event_participants sp3
                  WHERE sp3.shared_event_id = se2.shared_event_id AND sp3.is_removed = FALSE) AS participant_count
                 FROM polyculy.dbo.shared_events se2 JOIN users u2 ON se2.organizer_user_id = u2.user_id
                 WHERE se2.organizer_user_id = :uid2 AND se2.global_state != 'cancelled'";
        params["uid2"] = { value: arguments.userId, cfsqltype: "cf_sql_integer" };

        if (len(arguments.startDate)) {
            sql &= " AND se2.start_time >= :sd2";
            params["sd2"] = { value: arguments.startDate, cfsqltype: "cf_sql_timestamp" };
        }
        if (len(arguments.endDate)) {
            sql &= " AND se2.start_time <= :ed2";
            params["ed2"] = { value: arguments.endDate, cfsqltype: "cf_sql_timestamp" };
        }

        sql &= " ORDER BY start_time";
        return queryExecute(sql, params);
    }

    function getConflicts(required numeric userId, required string startTime, required string endTime) {
        // Check personal events that block time
        var personalConflicts = queryExecute(
            "SELECT event_id, title, start_time, end_time, 'personal' AS event_type
             FROM polyculy.dbo.personal_events
             WHERE owner_user_id = :uid AND is_cancelled = FALSE
             AND start_time < :endTime AND end_time > :startTime",
            {
                uid: { value: arguments.userId, cfsqltype: "cf_sql_integer" },
                startTime: { value: arguments.startTime, cfsqltype: "cf_sql_timestamp" },
                endTime: { value: arguments.endTime, cfsqltype: "cf_sql_timestamp" }
            }
        );

        // Check shared events where user accepted
        var sharedConflicts = queryExecute(
            "SELECT se.shared_event_id AS event_id, se.title, se.start_time, se.end_time,
                    CASE WHEN se.global_state = 'active' THEN 'hard' ELSE 'soft' END AS conflict_type
             FROM polyculy.dbo.shared_events se
             JOIN polyculy.dbo.shared_event_participants sep ON se.shared_event_id = sep.shared_event_id
             WHERE sep.user_id = :uid AND sep.response_status = 'accepted' AND sep.is_removed = FALSE
             AND se.global_state != 'cancelled'
             AND se.start_time < :endTime AND se.end_time > :startTime",
            {
                uid: { value: arguments.userId, cfsqltype: "cf_sql_integer" },
                startTime: { value: arguments.startTime, cfsqltype: "cf_sql_timestamp" },
                endTime: { value: arguments.endTime, cfsqltype: "cf_sql_timestamp" }
            }
        );

        return { personal: personalConflicts, shared: sharedConflicts };
    }

    function transferOwnership(required numeric eventId, required numeric newOrganizerId) {
        queryExecute(
            "UPDATE polyculy.dbo.shared_events SET organizer_user_id = :newOrg, ownership_transfer_active = FALSE,
             ownership_transfer_deadline = NULL, updated_at = CURRENT_TIMESTAMP WHERE shared_event_id = :eid",
            {
                eid: { value: arguments.eventId, cfsqltype: "cf_sql_integer" },
                newOrg: { value: arguments.newOrganizerId, cfsqltype: "cf_sql_integer" }
            }
        );
        // If new organizer was a pending participant, set them to accepted
        queryExecute(
            "UPDATE polyculy.dbo.shared_event_participants SET response_status = 'accepted', updated_at = CURRENT_TIMESTAMP
             WHERE polyculy.dbo.shared_event_id = :eid AND user_id = :uid",
            {
                eid: { value: arguments.eventId, cfsqltype: "cf_sql_integer" },
                uid: { value: arguments.newOrganizerId, cfsqltype: "cf_sql_integer" }
            }
        );
    }

    function initiateOwnershipTransfer(required numeric eventId, required string deadline) {
        queryExecute(
            "UPDATE polyculy.dbo.shared_events SET ownership_transfer_active = TRUE, ownership_transfer_deadline = :dl, updated_at = CURRENT_TIMESTAMP
             WHERE shared_event_id = :eid",
            {
                eid: { value: arguments.eventId, cfsqltype: "cf_sql_integer" },
                dl: { value: arguments.deadline, cfsqltype: "cf_sql_timestamp" }
            }
        );
    }

}
