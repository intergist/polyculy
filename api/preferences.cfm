<cfscript>
    setting showDebugOutput=false;
    cfheader(name="Content-Type", value="application/json");

    userSvc = new model.UserService();
    connSvc = new model.ConnectionService();
    action = url.action ?: "get";
    response = { "success": true };

    try {
        switch (action) {
            case "get":
                user = userSvc.getById(session.userId);
                if (user.recordCount) {
                    response["data"] = {
                        "userId": user.user_id,
                        "email": user.email,
                        "displayName": user.display_name,
                        "timezoneId": user.timezone_id,
                        "calendarCreated": user.calendar_created
                    };
                }
                break;

            case "saveTimezone":
                if (!structKeyExists(form, "timezoneId")) {
                    response = { "success": false, "message": "Timezone required." }; break;
                }
                userSvc.updateTimezone(session.userId, form.timezoneId);
                session.timezoneId = form.timezoneId;
                response["message"] = "Timezone updated.";
                break;

            case "saveDisplayPrefs":
                if (structKeyExists(form, "targetUserId")) {
                    connSvc.updateDisplayPrefs(
                        session.userId, form.targetUserId,
                        form.nickname ?: "", form.avatarOverride ?: "", form.calendarColor ?: ""
                    );
                    response["message"] = "Display preferences saved.";
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
