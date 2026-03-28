<cfscript>
    setting showDebugOutput=false;
    cfheader(name="Content-Type", value="application/json");

    eventSvc = new model.EventService();
    seSvc = new model.SharedEventService();
    connSvc = new model.ConnectionService();
    userSvc = new model.UserService();

    action = url.action ?: "events";
    response = { "success": true };

    try {
        switch (action) {
            case "events":
                // Get all events for the calendar view (personal + shared)
                startDate = url.startDate ?: "";
                endDate = url.endDate ?: "";

                personalEvents = eventSvc.getPersonalEventsForUser(session.userId, startDate, endDate);
                sharedEvents = seSvc.getEventsForUser(session.userId, startDate, endDate);

                allEvents = [];
                // Personal events
                for (row in personalEvents) {
                    arrayAppend(allEvents, {
                        "id": row.event_id,
                        "type": "personal",
                        "title": row.title,
                        "start": dateTimeFormat(row.start_time, "yyyy-MM-dd'T'HH:nn:ss"),
                        "end": isNull(row.end_time) ? "" : dateTimeFormat(row.end_time, "yyyy-MM-dd'T'HH:nn:ss"),
                        "allDay": row.all_day,
                        "details": row.event_details ?: "",
                        "address": row.address ?: "",
                        "visibilityTier": row.visibility_tier,
                        "isBlocking": true,
                        "ownerUserId": row.owner_user_id,
                        "state": "active"
                    });
                }

                // Shared events
                for (row in sharedEvents) {
                    isOrganizer = (row.response_status == "organizer" || row.organizer_user_id == session.userId);
                    isAccepted = (row.response_status == "accepted" || isOrganizer);
                    arrayAppend(allEvents, {
                        "id": row.shared_event_id,
                        "type": "shared",
                        "title": row.title,
                        "start": dateTimeFormat(row.start_time, "yyyy-MM-dd'T'HH:nn:ss"),
                        "end": isNull(row.end_time) ? "" : dateTimeFormat(row.end_time, "yyyy-MM-dd'T'HH:nn:ss"),
                        "allDay": row.all_day,
                        "details": row.event_details ?: "",
                        "address": row.address ?: "",
                        "organizer": row.organizer_name,
                        "organizerId": row.organizer_user_id,
                        "responseStatus": row.response_status,
                        "isBlocking": isAccepted,
                        "state": row.global_state,
                        "participantCount": row.participant_count ?: 0,
                        "isOrganizer": isOrganizer
                    });
                }

                response["data"] = allEvents;
                break;

            case "overlay":
                // Get events visible to current user from other polycule members
                startDate = url.startDate ?: "";
                endDate = url.endDate ?: "";
                connected = connSvc.getConnectedUsers(session.userId);

                overlayEvents = [];
                for (member in connected) {
                    visibleEvents = eventSvc.getVisibleEventsForViewer(session.userId, member.other_user_id, startDate, endDate);
                    for (ev in visibleEvents) {
                        arrayAppend(overlayEvents, {
                            "id": ev.event_id,
                            "type": "personal_overlay",
                            "title": (ev.visibility_type == "full_details") ? ev.title : "Busy",
                            "start": dateTimeFormat(ev.start_time, "yyyy-MM-dd'T'HH:nn:ss"),
                            "end": isNull(ev.end_time) ? "" : dateTimeFormat(ev.end_time, "yyyy-MM-dd'T'HH:nn:ss"),
                            "allDay": ev.all_day,
                            "details": (ev.visibility_type == "full_details") ? (ev.event_details ?: "") : "",
                            "visibilityType": ev.visibility_type,
                            "ownerUserId": ev.owner_user_id,
                            "ownerName": ev.owner_name,
                            "calendarColor": member.calendar_color ?: "##7C3AED"
                        });
                    }
                }

                response["data"] = overlayEvents;
                break;

            case "setup":
                if (!structKeyExists(form, "method")) {
                    response = { "success": false, "message": "Setup method required." }; break;
                }
                userSvc.setCalendarCreated(session.userId);
                session.calendarCreated = true;
                response["message"] = "Calendar created.";
                break;

            case "toggleState":
                // Save or get toggle state for Our mode
                if (structKeyExists(form, "targetUserId") && structKeyExists(form, "isVisible")) {
                    existing = queryExecute(
                        "SELECT toggle_id FROM polyculy.dbo.calendar_toggle_state WHERE user_id = :uid AND target_user_id = :tid",
                        {
                            uid: { value: session.userId, cfsqltype: "cf_sql_integer" },
                            tid: { value: form.targetUserId, cfsqltype: "cf_sql_integer" }
                        }
                    );
                    if (existing.recordCount > 0) {
                        queryExecute(
                            "UPDATE polyculy.dbo.calendar_toggle_state SET is_visible = :vis WHERE toggle_id = :tid",
                            {
                                tid: { value: existing.toggle_id, cfsqltype: "cf_sql_integer" },
                                vis: { value: form.isVisible, cfsqltype: "cf_sql_bit" }
                            }
                        );
                    } else {
                        queryExecute(
                            "INSERT INTO polyculy.dbo.calendar_toggle_state (user_id, target_user_id, is_visible) VALUES (:uid, :tid, :vis)",
                            {
                                uid: { value: session.userId, cfsqltype: "cf_sql_integer" },
                                tid: { value: form.targetUserId, cfsqltype: "cf_sql_integer" },
                                vis: { value: form.isVisible, cfsqltype: "cf_sql_bit" }
                            }
                        );
                    }
                    response["message"] = "Toggle state saved.";
                } else {
                    // Get toggle states
                    q = queryExecute(
                        "SELECT target_user_id, is_visible FROM polyculy.dbo.calendar_toggle_state WHERE user_id = :uid",
                        { uid: { value: session.userId, cfsqltype: "cf_sql_integer" } }
                    );
                    states = {};
                    for (row in q) {
                        states[row.target_user_id] = row.is_visible;
                    }
                    response["data"] = states;
                }
                break;

            default:
                response = { "success": false, "message": "Unknown action: #action#" };
        }
    } catch (any e) {
        response = { "success": false, "message": e.message };
    }

    writeOutput(serializeJSON(response));
</cfscript>
