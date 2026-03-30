<cfcomponent>

	<cffunction name="create" access="public" returntype="any">
		<cfargument name="data" type="struct" required="true">

		<cfset var qResult = "">

		<cfquery datasource="polyculy" result="qResult">
			INSERT INTO polyculy.dbo.shared_events
				(organizer_user_id, title, start_time, end_time, all_day, timezone_id, event_details, address, reminder_minutes, reminder_scope, participant_visibility, global_state)
			VALUES
				(
					<cfqueryparam value="#arguments.data.organizerId#" cfsqltype="cf_sql_integer">,
					<cfqueryparam value="#arguments.data.title#" cfsqltype="cf_sql_varchar">,
					<cfqueryparam value="#arguments.data.startTime#" cfsqltype="cf_sql_timestamp">,
					<cfif len(arguments.data.endTime ?: "")>
						<cfqueryparam value="#arguments.data.endTime#" cfsqltype="cf_sql_timestamp">
					<cfelse>
						<cfqueryparam null="true" cfsqltype="cf_sql_timestamp">
					</cfif>,
					<cfqueryparam value="#(arguments.data.allDay ?: false)#" cfsqltype="cf_sql_bit">,
					<cfqueryparam value="#(arguments.data.timezoneId ?: 'America/New_York')#" cfsqltype="cf_sql_varchar">,
					<cfqueryparam value="#(arguments.data.eventDetails ?: '')#" cfsqltype="cf_sql_varchar">,
					<cfqueryparam value="#(arguments.data.address ?: '')#" cfsqltype="cf_sql_varchar">,
					<cfif len(arguments.data.reminderMinutes ?: "")>
						<cfqueryparam value="#arguments.data.reminderMinutes#" cfsqltype="cf_sql_integer">
					<cfelse>
						<cfqueryparam null="true" cfsqltype="cf_sql_integer">
					</cfif>,
					<cfqueryparam value="#(arguments.data.reminderScope ?: 'me')#" cfsqltype="cf_sql_varchar">,
					<cfqueryparam value="#(arguments.data.participantVisibility ?: 'visible')#" cfsqltype="cf_sql_varchar">,
					'tentative'
				)
		</cfquery>

		<cfreturn listFirst(qResult.generatedKey)>
	</cffunction>

	<cffunction name="addParticipant" access="public" returntype="void">
		<cfargument name="eventId" type="numeric" required="true">
		<cfargument name="userId" type="numeric" required="true">
		<cfargument name="attendanceType" type="string" required="false" default="required">
		<cfargument name="isOneHop" type="boolean" required="false" default="false">
		<cfargument name="linkPersonUserId" type="numeric" required="false" default="0">

		<cfquery datasource="polyculy">
			INSERT INTO polyculy.dbo.shared_event_participants
				(shared_event_id, user_id, attendance_type, is_one_hop, link_person_user_id)
			VALUES
				(
					<cfqueryparam value="#arguments.eventId#" cfsqltype="cf_sql_integer">,
					<cfqueryparam value="#arguments.userId#" cfsqltype="cf_sql_integer">,
					<cfqueryparam value="#arguments.attendanceType#" cfsqltype="cf_sql_varchar">,
					<cfqueryparam value="#arguments.isOneHop#" cfsqltype="cf_sql_bit">,
					<cfif arguments.linkPersonUserId EQ 0>
						<cfqueryparam null="true" cfsqltype="cf_sql_integer">
					<cfelse>
						<cfqueryparam value="#arguments.linkPersonUserId#" cfsqltype="cf_sql_integer">
					</cfif>
				)
		</cfquery>
	</cffunction>

	<cffunction name="getById" access="public" returntype="query">
		<cfargument name="eventId" type="numeric" required="true">

		<cfset var q = "">

		<cfquery name="q" datasource="polyculy">
			SELECT
				se.*,
				u.display_name AS organizer_name,
				u.email AS organizer_email
			FROM polyculy.dbo.shared_events se
				JOIN users u ON se.organizer_user_id = u.user_id
			WHERE se.shared_event_id = <cfqueryparam value="#arguments.eventId#" cfsqltype="cf_sql_integer">
		</cfquery>

		<cfreturn q>
	</cffunction>

	<cffunction name="getParticipants" access="public" returntype="query">
		<cfargument name="eventId" type="numeric" required="true">

		<cfset var q = "">

		<cfquery name="q" datasource="polyculy">
			SELECT
				sep.*,
				u.display_name,
				u.email,
				u.avatar_url,
				dp.calendar_color,
				dp.nickname
			FROM polyculy.dbo.shared_event_participants sep
				JOIN polyculy.dbo.users u ON sep.user_id = u.user_id
				LEFT JOIN polyculy.dbo.connection_display_prefs dp ON dp.target_user_id = sep.user_id
			WHERE
				sep.shared_event_id = <cfqueryparam value="#arguments.eventId#" cfsqltype="cf_sql_integer">
				AND sep.is_removed = FALSE
			ORDER BY sep.attendance_type, u.display_name
		</cfquery>

		<cfreturn q>
	</cffunction>

	<cffunction name="respondToInvitation" access="public" returntype="void">
		<cfargument name="eventId" type="numeric" required="true">
		<cfargument name="userId" type="numeric" required="true">
		<cfargument name="response" type="string" required="true">

		<cfquery datasource="polyculy">
			UPDATE polyculy.dbo.shared_event_participants
			SET
				response_status = <cfqueryparam value="#arguments.response#" cfsqltype="cf_sql_varchar">,
				updated_at = CURRENT_TIMESTAMP
			WHERE
				shared_event_id = <cfqueryparam value="#arguments.eventId#" cfsqltype="cf_sql_integer">
				AND user_id = <cfqueryparam value="#arguments.userId#" cfsqltype="cf_sql_integer">
				AND is_removed = FALSE
		</cfquery>

		<!--- Recalculate global state --->
		<cfset recalculateState(arguments.eventId)>
	</cffunction>

	<cffunction name="recalculateState" access="public" returntype="void">
		<cfargument name="eventId" type="numeric" required="true">

		<cfset var event = getById(arguments.eventId)>
		<cfset var q = "">
		<cfset var newState = "">

		<cfif NOT event.recordCount OR event.global_state EQ "cancelled">
			<cfreturn>
		</cfif>

		<cfquery name="q" datasource="polyculy">
			SELECT COUNT(*) AS cnt
			FROM polyculy.dbo.shared_event_participants
			WHERE
				shared_event_id = <cfqueryparam value="#arguments.eventId#" cfsqltype="cf_sql_integer">
				AND user_id != <cfqueryparam value="#event.organizer_user_id#" cfsqltype="cf_sql_integer">
				AND response_status = 'accepted'
				AND is_removed = FALSE
		</cfquery>

		<cfif q.cnt GT 0>
			<cfset newState = "active">
		<cfelse>
			<cfset newState = "tentative">
		</cfif>

		<cfquery datasource="polyculy">
			UPDATE polyculy.dbo.shared_events
			SET
				global_state = <cfqueryparam value="#newState#" cfsqltype="cf_sql_varchar">,
				updated_at = CURRENT_TIMESTAMP
			WHERE shared_event_id = <cfqueryparam value="#arguments.eventId#" cfsqltype="cf_sql_integer">
		</cfquery>
	</cffunction>

	<cffunction name="updateEvent" access="public" returntype="struct">
		<cfargument name="eventId" type="numeric" required="true">
		<cfargument name="data" type="struct" required="true">
		<cfargument name="organizerId" type="numeric" required="true">

		<cfset var current = getById(arguments.eventId)>
		<cfset var isMaterialEdit = false>

		<cfif NOT current.recordCount OR current.organizer_user_id NEQ arguments.organizerId>
			<cfreturn { success = false, message = "Not authorized" }>
		</cfif>

		<!--- Determine if edit is material (time or location changed) --->
		<cfif current.start_time NEQ arguments.data.startTime OR (current.end_time ?: "") NEQ (arguments.data.endTime ?: "")>
			<cfset isMaterialEdit = true>
		</cfif>
		<cfif (current.address ?: "") NEQ (arguments.data.address ?: "")>
			<cfset isMaterialEdit = true>
		</cfif>

		<cfquery datasource="polyculy">
			UPDATE polyculy.dbo.shared_events
			SET
				title = <cfqueryparam value="#arguments.data.title#" cfsqltype="cf_sql_varchar">,
				start_time = <cfqueryparam value="#arguments.data.startTime#" cfsqltype="cf_sql_timestamp">,
				end_time =
					<cfif len(arguments.data.endTime ?: "")>
						<cfqueryparam value="#arguments.data.endTime#" cfsqltype="cf_sql_timestamp">
					<cfelse>
						<cfqueryparam null="true" cfsqltype="cf_sql_timestamp">
					</cfif>,
				all_day = <cfqueryparam value="#(arguments.data.allDay ?: false)#" cfsqltype="cf_sql_bit">,
				event_details = <cfqueryparam value="#(arguments.data.eventDetails ?: '')#" cfsqltype="cf_sql_varchar">,
				address = <cfqueryparam value="#(arguments.data.address ?: '')#" cfsqltype="cf_sql_varchar">,
				reminder_minutes =
					<cfif len(arguments.data.reminderMinutes ?: "")>
						<cfqueryparam value="#arguments.data.reminderMinutes#" cfsqltype="cf_sql_integer">
					<cfelse>
						<cfqueryparam null="true" cfsqltype="cf_sql_integer">
					</cfif>,
				reminder_scope = <cfqueryparam value="#(arguments.data.reminderScope ?: 'me')#" cfsqltype="cf_sql_varchar">,
				participant_visibility = <cfqueryparam value="#(arguments.data.participantVisibility ?: 'visible')#" cfsqltype="cf_sql_varchar">,
				updated_at = CURRENT_TIMESTAMP
			WHERE shared_event_id = <cfqueryparam value="#arguments.eventId#" cfsqltype="cf_sql_integer">
		</cfquery>

		<cfif isMaterialEdit>
			<!--- Reset all acceptances to pending --->
			<cfquery datasource="polyculy">
				UPDATE polyculy.dbo.shared_event_participants
				SET
					response_status = 'pending',
					updated_at = CURRENT_TIMESTAMP
				WHERE
					shared_event_id = <cfqueryparam value="#arguments.eventId#" cfsqltype="cf_sql_integer">
					AND is_removed = FALSE
			</cfquery>

			<cfset recalculateState(arguments.eventId)>
		</cfif>

		<cfreturn { success = true, isMaterialEdit = isMaterialEdit }>
	</cffunction>

	<cffunction name="cancelEvent" access="public" returntype="void">
		<cfargument name="eventId" type="numeric" required="true">
		<cfargument name="reason" type="string" required="true">

		<cfquery datasource="polyculy">
			UPDATE polyculy.dbo.shared_events
			SET
				global_state = 'cancelled',
				cancellation_reason = <cfqueryparam value="#arguments.reason#" cfsqltype="cf_sql_varchar">,
				updated_at = CURRENT_TIMESTAMP
			WHERE shared_event_id = <cfqueryparam value="#arguments.eventId#" cfsqltype="cf_sql_integer">
		</cfquery>
	</cffunction>

	<cffunction name="removeParticipant" access="public" returntype="void">
		<cfargument name="eventId" type="numeric" required="true">
		<cfargument name="userId" type="numeric" required="true">

		<cfquery datasource="polyculy">
			UPDATE polyculy.dbo.shared_event_participants
			SET
				is_removed = TRUE,
				updated_at = CURRENT_TIMESTAMP
			WHERE
				shared_event_id = <cfqueryparam value="#arguments.eventId#" cfsqltype="cf_sql_integer">
				AND user_id = <cfqueryparam value="#arguments.userId#" cfsqltype="cf_sql_integer">
		</cfquery>

		<cfset recalculateState(arguments.eventId)>
	</cffunction>

	<cffunction name="getEventsForUser" access="public" returntype="query">
		<cfargument name="userId" type="numeric" required="true">
		<cfargument name="startDate" type="string" required="false" default="">
		<cfargument name="endDate" type="string" required="false" default="">

		<cfquery name="qGroupEvents" datasource="polyculy">
			SELECT
				se.*,
				u.display_name AS organizer_name,
				sep.response_status,
				sep.attendance_type,
				sep.is_one_hop,
				(
					SELECT COUNT(*)
					FROM polyculy.dbo.shared_event_participants sp2
					WHERE
						sp2.shared_event_id = se.shared_event_id
						AND isNull(sp2.is_removed,0)= 0
				) AS participant_count
			FROM polyculy.dbo.shared_events se
				JOIN polyculy.dbo.shared_event_participants sep ON se.shared_event_id = sep.shared_event_id
				JOIN polyculy.dbo.users u ON se.organizer_user_id = u.user_id
			WHERE
				sep.user_id = <cfqueryparam value="#VAL(arguments.userId)#" cfsqltype="cf_sql_integer">
				AND isNull(sep.is_removed,0) = 0
				AND se.global_state != 'cancelled'
			<cfif len(arguments.startDate) AND isDate(arguments.startDate)>
				AND se.start_time >= <cfqueryparam value="#arguments.startDate#" cfsqltype="cf_sql_varchar">
			</cfif>
			<cfif len(arguments.endDate) AND isDate(arguments.endDate)>
				AND se.start_time <= <cfqueryparam value="#arguments.endDate#" cfsqltype="cf_sql_varchar">
			</cfif>

			UNION

			SELECT
				se2.*,
				u2.display_name AS organizer_name,
				'organizer' AS response_status,
				'required' AS attendance_type,
				0 AS is_one_hop,
				(
					SELECT COUNT(*)
					FROM polyculy.dbo.shared_event_participants sp3
					WHERE
						sp3.shared_event_id = se2.shared_event_id
						AND isNull(sp3.is_removed,0) = 0
				) AS participant_count
			FROM polyculy.dbo.shared_events se2
				JOIN users u2 ON se2.organizer_user_id = u2.user_id
			WHERE
				se2.organizer_user_id = <cfqueryparam value="#arguments.userId#" cfsqltype="cf_sql_integer">
				AND se2.global_state != 'cancelled'
			<cfif len(arguments.startDate) AND isDate(arguments.startDate)>
				AND se2.start_time >= <cfqueryparam value="#arguments.startDate#" cfsqltype="cf_sql_varchar">
			</cfif>
			<cfif len(arguments.endDate) AND isDate(arguments.endDate)>
				AND se2.start_time <= <cfqueryparam value="#arguments.endDate#" cfsqltype="cf_sql_varchar">
			</cfif>

			ORDER BY start_time
		</cfquery>

		<cfreturn qGroupEvents>
	</cffunction>

	<cffunction name="getConflicts" access="public" returntype="struct">
		<cfargument name="userId" type="numeric" required="true">
		<cfargument name="startTime" type="string" required="true">
		<cfargument name="endTime" type="string" required="true">

		<cfset var personalConflicts = "">
		<cfset var sharedConflicts = "">

		<!--- Check personal events that block time --->
		<cfquery name="personalConflicts" datasource="polyculy">
			SELECT
				event_id,
				title,
				start_time,
				end_time,
				'personal' AS event_type
			FROM polyculy.dbo.personal_events
			WHERE
				owner_user_id = <cfqueryparam value="#arguments.userId#" cfsqltype="cf_sql_integer">
				AND is_cancelled = FALSE
				AND start_time < <cfqueryparam value="#arguments.endTime#" cfsqltype="cf_sql_timestamp">
				AND end_time > <cfqueryparam value="#arguments.startTime#" cfsqltype="cf_sql_timestamp">
		</cfquery>

		<!--- Check shared events where user accepted --->
		<cfquery name="sharedConflicts" datasource="polyculy">
			SELECT
				se.shared_event_id AS event_id,
				se.title,
				se.start_time,
				se.end_time,
				CASE
					WHEN se.global_state = 'active' THEN 'hard'
					ELSE 'soft'
				END AS conflict_type
			FROM polyculy.dbo.shared_events se
				JOIN polyculy.dbo.shared_event_participants sep ON se.shared_event_id = sep.shared_event_id
			WHERE
				sep.user_id = <cfqueryparam value="#arguments.userId#" cfsqltype="cf_sql_integer">
				AND sep.response_status = 'accepted'
				AND sep.is_removed = FALSE
				AND se.global_state != 'cancelled'
				AND se.start_time < <cfqueryparam value="#arguments.endTime#" cfsqltype="cf_sql_timestamp">
				AND se.end_time > <cfqueryparam value="#arguments.startTime#" cfsqltype="cf_sql_timestamp">
		</cfquery>

		<cfreturn {
			personal = personalConflicts,
			shared = sharedConflicts
		}>
	</cffunction>

	<cffunction name="transferOwnership" access="public" returntype="void">
		<cfargument name="eventId" type="numeric" required="true">
		<cfargument name="newOrganizerId" type="numeric" required="true">

		<cfquery datasource="polyculy">
			UPDATE polyculy.dbo.shared_events
			SET
				organizer_user_id = <cfqueryparam value="#arguments.newOrganizerId#" cfsqltype="cf_sql_integer">,
				ownership_transfer_active = FALSE,
				ownership_transfer_deadline = NULL,
				updated_at = CURRENT_TIMESTAMP
			WHERE shared_event_id = <cfqueryparam value="#arguments.eventId#" cfsqltype="cf_sql_integer">
		</cfquery>

		<!--- If new organizer was a pending participant, set them to accepted --->
		<cfquery datasource="polyculy">
			UPDATE polyculy.dbo.shared_event_participants
			SET
				response_status = 'accepted',
				updated_at = CURRENT_TIMESTAMP
			WHERE
				shared_event_id = <cfqueryparam value="#arguments.eventId#" cfsqltype="cf_sql_integer">
				AND user_id = <cfqueryparam value="#arguments.newOrganizerId#" cfsqltype="cf_sql_integer">
		</cfquery>
	</cffunction>

	<cffunction name="initiateOwnershipTransfer" access="public" returntype="void">
		<cfargument name="eventId" type="numeric" required="true">
		<cfargument name="deadline" type="string" required="true">

		<cfquery datasource="polyculy">
			UPDATE polyculy.dbo.shared_events
			SET
				ownership_transfer_active = TRUE,
				ownership_transfer_deadline = <cfqueryparam value="#arguments.deadline#" cfsqltype="cf_sql_timestamp">,
				updated_at = CURRENT_TIMESTAMP
			WHERE shared_event_id = <cfqueryparam value="#arguments.eventId#" cfsqltype="cf_sql_integer">
		</cfquery>
	</cffunction>

</cfcomponent>