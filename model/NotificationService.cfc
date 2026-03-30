<cfcomponent>

	<cffunction name="create" access="public" returntype="void">
		<cfargument name="userId" type="numeric" required="true">
		<cfargument name="notificationType" type="string" required="true">
		<cfargument name="title" type="string" required="true">
		<cfargument name="message" type="string" required="true">
		<cfargument name="entityType" type="string" required="false" default="">
		<cfargument name="entityId" type="numeric" required="false" default="0">

		<cfquery datasource="polyculy">
			INSERT INTO polyculy.dbo.notifications
				(user_id, notification_type, title, message, related_entity_type, related_entity_id)
			VALUES
				(
					<cfqueryparam value="#arguments.userId#" cfsqltype="cf_sql_integer">,
					<cfqueryparam value="#arguments.notificationType#" cfsqltype="cf_sql_varchar">,
					<cfqueryparam value="#arguments.title#" cfsqltype="cf_sql_varchar">,
					<cfqueryparam value="#arguments.message#" cfsqltype="cf_sql_varchar">,
					<cfif len(arguments.entityType)>
						<cfqueryparam value="#arguments.entityType#" cfsqltype="cf_sql_varchar">
					<cfelse>
						<cfqueryparam null="true" cfsqltype="cf_sql_varchar">
					</cfif>,
					<cfif arguments.entityId EQ 0>
						<cfqueryparam null="true" cfsqltype="cf_sql_integer">
					<cfelse>
						<cfqueryparam value="#arguments.entityId#" cfsqltype="cf_sql_integer">
					</cfif>
				)
		</cfquery>
	</cffunction>

	<cffunction name="getUnreadCount" access="public" returntype="numeric">
		<cfargument name="userId" type="numeric" required="true">

		<cfset var q = "">

		<cfquery name="q" datasource="polyculy">
			SELECT COUNT(*) AS cnt
			FROM polyculy.dbo.notifications
			WHERE
				user_id = <cfqueryparam value="#arguments.userId#" cfsqltype="cf_sql_integer">
				AND isNull(is_read,0) = 0
		</cfquery>

		<cfreturn q.cnt>
	</cffunction>

	<cffunction name="getRecent" access="public" returntype="query">
		<cfargument name="userId" type="numeric" required="true">
		<cfargument name="limit" type="numeric" required="false" default="20">

		<cfset var q = "">

		<cfquery name="q" datasource="polyculy">
			SELECT TOP(<cfqueryparam value="#arguments.limit#" cfsqltype="cf_sql_integer">) *
			FROM polyculy.dbo.notifications
			WHERE user_id = <cfqueryparam value="#arguments.userId#" cfsqltype="cf_sql_integer">
			ORDER BY created_at DESC
		</cfquery>

		<cfreturn q>
	</cffunction>

	<cffunction name="markAsRead" access="public" returntype="void">
		<cfargument name="notificationId" type="numeric" required="true">
		<cfargument name="userId" type="numeric" required="true">

		<cfquery datasource="polyculy">
			UPDATE polyculy.dbo.notifications
			SET is_read = TRUE
			WHERE
				notification_id = <cfqueryparam value="#arguments.notificationId#" cfsqltype="cf_sql_integer">
				AND user_id = <cfqueryparam value="#arguments.userId#" cfsqltype="cf_sql_integer">
		</cfquery>
	</cffunction>

	<cffunction name="markAllAsRead" access="public" returntype="void">
		<cfargument name="userId" type="numeric" required="true">

		<cfquery datasource="polyculy">
			UPDATE polyculy.dbo.notifications
			SET is_read = TRUE
			WHERE
				user_id = <cfqueryparam value="#arguments.userId#" cfsqltype="cf_sql_integer">
				AND is_read = FALSE
		</cfquery>
	</cffunction>

	<cffunction name="getPreferences" access="public" returntype="query">
		<cfargument name="userId" type="numeric" required="true">

		<cfset var q = "">

		<cfquery name="q" datasource="polyculy">
			SELECT *
			FROM polyculy.dbo.notification_preferences
			WHERE user_id = <cfqueryparam value="#arguments.userId#" cfsqltype="cf_sql_integer">
		</cfquery>

		<cfreturn q>
	</cffunction>

	<cffunction name="savePreference" access="public" returntype="void">
		<cfargument name="userId" type="numeric" required="true">
		<cfargument name="notificationType" type="string" required="true">
		<cfargument name="isEnabled" type="boolean" required="false" default="true">
		<cfargument name="deliveryMode" type="string" required="false" default="instant">
		<cfargument name="quietStart" type="string" required="false" default="">
		<cfargument name="quietEnd" type="string" required="false" default="">

		<cfset var existing = "">

		<cfquery name="existing" datasource="polyculy">
			SELECT pref_id
			FROM polyculy.dbo.notification_preferences
			WHERE
				user_id = <cfqueryparam value="#arguments.userId#" cfsqltype="cf_sql_integer">
				AND notification_type = <cfqueryparam value="#arguments.notificationType#" cfsqltype="cf_sql_varchar">
		</cfquery>

		<cfif existing.recordCount GT 0>
			<cfquery datasource="polyculy">
				UPDATE polyculy.dbo.notification_preferences
				SET
					is_enabled = <cfqueryparam value="#arguments.isEnabled#" cfsqltype="cf_sql_bit">,
					delivery_mode = <cfqueryparam value="#arguments.deliveryMode#" cfsqltype="cf_sql_varchar">,
					quiet_hours_start =
						<cfif len(arguments.quietStart)>
							<cfqueryparam value="#arguments.quietStart#" cfsqltype="cf_sql_varchar">
						<cfelse>
							<cfqueryparam null="true" cfsqltype="cf_sql_varchar">
						</cfif>,
					quiet_hours_end =
						<cfif len(arguments.quietEnd)>
							<cfqueryparam value="#arguments.quietEnd#" cfsqltype="cf_sql_varchar">
						<cfelse>
							<cfqueryparam null="true" cfsqltype="cf_sql_varchar">
						</cfif>
				WHERE pref_id = <cfqueryparam value="#existing.pref_id#" cfsqltype="cf_sql_integer">
			</cfquery>
		<cfelse>
			<cfquery datasource="polyculy">
				INSERT INTO polyculy.dbo.notification_preferences
					(user_id, notification_type, is_enabled, delivery_mode, quiet_hours_start, quiet_hours_end)
				VALUES
					(
						<cfqueryparam value="#arguments.userId#" cfsqltype="cf_sql_integer">,
						<cfqueryparam value="#arguments.notificationType#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#arguments.isEnabled#" cfsqltype="cf_sql_bit">,
						<cfqueryparam value="#arguments.deliveryMode#" cfsqltype="cf_sql_varchar">,
						<cfif len(arguments.quietStart)>
							<cfqueryparam value="#arguments.quietStart#" cfsqltype="cf_sql_varchar">
						<cfelse>
							<cfqueryparam null="true" cfsqltype="cf_sql_varchar">
						</cfif>,
						<cfif len(arguments.quietEnd)>
							<cfqueryparam value="#arguments.quietEnd#" cfsqltype="cf_sql_varchar">
						<cfelse>
							<cfqueryparam null="true" cfsqltype="cf_sql_varchar">
						</cfif>
					)
			</cfquery>
		</cfif>
	</cffunction>

</cfcomponent>