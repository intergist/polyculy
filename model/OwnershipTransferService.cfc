component {

    function initiateTransfer(required numeric eventId, required numeric removedUserId) {
        var sharedSvc = new model.SharedEventService();
        var notifSvc = new model.NotificationService();

        var evt = sharedSvc.getById(arguments.eventId);
        var participants = sharedSvc.getParticipants(arguments.eventId);
        var activeCount = sharedSvc.getActiveParticipantCount(arguments.eventId);

        // If only 2 people and one leaves, cancel the event
        if (activeCount <= 1) {
            sharedSvc.cancelEvent(arguments.eventId, "Organizer left and no other participants remain");
            return { action: "cancelled" };
        }

        // Calculate deadline tier based on time until event
        var hoursUntilEvent = dateDiff("h", now(), evt.start_time);
        var deadline = "";

        if (hoursUntilEvent < 2) {
            // Very late: auto-cancel
            sharedSvc.cancelEvent(arguments.eventId, "Organizer removed too close to event start");
            return { action: "cancelled", reason: "Too close to event start for ownership transfer" };
        } else if (hoursUntilEvent < 24) {
            // Late: 2-hour window
            deadline = dateAdd("h", 2, now());
        } else {
            // Standard: 24-hour window
            deadline = dateAdd("h", 24, now());
        }

        sharedSvc.initiateOwnershipTransfer(arguments.eventId, deadline);

        // Notify all remaining participants
        for (var p in participants) {
            if (p.user_id != arguments.removedUserId && !p.is_removed) {
                notifSvc.create(
                    p.user_id,
                    "ownership_transfer",
                    "Event Needs New Organizer",
                    "The event ""#evt.title#"" needs a new organizer. Claim it before #dateFormat(deadline, 'mm/dd/yyyy')# #timeFormat(deadline, 'hh:mm tt')#.",
                    "shared_event",
                    arguments.eventId
                );
            }
        }

        return { action: "transfer_initiated", deadline: deadline };
    }

    function claimOwnership(required numeric eventId, required numeric claimantUserId) {
        var sharedSvc = new model.SharedEventService();
        var evt = sharedSvc.getById(arguments.eventId);

        if (!evt.ownership_transfer_active) {
            return { success: false, message: "No active ownership transfer for this event" };
        }

        // Check deadline
        if (dateCompare(now(), evt.ownership_transfer_deadline) > 0) {
            sharedSvc.cancelEvent(arguments.eventId, "Ownership transfer deadline expired");
            return { success: false, message: "Transfer deadline has passed. Event cancelled." };
        }

        // First-claim-wins: atomically transfer
        sharedSvc.transferOwnership(arguments.eventId, arguments.claimantUserId);

        // Verify it worked (another user may have claimed first)
        var updated = sharedSvc.getById(arguments.eventId);
        if (updated.organizer_user_id == arguments.claimantUserId) {
            var notifSvc = new model.NotificationService();
            var participants = sharedSvc.getParticipants(arguments.eventId);
            for (var p in participants) {
                if (p.user_id != arguments.claimantUserId && !p.is_removed) {
                    notifSvc.create(
                        p.user_id,
                        "ownership_claimed",
                        "New Event Organizer",
                        "#updated.organizer_name ?: 'Someone'# is now the organizer of ""#updated.title#"".",
                        "shared_event",
                        arguments.eventId
                    );
                }
            }
            return { success: true, message: "You are now the organizer" };
        } else {
            return { success: false, message: "Another participant already claimed this event" };
        }
    }

    function getTransferableEvents() {
        return queryExecute(
            "SELECT se.shared_event_id, se.title, se.start_time, se.ownership_transfer_deadline,
                    u.display_name AS organizer_name
             FROM polyculy.dbo.shared_events se
             JOIN users u ON u.user_id = se.organizer_user_id
             WHERE se.ownership_transfer_active = TRUE AND se.global_state != 'cancelled'
             ORDER BY se.ownership_transfer_deadline ASC",
            {},
            { datasource: "polyculy" }
        );
    }

}
