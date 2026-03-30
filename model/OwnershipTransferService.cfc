<cfcomponent>

	<cffunction name="initiateTransfer" access="public" returntype="struct">
		<cfargument name="eventId" type="numeric" required="true">
		<cfargument name="removedUserId" type="numeric" required="true">

		<cfset var sharedSvc = createObject("component", "model.SharedEventService")>
		<cfset var notifSvc = createObject("component", "model.NotificationService")>
		<cfset var evt = sharedSvc.getById(arguments.eventId)>
		<cfset var participants = sharedSvc.getParticipants(arguments.eventId)>
		<cfset var activeCount = sharedSvc.getActiveParticipantCount(arguments.eventId)>
		<cfset var hoursUntilEvent = dateDiff("h", now(), evt.start_time)>
		<cfset var deadline = "">
		<cfset var p = "">

		<!--- If only 2 people and one leaves, cancel the event --->
		<cfif activeCount LTE 1>
			<cfset sharedSvc.cancelEvent(arguments.eventId, "Organizer left and no other participants remain")>
			<cfreturn { action = "cancelled" }>
		</cfif>

		<!--- Calculate deadline tier based on time until event --->
		<cfif hoursUntilEvent LT 2>
			<!--- Very late: auto-cancel --->
			<cfset sharedSvc.cancelEvent(arguments.eventId, "Organizer removed too close to event start")>
			<cfreturn {
				action = "cancelled",
				reason = "Too close to event start for ownership transfer"
			}>
		<cfelseif hoursUntilEvent LT 24>
			<!--- Late: 2-hour window --->
			<cfset deadline = dateAdd("h", 2, now())>
		<cfelse>
			<!--- Standard: 24-hour window --->
			<cfset deadline = dateAdd("h", 24, now())>
		</cfif>

		<cfset sharedSvc.initiateOwnershipTransfer(arguments.eventId, deadline)>

		<!--- Notify all remaining participants --->
		<cfloop array="#participants#" index="p">
			<cfif p.user_id NEQ arguments.removedUserId AND NOT p.is_removed>
				<cfset notifSvc.create(
					p.user_id,
					"ownership_transfer",
					"Event Needs New Organizer",
					"The event ""#evt.title#"" needs a new organizer. Claim it before #dateFormat(deadline, 'mm/dd/yyyy')# #timeFormat(deadline, 'hh:mm tt')#.",
					"shared_event",
					arguments.eventId
				)>
			</cfif>
		</cfloop>

		<cfreturn { action = "transfer_initiated", deadline = deadline }>
	</cffunction>

	<cffunction name="claimOwnership" access="public" returntype="struct">
		<cfargument name="eventId" type="numeric" required="true">
		<cfargument name="claimantUserId" type="numeric" required="true">

		<cfset var sharedSvc = createObject("component", "model.SharedEventService")>
		<cfset var evt = sharedSvc.getById(arguments.eventId)>
		<cfset var updated = "">
		<cfset var notifSvc = "">
		<cfset var participants = "">
		<cfset var p = "">

		<cfif NOT evt.ownership_transfer_active>
			<cfreturn { success = false, message = "No active ownership transfer for this event" }>
		</cfif>

		<!--- Check deadline --->
		<cfif dateCompare(now(), evt.ownership_transfer_deadline) GT 0>
			<cfset sharedSvc.cancelEvent(arguments.eventId, "Ownership transfer deadline expired")>
			<cfreturn { success = false, message = "Transfer deadline has passed. Event cancelled." }>
		</cfif>

		<!--- First-claim-wins: atomically transfer --->
		<cfset sharedSvc.transferOwnership(arguments.eventId, arguments.claimantUserId)>

		<!--- Verify it worked (another user may have claimed first) --->
		<cfset updated = sharedSvc.getById(arguments.eventId)>

		<cfif updated.organizer_user_id EQ arguments.claimantUserId>
			<cfset notifSvc = createObject("component", "model.NotificationService")>
			<cfset participants = sharedSvc.getParticipants(arguments.eventId)>

			<cfloop array="#participants#" index="p">
				<cfif p.user_id NEQ arguments.claimantUserId AND NOT p.is_removed>
					<cfset notifSvc.create(
						p.user_id,
						"ownership_claimed",
						"New Event Organizer",
						"#(len(updated.organizer_name) ? updated.organizer_name : 'Someone')# is now the organizer of ""#updated.title#"".",
						"shared_event",
						arguments.eventId
					)>
				</cfif>
			</cfloop>

			<cfreturn { success = true, message = "You are now the organizer" }>
		<cfelse>
			<cfreturn { success = false, message = "Another participant already claimed this event" }>
		</cfif>
	</cffunction>

	<cffunction name="getTransferableEvents" access="public" returntype="query">
		<cfset var q = "">

		<cfquery name="q" datasource="polyculy">
			SELECT
				se.shared_event_id,
				se.title,
				se.start_time,
				se.ownership_transfer_deadline,
				u.display_name AS organizer_name
			FROM polyculy.dbo.shared_events se
				JOIN polyculy.dbo.users u ON u.user_id = se.organizer_user_id
			WHERE
				se.ownership_transfer_active = TRUE
				AND se.global_state != 'cancelled'
			ORDER BY se.ownership_transfer_deadline ASC
		</cfquery>

		<cfreturn q>
	</cffunction>

</cfcomponent>