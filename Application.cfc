<cfcomponent>
	
	<cfset this.name = "Polyculy">
	<cfset this.applicationTimeout = createTimeSpan(1, 0, 0, 0)>
	<cfset this.sessionManagement = true>
	<cfset this.sessionTimeout = createTimeSpan(0, 2, 0, 0)>
	<cfset this.datasource = "polyculy">
	
	<!--- Mappings --->
	<cfset this.mappings["/components"] = getDirectoryFromPath(getCurrentTemplatePath()) & "components">
	<cfset this.mappings["/model"]      = getDirectoryFromPath(getCurrentTemplatePath()) & "model">
	<cfset this.mappings["/api"]        = getDirectoryFromPath(getCurrentTemplatePath()) & "api">
	
	<!--- Custom tag paths for layout --->
	<cfset this.customTagPaths = getDirectoryFromPath(getCurrentTemplatePath()) & "views/layouts">
	
	<cffunction name="onApplicationStart" returntype="boolean" output="false">
		<cfset application.datasource = "polyculy">
		<cfset var dbInit = createObject("component", "components.DatabaseInit")>
		<cfset dbInit.initialize()>
		<cfreturn true>
	</cffunction>
	
	<cffunction name="onSessionStart" output="false">
		<cfset session.isLoggedIn = false>
		<cfset session.userId = 0>
		<cfset session.userEmail = "">
		<cfset session.displayName = "">
		<cfset session.csrfToken = hash(createUUID() & now(), "SHA-256")>
	</cffunction>
	
	<cffunction name="onRequestStart" returntype="boolean" output="false">
		<cfargument name="targetPage" type="string" required="true">

		<!--- Allow reinit via URL param --->
		<cfif structKeyExists(url, "reinit")>
			<cfset onApplicationStart()>
		</cfif>

		<!--- Determine if this is a public page (no auth required) --->
		<cfset local.publicPages = ["/index.cfm", "/views/auth/login.cfm",  "/views/auth/signup.cfm", "/views/auth/recovery.cfm", "test.cfm"]>
		<cfset local.publicAPIs = ["/api/auth.cfm", "/api/reset-seed.cfm"]>
		<cfset local.requestedPage = arguments.targetPage>
		<cfset local.isPublic = false>

		<cfloop array="#local.publicPages#" index="pg">
			<cfif local.requestedPage contains pg>
				<cfset local.isPublic = true>
				<cfbreak>
			</cfif>
		</cfloop>

		<cfloop array="#local.publicAPIs#" index="pg">
			<cfif requestedPage contains pg>
				<cfset local.isPublic = true>
				<cfbreak>
			</cfif>
		</cfloop>

		<!--- Redirect to login if not authenticated and not on public page --->
		<cfif NOT local.isPublic AND (NOT structKeyExists(session, "isLoggedIn") OR NOT session.isLoggedIn)>
			<cflocation url="/index.cfm" addtoken="false">
			<cfreturn false>
		</cfif>

		<cfreturn true>
	</cffunction>
	

<!--- 	<cffunction name="onError" output="false">
		<cfargument name="exception" required="true">
		<cfargument name="eventName" required="true">
	
		<cfif structKeyExists(url, "format") AND url.format EQ "json">
			<cfheader name="Content-Type" value="application/json">
			<cfoutput>#serializeJSON({ "success": false, "message": exception.message & " " & exception.Detail })#</cfoutput>
		<cfelse>
			<cfinclude template="/views/auth/login.cfm">
		</cfif>
	</cffunction> --->


</cfcomponent>