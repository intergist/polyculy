<cfsetting showDebugOutput="false">
<cfheader name="Content-Type" value="application/json">

<cfset licSvc = createObject("component", "model.LicenceService")>
<cfset auditSvc = createObject("component", "model.AuditService")>
<cfset notifSvc = createObject("component", "model.NotificationService")>

<cfset action = structKeyExists(url, "action") AND len(url.action) ? url.action : "list">
<cfset response = { "success" = true }>

<cftry>
	<cfswitch expression="#action#">
		<cfcase value="list">
			<cfset q = licSvc.getByUser(session.userId)>
			<cfset data = []>
			<cfloop query="q">
				<cfset arrayAppend(data, q[currentRow])>
			</cfloop>
			<cfset response["data"] = data>
		</cfcase>

		<cfcase value="validate">
			<cfset rawCode = "">
			<cfif structKeyExists(url, "code") AND len(url.code)>
				<cfset rawCode = url.code>
			<cfelseif structKeyExists(form, "code") AND len(form.code)>
				<cfset rawCode = form.code>
			</cfif>
			<cfset q = licSvc.validate(rawCode)>
			<cfset response["data"] = { "valid" = q.recordCount GT 0 }>
			<cfif q.recordCount>
				<cfset response["data"]["licence_type"] = q.licence_type>
			</cfif>
		</cfcase>

		<cfcase value="gift">
			<cfset licSvc.giftLicence(session.userId, form.to_email, form.licence_code)>
			<cfset auditSvc.log(
				session.userId,
				"licence_gift",
				"licence",
				0,
				"Gifted license #form.licence_code# to #form.to_email#"
			)>
			<cfset notifSvc.create(
				session.userId,
				"licence_gifted",
				"License Gifted",
				"You gifted a license to #form.to_email#.",
				"licence",
				0
			)>
			<cfset response["message"] = "License gifted successfully">
		</cfcase>

		<cfcase value="available">
			<cfset q = licSvc.getAvailableForUser(session.userId)>
			<cfset data = []>
			<cfloop query="q">
				<cfset arrayAppend(data, q[currentRow])>
			</cfloop>
			<cfset response["data"] = data>
		</cfcase>

		<cfdefaultcase>
			<cfset response = { "success" = false, "message" = "Unknown action" }>
		</cfdefaultcase>
	</cfswitch>

	<cfcatch type="any">
		<cfset response = { "success" = false, "message" = cfcatch.message }>
	</cfcatch>
</cftry>

<cfoutput>#serializeJSON(response)#</cfoutput>