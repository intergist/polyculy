<cfscript>
    setting showDebugOutput=false;
    cfheader(name="Content-Type", value="application/json");

    eventSvc = new model.EventService();
    auditSvc = new model.AuditService();

    action = url.action ?: "list";
    response = { "success": true };

    try {
        switch (action) {
            case "list":
                q = eventSvc.getPersonalEventsForUser(session.userId, url.startDate ?: "", url.endDate ?: "");
                events = [];
                for (row in q) { arrayAppend(events, row); }
                response["data"] = events;
                break;

            case "get":
                if (!structKeyExists(url, "id")) {
                    response = { "success": false, "message": "Event ID required." };
                    break;
                }
                q = eventSvc.getPersonalEvent(url.id);
                if (q.recordCount) {
                    row = {};
                    for (col in listToArray(q.columnList)) { row[lCase(col)] = q[col][1]; }
                    // Get visibility records
                    vis = eventSvc.getVisibilityRecords(url.id);
                    visData = [];
                    for (v in vis) { arrayAppend(visData, v); }
                    row["visibility"] = visData;
                    response["data"] = row;
                } else {
                    response = { "success": false, "message": "Event not found." };
                }
                break;

            case "create":
                startTimeStr = form.startDate & " " & form.startHour & ":" & form.startMinute & " " & form.startAmPm;
                endTimeStr = form.endDate ?: form.startDate;
                endTimeStr = endTimeStr & " " & (form.endHour ?: form.startHour) & ":" & (form.endMinute ?: form.startMinute) & " " & (form.endAmPm ?: form.startAmPm);

                eventData = {
                    userId: session.userId,
                    title: form.title,
                    startTime: parseDateTime(startTimeStr),
                    endTime: parseDateTime(endTimeStr),
                    allDay: structKeyExists(form, "allDay"),
                    timezoneId: session.timezoneId ?: "America/New_York",
                    eventDetails: form.eventDetails ?: "",
                    address: form.address ?: "",
                    reminderMinutes: form.reminderMinutes ?: "",
                    visibilityTier: form.visibilityTier ?: "invisible"
                };

                newId = eventSvc.createPersonalEvent(eventData);

                // Handle visibility settings
                fullDetailUsers = [];
                busyBlockUsers = [];
                if (structKeyExists(form, "fullDetailUsers") && len(form.fullDetailUsers)) {
                    fullDetailUsers = listToArray(form.fullDetailUsers);
                }
                if (structKeyExists(form, "busyBlockUsers") && len(form.busyBlockUsers)) {
                    busyBlockUsers = listToArray(form.busyBlockUsers);
                }
                eventSvc.setVisibility(newId, eventData.visibilityTier, fullDetailUsers, busyBlockUsers);

                auditSvc.log("event_created", "personal_event", newId,
                    "Created personal event: #form.title#", session.userId);
                response["message"] = "Event created.";
                response["id"] = newId;
                break;

            case "update":
                if (!structKeyExists(form, "eventId")) {
                    response = { "success": false, "message": "Event ID required." };
                    break;
                }
                startTimeStr = form.startDate & " " & form.startHour & ":" & form.startMinute & " " & form.startAmPm;
                endTimeStr = (form.endDate ?: form.startDate) & " " & (form.endHour ?: form.startHour) & ":" & (form.endMinute ?: form.startMinute) & " " & (form.endAmPm ?: form.startAmPm);

                eventData = {
                    userId: session.userId,
                    title: form.title,
                    startTime: parseDateTime(startTimeStr),
                    endTime: parseDateTime(endTimeStr),
                    allDay: structKeyExists(form, "allDay"),
                    eventDetails: form.eventDetails ?: "",
                    address: form.address ?: "",
                    reminderMinutes: form.reminderMinutes ?: "",
                    visibilityTier: form.visibilityTier ?: "invisible"
                };
                eventSvc.updatePersonalEvent(form.eventId, eventData);

                // Update visibility
                fullDetailUsers = [];
                busyBlockUsers = [];
                if (structKeyExists(form, "fullDetailUsers") && len(form.fullDetailUsers)) {
                    fullDetailUsers = listToArray(form.fullDetailUsers);
                }
                if (structKeyExists(form, "busyBlockUsers") && len(form.busyBlockUsers)) {
                    busyBlockUsers = listToArray(form.busyBlockUsers);
                }
                eventSvc.setVisibility(form.eventId, eventData.visibilityTier, fullDetailUsers, busyBlockUsers);

                auditSvc.log("event_updated", "personal_event", form.eventId,
                    "Updated personal event: #form.title#", session.userId);
                response["message"] = "Event updated.";
                break;

            case "delete":
                if (!structKeyExists(form, "eventId")) {
                    response = { "success": false, "message": "Event ID required." };
                    break;
                }
                eventSvc.deletePersonalEvent(form.eventId, session.userId);
                auditSvc.log("event_deleted", "personal_event", form.eventId,
                    "Deleted personal event", session.userId);
                response["message"] = "Event deleted.";
                break;

            default:
                response = { "success": false, "message": "Unknown action: #action#" };
        }
    } catch (any e) {
        response = { "success": false, "message": e.message };
    }

    writeOutput(serializeJSON(response));
</cfscript>
