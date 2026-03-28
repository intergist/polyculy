component {

    function getAffectedEvents(required numeric userId1, required numeric userId2) {
        // Find all shared events where both users are involved (as organizer or participant)
        return queryExecute(
            "SELECT DISTINCT se.shared_event_id, se.title, se.organizer_user_id, se.global_state,
                    se.start_time, se.end_time, u.display_name AS organizer_name,
                    (SELECT COUNT(*) FROM polyculy.dbo.shared_event_participants sp
                     WHERE sp.shared_event_id = se.shared_event_id AND sp.is_removed = FALSE) AS total_participants,
                    CASE WHEN (SELECT COUNT(*) FROM polyculy.dbo.shared_event_participants sp
                              WHERE sp.shared_event_id = se.shared_event_id AND sp.is_removed = FALSE) <= 1
                         AND se.organizer_user_id IN (:u1, :u2)
                         THEN 'two_person' ELSE 'multi_person' END AS event_type,
                    CASE WHEN (SELECT COUNT(*) FROM connections cc
                              WHERE cc.status = 'connected'
                              AND ((cc.user_id_1 = :u2 AND cc.user_id_2 IN
                                   (SELECT sp2.user_id FROM shared_event_participants sp2
                                    WHERE sp2.shared_event_id = se.shared_event_id AND sp2.is_removed = FALSE AND sp2.user_id NOT IN (:u1, :u2)))
                              OR (cc.user_id_2 = :u2 AND cc.user_id_1 IN
                                   (SELECT sp3.user_id FROM shared_event_participants sp3
                                    WHERE sp3.shared_event_id = se.shared_event_id AND sp3.is_removed = FALSE AND sp3.user_id NOT IN (:u1, :u2))))) > 0
                         THEN TRUE ELSE FALSE END AS has_other_connections
             FROM polyculy.dbo.shared_events se
             JOIN users u ON se.organizer_user_id = u.user_id
             WHERE se.global_state != 'cancelled'
             AND (se.organizer_user_id IN (:u1, :u2)
                  OR se.shared_event_id IN (SELECT sp.shared_event_id FROM shared_event_participants sp
                                            WHERE sp.user_id IN (:u1, :u2) AND sp.is_removed = FALSE))
             AND se.shared_event_id IN (SELECT sp4.shared_event_id FROM shared_event_participants sp4
                                        WHERE sp4.user_id = :u1 AND sp4.is_removed = FALSE
                                        UNION SELECT se2.shared_event_id FROM polyculy.dbo.shared_events se2 WHERE se2.organizer_user_id = :u1)
             AND se.shared_event_id IN (SELECT sp5.shared_event_id FROM polyculy.dbo.shared_event_participants sp5
                                        WHERE sp5.user_id = :u2 AND sp5.is_removed = FALSE
                                        UNION SELECT se3.shared_event_id FROM polyculy.dbo.shared_events se3 WHERE se3.organizer_user_id = :u2)
             ORDER BY se.start_time",
            {
                u1: { value: arguments.userId1, cfsqltype: "cf_sql_integer" },
                u2: { value: arguments.userId2, cfsqltype: "cf_sql_integer" }
            }
        );
    }

    function executeRevocation(required numeric connectionId, required numeric revokerId, required numeric revokedUserId, array eventDecisions = []) {
        var connSvc = new ConnectionService();
        var seSvc = new SharedEventService();
        var auditSvc = new AuditService();
        var notifSvc = new NotificationService();

        // Revoke the connection
        connSvc.revokeConnection(arguments.connectionId, arguments.revokerId);

        // Log audit
        auditSvc.log("connection_revoked", "connection", arguments.connectionId,
            "Connection revoked by user #arguments.revokerId#", arguments.revokerId);

        // Notify the other party
        notifSvc.create(arguments.revokedUserId, "connection_revoked", "Connection Revoked",
            "A connection has been revoked.", "connection", arguments.connectionId);

        // Process event decisions
        for (var decision in arguments.eventDecisions) {
            var eventId = decision.eventId;
            var action = decision.action; // "remove", "keep", "cancel"

            if (action == "cancel") {
                seSvc.cancelEvent(eventId, "revoked_two_person_event");
                auditSvc.log("event_cancelled_revocation", "shared_event", eventId,
                    "Event cancelled due to connection revocation", arguments.revokerId);
            } else if (action == "remove") {
                seSvc.removeParticipant(eventId, arguments.revokedUserId);
                auditSvc.log("participant_removed_revocation", "shared_event", eventId,
                    "Participant removed due to revocation", arguments.revokerId);
            }
            // "keep" = no action needed on the event
        }

        return { success: true };
    }

}
