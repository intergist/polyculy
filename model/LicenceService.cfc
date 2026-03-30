<cfcomponent>

	<cffunction name="validateCode" access="public" returntype="query">
		<cfargument name="licenceCode" type="string" required="true">

		<cfset var qLicense = "">

		<cfquery name="qLicense" datasource="#application.datasource#">
			SELECT	licence_id, licence_code, licence_type, status, gifted_to_email
			FROM		polyculy.dbo.licences
			WHERE	licence_code = <cfqueryparam value="#arguments.licenceCode#" cfsqltype="cf_sql_varchar">
						AND status IN ('available','gifted_pending')
		</cfquery>

		<cfreturn qLicense>
	</cffunction>

	<cffunction name="redeemCode" access="public" returntype="void">
		<cfargument name="licenceCode" type="string" required="true">
		<cfargument name="userId" type="numeric" required="true">

		<cfquery datasource="polyculy">
			UPDATE polyculy.dbo.licences
			SET
				redeemed_by_user_id = <cfqueryparam value="#arguments.userId#" cfsqltype="cf_sql_integer">,
				status = 'redeemed',
				redeemed_at = CURRENT_TIMESTAMP
			WHERE
				licence_code = <cfqueryparam value="#arguments.licenceCode#" cfsqltype="cf_sql_varchar">
				AND status IN ('available','gifted_pending')
		</cfquery>
	</cffunction>

	<cffunction name="giftLicence" access="public" returntype="struct">
		<cfargument name="fromUserId" type="numeric" required="true">
		<cfargument name="toEmail" type="string" required="true">
		<cfargument name="licenceCode" type="string" required="true">

		<cfset var existing = "">

		<!--- Check if already gifted to this email --->
		<cfquery name="existing" datasource="polyculy">
			SELECT licence_id
			FROM polyculy.dbo.licences
			WHERE
				gifted_to_email = <cfqueryparam value="#arguments.toEmail#" cfsqltype="cf_sql_varchar">
				AND status = 'gifted_pending'
		</cfquery>

		<cfif existing.recordCount GT 0>
			<cfreturn { success = false, message = "A license has already been gifted to this person." }>
		</cfif>

		<cfquery datasource="polyculy">
			INSERT INTO polyculy.dbo.licences
				(licence_code, licence_type, gifted_to_email, gifted_by_user_id, status)
			VALUES
				(
					<cfqueryparam value="#arguments.licenceCode#" cfsqltype="cf_sql_varchar">,
					'gifted',
					<cfqueryparam value="#arguments.toEmail#" cfsqltype="cf_sql_varchar">,
					<cfqueryparam value="#arguments.fromUserId#" cfsqltype="cf_sql_integer">,
					'gifted_pending'
				)
		</cfquery>

		<cfreturn { success = true, message = "License gifted successfully." }>
	</cffunction>

	<cffunction name="isGiftedTo" access="public" returntype="boolean">
		<cfargument name="email" type="string" required="true">

		<cfset var q = "">

		<cfquery name="q" datasource="polyculy">
			SELECT licence_id
			FROM polyculy.dbo.licences
			WHERE
				gifted_to_email = <cfqueryparam value="#arguments.email#" cfsqltype="cf_sql_varchar">
				AND status = 'gifted_pending'
		</cfquery>

		<cfreturn q.recordCount GT 0>
	</cffunction>

	<cffunction name="getByUser" access="public" returntype="query">
		<cfargument name="userId" type="numeric" required="true">

		<cfset var q = "">

		<cfquery name="q" datasource="polyculy">
			SELECT l.*, u.display_name AS gifted_by_name
			FROM polyculy.dbo.licences l
				LEFT JOIN polyculy.dbo.users u ON l.gifted_by_user_id = u.user_id
			WHERE
				l.redeemed_by_user_id = <cfqueryparam value="#arguments.userId#" cfsqltype="cf_sql_integer">
				OR l.gifted_by_user_id = <cfqueryparam value="#arguments.userId#" cfsqltype="cf_sql_integer">
			ORDER BY l.created_at DESC
		</cfquery>

		<cfreturn q>
	</cffunction>

	<!--- Alias used by licences.cfm API handler --->
	<cffunction name="validate" access="public" returntype="query">
		<cfargument name="code" type="string" required="true">
		<cfreturn validateCode(arguments.code)>
	</cffunction>

	<!--- Get available (unredeemed, ungifted) licences for a user to gift --->
	<cffunction name="getAvailableForUser" access="public" returntype="query">
		<cfargument name="userId" type="numeric" required="true">

		<cfset var q = "">

		<cfquery name="q" datasource="polyculy">
			SELECT licence_id, licence_code, licence_type, status, created_at
			FROM polyculy.dbo.licences
			WHERE status = 'available'
			ORDER BY created_at DESC
		</cfquery>

		<cfreturn q>
	</cffunction>

</cfcomponent>