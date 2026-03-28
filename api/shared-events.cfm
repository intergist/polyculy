<cfscript>
    setting showDebugOutput=false;
    cfheader(name="Content-Type", value="application/json");

    seSvc = new model.SharedEventService();
    proposalSvc = new model.ProposalService();
    auditSvc = new model.AuditService();
    notifSvc = new model.NotificationService();

    action = url.action ?: "list";
    response = { "success": true };

    try {
        switch (action) {
            case "list":
                q = seSvc.getEventsForUser(session.userId, url.startDate ?: "", url.endDate ?: "");
                events = [];
                for (row in q) { arrayAppend(events, row); }
                response["data"] = events;
                break;

            case "get":
                if (!structKeyExists(url, "id")) {
                    response = { "success": false, "message": "Event ID required." }; break;
                }
                q = seSvc.getById(url.id);
                if (q.recordCount) {
                    row = {};
                    for (col in listToArray(q.columnList)) { row[lCase(col)] = q[col][1]; }
                    participants = seSvc.getParticipants(url.id);
                    pList = [];
                    for (p in participants) { arrayAppend(pList, p); }
                    row["participants"] = pList;
                    proposals = proposalSvc.getAllByEvent(url.id);
                    propList = [];
                    for (pr in proposals) { arrayAppend(propList, pr); }
                    row["proposals"] = propList;
                    response["data"] = row;
                } else {
                    response = { "success": false, "message": "Event not found." };
                }
                break;

            case "create":
                startTimeStr = form.startDate & " " & form.startHour & ":" & form.startMinute & " " & form.startAmPm;
                endTimeStr = (form.endDate ?: form.startDate) & " " & (form.endHour ?: form.startHour) & ":" & (form.endMinute ?: form.startMinute) & " " & (form.endAmPm ?: form.startAmPm);

                eventData = {
                    organizerId: session.userId,
                    title: form.title,
                    startTime: parseDateTime(startTimeStr),
                    endTime: parseDateTime(endTimeStr),
                    allDay: structKeyExists(form, "allDay"),
                    timezoneId: session.timezoneId ?: "America/New_York",
                    eventDetails: form.eventDetails ?: "",
                    address: form.address ?: "",
                    reminderMinutes: form.reminderMinutes ?: "",
                    reminderScope: form.reminderScope ?: "me",
                    participantVisibility: form.participantVisibility ?: "visible"
                };

                newId = seSvc.create(eventData);

                // Add participants
                if (structKeyExists(form, "participants") && len(form.participants)) {
                    participantList = listToArray(form.participants);
                    for (pid in participantList) {
                        aType = form["attendance_#pid#"] ?: "required";
                        seSvc.addParticipant(newId, pid, aType);

                        // Notify participant
                        notifSvc.create(pid, "shared_event_invitation", "Event Invitation",
                            session.displayName & " invited you to " & form.title, "shared_event", newId);
                    }
                }

                auditSvc.log("event_created", "shared_event", newId,
                    "Created shared event: #form.title#", session.userId);
                response["message"] = "Shared event created and invitations sent.";
                response["id"] = newId;
                break;

            case "respond":
                if (!structKeyExists(form, "eventId") || !structKeyExists(form, "response")) {
                    response = { "success": false, "message": "Event ID and response required." }; break;
                }
                seSvc.respondToInvitation(form.eventId, session.userId, form.response);

                // Notify organizer (except for Maybe)
                event = seSvc.getById(form.eventId);
                if (event.recordCount && form.response != "maybe") {
                    notifSvc.create(event.organizer_user_id, "shared_event_#form.response#",
                        "Event #form.response#",
                        session.displayName & " " & form.response & " your invitation to " & event.title,
                        "shared_event", form.eventId);
                }

                auditSvc.log("event_#form.response#", "shared_event", form.eventId,
                    "#session.displayName# #form.response# the invitation", session.userId);
                response["message"] = "Response recorded.";
                break;

            case "update":
                if (!structKeyExists(form, "eventId")) {
                    response = { "success": false, "message": "Event ID required." }; break;
                }
                startTimeStr = form.startDate & " " & form.startHour & ":" & form.startMinute & " " & form.startAmPm;
                endTimeStr = (form.endDate ?: form.startDate) & " " & (form.endHour ?: form.startHour) & ":" & (form.endMinute ?: form.startMinute) & " " & (form.endAmPm ?: form.startAmPm);

                eventData = {
                    title: form.title,
                    startTime: parseDateTime(startTimeStr),
                    endTime: parseDateTime(endTimeStr),
                    allDay: structKeyExists(form, "allDay"),
                    eventDetails: form.eventDetails ?: "",
                    address: form.address ?: "",
                    reminderMinutes: form.reminderMinutes ?: "",
                    reminderScope: form.reminderScope ?: "me",
                    participantVisibility: form.participantVisibility ?: "visible"
                };
                result = seSvc.updateEvent(form.eventId, eventData, session.userId);
                if (!result.success) {
                    response = result; break;
                }
                if (result.isMaterialEdit) {
                    // Notify all participants of material edit
                    participants = seSvc.getParticipants(form.eventId);
                    for (p in participants) {
                        if (p.user_id != session.userId) {
                            notifSvc.create(p.user_id, "material_edit", "Event Updated",
                                "The event '" & form.title & "' has been updated. Please re-confirm your attendance.",
                                "shared_event", form.eventId);
                        }
                    }
                }
                auditSvc.log("event_updated", "shared_event", form.eventId,
                    "Updated shared event: #form.title# (material=#result.isMaterialEdit#)", session.userId);
                response["message"] = result.isMaterialEdit ? "Event updated. All acceptances have been reset." : "Event updated.";
                break;

            case "cancel":
                if (!structKeyExists(form, "eventId")) {
                    response = { "success": false, "message": "Event ID required." }; break;
                }
                seSvc.cancelEvent(form.eventId, "organizer_cancelled");
                participants = seSvc.getParticipants(form.eventId);
                for (p in participants) {
                    notifSvc.create(p.user_id, "event_cancelled", "Event Cancelled",
                        "An event has been cancelled.", "shared_event", form.eventId);
                }
                auditSvc.log("event_cancelled", "shared_event", form.eventId,
                    "Shared event cancelled by organizer", session.userId);
                response["message"] = "Event cancelled.";
                break;

            case "removeParticipant":
                if (!structKeyExists(form, "eventId") || !structKeyExists(form, "participantUserId")) {
                    response = { "success": false, "message": "Event and participant IDs required." }; break;
                }
                seSvc.removeParticipant(form.eventId, form.participantUserId);
                notifSvc.create(form.participantUserId, "participant_removed", "Removed from Event",
                    "You have been removed from a shared event.", "shared_event", form.eventId);
                auditSvc.log("participant_removed", "shared_event", form.eventId,
                    "Participant removed from event", session.userId);
                response["message"] = "Participant removed.";
                break;

            case "propose":
                if (!structKeyExists(form, "eventId") || !structKeyExists(form, "proposedStartDate")) {
                    response = { "success": false, "message": "Event ID and proposed time required." }; break;
                }
                pStartStr = form.proposedStartDate & " " & form.proposedStartHour & ":" & form.proposedStartMinute & " " & form.proposedStartAmPm;
                pEndStr = (form.proposedEndDate ?: form.proposedStartDate) & " " & form.proposedEndHour & ":" & form.proposedEndMinute & " " & form.proposedEndAmPm;

                proposalSvc.create(form.eventId, session.userId, parseDateTime(pStartStr), parseDateTime(pEndStr), form.proposalMessage ?: "");

                event = seSvc.getById(form.eventId);
                if (event.recordCount) {
                    notifSvc.create(event.organizer_user_id, "new_time_proposed", "New Time Proposed",
                        session.displayName & " proposed a new time for " & event.title, "shared_event", form.eventId);
                }
                auditSvc.log("time_proposed", "shared_event", form.eventId,
                    "New time proposed by " & session.displayName, session.userId);
                response["message"] = "Proposal submitted.";
                break;

            case "acceptProposal":
                if (!structKeyExists(form, "proposalId")) {
                    response = { "success": false, "message": "Proposal ID required." }; break;
                }
                result = proposalSvc.acceptProposal(form.proposalId);
                if (result.success) {
                    // Notify all participants
                    participants = seSvc.getParticipants(result.eventId);
                    for (p in participants) {
                        notifSvc.create(p.user_id, "proposal_accepted", "Time Changed",
                            "The event time has been updated based on a proposal. Please re-confirm.",
                            "shared_event", result.eventId);
                    }
                    auditSvc.log("proposal_accepted", "shared_event", result.eventId,
                        "Proposal accepted, event time updated", session.userId);
                }
                response = result;
                break;

            case "rejectProposal":
                if (!structKeyExists(form, "proposalId")) {
                    response = { "success": false, "message": "Proposal ID required." }; break;
                }
                proposalSvc.rejectProposal(form.proposalId);
                auditSvc.log("proposal_rejected", "proposal", form.proposalId,
                    "Proposal rejected", session.userId);
                response["message"] = "Proposal rejected.";
                break;

            case "conflicts":
                if (!structKeyExists(url, "userId") || !structKeyExists(url, "startTime") || !structKeyExists(url, "endTime")) {
                    response = { "success": false, "message": "User ID and time range required." }; break;
                }
                conflicts = seSvc.getConflicts(url.userId, url.startTime, url.endTime);
                response["data"] = conflicts;
                break;

            case "claimOwnership":
                if (!structKeyExists(form, "eventId")) {
                    response = { "success": false, "message": "Event ID required." }; break;
                }
                seSvc.transferOwnership(form.eventId, session.userId);
                participants = seSvc.getParticipants(form.eventId);
                for (p in participants) {
                    notifSvc.create(p.user_id, "ownership_claimed", "New Organizer",
                        session.displayName & " has claimed ownership of the event.", "shared_event", form.eventId);
                }
                auditSvc.log("ownership_claimed", "shared_event", form.eventId,
                    "Ownership claimed by " & session.displayName, session.userId);
                response["message"] = "You are now the organizer.";
                break;

            default:
                response = { "success": false, "message": "Unknown action: #action#" };
        }
    } catch (any e) {
        response = { "success": false, "message": e.message };
    }

    writeOutput(serializeJSON(response));
</cfscript>
