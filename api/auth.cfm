<cfsetting showDebugOutput="false">
<cfheader name="Content-Type" value="application/json">

<cfset userSvc = createObject("component", "model.UserService")>
<cfset licSvc = createObject("component", "model.LicenceService")>
<cfset auditSvc = createObject("component", "model.AuditService")>

<cfparam name="url.action" default="login">
<cfparam name="form.action" default="">



<cfif len(form.action)>
	<cfset variables.action = form.action>
<cfelse>
	<cfset variables.action = url.action>
</cfif>

<cfset response = { "success" = true }>

<cftry>
<cfif variables.action EQ "login">

	<cfif NOT structKeyExists(form, "email") OR NOT structKeyExists(form, "password")>
		<cfset response = { "success" = false, "message" = "Email and password are required." }>
		<cfabort>
	</cfif>

	<cfset qUser = userSvc.authenticate(trim(form.email), form.password)>

	<cfif qUser.recordCount GT 0>
		<cfset session.isLoggedIn = true>
		<cfset session.userId = qUser.user_id>
		<cfset session.userEmail = qUser.email>
		<cfset session.displayName = qUser.display_name>
		<cfset session.timezoneId = qUser.timezone_id>
		<cfset session.calendarCreated = qUser.calendar_created>

		<cfset response["message"] = "Login successful.">
		<cfset response["user"] = {
				"userId" = qUser.user_id,
				"email" = qUser.email,
				"displayName" = qUser.display_name,
				"calendarCreated" = qUser.calendar_created
		}>
	<cfelse>
		<cfset response = { "success" = false, "message" = "Invalid email or password." }>
	</cfif>

<cfelseif variables.action EQ "signup">

		<cfif NOT structKeyExists(form, "email") OR NOT structKeyExists(form, "licenceCode") OR ( structKeyExists(form, "email") AND TRIM(form.email) EQ "" ) OR ( structKeyExists(form, "licenceCode") AND TRIM(form.licenceCode) EQ ""  )>
			<cfset response = { "success" = false, "message" = "Email and license code are required." }>
			<cfabort>
		</cfif>
		
		<cfif isDefined("url.email") AND url.email NEQ "">
			<cfset variables.email = trim(url.email)>
		<cfelse>
			<cfset variables.email = trim(form.email)>
		</cfif>

		<cfif isDefined("url.code") AND url.code NEQ "">
			<cfset variables.code = trim(url.code)>
		<cfelse>
			<cfset variables.code = trim(form.licenceCode)>
		</cfif>
		
		<cfset qExistingUser = userSvc.getByEmail(email)>
		
		<cfif qExistingUser.recordCount GT 0>
			<cfset response = { "success" = false, "message" = "An account with this email already exists." }>
			<cfabort>
		</cfif>

		<cfset qLicense = licSvc.validateCode(variables.code)>
	
		
		<cfif qLicense.recordCount EQ 0>
			<cfset response = { "success" = false, "message" = "Invalid or already redeemed license code." }>
			<cfabort>
		</cfif>

		<cfif qLicense.status EQ "gifted_pending" AND len(licence.gifted_to_email) AND licence.gifted_to_email NEQ email>
			<cfset response = { "success" = false, "message" = "This license code was gifted to a different email address." }>
			<cfabort>
		</cfif>

		<cfset response["step"] = "set_password">
		<cfset response["email"] = email>
		<cfset response["licenceCode"] = code>
		
	<cfelseif variables.action EQ "completeSignup">

		<cfif NOT structKeyExists(form, "email") OR NOT structKeyExists(form, "password") OR NOT structKeyExists(form, "licenceCode") OR NOT structKeyExists(form, "displayName")>
			<cfset response = { "success" = false, "message" = "All fields are required." }>
			<cfabort>
		</cfif>

		<cfset email = trim(form.email)>
		<cfset password = form.password>
		<cfset code = trim(form.licenceCode)>
		<cfset displayName = trim(form.displayName)>

		<cfif len(password) LT 6>
			<cfset response = { "success" = false, "message" = "Password must be at least 6 characters." }>
			<cfabort>
		</cfif>

		<cfset newUserId = userSvc.create(email, password, displayName)>
		<cfset licSvc.redeemCode(code, newUserId)>

		<cfquery datasource="#application.datasource#">
			UPDATE polyculy.dbo.connections
			SET user_id_2 = <cfqueryparam value="#newUserId#" cfsqltype="cf_sql_integer">,
					status = 'awaiting_confirmation',
					updated_at = CURRENT_TIMESTAMP
			WHERE invited_email = <cfqueryparam value="#email#" cfsqltype="cf_sql_varchar">
				AND status IN ('awaiting_signup', 'licence_gifted_awaiting_signup')
		</cfquery>

		<cfset auditSvc.log("user_signup", "user", newUserId, "New user signed up: #displayName#", newUserId)>

		<cfset session.isLoggedIn = true>
		<cfset session.userId = newUserId>
		<cfset session.userEmail = email>
		<cfset session.displayName = displayName>
		<cfset session.timezoneId = "America/New_York">
		<cfset session.calendarCreated = false>

		<cfset response["message"] = "Account created successfully.">
		<cfset response["userId"] = newUserId>

    <cfelseif variables.action EQ "logout">

			<cfset structClear(session)>
			<cfset session.isLoggedIn = false>
			<cfset response["message"] = "Logged out.">

    <cfelseif variables.action EQ "recovery">
			<!---todo: recovery routine  --->
			<cfset response["message"] = "If this email exists, a recovery link has been sent.">

    <cfelse>
			<cfset response = { "success" = false, "message" = "Unknown action: #variables.action#" }>
    </cfif>

 	<cfcatch type="any">
  	<cfset response = { "success" = false, "message" = cfcatch.message }>
  </cfcatch>
</cftry>

<cfoutput>#serializeJSON(response)#</cfoutput>