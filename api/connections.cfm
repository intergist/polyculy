<cfscript>
    setting showDebugOutput=false;
    cfheader(name="Content-Type", value="application/json");

    connSvc = new model.ConnectionService();
    licSvc = new model.LicenceService();
    auditSvc = new model.AuditService();
    notifSvc = new model.NotificationService();

    action = url.action ?: "list";
    response = { "success": true };

    try {
        switch (action) {
            case "list":
                q = connSvc.getPolyculeMembers(session.userId);
                members = [];
                for (row in q) {
                    displayName = "";
                    if (len(trim(row.nickname ?: ""))) displayName = row.nickname;
                    else if (len(trim(row.display_name ?: ""))) displayName = row.display_name;
                    else if (len(trim(row.invited_display_name ?: ""))) displayName = row.invited_display_name;
                    else displayName = "Unknown";
                    arrayAppend(members, {
                        "connectionId": row.connection_id ?: 0,
                        "otherUserId": row.other_user_id ?: 0,
                        "displayName": displayName,
                        "email": len(trim(row.email ?: "")) ? row.email : (row.invited_email ?: ""),
                        "status": row.status,
                        "calendarColor": len(trim(row.calendar_color ?: "")) ? row.calendar_color : "##7C3AED",
                        "avatarOverride": row.avatar_override ?: "",
                        "isHidden": row.is_hidden ?: false
                    });
                }
                response["data"] = members;
                break;

            case "connected":
                q = connSvc.getConnectedUsers(session.userId);
                members = [];
                for (row in q) {
                    connDisplayName = "";
                    if (len(trim(row.nickname ?: ""))) connDisplayName = row.nickname;
                    else if (len(trim(row.display_name ?: ""))) connDisplayName = row.display_name;
                    else connDisplayName = "Unknown";
                    arrayAppend(members, {
                        "userId": row.other_user_id,
                        "displayName": connDisplayName,
                        "email": row.email,
                        "calendarColor": len(trim(row.calendar_color ?: "")) ? row.calendar_color : "##7C3AED"
                    });
                }
                response["data"] = members;
                break;

            case "send":
                if (!structKeyExists(form, "email") || !structKeyExists(form, "displayName")) {
                    response = { "success": false, "message": "Email and display name are required." };
                    break;
                }
                result = connSvc.sendRequest(session.userId, trim(form.email), trim(form.displayName));
                response = result;
                if (result.success) {
                    auditSvc.log("connection_request", "connection", 0,
                        "Connection request sent to #trim(form.email)#", session.userId);
                }
                break;

            case "confirm":
                if (!structKeyExists(form, "connectionId")) {
                    response = { "success": false, "message": "Connection ID required." };
                    break;
                }
                connSvc.confirmConnection(form.connectionId, session.userId);
                auditSvc.log("connection_confirmed", "connection", form.connectionId,
                    "Connection confirmed", session.userId);

                // Notify the other user
                conn = queryExecute(
                    "SELECT user_id_1, user_id_2 FROM polyculy.dbo.connections WHERE connection_id = :cid",
                    { cid: { value: form.connectionId, cfsqltype: "cf_sql_integer" } }
                );
                if (conn.recordCount) {
                    otherUserId = (conn.user_id_1 == session.userId) ? conn.user_id_2 : conn.user_id_1;
                    notifSvc.create(otherUserId, "connection_confirmed", "Connection Confirmed",
                        session.displayName & " confirmed your connection.", "connection", form.connectionId);
                }
                response["message"] = "Connection confirmed.";
                break;

            case "revoke":
                if (!structKeyExists(form, "connectionId")) {
                    response = { "success": false, "message": "Connection ID required." };
                    break;
                }
                connSvc.revokeConnection(form.connectionId, session.userId);
                auditSvc.log("connection_revoked", "connection", form.connectionId,
                    "Connection revoked", session.userId);
                response["message"] = "Connection revoked.";
                break;

            case "hide":
                if (!structKeyExists(form, "connectionId")) {
                    response = { "success": false, "message": "Connection ID required." };
                    break;
                }
                connSvc.hideConnection(form.connectionId);
                response["message"] = "Connection hidden.";
                break;

            case "giftLicence":
                if (!structKeyExists(form, "email")) {
                    response = { "success": false, "message": "Email required." };
                    break;
                }
                giftCode = "GIFT-" & uCase(left(hash(createUUID()), 8));
                result = licSvc.giftLicence(session.userId, trim(form.email), giftCode);
                if (result.success) {
                    // Update connection status to licence_gifted_awaiting_signup
                    queryExecute(
                        "UPDATE polyculy.dbo.connections SET status = 'licence_gifted_awaiting_signup', updated_at = CURRENT_TIMESTAMP
                         WHERE (invited_email = :email OR user_id_2 IN (SELECT user_id FROM users WHERE email = :email))
                         AND (user_id_1 = :uid OR initiated_by = :uid)
                         AND status = 'awaiting_signup'",
                        {
                            email: { value: trim(form.email), cfsqltype: "cf_sql_varchar" },
                            uid: { value: session.userId, cfsqltype: "cf_sql_integer" }
                        }
                    );
                    auditSvc.log("licence_gifted", "licence", 0,
                        "License gifted to #trim(form.email)#", session.userId);
                }
                response = result;
                break;

            case "updatePrefs":
                if (!structKeyExists(form, "targetUserId")) {
                    response = { "success": false, "message": "Target user ID required." };
                    break;
                }
                connSvc.updateDisplayPrefs(
                    session.userId,
                    form.targetUserId,
                    form.nickname ?: "",
                    form.avatarOverride ?: "",
                    form.calendarColor ?: ""
                );
                response["message"] = "Preferences updated.";
                break;

            default:
                response = { "success": false, "message": "Unknown action: #action#" };
        }
    } catch (any e) {
        response = { "success": false, "message": e.message };
    }

    writeOutput(serializeJSON(response));
</cfscript>
