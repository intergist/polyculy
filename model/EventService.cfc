component {

    function createPersonalEvent(required struct data) {
        queryExecute(
            "INSERT INTO polyculy.dbo.personal_events (owner_user_id, title, start_time, end_time, all_day, timezone_id, event_details, address, reminder_minutes, visibility_tier)
             VALUES (:owner, :title, :startTime, :endTime, :allDay, :tz, :details, :addr, :reminder, :visibility)",
            {
                owner: { value: data.userId, cfsqltype: "cf_sql_integer" },
                title: { value: data.title, cfsqltype: "cf_sql_varchar" },
                startTime: { value: data.startTime, cfsqltype: "cf_sql_timestamp" },
                endTime: { value: data.endTime, cfsqltype: "cf_sql_timestamp", null: !len(data.endTime ?: "") },
                allDay: { value: data.allDay ?: false, cfsqltype: "cf_sql_bit" },
                tz: { value: data.timezoneId ?: "America/New_York", cfsqltype: "cf_sql_varchar" },
                details: { value: data.eventDetails ?: "", cfsqltype: "cf_sql_varchar" },
                addr: { value: data.address ?: "", cfsqltype: "cf_sql_varchar" },
                reminder: { value: data.reminderMinutes ?: "", cfsqltype: "cf_sql_integer", null: !len(data.reminderMinutes ?: "") },
                visibility: { value: data.visibilityTier ?: "invisible", cfsqltype: "cf_sql_varchar" }
            },
            { result: "qResult" }
        );
        return listFirst(qResult.generatedKey);
    }

    function updatePersonalEvent(required numeric eventId, required struct data) {
        queryExecute(
            "UPDATE polyculy.dbo.personal_events SET title = :title, start_time = :startTime, end_time = :endTime,
             all_day = :allDay, event_details = :details, address = :addr,
             reminder_minutes = :reminder, visibility_tier = :visibility, updated_at = CURRENT_TIMESTAMP
             WHERE event_id = :eid AND owner_user_id = :owner",
            {
                eid: { value: arguments.eventId, cfsqltype: "cf_sql_integer" },
                owner: { value: data.userId, cfsqltype: "cf_sql_integer" },
                title: { value: data.title, cfsqltype: "cf_sql_varchar" },
                startTime: { value: data.startTime, cfsqltype: "cf_sql_timestamp" },
                endTime: { value: data.endTime, cfsqltype: "cf_sql_timestamp", null: !len(data.endTime ?: "") },
                allDay: { value: data.allDay ?: false, cfsqltype: "cf_sql_bit" },
                details: { value: data.eventDetails ?: "", cfsqltype: "cf_sql_varchar" },
                addr: { value: data.address ?: "", cfsqltype: "cf_sql_varchar" },
                reminder: { value: data.reminderMinutes ?: "", cfsqltype: "cf_sql_integer", null: !len(data.reminderMinutes ?: "") },
                visibility: { value: data.visibilityTier ?: "invisible", cfsqltype: "cf_sql_varchar" }
            }
        );
    }

    function deletePersonalEvent(required numeric eventId, required numeric userId) {
        // Clear visibility records
        queryExecute("DELETE FROM polyculy.dbo.personal_event_visibility WHERE event_id = :eid",
            { eid: { value: arguments.eventId, cfsqltype: "cf_sql_integer" } });
        // Cancel event
        queryExecute(
            "UPDATE polyculy.dbo.personal_events SET is_cancelled = TRUE, updated_at = CURRENT_TIMESTAMP
             WHERE event_id = :eid AND owner_user_id = :uid",
            {
                eid: { value: arguments.eventId, cfsqltype: "cf_sql_integer" },
                uid: { value: arguments.userId, cfsqltype: "cf_sql_integer" }
            }
        );
    }

    function getPersonalEvent(required numeric eventId) {
        return queryExecute(
            "SELECT e.*, u.display_name AS owner_name
             FROM polyculy.dbo.personal_events e 
						 			JOIN polyculy.dbo.users u ON e.owner_user_id = u.user_id
             WHERE e.event_id = :eid AND e.is_cancelled = FALSE",
            { eid: { value: arguments.eventId, cfsqltype: "cf_sql_integer" } }
        );
    }

    function getPersonalEventsForUser(required numeric userId, string startDate = "", string endDate = "") {
        var sql = "SELECT e.*, u.display_name AS owner_name
                   FROM polyculy.dbo.personal_events e 
									 			JOIN polyculy.dbo.users u ON e.owner_user_id = u.user_id
                   WHERE e.owner_user_id = :uid AND e.is_cancelled = FALSE";
        var params = { uid: { value: arguments.userId, cfsqltype: "cf_sql_integer" } };

        if (len(arguments.startDate)) {
            sql &= " AND e.start_time >= :sd";
            params["sd"] = { value: arguments.startDate, cfsqltype: "cf_sql_timestamp" };
        }
        if (len(arguments.endDate)) {
            sql &= " AND e.start_time <= :ed";
            params["ed"] = { value: arguments.endDate, cfsqltype: "cf_sql_timestamp" };
        }
        sql &= " ORDER BY e.start_time";
        return queryExecute(sql, params);
    }

    function getVisibleEventsForViewer(required numeric viewerUserId, required numeric ownerUserId, string startDate = "", string endDate = "") {
        var sql = "SELECT e.event_id, e.title, e.start_time, e.end_time, e.all_day, e.timezone_id,
                          e.event_details, e.address, e.owner_user_id, v.visibility_type,
                          u.display_name AS owner_name
                   FROM polyculy.dbo.personal_events e
                   			JOIN polyculy.dbo.personal_event_visibility v ON e.event_id = v.event_id
                   			JOIN polyculy.dbo.users u ON e.owner_user_id = u.user_id
                   WHERE v.target_user_id = :viewer AND e.owner_user_id = :owner AND e.is_cancelled = FALSE";
        var params = {
            viewer: { value: arguments.viewerUserId, cfsqltype: "cf_sql_integer" },
            owner: { value: arguments.ownerUserId, cfsqltype: "cf_sql_integer" }
        };
        if (len(arguments.startDate)) {
            sql &= " AND e.start_time >= :sd";
            params["sd"] = { value: arguments.startDate, cfsqltype: "cf_sql_timestamp" };
        }
        if (len(arguments.endDate)) {
            sql &= " AND e.start_time <= :ed";
            params["ed"] = { value: arguments.endDate, cfsqltype: "cf_sql_timestamp" };
        }
        sql &= " ORDER BY e.start_time";
        return queryExecute(sql, params);
    }

    function setVisibility(required numeric eventId, required string tier, array fullDetailUsers = [], array busyBlockUsers = []) {
        // Clear existing visibility records
        queryExecute("DELETE FROM polyculy.dbo.personal_event_visibility WHERE event_id = :eid",
            { eid: { value: arguments.eventId, cfsqltype: "cf_sql_integer" } });

        // Update the tier on the event itself
        queryExecute(
            "	UPDATE polyculy.dbo.personal_events 
							SET visibility_tier = :tier, updated_at = CURRENT_TIMESTAMP 
							WHERE event_id = :eid",
            {
                eid: { value: arguments.eventId, cfsqltype: "cf_sql_integer" },
                tier: { value: arguments.tier, cfsqltype: "cf_sql_varchar" }
            }
        );

        if (arguments.tier == "invisible") return;

        // Insert full-details visibility records
        for (var uid in arguments.fullDetailUsers) {
            queryExecute(
                "INSERT INTO polyculy.dbo.personal_event_visibility (event_id, target_user_id, visibility_type) VALUES (:eid, :uid, 'full_details')",
                {
                    eid: { value: arguments.eventId, cfsqltype: "cf_sql_integer" },
                    uid: { value: uid, cfsqltype: "cf_sql_integer" }
                }
            );
        }

        // Insert busy-block visibility records
        for (var uid in arguments.busyBlockUsers) {
            queryExecute(
                "INSERT INTO polyculy.dbo.personal_event_visibility (event_id, target_user_id, visibility_type) VALUES (:eid, :uid, 'busy_block')",
                {
                    eid: { value: arguments.eventId, cfsqltype: "cf_sql_integer" },
                    uid: { value: uid, cfsqltype: "cf_sql_integer" }
                }
            );
        }
    }

    function getVisibilityRecords(required numeric eventId) {
        return queryExecute(
            "	SELECT v.*, u.display_name 
							FROM  polyculy.dbo.personal_event_visibility v
             				JOIN polyculy.dbo.users u ON v.target_user_id = u.user_id WHERE v.event_id = :eid",
            { eid: { value: arguments.eventId, cfsqltype: "cf_sql_integer" } }
        );
    }

}
