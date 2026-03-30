<cfcomponent>

	<cffunction name="getAffectedEvents" access="public" returntype="query">
		<cfargument name="userId1" type="numeric" required="true">
		<cfargument name="userId2" type="numeric" required="true">

		<cfset var q = "">

		<!--- Find all shared events where both users are involved (as organizer or participant) --->
		<cfquery name="q" datasource="polyculy">
			SELECT DISTINCT
				se.shared_event_id,
				se.title,
				se.organizer_user_id,
				se.global_state,
				se.start_time,
				se.end_time,
				u.display_name AS organizer_name,
				(
					SELECT COUNT(*)
					FROM polyculy.dbo.shared_event_participants sp
					WHERE
						sp.shared_event_id = se.shared_event_id
						AND sp.is_removed = FALSE
				) AS total_participants,
				CASE
					WHEN (
						SELECT COUNT(*)
						FROM polyculy.dbo.shared_event_participants sp
						WHERE
							sp.shared_event_id = se.shared_event_id
							AND sp.is_removed = FALSE
					) <= 1
					AND se.organizer_user_id IN (
						<cfqueryparam value="#arguments.userId1#" cfsqltype="cf_sql_integer">,
						<cfqueryparam value="#arguments.userId2#" cfsqltype="cf_sql_integer">
					)
					THEN 'two_person'
					ELSE 'multi_person'
				END AS event_type,
				CASE
					WHEN (
						SELECT COUNT(*)
						FROM connections cc
						WHERE
							cc.status = 'connected'
							AND (
								(
									cc.user_id_1 = <cfqueryparam value="#arguments.userId2#" cfsqltype="cf_sql_integer">
									AND cc.user_id_2 IN (
										SELECT sp2.user_id
										FROM shared_event_participants sp2
										WHERE
											sp2.shared_event_id = se.shared_event_id
											AND sp2.is_removed = FALSE
											AND sp2.user_id NOT IN (
												<cfqueryparam value="#arguments.userId1#" cfsqltype="cf_sql_integer">,
												<cfqueryparam value="#arguments.userId2#" cfsqltype="cf_sql_integer">
											)
									)
								)
								OR (
									cc.user_id_2 = <cfqueryparam value="#arguments.userId2#" cfsqltype="cf_sql_integer">
									AND cc.user_id_1 IN (
										SELECT sp3.user_id
										FROM shared_event_participants sp3
										WHERE
											sp3.shared_event_id = se.shared_event_id
											AND sp3.is_removed = FALSE
											AND sp3.user_id NOT IN (
												<cfqueryparam value="#arguments.userId1#" cfsqltype="cf_sql_integer">,
												<cfqueryparam value="#arguments.userId2#" cfsqltype="cf_sql_integer">
											)
									)
								)
							)
					) > 0
					THEN 1
					ELSE 0
				END AS has_other_connections
			FROM polyculy.dbo.shared_events se
				JOIN users u ON se.organizer_user_id = u.user_id
			WHERE
				se.global_state != 'cancelled'
				AND (
					se.organizer_user_id IN (
						<cfqueryparam value="#arguments.userId1#" cfsqltype="cf_sql_integer">,
						<cfqueryparam value="#arguments.userId2#" cfsqltype="cf_sql_integer">
					)
					OR se.shared_event_id IN (
						SELECT sp.shared_event_id
						FROM shared_event_participants sp
						WHERE
							sp.user_id IN (
								<cfqueryparam value="#arguments.userId1#" cfsqltype="cf_sql_integer">,
								<cfqueryparam value="#arguments.userId2#" cfsqltype="cf_sql_integer">
							)
							AND sp.is_removed = FALSE
					)
				)
				AND se.shared_event_id IN (
					SELECT sp4.shared_event_id
					FROM shared_event_participants sp4
					WHERE sp4.user_id = <cfqueryparam value="#arguments.userId1#" cfsqltype="cf_sql_integer">
						AND sp4.is_removed = FALSE
					UNION
					SELECT se2.shared_event_id
					FROM polyculy.dbo.shared_events se2
					WHERE se2.organizer_user_id = <cfqueryparam value="#arguments.userId1#" cfsqltype="cf_sql_integer">
				)
				AND se.shared_event_id IN (
					SELECT sp5.shared_event_id
					FROM polyculy.dbo.shared_event_participants sp5
					WHERE sp5.user_id = <cfqueryparam value="#arguments.userId2#" cfsqltype="cf_sql_integer">
						AND sp5.is_removed = FALSE
					UNION
					SELECT se3.shared_event_id
					FROM polyculy.dbo.shared_events se3
					WHERE se3.organizer_user_id = <cfqueryparam value="#arguments.userId2#" cfsqltype="cf_sql_integer">
				)
			ORDER BY se.start_time
		</cfquery>

		<cfreturn q>
	</cffunction>

	<cffunction name="executeRevocation" access="public" returntype="struct">
		<cfargument name="connectionId" type="numeric" required="true">
		<cfargument name="revokerId" type="numeric" required="true">
		<cfargument name="revokedUserId" type="numeric" required="true">
		<cfargument name="eventDecisions" type="array" required="false" default="#[]#">

		<cfset var connSvc = createObject("component", "ConnectionService")>
		<cfset var seSvc = createObject("component", "SharedEventService")>
		<cfset var auditSvc = createObject("component", "AuditService")>
		<cfset var notifSvc = createObject("component", "NotificationService")>
		<cfset var decision = "">
		<cfset var eventId = 0>
		<cfset var action = "">

		<!--- Revoke the connection --->
		<cfset connSvc.revokeConnection(arguments.connectionId, arguments.revokerId)>

		<!--- Log audit --->
		<cfset auditSvc.log(
			"connection_revoked",
			"connection",
			arguments.connectionId,
			"Connection revoked by user #arguments.revokerId#",
			arguments.revokerId
		)>

		<!--- Notify the other party --->
		<cfset notifSvc.create(
			arguments.revokedUserId,
			"connection_revoked",
			"Connection Revoked",
			"A connection has been revoked.",
			"connection",
			arguments.connectionId
		)>

		<!--- Process event decisions --->
		<cfloop array="#arguments.eventDecisions#" index="decision">
			<cfset eventId = decision.eventId>
			<cfset action = decision.action> <!--- "remove", "keep", "cancel" --->

			<cfif action EQ "cancel">
				<cfset seSvc.cancelEvent(eventId, "revoked_two_person_event")>
				<cfset auditSvc.log(
					"event_cancelled_revocation",
					"shared_event",
					eventId,
					"Event cancelled due to connection revocation",
					arguments.revokerId
				)>
			<cfelseif action EQ "remove">
				<cfset seSvc.removeParticipant(eventId, arguments.revokedUserId)>
				<cfset auditSvc.log(
					"participant_removed_revocation",
					"shared_event",
					eventId,
					"Participant removed due to revocation",
					arguments.revokerId
				)>
			</cfif>
			<!--- "keep" = no action needed on the event --->
		</cfloop>

		<cfreturn { success = true }>
	</cffunction>

</cfcomponent>