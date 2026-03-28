<cfscript>
    setting showDebugOutput=false;
    cfheader(name="Content-Type", value="application/json");

    propSvc = new model.ProposalService();
    auditSvc = new model.AuditService();
    notifSvc = new model.NotificationService();
    sharedSvc = new model.SharedEventService();

    action = url.action ?: "list";
    response = { "success": true };

    try {
        switch (action) {
            case "listForEvent":
                q = propSvc.getAllByEvent(url.event_id);
                data = [];
                for (row in q) { arrayAppend(data, row); }
                response["data"] = data;
                break;

            case "activeForEvent":
                q = propSvc.getActiveByEvent(url.event_id);
                data = [];
                for (row in q) { arrayAppend(data, row); }
                response["data"] = data;
                break;

            case "create":
                propSvc.create(
                    form.event_id,
                    session.userId,
                    form.proposed_start,
                    form.proposed_end,
                    form.message ?: ""
                );

                // Notify organizer
                evt = sharedSvc.getById(form.event_id);
                if (evt.organizer_user_id != session.userId) {
                    notifSvc.create(evt.organizer_user_id, "proposal_received", "New Time Proposal", "#session.displayName# proposed a new time for ""#evt.title#"".", "shared_event", form.event_id);
                }

                auditSvc.log("proposal_create", "shared_event", form.event_id, "Proposed new time", session.userId);
                response["message"] = "Proposal submitted";
                break;

            case "accept":
                result = propSvc.acceptProposal(form.proposal_id);
                if (structKeyExists(result, "success") && !result.success) {
                    response = result;
                } else {
                    response["message"] = "Proposal accepted — event time updated, acceptances reset";
                }
                break;

            case "reject":
                propSvc.rejectProposal(form.proposal_id);
                response["message"] = "Proposal rejected";
                break;

            case "withdraw":
                propSvc.rejectProposal(form.proposal_id);
                response["message"] = "Proposal withdrawn";
                break;

            default:
                response = { "success": false, "message": "Unknown action" };
        }
    } catch (any e) {
        response = { "success": false, "message": e.message };
    }

    writeOutput(serializeJSON(response));
</cfscript>
