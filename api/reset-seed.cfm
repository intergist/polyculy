<cfsetting showDebugOutput="false">
<cfheader name="Content-Type" value="application/json">

<cftry>
	<!--- Reset seed data to pristine state. Order respects FK constraints. --->
	<!--- Seed IDs: users 1-7, connections 1-6, personal_events 1-3,
	     shared_events 1-4, notifications 1-3, licences 1-10 --->

	<!--- Delete child tables first (FK leaves) --->

	<!--- Informational emails reference shared_events --->
	<cfquery name="qInformationalEmails" datasource="polyculy">
		DELETE FROM polyculy.dbo.informational_emails WHERE shared_event_id > 4
	</cfquery>

	<!--- Proposals reference shared_events --->
	<cfquery name="qProposalsChild" datasource="polyculy">
		DELETE FROM polyculy.dbo.proposals WHERE shared_event_id > 4
	</cfquery>

	<!--- Also clean test-generated proposals on seed events --->
	<cfquery name="qProposalsAll" datasource="polyculy">
		DELETE FROM polyculy.dbo.proposals
	</cfquery>

	<!--- Shared event participants reference shared_events --->
	<cfquery name="qSharedEventParticipants" datasource="polyculy">
		DELETE FROM polyculy.dbo.shared_event_participants WHERE shared_event_id > 4
	</cfquery>

	<!--- Personal event visibility references personal_events --->
	<cfquery name="qPersonalEventVisibility" datasource="polyculy">
		DELETE FROM polyculy.dbo.personal_event_visibility WHERE event_id > 3
	</cfquery>

	<!--- Now safe to delete parent tables --->

	<!--- Shared events --->
	<cfquery name="qSharedEvents" datasource="polyculy">
		DELETE FROM polyculy.dbo.shared_events WHERE shared_event_id > 4
	</cfquery>

	<!--- Personal events --->
	<cfquery name="qPersonalEvents" datasource="polyculy">
		DELETE FROM polyculy.dbo.personal_events WHERE event_id > 3
	</cfquery>

	<!--- Connections --->
	<cfquery name="qConnectionsDelete" datasource="polyculy">
		DELETE FROM polyculy.dbo.connections WHERE connection_id > 6
	</cfquery>

	<!--- Notifications --->
	<cfquery name="qNotificationsDelete" datasource="polyculy">
		DELETE FROM polyculy.dbo.notifications WHERE notification_id > 3
	</cfquery>

	<!--- Audit log --->
	<cfquery name="qAuditLogDelete" datasource="polyculy">
		DELETE FROM polyculy.dbo.audit_log WHERE audit_id > 10
	</cfquery>

	<!--- Reset seed data to pristine state --->

	<!--- Connections --->
	<cfquery name="qConnections1" datasource="polyculy">
		UPDATE polyculy.dbo.connections
		SET status = 'connected'
		WHERE connection_id = 1
	</cfquery>

	<cfquery name="qConnections2" datasource="polyculy">
		UPDATE polyculy.dbo.connections
		SET status = 'awaiting_confirmation'
		WHERE connection_id = 2
	</cfquery>

	<cfquery name="qConnections3" datasource="polyculy">
		UPDATE polyculy.dbo.connections
		SET status = 'awaiting_confirmation'
		WHERE connection_id = 3
	</cfquery>

	<cfquery name="qConnections4" datasource="polyculy">
		UPDATE polyculy.dbo.connections
		SET status = 'licence_gifted_awaiting_signup'
		WHERE connection_id = 4
	</cfquery>

	<cfquery name="qConnections5" datasource="polyculy">
		UPDATE polyculy.dbo.connections
		SET status = 'awaiting_signup'
		WHERE connection_id = 5
	</cfquery>

	<cfquery name="qConnections6" datasource="polyculy">
		UPDATE polyculy.dbo.connections
		SET status = 'revoked'
		WHERE connection_id = 6
	</cfquery>

	<!--- Shared events states --->
	<cfquery name="qSharedEvents1" datasource="polyculy">
		UPDATE polyculy.dbo.shared_events
		SET global_state = 'tentative',
			cancellation_reason = '',
			ownership_transfer_active = 0
		WHERE shared_event_id = 1
	</cfquery>

	<cfquery name="qSharedEvents2" datasource="polyculy">
		UPDATE polyculy.dbo.shared_events
		SET global_state = 'active',
			cancellation_reason = '',
			ownership_transfer_active = 0
		WHERE shared_event_id = 2
	</cfquery>

	<cfquery name="qSharedEvents3" datasource="polyculy">
		UPDATE polyculy.dbo.shared_events
		SET global_state = 'tentative',
			cancellation_reason = '',
			ownership_transfer_active = 0
		WHERE shared_event_id = 3
	</cfquery>

	<cfquery name="qSharedEvents4" datasource="polyculy">
		UPDATE polyculy.dbo.shared_events
		SET global_state = 'active',
			cancellation_reason = '',
			ownership_transfer_active = 0
		WHERE shared_event_id = 4
	</cfquery>

	<!--- Shared event participant statuses (reset to original seed state) --->
	<cfquery name="qSharedEventParticipantsReset" datasource="polyculy">
		UPDATE polyculy.dbo.shared_event_participants
		SET response_status = 'pending',
			is_removed = 0
		WHERE participant_id = 1
	</cfquery>

	<!--- Notifications --->
	<cfquery name="qNotificationsUnread" datasource="polyculy">
		UPDATE polyculy.dbo.notifications
		SET is_read = 0
		WHERE notification_id IN (1, 2)
	</cfquery>

	<cfquery name="qNotificationsRead" datasource="polyculy">
		UPDATE polyculy.dbo.notifications
		SET is_read = 1
		WHERE notification_id = 3
	</cfquery>

	<!--- Licences --->
	<cfquery name="qLicencesDelete" datasource="polyculy">
		DELETE FROM polyculy.dbo.licences
		WHERE licence_id > 10
	</cfquery>

	<cfquery name="qLicencesAvailable" datasource="polyculy">
		UPDATE polyculy.dbo.licences
		SET status = 'available'
		WHERE licence_id IN (7, 8, 9, 10)
	</cfquery>

	<cfquery name="qLicencesGiftedPending" datasource="polyculy">
		UPDATE polyculy.dbo.licences
		SET status = 'gifted_pending'
		WHERE licence_id = 5
	</cfquery>

	<cfset result = { "success" = true, "message" = "Seed data reset to pristine state." }>

	<cfcatch type="any">
		<cfset result = { "success" = false, "message" = cfcatch.message }>
	</cfcatch>
</cftry>

<cfoutput>#serializeJSON(result)#</cfoutput>