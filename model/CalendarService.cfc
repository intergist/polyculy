<cfcomponent>

	<cffunction name="getCalendarData" access="public" returntype="any" output="false">
		<cfargument name="userId" type="numeric" required="true">
		<cfargument name="viewType" type="string" required="true">
		<cfargument name="startDate" type="string" required="true">
		<cfargument name="endDate" type="string" required="true">
		<cfargument name="mode" type="string" required="false" default="mine">
		<cfargument name="enabledUserIds" type="string" required="false" default="">

		<cfset var result = {
			personalEvents = [],
			sharedEvents = [],
			othersEvents = []
		}>

		<cfset var eventSvc = createObject("component", "model.EventService")>
		<cfset var sharedSvc = createObject("component", "model.SharedEventService")>
		<cfset var connSvc = createObject("component", "model.ConnectionService")>

		<!--- My personal events --->
		<cfset var myEvents = eventSvc.getPersonalEventsForUser(arguments.userId, arguments.startDate, arguments.endDate)>
		<cfloop query="myEvents">
			<cfset arrayAppend(result.personalEvents, {
				event_id = myEvents.event_id,
				title = myEvents.title,
				start_time = myEvents.start_time,
				end_time = myEvents.end_time,
				all_day = myEvents.all_day,
				type = "personal",
				owner = "me",
				owner_user_id = arguments.userId,
				visibility_tier = myEvents.visibility_tier
			})>
		</cfloop>

		<!--- My shared events --->
		<cfset var myShared = sharedSvc.getForUser(arguments.userId, arguments.startDate, arguments.endDate)>
		<cfloop query="myShared">
			<cfset arrayAppend(result.sharedEvents, {
				event_id = myShared.shared_event_id,
				title = myShared.title,
				start_time = myShared.start_time,
				end_time = myShared.end_time,
				all_day = myShared.all_day,
				type = "shared",
				global_state = myShared.global_state,
				response_status = myShared.response_status,
				organizer_name = myShared.organizer_name,
				organizer_user_id = myShared.organizer_user_id
			})>
		</cfloop>

		<!--- "Our" mode: include connected users' visible events --->
		<cfif arguments.mode EQ "our">
			<cfset var connectedUsers = connSvc.getConnectedUsers(arguments.userId)>
			<cfloop query="connectedUsers">
				<!--- Skip if not in enabled list (when filter is applied) --->
				<cfif len(arguments.enabledUserIds) AND NOT listFind(arguments.enabledUserIds, connectedUsers.user_id)>
					<cfcontinue>
				</cfif>

				<cfset var visibleEvents = eventSvc.getVisibleEventsForViewer(connectedUsers.user_id, arguments.userId, arguments.startDate, arguments.endDate)>
				<cfloop query="visibleEvents">
					<cfset arrayAppend(result.othersEvents, {
						event_id = visibleEvents.event_id,
						title = (visibleEvents.visibility_type EQ "busy_block" ? "Busy" : visibleEvents.title),
						start_time = visibleEvents.start_time,
						end_time = visibleEvents.end_time,
						all_day = visibleEvents.all_day,
						type = "personal",
						owner = (len(connectedUsers.nickname) ? connectedUsers.nickname : connectedUsers.display_name),
						owner_user_id = connectedUsers.user_id,
						visibility_type = visibleEvents.visibility_type,
						calendar_color = (len(connectedUsers.calendar_color) ? connectedUsers.calendar_color : "##7C3AED")
					})>
				</cfloop>
			</cfloop>
		</cfif>

		<cfreturn result>
	</cffunction>

	<cffunction name="getPolyculeMembers" access="public" returntype="any" output="false">
		<cfargument name="userId" type="numeric" required="true">

		<cfset var connSvc = createObject("component", "model.ConnectionService")>
		<cfset var members = []>
		<cfset var connected = connSvc.getConnectedUsers(arguments.userId)>

		<cfloop query="connected">
			<cfset arrayAppend(members, {
				user_id = connected.user_id,
				display_name = (len(connected.nickname) ? connected.nickname : connected.display_name),
				calendar_color = (len(connected.calendar_color) ? connected.calendar_color : "##7C3AED"),
				avatar_url = (len(connected.avatar_url) ? connected.avatar_url : "")
			})>
		</cfloop>

		<cfreturn members>
	</cffunction>

</cfcomponent>