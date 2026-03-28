component {

    function getCalendarData(required numeric userId, required string viewType, required string startDate, required string endDate, string mode = "mine", string enabledUserIds = "") {
        var result = {
            personalEvents: [],
            sharedEvents: [],
            othersEvents: []
        };

        var eventSvc = new model.EventService();
        var sharedSvc = new model.SharedEventService();
        var connSvc = new model.ConnectionService();

        // My personal events
        var myEvents = eventSvc.getPersonalEventsForUser(arguments.userId, arguments.startDate, arguments.endDate);
        for (var row in myEvents) {
            arrayAppend(result.personalEvents, {
                event_id: row.event_id,
                title: row.title,
                start_time: row.start_time,
                end_time: row.end_time,
                all_day: row.all_day,
                type: "personal",
                owner: "me",
                owner_user_id: arguments.userId,
                visibility_tier: row.visibility_tier
            });
        }

        // My shared events
        var myShared = sharedSvc.getForUser(arguments.userId, arguments.startDate, arguments.endDate);
        for (var row in myShared) {
            arrayAppend(result.sharedEvents, {
                event_id: row.shared_event_id,
                title: row.title,
                start_time: row.start_time,
                end_time: row.end_time,
                all_day: row.all_day,
                type: "shared",
                global_state: row.global_state,
                response_status: row.response_status,
                organizer_name: row.organizer_name,
                organizer_user_id: row.organizer_user_id
            });
        }

        // "Our" mode: include connected users' visible events
        if (arguments.mode == "our") {
            var connectedUsers = connSvc.getConnectedUsers(arguments.userId);
            for (var cu in connectedUsers) {
                // Skip if not in enabled list (when filter is applied)
                if (len(arguments.enabledUserIds) && !listFind(arguments.enabledUserIds, cu.user_id)) {
                    continue;
                }

                var visibleEvents = eventSvc.getVisibleEventsForViewer(cu.user_id, arguments.userId, arguments.startDate, arguments.endDate);
                for (var ev in visibleEvents) {
                    arrayAppend(result.othersEvents, {
                        event_id: ev.event_id,
                        title: (ev.visibility_type == "busy_block") ? "Busy" : ev.title,
                        start_time: ev.start_time,
                        end_time: ev.end_time,
                        all_day: ev.all_day,
                        type: "personal",
                        owner: cu.nickname ?: cu.display_name,
                        owner_user_id: cu.user_id,
                        visibility_type: ev.visibility_type,
                        calendar_color: cu.calendar_color ?: "##7C3AED"
                    });
                }
            }
        }

        return result;
    }

    function getPolyculeMembers(required numeric userId) {
        var connSvc = new model.ConnectionService();
        var members = [];
        var connected = connSvc.getConnectedUsers(arguments.userId);
        for (var cu in connected) {
            arrayAppend(members, {
                user_id: cu.user_id,
                display_name: cu.nickname ?: cu.display_name,
                calendar_color: cu.calendar_color ?: "##7C3AED",
                avatar_url: cu.avatar_url ?: ""
            });
        }
        return members;
    }

}
