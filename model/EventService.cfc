<cfcomponent>

	<cffunction name="createPersonalEvent" access="public" returntype="any">
		<cfargument name="data" type="struct" required="true">

		<cfset var qResult = "">

		<cfquery datasource="polyculy" result="qResult">
			INSERT INTO polyculy.dbo.personal_events
				(owner_user_id, title, start_time, end_time, all_day, timezone_id, event_details, address, reminder_minutes, visibility_tier)
			VALUES
				(
					<cfqueryparam value="#arguments.data.userId#" cfsqltype="cf_sql_integer">,
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
					<cfqueryparam value="#(arguments.data.visibilityTier ?: 'invisible')#" cfsqltype="cf_sql_varchar">
				)
		</cfquery>

		<cfreturn listFirst(qResult.generatedKey)>
	</cffunction>

	<cffunction name="updatePersonalEvent" access="public" returntype="void">
		<cfargument name="eventId" type="numeric" required="true">
		<cfargument name="data" type="struct" required="true">

		<cfquery datasource="polyculy">
			UPDATE polyculy.dbo.personal_events
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
				visibility_tier = <cfqueryparam value="#(arguments.data.visibilityTier ?: 'invisible')#" cfsqltype="cf_sql_varchar">,
				updated_at = CURRENT_TIMESTAMP
			WHERE
				event_id = <cfqueryparam value="#arguments.eventId#" cfsqltype="cf_sql_integer">
				AND owner_user_id = <cfqueryparam value="#arguments.data.userId#" cfsqltype="cf_sql_integer">
		</cfquery>
	</cffunction>

	<cffunction name="deletePersonalEvent" access="public" returntype="void">
		<cfargument name="eventId" type="numeric" required="true">
		<cfargument name="userId" type="numeric" required="true">

		<!--- Clear visibility records --->
		<cfquery datasource="polyculy">
			DELETE FROM polyculy.dbo.personal_event_visibility
			WHERE event_id = <cfqueryparam value="#arguments.eventId#" cfsqltype="cf_sql_integer">
		</cfquery>

		<!--- Cancel event --->
		<cfquery datasource="polyculy">
			UPDATE polyculy.dbo.personal_events
			SET is_cancelled = TRUE,
			    updated_at = CURRENT_TIMESTAMP
			WHERE
				event_id = <cfqueryparam value="#arguments.eventId#" cfsqltype="cf_sql_integer">
				AND owner_user_id = <cfqueryparam value="#arguments.userId#" cfsqltype="cf_sql_integer">
		</cfquery>
	</cffunction>

	<cffunction name="getPersonalEvent" access="public" returntype="query">
		<cfargument name="eventId" type="numeric" required="true">

		<cfquery name="qEvent" datasource="polyculy">
			SELECT e.*, u.display_name AS owner_name
			FROM polyculy.dbo.personal_events e
				JOIN polyculy.dbo.users u ON e.owner_user_id = u.user_id
			WHERE
				e.event_id = <cfqueryparam value="#arguments.eventId#" cfsqltype="cf_sql_integer">
				AND e.is_cancelled = FALSE
		</cfquery>

		<cfreturn qEvent>
	</cffunction>

	<cffunction name="getPersonalEventsForUser" access="public" returntype="query">
		<cfargument name="userId" type="numeric" required="true">
		<cfargument name="startDate" type="string" required="false" default="">
		<cfargument name="endDate" type="string" required="false" default="">

		<cfquery name="qPersonalEventsForUser" datasource="#application.datasource#">
			SELECT 	e.*, u.display_name AS owner_name
			FROM 		polyculy.dbo.personal_events e
							JOIN polyculy.dbo.users u ON e.owner_user_id = u.user_id
			WHERE		e.owner_user_id = <cfqueryparam value="#arguments.userId#" cfsqltype="cf_sql_integer">
			 				AND isNull(e.is_cancelled, 0) = 0
							<cfif len(arguments.startDate) AND isDate(arguments.startDate)>
								AND e.start_time >= <cfqueryparam value="#arguments.startDate#" cfsqltype="cf_sql_timestamp">
							</cfif>
							<cfif len(arguments.endDate) AND isDate(arguments.endDate)>
								AND e.start_time <= <cfqueryparam value="#arguments.endDate#" cfsqltype="cf_sql_timestamp">
							</cfif>
							ORDER BY e.start_time							
		</cfquery>
		
		<cfreturn qPersonalEventsForUser>
	</cffunction>

	<cffunction name="getVisibleEventsForViewer" access="public" returntype="query">
		<cfargument name="viewerUserId" type="numeric" required="true">
		<cfargument name="ownerUserId" type="numeric" required="true">
		<cfargument name="startDate" type="string" required="false" default="">
		<cfargument name="endDate" type="string" required="false" default="">

		<cfset var q = "">

		<cfquery name="q" datasource="polyculy">
			SELECT
				e.event_id, e.title, e.start_time, e.end_time, e.all_day, e.timezone_id,
				e.event_details, e.address, e.owner_user_id, v.visibility_type,
				u.display_name AS owner_name
			FROM polyculy.dbo.personal_events e
				JOIN polyculy.dbo.personal_event_visibility v ON e.event_id = v.event_id
				JOIN polyculy.dbo.users u ON e.owner_user_id = u.user_id
			WHERE
				v.target_user_id = <cfqueryparam value="#arguments.viewerUserId#" cfsqltype="cf_sql_integer">
				AND e.owner_user_id = <cfqueryparam value="#arguments.ownerUserId#" cfsqltype="cf_sql_integer">
				AND e.is_cancelled = FALSE
			<cfif len(arguments.startDate)>
				AND e.start_time >= <cfqueryparam value="#arguments.startDate#" cfsqltype="cf_sql_timestamp">
			</cfif>
			<cfif len(arguments.endDate)>
				AND e.start_time <= <cfqueryparam value="#arguments.endDate#" cfsqltype="cf_sql_timestamp">
			</cfif>
			ORDER BY e.start_time
		</cfquery>

		<cfreturn q>
	</cffunction>

	<cffunction name="setVisibility" access="public" returntype="void">
		<cfargument name="eventId" type="numeric" required="true">
		<cfargument name="tier" type="string" required="true">
		<cfargument name="fullDetailUsers" type="array" required="false" default="#[]#">
		<cfargument name="busyBlockUsers" type="array" required="false" default="#[]#">

		<!--- Clear existing visibility records --->
		<cfquery datasource="polyculy">
			DELETE FROM polyculy.dbo.personal_event_visibility
			WHERE event_id = <cfqueryparam value="#arguments.eventId#" cfsqltype="cf_sql_integer">
		</cfquery>

		<!--- Update the tier on the event itself --->
		<cfquery datasource="polyculy">
			UPDATE polyculy.dbo.personal_events
			SET visibility_tier = <cfqueryparam value="#arguments.tier#" cfsqltype="cf_sql_varchar">,
			    updated_at = CURRENT_TIMESTAMP
			WHERE event_id = <cfqueryparam value="#arguments.eventId#" cfsqltype="cf_sql_integer">
		</cfquery>

		<cfif arguments.tier EQ "invisible">
			<cfreturn>
		</cfif>

		<!--- Insert full-details visibility records --->
		<cfloop array="#arguments.fullDetailUsers#" index="uid">
			<cfquery datasource="polyculy">
				INSERT INTO polyculy.dbo.personal_event_visibility
					(event_id, target_user_id, visibility_type)
				VALUES
					(
						<cfqueryparam value="#arguments.eventId#" cfsqltype="cf_sql_integer">,
						<cfqueryparam value="#uid#" cfsqltype="cf_sql_integer">,
						'full_details'
					)
			</cfquery>
		</cfloop>

		<!--- Insert busy-block visibility records --->
		<cfloop array="#arguments.busyBlockUsers#" index="uid">
			<cfquery datasource="polyculy">
				INSERT INTO polyculy.dbo.personal_event_visibility
					(event_id, target_user_id, visibility_type)
				VALUES
					(
						<cfqueryparam value="#arguments.eventId#" cfsqltype="cf_sql_integer">,
						<cfqueryparam value="#uid#" cfsqltype="cf_sql_integer">,
						'busy_block'
					)
			</cfquery>
		</cfloop>
	</cffunction>

	<cffunction name="getVisibilityRecords" access="public" returntype="query">
		<cfargument name="eventId" type="numeric" required="true">

		<cfquery name="q" datasource="polyculy">
			SELECT v.*, u.display_name
			FROM polyculy.dbo.personal_event_visibility v
				JOIN polyculy.dbo.users u ON v.target_user_id = u.user_id
			WHERE v.event_id = <cfqueryparam value="#arguments.eventId#" cfsqltype="cf_sql_integer">
		</cfquery>

		<cfreturn q>
	</cffunction>

</cfcomponent>