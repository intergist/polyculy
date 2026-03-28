component {

    function create(required numeric userId, required string notificationType, required string title, required string message, string entityType = "", numeric entityId = 0) {
        queryExecute(
            "INSERT INTO polyculy.dbo.notifications (user_id, notification_type, title, message, related_entity_type, related_entity_id)
             VALUES (:uid, :ntype, :title, :msg, :etype, :eid)",
            {
                uid: { value: arguments.userId, cfsqltype: "cf_sql_integer" },
                ntype: { value: arguments.notificationType, cfsqltype: "cf_sql_varchar" },
                title: { value: arguments.title, cfsqltype: "cf_sql_varchar" },
                msg: { value: arguments.message, cfsqltype: "cf_sql_varchar" },
                etype: { value: arguments.entityType, cfsqltype: "cf_sql_varchar", null: !len(arguments.entityType) },
                eid: { value: arguments.entityId, cfsqltype: "cf_sql_integer", null: arguments.entityId == 0 }
            }
        );
    }

    function getUnreadCount(required numeric userId) {
        var q = queryExecute(
            "	SELECT COUNT(*) AS cnt 
							FROM polyculy.dbo.notifications WHERE user_id = :uid AND isNull(is_read,0) = 0",
            { uid: { value: arguments.userId, cfsqltype: "cf_sql_integer" } }
        );
        return q.cnt;
    }

    function getRecent(required numeric userId, numeric limit = 20) {
        return queryExecute(
            "SELECT TOP(:lim) * FROM polyculy.dbo.notifications WHERE user_id = :uid ORDER BY created_at DESC",
            {
                uid: { value: arguments.userId, cfsqltype: "cf_sql_integer" },
                lim: { value: arguments.limit, cfsqltype: "cf_sql_integer" }
            }
        );
    }

    function markAsRead(required numeric notificationId, required numeric userId) {
        queryExecute(
            "UPDATE polyculy.dbo.notifications SET is_read = TRUE WHERE notification_id = :nid AND user_id = :uid",
            {
                nid: { value: arguments.notificationId, cfsqltype: "cf_sql_integer" },
                uid: { value: arguments.userId, cfsqltype: "cf_sql_integer" }
            }
        );
    }

    function markAllAsRead(required numeric userId) {
        queryExecute(
            "UPDATE polyculy.dbo.notifications SET is_read = TRUE WHERE user_id = :uid AND is_read = FALSE",
            { uid: { value: arguments.userId, cfsqltype: "cf_sql_integer" } }
        );
    }

    function getPreferences(required numeric userId) {
        return queryExecute(
            "SELECT * FROM polyculy.dbo.notification_preferences WHERE user_id = :uid",
            { uid: { value: arguments.userId, cfsqltype: "cf_sql_integer" } }
        );
    }

    function savePreference(required numeric userId, required string notificationType, boolean isEnabled = true, string deliveryMode = "instant", string quietStart = "", string quietEnd = "") {
        var existing = queryExecute(
            "SELECT pref_id FROM polyculy.dbo.notification_preferences WHERE user_id = :uid AND notification_type = :nt",
            {
                uid: { value: arguments.userId, cfsqltype: "cf_sql_integer" },
                nt: { value: arguments.notificationType, cfsqltype: "cf_sql_varchar" }
            }
        );
        if (existing.recordCount > 0) {
            queryExecute(
                "UPDATE polyculy.dbo.notification_preferences SET is_enabled = :enabled, delivery_mode = :mode,
                 quiet_hours_start = :qs, quiet_hours_end = :qe WHERE pref_id = :pid",
                {
                    pid: { value: existing.pref_id, cfsqltype: "cf_sql_integer" },
                    enabled: { value: arguments.isEnabled, cfsqltype: "cf_sql_bit" },
                    mode: { value: arguments.deliveryMode, cfsqltype: "cf_sql_varchar" },
                    qs: { value: arguments.quietStart, cfsqltype: "cf_sql_varchar", null: !len(arguments.quietStart) },
                    qe: { value: arguments.quietEnd, cfsqltype: "cf_sql_varchar", null: !len(arguments.quietEnd) }
                }
            );
        } else {
            queryExecute(
                "INSERT INTO polyculy.dbo.notification_preferences (user_id, notification_type, is_enabled, delivery_mode, quiet_hours_start, quiet_hours_end)
                 VALUES (:uid, :nt, :enabled, :mode, :qs, :qe)",
                {
                    uid: { value: arguments.userId, cfsqltype: "cf_sql_integer" },
                    nt: { value: arguments.notificationType, cfsqltype: "cf_sql_varchar" },
                    enabled: { value: arguments.isEnabled, cfsqltype: "cf_sql_bit" },
                    mode: { value: arguments.deliveryMode, cfsqltype: "cf_sql_varchar" },
                    qs: { value: arguments.quietStart, cfsqltype: "cf_sql_varchar", null: !len(arguments.quietStart) },
                    qe: { value: arguments.quietEnd, cfsqltype: "cf_sql_varchar", null: !len(arguments.quietEnd) }
                }
            );
        }
    }

}
