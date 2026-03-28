component {

    function create(required numeric eventId, required numeric userId, required string proposedStart, required string proposedEnd, string message = "") {
        // Withdraw any existing active proposal by this user for this event
        queryExecute(
            "UPDATE polyculy.dbo.proposals SET status = 'withdrawn', updated_at = CURRENT_TIMESTAMP
             WHERE shared_event_id = :eid AND proposer_user_id = :uid AND status = 'active'",
            {
                eid: { value: arguments.eventId, cfsqltype: "cf_sql_integer" },
                uid: { value: arguments.userId, cfsqltype: "cf_sql_integer" }
            }
        );

        queryExecute(
            "INSERT INTO polyculy.dbo.proposals (shared_event_id, proposer_user_id, proposed_start, proposed_end, message, status)
             VALUES (:eid, :uid, :pstart, :pend, :msg, 'active')",
            {
                eid: { value: arguments.eventId, cfsqltype: "cf_sql_integer" },
                uid: { value: arguments.userId, cfsqltype: "cf_sql_integer" },
                pstart: { value: arguments.proposedStart, cfsqltype: "cf_sql_timestamp" },
                pend: { value: arguments.proposedEnd, cfsqltype: "cf_sql_timestamp" },
                msg: { value: arguments.message, cfsqltype: "cf_sql_varchar", null: !len(arguments.message) }
            }
        );
    }

    function getActiveByEvent(required numeric eventId) {
        return queryExecute(
            "SELECT p.*, u.display_name AS proposer_name, u.avatar_url AS proposer_avatar
             FROM polyculy.dbo.proposals p 
						 JOIN polyculy.dbo.users u ON p.proposer_user_id = u.user_id
             WHERE p.shared_event_id = :eid AND p.status = 'active'
             ORDER BY p.created_at DESC",
            { eid: { value: arguments.eventId, cfsqltype: "cf_sql_integer" } }
        );
    }

    function getAllByEvent(required numeric eventId) {
        return queryExecute(
            "SELECT p.*, u.display_name AS proposer_name, u.avatar_url AS proposer_avatar
             FROM polyculy.dbo.proposals p JOIN users u ON p.proposer_user_id = u.user_id
             WHERE p.shared_event_id = :eid
             ORDER BY p.created_at DESC",
            { eid: { value: arguments.eventId, cfsqltype: "cf_sql_integer" } }
        );
    }

    function acceptProposal(required numeric proposalId) {
        var proposal = queryExecute(
            "SELECT * FROM polyculy.dbo.proposals WHERE proposal_id = :pid AND status = 'active'",
            { pid: { value: arguments.proposalId, cfsqltype: "cf_sql_integer" } }
        );
        if (!proposal.recordCount) return { success: false, message: "Proposal not found or not active." };

        // Mark proposal as accepted
        queryExecute(
            "UPDATE polyculy.dbo.proposals SET status = 'accepted', updated_at = CURRENT_TIMESTAMP WHERE proposal_id = :pid",
            { pid: { value: arguments.proposalId, cfsqltype: "cf_sql_integer" } }
        );

        // Reject all other active proposals for this event
        queryExecute(
            "UPDATE polyculy.dbo.proposals SET status = 'rejected', updated_at = CURRENT_TIMESTAMP
             WHERE shared_event_id = :eid AND proposal_id != :pid AND status = 'active'",
            {
                eid: { value: proposal.shared_event_id, cfsqltype: "cf_sql_integer" },
                pid: { value: arguments.proposalId, cfsqltype: "cf_sql_integer" }
            }
        );

        // Update event time (material edit)
        queryExecute(
            "UPDATE polyculy.dbo.shared_events SET start_time = :st, end_time = :et, updated_at = CURRENT_TIMESTAMP
             WHERE shared_event_id = :eid",
            {
                eid: { value: proposal.shared_event_id, cfsqltype: "cf_sql_integer" },
                st: { value: proposal.proposed_start, cfsqltype: "cf_sql_timestamp" },
                et: { value: proposal.proposed_end, cfsqltype: "cf_sql_timestamp" }
            }
        );

        // Reset all participant acceptances to pending
        queryExecute(
            "UPDATE polyculy.dbo.shared_event_participants SET response_status = 'pending', updated_at = CURRENT_TIMESTAMP
             WHERE shared_event_id = :eid AND is_removed = FALSE",
            { eid: { value: proposal.shared_event_id, cfsqltype: "cf_sql_integer" } }
        );

        // Recalculate state
        var seSvc = new SharedEventService();
        seSvc.recalculateState(proposal.shared_event_id);

        return { success: true, eventId: proposal.shared_event_id };
    }

    function rejectProposal(required numeric proposalId) {
        queryExecute(
            "UPDATE polyculy.dbo.proposals SET status = 'rejected', updated_at = CURRENT_TIMESTAMP WHERE proposal_id = :pid",
            { pid: { value: arguments.proposalId, cfsqltype: "cf_sql_integer" } }
        );
    }

}
