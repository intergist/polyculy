<cfsetting showDebugOutput="false">
<cfheader name="Content-Type" value="application/json">

<cfset eventSvc = createObject("component", "model.EventService")>
<cfset seSvc    = createObject("component", "model.SharedEventService")>
<cfset connSvc  = createObject("component", "model.ConnectionService")>
<cfset userSvc  = createObject("component", "model.UserService")>

<cfset action   = structKeyExists(url, "action") AND len(url.action) ? url.action : "events">
<cfset response = { "success" = true }>

<cftry>

	<cfswitch expression="#action#">

		<cfcase value="events">
			<cfset startDate = structKeyExists(url, "startDate") ? url.startDate : "">
			<cfset endDate   = structKeyExists(url, "endDate")   ? url.endDate   : "">

			<cfset qPersonalEvents = eventSvc.getPersonalEventsForUser(session.userId, startDate, endDate)>
			<cfset sharedEvents   = seSvc.getEventsForUser(session.userId, startDate, endDate)>

			<cfset allEvents = []>

			<!--- Personal events --->
			<cfloop query="qPersonalEvents">
					<cfset rowStruct = {
							"id"            = qPersonalEvents.event_id,
							"type"          = "personal",
							"title"         = qPersonalEvents.title,
							"start"         = DateTimeFormat(qPersonalEvents.start_time, "yyyy-MM-dd'T'HH:nn:ss"),
							"end"           = isNull(qPersonalEvents.end_time) ? "" : dateTimeFormat(qPersonalEvents.end_time, "yyyy-MM-dd'T'HH:nn:ss"),
							"allDay"        = qPersonalEvents.all_day,
							"details"       = isNull(qPersonalEvents.event_details) ? "" : qPersonalEvents.event_details,
							"address"       = isNull(qPersonalEvents.address) ? "" : qPersonalEvents.address,
							"visibilityTier"= qPersonalEvents.visibility_tier,
							"isBlocking"    = true,
							"ownerUserId"   = qPersonalEvents.owner_user_id,
							"state"         = "active"
					}>
					<cfset arrayAppend(allEvents, rowStruct)>
			</cfloop>

			<!--- Shared events --->
			<cfloop query="sharedEvents">
					<cfset isOrganizer = ( sharedEvents.response_status EQ "organizer" OR sharedEvents.organizer_user_id EQ session.userId )>
					<cfset isAccepted  = ( sharedEvents.response_status EQ "accepted" OR isOrganizer )>

					<cfset rowStruct = {
							"id"              = sharedEvents.shared_event_id,
							"type"            = "shared",
							"title"           = sharedEvents.title,
							"start"           = dateTimeFormat(sharedEvents.start_time, "yyyy-MM-dd'T'HH:nn:ss"),
							"end"             = isNull(sharedEvents.end_time) ? "" : dateTimeFormat(sharedEvents.end_time, "yyyy-MM-dd'T'HH:nn:ss"),
							"allDay"          = sharedEvents.all_day,
							"details"         = isNull(sharedEvents.event_details) ? "" : sharedEvents.event_details,
							"address"         = isNull(sharedEvents.address) ? "" : sharedEvents.address,
							"organizer"       = sharedEvents.organizer_name,
							"organizerId"     = sharedEvents.organizer_user_id,
							"responseStatus"  = sharedEvents.response_status,
							"isBlocking"      = isAccepted,
							"state"           = sharedEvents.global_state,
							"participantCount"= isNull(sharedEvents.participant_count) ? 0 : sharedEvents.participant_count,
							"isOrganizer"     = isOrganizer
					}>
					<cfset arrayAppend(allEvents, rowStruct)>
			</cfloop>

			<cfset response["data"] = allEvents>
		</cfcase>

		<cfcase value="overlay">
				<cfset startDate = structKeyExists(url, "startDate") ? url.startDate : "">
				<cfset endDate   = structKeyExists(url, "endDate")   ? url.endDate   : "">

				<cfset connected = connSvc.getConnectedUsers(session.userId)>
				<cfset overlayEvents = []>

				<cfloop query="connected">
						<cfset visibleEvents = eventSvc.getVisibleEventsForViewer(
								session.userId,
								connected.other_user_id,
								startDate,
								endDate
						)>

						<cfloop query="visibleEvents">
								<cfset titleVal   = visibleEvents.visibility_type EQ "full_details" ? visibleEvents.title : "Busy">
								<cfset detailsVal = visibleEvents.visibility_type EQ "full_details" ? ( isNull(visibleEvents.event_details) ? "" : visibleEvents.event_details ) : "">

								<cfset rowStruct = {
										"id"             = visibleEvents.event_id,
										"type"           = "personal_overlay",
										"title"          = titleVal,
										"start"          = dateTimeFormat(visibleEvents.start_time, "yyyy-MM-dd'T'HH:nn:ss"),
										"end"            = isNull(visibleEvents.end_time) ? "" : dateTimeFormat(visibleEvents.end_time, "yyyy-MM-dd'T'HH:nn:ss"),
										"allDay"         = visibleEvents.all_day,
										"details"        = detailsVal,
										"visibilityType" = visibleEvents.visibility_type,
										"ownerUserId"    = visibleEvents.owner_user_id,
										"ownerName"      = visibleEvents.owner_name,
										"calendarColor"  = isNull(connected.calendar_color) OR NOT len(trim(connected.calendar_color)) ? "##7C3AED" : connected.calendar_color
								}>
								<cfset arrayAppend(overlayEvents, rowStruct)>
						</cfloop>
				</cfloop>

				<cfset response["data"] = overlayEvents>
		</cfcase>
	
		<cfcase value="setup">
			<cfif NOT structKeyExists(form, "method")>
				<cfset response = { "success" = false, "message" = "Setup method required." }>
			<cfelse>
				<cfset userSvc.setCalendarCreated(session.userId)>
				<cfset session.calendarCreated = true>
				<cfset response["message"] = "Calendar created.">
			</cfif>
		</cfcase>
	
		<cfcase value="toggleState">
				<cfif structKeyExists(form, "targetUserId") AND structKeyExists(form, "isVisible")>
						<cfset existing = queryExecute(
								"SELECT toggle_id FROM polyculy.dbo.calendar_toggle_state WHERE user_id = :uid AND target_user_id = :tid",
								{
										uid = { value = session.userId, cfsqltype = "cf_sql_integer" },
										tid = { value = form.targetUserId, cfsqltype = "cf_sql_integer" }
								}
						)>

						<cfif existing.recordCount GT 0>
								<cfset queryExecute(
										"UPDATE polyculy.dbo.calendar_toggle_state SET is_visible = :vis WHERE toggle_id = :tid",
										{
												tid = { value = existing.toggle_id, cfsqltype = "cf_sql_integer" },
												vis = { value = form.isVisible, cfsqltype = "cf_sql_bit" }
										}
								)>
						<cfelse>
								<cfset queryExecute(
										"INSERT INTO polyculy.dbo.calendar_toggle_state (user_id, target_user_id, is_visible) VALUES (:uid, :tid, :vis)",
										{
												uid = { value = session.userId, cfsqltype = "cf_sql_integer" },
												tid = { value = form.targetUserId, cfsqltype = "cf_sql_integer" },
												vis = { value = form.isVisible, cfsqltype = "cf_sql_bit" }
										}
								)>
						</cfif>

						<cfset response["message"] = "Toggle state saved.">
				<cfelse>
						<cfset q = queryExecute(
								"SELECT target_user_id, is_visible FROM polyculy.dbo.calendar_toggle_state WHERE user_id = :uid",
								{ uid = { value = session.userId, cfsqltype = "cf_sql_integer" } }
						)>

						<cfset states = {}>

						<cfloop query="q">
								<cfset states[q.target_user_id] = q.is_visible>
						</cfloop>

						<cfset response["data"] = states>
				</cfif>
		</cfcase>

		<cfdefaultcase>
				<cfset response = { "success" = false, "message" = "Unknown action: #action#" }>
		</cfdefaultcase>
	
	</cfswitch>
	
	<cfcatch type="any">
			<cfset response = { "success" = false, "message" = cfcatch.message }>
	</cfcatch>

</cftry>

<cfoutput>#serializeJSON(response)#</cfoutput>