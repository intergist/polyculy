component {

    function log(required string actionType, required string entityType, numeric entityId = 0, string details = "", numeric actorUserId = 0) {
        queryExecute(
            "INSERT INTO polyculy.dbo.audit_log (actor_user_id, action_type, entity_type, entity_id, details)
             VALUES (:actor, :action, :etype, :eid, :details)",
            {
                actor: { value: arguments.actorUserId, cfsqltype: "cf_sql_integer", null: arguments.actorUserId == 0 },
                action: { value: arguments.actionType, cfsqltype: "cf_sql_varchar" },
                etype: { value: arguments.entityType, cfsqltype: "cf_sql_varchar" },
                eid: { value: arguments.entityId, cfsqltype: "cf_sql_integer", null: arguments.entityId == 0 },
                details: { value: arguments.details, cfsqltype: "cf_sql_varchar" }
            }
        );
    }

    function getRecent(numeric limit = 50) {
        return queryExecute(
            "SELECT TOP(:lim) a.*, u.display_name AS actor_name
             FROM polyculy.dbo.audit_log a LEFT JOIN users u ON a.actor_user_id = u.user_id
             ORDER BY a.created_at DESC",
            { lim: { value: arguments.limit, cfsqltype: "cf_sql_integer" } }
        );
    }

    function getByEntity(required string entityType, required numeric entityId) {
        return queryExecute(
            "SELECT a.*, u.display_name AS actor_name
             FROM polyculy.dbo.audit_log a LEFT JOIN users u ON a.actor_user_id = u.user_id
             WHERE a.entity_type = :etype AND a.entity_id = :eid
             ORDER BY a.created_at DESC",
            {
                etype: { value: arguments.entityType, cfsqltype: "cf_sql_varchar" },
                eid: { value: arguments.entityId, cfsqltype: "cf_sql_integer" }
            }
        );
    }

}
