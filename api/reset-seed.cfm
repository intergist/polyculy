<cfscript>
setting showDebugOutput=false;
cfheader(name="Content-Type", value="application/json");

try {
    // ────────────────────────────────────────────────────────────
    // Reset seed data to pristine state. Order respects FK constraints.
    // Seed IDs: users 1-7, connections 1-6, personal_events 1-3,
    //   shared_events 1-4, notifications 1-3, licences 1-10
    // ────────────────────────────────────────────────────────────

    // ── Delete child tables first (FK leaves) ──────────────────

    // Informational emails reference shared_events
    queryExecute("DELETE FROM polyculy.dbo.informational_emails WHERE shared_event_id > 4", {}, { datasource: "polyculy" });

    // Proposals reference shared_events
    queryExecute("DELETE FROM polyculy.dbo.proposals WHERE shared_event_id > 4", {}, { datasource: "polyculy" });
    // Also clean test-generated proposals on seed events
    queryExecute("DELETE FROM polyculy.dbo.proposals", {}, { datasource: "polyculy" });

    // Shared event participants reference shared_events
    queryExecute("DELETE FROM polyculy.dbo.shared_event_participants WHERE shared_event_id > 4", {}, { datasource: "polyculy" });

    // Personal event visibility references personal_events
    queryExecute("DELETE FROM polyculy.dbo.personal_event_visibility WHERE event_id > 3", {}, { datasource: "polyculy" });

    // ── Now safe to delete parent tables ────────────────────────

    // Shared events
    queryExecute("DELETE FROM polyculy.dbo.shared_events WHERE shared_event_id > 4", {}, { datasource: "polyculy" });

    // Personal events
    queryExecute("DELETE FROM polyculy.dbo.personal_events WHERE event_id > 3", {}, { datasource: "polyculy" });

    // Connections
    queryExecute("DELETE FROM polyculy.dbo.connections WHERE connection_id > 6", {}, { datasource: "polyculy" });

    // Notifications
    queryExecute("DELETE FROM polyculy.dbo.notifications WHERE notification_id > 3", {}, { datasource: "polyculy" });

    // Audit log
    queryExecute("DELETE FROM polyculy.dbo.audit_log WHERE audit_id > 10", {}, { datasource: "polyculy" });

    // ── Reset seed data to pristine state ──────────────────────

    // Connections
    queryExecute("UPDATE polyculy.dbo.connections SET status = 'connected' WHERE connection_id = 1", {}, { datasource: "polyculy" });
    queryExecute("UPDATE polyculy.dbo.connections SET status = 'awaiting_confirmation' WHERE connection_id = 2", {}, { datasource: "polyculy" });
    queryExecute("UPDATE polyculy.dbo.connections SET status = 'awaiting_confirmation' WHERE connection_id = 3", {}, { datasource: "polyculy" });
    queryExecute("UPDATE polyculy.dbo.connections SET status = 'licence_gifted_awaiting_signup' WHERE connection_id = 4", {}, { datasource: "polyculy" });
    queryExecute("UPDATE polyculy.dbo.connections SET status = 'awaiting_signup' WHERE connection_id = 5", {}, { datasource: "polyculy" });
    queryExecute("UPDATE polyculy.dbo.connections SET status = 'revoked' WHERE connection_id = 6", {}, { datasource: "polyculy" });

    // Shared events states
    queryExecute("UPDATE polyculy.dbo.shared_events SET global_state = 'tentative', cancellation_reason = '', ownership_transfer_active = false WHERE shared_event_id = 1", {}, { datasource: "polyculy" });
    queryExecute("UPDATE polyculy.dbo.shared_events SET global_state = 'active', cancellation_reason = '', ownership_transfer_active = false WHERE shared_event_id = 2", {}, { datasource: "polyculy" });
    queryExecute("UPDATE polyculy.dbo.shared_events SET global_state = 'tentative', cancellation_reason = '', ownership_transfer_active = false WHERE shared_event_id = 3", {}, { datasource: "polyculy" });
    queryExecute("UPDATE polyculy.dbo.shared_events SET global_state = 'active', cancellation_reason = '', ownership_transfer_active = false WHERE shared_event_id = 4", {}, { datasource: "polyculy" });

    // Shared event participant statuses (reset to original seed state)
    queryExecute("UPDATE polyculy.dbo.shared_event_participants SET response_status = 'pending', is_removed = false WHERE participant_id = 1", {}, { datasource: "polyculy" });

    // Notifications
    queryExecute("UPDATE polyculy.dbo.notifications SET is_read = false WHERE notification_id IN (1, 2)", {}, { datasource: "polyculy" });
    queryExecute("UPDATE polyculy.dbo.notifications SET is_read = true WHERE notification_id = 3", {}, { datasource: "polyculy" });

    // Licences
    queryExecute("DELETE FROM polyculy.dbo.licences WHERE licence_id > 10", {}, { datasource: "polyculy" });
    queryExecute("UPDATE polyculy.dbo.licences SET status = 'available' WHERE licence_id IN (7, 8, 9, 10)", {}, { datasource: "polyculy" });
    queryExecute("UPDATE polyculy.dbo.licences SET status = 'gifted_pending' WHERE licence_id = 5", {}, { datasource: "polyculy" });

    writeOutput(serializeJSON({ "success": true, "message": "Seed data reset to pristine state." }));
} catch (any e) {
    writeOutput(serializeJSON({ "success": false, "message": e.message }));
}
</cfscript>
