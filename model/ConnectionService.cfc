<cfcomponent>

	<cffunction name="getByUser" access="public" returntype="any" output="false">
		<cfargument name="userId" type="numeric" required="true">

		<cfreturn queryExecute(
			"SELECT c.connection_id, c.user_id_1, c.user_id_2, c.status, c.invited_email,
					c.invited_display_name, c.initiated_by, c.created_at, c.is_hidden,
					u1.display_name AS user1_name, u1.email AS user1_email, u1.avatar_url AS user1_avatar,
					u2.display_name AS user2_name, u2.email AS user2_email, u2.avatar_url AS user2_avatar,
					dp.nickname, dp.avatar_override, dp.calendar_color
			 FROM polyculy.dbo.connections c
			 LEFT JOIN users u1 ON c.user_id_1 = u1.user_id
			 LEFT JOIN users u2 ON c.user_id_2 = u2.user_id
			 LEFT JOIN connection_display_prefs dp ON dp.user_id = :uid
				AND dp.target_user_id = CASE WHEN c.user_id_1 = :uid THEN c.user_id_2 ELSE c.user_id_1 END
			 WHERE (c.user_id_1 = :uid OR c.user_id_2 = :uid)
			 ORDER BY c.status, c.created_at DESC",
			{
				uid = { value = arguments.userId, cfsqltype = "cf_sql_integer" }
			}
		)>
	</cffunction>

	<cffunction name="getConnectedUsers" access="public" returntype="any" output="false">
		<cfargument name="userId" type="numeric" required="true">

		<cfreturn queryExecute(
			"SELECT CASE WHEN c.user_id_1 = :uid THEN c.user_id_2 ELSE c.user_id_1 END AS other_user_id,
					CASE WHEN c.user_id_1 = :uid THEN u2.display_name ELSE u1.display_name END AS display_name,
					CASE WHEN c.user_id_1 = :uid THEN u2.email ELSE u1.email END AS email,
					dp.calendar_color, dp.nickname
			 FROM polyculy.dbo.connections c
			 LEFT JOIN users u1 ON c.user_id_1 = u1.user_id
			 LEFT JOIN users u2 ON c.user_id_2 = u2.user_id
			 LEFT JOIN connection_display_prefs dp ON dp.user_id = :uid
				AND dp.target_user_id = CASE WHEN c.user_id_1 = :uid THEN c.user_id_2 ELSE c.user_id_1 END
			 WHERE (c.user_id_1 = :uid OR c.user_id_2 = :uid) AND c.status = 'connected'
			 ORDER BY display_name",
			{
				uid = { value = arguments.userId, cfsqltype = "cf_sql_integer" }
			}
		)>
	</cffunction>

	<cffunction name="getGroupMembers" access="public" returntype="any" output="false">
	<cfargument name="userId" type="numeric" required="true">

	<cfquery name="qGroupMembers" datasource="#application.datasource#">
		DECLARE @UserID int = <cfqueryparam value="#VAL(Arguments.userId)#" cfsqltype="cf_sql_integer">
		SELECT	c.connection_id,
						CASE WHEN c.user_id_1 = @UserID THEN c.user_id_2 ELSE c.user_id_1 END AS other_user_id,
						CASE WHEN c.user_id_1 = @UserID THEN u2.display_name ELSE u1.display_name END AS display_name,
						CASE WHEN c.user_id_1 = @UserID THEN u2.email ELSE u1.email END AS email,
						c.status, c.invited_display_name, c.invited_email, c.is_hidden,
						dp.calendar_color, dp.nickname, dp.avatar_override
		FROM		polyculy.dbo.connections c
			 			LEFT JOIN polyculy.dbo.users u1 ON c.user_id_1 = u1.user_id
			 			LEFT JOIN polyculy.dbo.users u2 ON c.user_id_2 = u2.user_id
			 			LEFT JOIN polyculy.dbo.connection_display_prefs dp ON dp.user_id = @UserID 
											AND dp.target_user_id = CASE WHEN c.user_id_1 = @UserID  THEN c.user_id_2 ELSE c.user_id_1 END
		WHERE 	(c.user_id_1 = @UserID OR c.user_id_2 = @UserID)
						AND (isNull(c.is_hidden,0) = 0 OR c.status != 'revoked')
		ORDER BY
				CASE c.status
					WHEN 'connected' THEN 1
					WHEN 'awaiting_confirmation' THEN 2
					WHEN 'licence_gifted_awaiting_signup' THEN 3
					WHEN 'awaiting_signup' THEN 4
					WHEN 'revoked' THEN 5
				END
			</cfquery>
		<cfreturn qGroupMembers/>
	</cffunction>

	<cffunction name="sendRequest" access="public" returntype="any" output="false">
		<cfargument name="fromUserId" type="numeric" required="true">
		<cfargument name="toEmail" type="string" required="true">
		<cfargument name="displayName" type="string" required="true">

		<!--- Check if user exists on platform --->
		<cfset var existingUser = queryExecute(
			"SELECT polyculy.dbo.user_id FROM users WHERE email = :email",
			{
				email = { value = arguments.toEmail, cfsqltype = "cf_sql_varchar" }
			}
		)>

		<!--- Check if connection already exists --->
		<cfif existingUser.recordCount GT 0>
			<cfset var toUserId = existingUser.user_id>
			<cfset var existing = queryExecute(
				"SELECT connection_id, status FROM polyculy.dbo.connections
				 WHERE (user_id_1 = :u1 AND user_id_2 = :u2) OR (user_id_1 = :u2 AND user_id_2 = :u1)",
				{
					u1 = { value = arguments.fromUserId, cfsqltype = "cf_sql_integer" },
					u2 = { value = toUserId, cfsqltype = "cf_sql_integer" }
				}
			)>

			<cfif existing.recordCount GT 0 AND existing.status NEQ "revoked">
				<cfreturn { success = false, message = "A connection already exists with this person." }>
			</cfif>

			<cfset var uid1 = min(arguments.fromUserId, toUserId)>
			<cfset var uid2 = max(arguments.fromUserId, toUserId)>

			<cfif existing.recordCount GT 0 AND existing.status EQ "revoked">
				<!--- Reconnect --->
				<cfset queryExecute(
					"UPDATE polyculy.dbo.connections SET status = 'awaiting_confirmation', updated_at = CURRENT_TIMESTAMP
					 WHERE connection_id = :cid",
					{
						cid = { value = existing.connection_id, cfsqltype = "cf_sql_integer" }
					}
				)>
			<cfelse>
				<cfset queryExecute(
					"INSERT INTO polyculy.dbo.connections (user_id_1, user_id_2, status, initiated_by)
					 VALUES (:u1, :u2, 'awaiting_confirmation', :init)",
					{
						u1 = { value = uid1, cfsqltype = "cf_sql_integer" },
						u2 = { value = uid2, cfsqltype = "cf_sql_integer" },
						init = { value = arguments.fromUserId, cfsqltype = "cf_sql_integer" }
					}
				)>
			</cfif>

			<cfreturn { success = true, message = "Connection request sent.", status = "awaiting_confirmation" }>
		<cfelse>
			<!--- User not on platform yet --->
			<cfset var uid1 = arguments.fromUserId>
			<cfset queryExecute(
				"INSERT INTO polyculy.dbo.connections (user_id_1, status, invited_email, invited_display_name, initiated_by)
				 VALUES (:u1, 'awaiting_signup', :email, :name, :init)",
				{
					u1 = { value = uid1, cfsqltype = "cf_sql_integer" },
					email = { value = arguments.toEmail, cfsqltype = "cf_sql_varchar" },
					name = { value = arguments.displayName, cfsqltype = "cf_sql_varchar" },
					init = { value = arguments.fromUserId, cfsqltype = "cf_sql_integer" }
				}
			)>

			<cfreturn { success = true, message = "Invitation sent.", status = "awaiting_signup" }>
		</cfif>
	</cffunction>

	<cffunction name="confirmConnection" access="public" returntype="void" output="false">
		<cfargument name="connectionId" type="numeric" required="true">
		<cfargument name="userId" type="numeric" required="true">

		<cfset queryExecute(
			"UPDATE polyculy.dbo.connections SET status = 'connected', updated_at = CURRENT_TIMESTAMP
			 WHERE connection_id = :cid AND status = 'awaiting_confirmation'
			 AND (user_id_1 = :uid OR user_id_2 = :uid)",
			{
				cid = { value = arguments.connectionId, cfsqltype = "cf_sql_integer" },
				uid = { value = arguments.userId, cfsqltype = "cf_sql_integer" }
			}
		)>
	</cffunction>

	<cffunction name="revokeConnection" access="public" returntype="void" output="false">
		<cfargument name="connectionId" type="numeric" required="true">
		<cfargument name="userId" type="numeric" required="true">

		<cfset queryExecute(
			"UPDATE polyculy.dbo.connections SET status = 'revoked', updated_at = CURRENT_TIMESTAMP
			 WHERE connection_id = :cid AND (user_id_1 = :uid OR user_id_2 = :uid)",
			{
				cid = { value = arguments.connectionId, cfsqltype = "cf_sql_integer" },
				uid = { value = arguments.userId, cfsqltype = "cf_sql_integer" }
			}
		)>
	</cffunction>

	<cffunction name="hideConnection" access="public" returntype="void" output="false">
		<cfargument name="connectionId" type="numeric" required="true">

		<cfset queryExecute(
			"UPDATE polyculy.dbo.connections SET is_hidden = TRUE WHERE connection_id = :cid",
			{
				cid = { value = arguments.connectionId, cfsqltype = "cf_sql_integer" }
			}
		)>
	</cffunction>

	<cffunction name="getConnectionBetween" access="public" returntype="any" output="false">
		<cfargument name="userId1" type="numeric" required="true">
		<cfargument name="userId2" type="numeric" required="true">

		<cfreturn queryExecute(
			"SELECT polyculy.dbo.connection_id, status FROM connections
			 WHERE (user_id_1 = :u1 AND user_id_2 = :u2) OR (user_id_1 = :u2 AND user_id_2 = :u1)",
			{
				u1 = { value = arguments.userId1, cfsqltype = "cf_sql_integer" },
				u2 = { value = arguments.userId2, cfsqltype = "cf_sql_integer" }
			}
		)>
	</cffunction>

	<cffunction name="updateDisplayPrefs" access="public" returntype="void" output="false">
		<cfargument name="userId" type="numeric" required="true">
		<cfargument name="targetUserId" type="numeric" required="true">
		<cfargument name="nickname" type="string" required="false" default="">
		<cfargument name="avatarOverride" type="string" required="false" default="">
		<cfargument name="calendarColor" type="string" required="false" default="">
		
		<cfquery name="qUserPref" datasource="#application.datasource#">
			SELECT 	polyculy.dbo.pref_id 
			FROM		connection_display_prefs 
			WHERE 	user_id = <cfqueryparam value="#VAL(Arguments.userId)#" cfsqltype="cf_sql_integer">
							AND target_user_id = <cfqueryparam value="#VAL(Arguments.targetUserId)#" cfsqltype="cf_sql_integer">
		</cfquery>
		<cfset local.defaultColor="##7C3AED"/>
		
		<cfif qUserPref.recordCount GT 0>
			<cfquery datasource="#application.datasource#">
				UPDATE	polyculy.dbo.connection_display_prefs 
				SET 		nickname = <cfqueryparam value="#Arguments.nickname#" cfsqltype="cf_sql_varchar" null="#NOT len(arguments.nickname)#">, 
								avatar_override = <cfqueryparam value="#Arguments.avatarOverride#" cfsqltype="cf_sql_varchar" null="#NOT len(arguments.avatarOverride)#">, 
								calendar_color = <cfqueryparam value="#(len(arguments.calendarColor) ? arguments.calendarColor : local.defaultColor)#" cfsqltype="cf_sql_varchar" null="#NOT len(arguments.nickname)#">
				 WHERE 	user_id = <cfqueryparam value="#VAL(Arguments.userId)#" cfsqltype="cf_sql_integer">
				 				AND target_user_id = <cfqueryparam value="#VAL(Arguments.targetUserId)#" cfsqltype="cf_sql_integer">
			
			</cfquery>

		<cfelse>
			<cfquery datasource="#application.datasource#">
				INSERT INTO polyculy.dbo.connection_display_prefs 
					(user_id, target_user_id, nickname, avatar_override, calendar_color)
				 VALUES 
				 	(	<cfqueryparam value="#VAL(Arguments.userId)#" cfsqltype="cf_sql_integer">, 
						<cfqueryparam value="#VAL(Arguments.targetUserId)#" cfsqltype="cf_sql_integer">, 
						<cfqueryparam value="#Arguments.nickname#" cfsqltype="cf_sql_varchar" null="#NOT len(arguments.nickname)#">, 
						<cfqueryparam value="#Arguments.avatarOverride#" cfsqltype="cf_sql_varchar" null="#NOT len(arguments.avatarOverride)#">, 
						<cfqueryparam value="#(len(arguments.calendarColor) ? arguments.calendarColor : local.defaultColor)#" cfsqltype="cf_sql_varchar" null="#NOT len(arguments.nickname)#"> )
			
			</cfquery>

		</cfif>
	</cffunction>

	<cffunction name="upgradeToGifted" access="public" returntype="void" output="false">
		<cfargument name="connectionId" type="numeric" required="true">

		<cfset queryExecute(
			"UPDATE polyculy.dbo.connections SET status = 'licence_gifted_awaiting_signup', updated_at = CURRENT_TIMESTAMP
			 WHERE connection_id = :cid AND status = 'awaiting_signup'",
			{
				cid = { value = arguments.connectionId, cfsqltype = "cf_sql_integer" }
			}
		)>
	</cffunction>

</cfcomponent>