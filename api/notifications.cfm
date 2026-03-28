<cfscript>
    setting showDebugOutput=false;
    cfheader(name="Content-Type", value="application/json");

    notifSvc = new model.NotificationService();
    action = url.action ?: "list";
    response = { "success": true };

    try {
        switch (action) {
            case "list":
                q = notifSvc.getRecent(session.userId, url.limit ?: 20);
                notifications = [];
                for (row in q) {
                    arrayAppend(notifications, {
                        "notification_id": row.notification_id,
                        "notification_type": row.notification_type,
                        "title": row.title,
                        "message": row.message,
                        "is_read": row.is_read,
                        "related_entity_type": row.related_entity_type ?: "",
                        "related_entity_id": row.related_entity_id ?: 0,
                        "created_at": dateTimeFormat(row.created_at, "yyyy-MM-dd'T'HH:nn:ss")
                    });
                }
                response["data"] = notifications;
                response["unreadCount"] = notifSvc.getUnreadCount(session.userId);
                break;

            case "unreadCount":
                response["count"] = notifSvc.getUnreadCount(session.userId);
                break;

            case "markRead":
                if (structKeyExists(form, "notificationId")) {
                    notifSvc.markAsRead(form.notificationId, session.userId);
                }
                response["message"] = "Marked as read.";
                break;

            case "markAllRead":
                notifSvc.markAllAsRead(session.userId);
                response["message"] = "All marked as read.";
                break;

            case "preferences":
                q = notifSvc.getPreferences(session.userId);
                prefs = [];
                for (row in q) { arrayAppend(prefs, row); }
                response["data"] = prefs;
                break;

            case "savePreference":
                if (!structKeyExists(form, "notificationType")) {
                    response = { "success": false, "message": "Notification type required." }; break;
                }
                notifSvc.savePreference(
                    session.userId,
                    form.notificationType,
                    structKeyExists(form, "isEnabled") ? form.isEnabled : true,
                    form.deliveryMode ?: "instant",
                    form.quietStart ?: "",
                    form.quietEnd ?: ""
                );
                response["message"] = "Preference saved.";
                break;

            default:
                response = { "success": false, "message": "Unknown action: #action#" };
        }
    } catch (any e) {
        response = { "success": false, "message": e.message };
    }

    writeOutput(serializeJSON(response));
</cfscript>
