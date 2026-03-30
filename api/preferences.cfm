<cfsetting showDebugOutput="false">
<cfheader name="Content-Type" value="application/json">

<cfset userSvc = createObject("component", "model.UserService")>
<cfset connSvc = createObject("component", "model.ConnectionService")>
<cfset action = structKeyExists(url, "action") AND len(url.action) ? url.action : "get">
<cfset response = { "success" = true }>

<cftry>
	<cfswitch expression="#action#">
		<cfcase value="get">
			<cfset user = userSvc.getById(session.userId)>
			<cfif user.recordCount>
				<cfset response["data"] = {
					"userId" = user.user_id,
					"email" = user.email,
					"displayName" = user.display_name,
					"timezoneId" = user.timezone_id,
					"calendarCreated" = user.calendar_created
				}>
			</cfif>
		</cfcase>

		<cfcase value="saveTimezone">
			<cfif NOT structKeyExists(form, "timezoneId")>
				<cfset response = { "success" = false, "message" = "Timezone required." }>
			<cfelse>
				<cfset userSvc.updateTimezone(session.userId, form.timezoneId)>
				<cfset session.timezoneId = form.timezoneId>
				<cfset response["message"] = "Timezone updated.">
			</cfif>
		</cfcase>

		<cfcase value="saveDisplayPrefs">
			<cfif structKeyExists(form, "targetUserId")>
				<cfset connSvc.updateDisplayPrefs(
					session.userId,
					form.targetUserId,
					structKeyExists(form, "nickname") ? form.nickname : "",
					structKeyExists(form, "avatarOverride") ? form.avatarOverride : "",
					structKeyExists(form, "calendarColor") ? form.calendarColor : ""
				)>
				<cfset response["message"] = "Display preferences saved.">
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