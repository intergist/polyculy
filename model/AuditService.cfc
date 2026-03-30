<cfcomponent>

	<cffunction name="log" access="public" returntype="void" output="false">
		<cfargument name="actionType" type="string" required="true">
		<cfargument name="entityType" type="string" required="true">
		<cfargument name="entityId" type="numeric" required="false" default="0">
		<cfargument name="details" type="string" required="false" default="">
		<cfargument name="actorUserId" type="numeric" required="false" default="0">

		<cfset queryExecute(
			"INSERT INTO polyculy.dbo.audit_log (actor_user_id, action_type, entity_type, entity_id, details)
			 VALUES (:actor, :action, :etype, :eid, :details)",
			{
				actor = { value = arguments.actorUserId, cfsqltype = "cf_sql_integer", null = (arguments.actorUserId EQ 0) },
				action = { value = arguments.actionType, cfsqltype = "cf_sql_varchar" },
				etype = { value = arguments.entityType, cfsqltype = "cf_sql_varchar" },
				eid = { value = arguments.entityId, cfsqltype = "cf_sql_integer", null = (arguments.entityId EQ 0) },
				details = { value = arguments.details, cfsqltype = "cf_sql_varchar" }
			}
		)>
	</cffunction>

	<cffunction name="getRecent" access="public" returntype="any" output="false">
		<cfargument name="limit" type="numeric" required="false" default="50">

		<cfreturn queryExecute(
			"SELECT TOP(:lim) a.*, u.display_name AS actor_name
			 FROM polyculy.dbo.audit_log a LEFT JOIN users u ON a.actor_user_id = u.user_id
			 ORDER BY a.created_at DESC",
			{
				lim = { value = arguments.limit, cfsqltype = "cf_sql_integer" }
			}
		)>
	</cffunction>

	<cffunction name="getByEntity" access="public" returntype="any" output="false">
		<cfargument name="entityType" type="string" required="true">
		<cfargument name="entityId" type="numeric" required="true">

		<cfreturn queryExecute(
			"SELECT a.*, u.display_name AS actor_name
			 FROM polyculy.dbo.audit_log a LEFT JOIN users u ON a.actor_user_id = u.user_id
			 WHERE a.entity_type = :etype AND a.entity_id = :eid
			 ORDER BY a.created_at DESC",
			{
				etype = { value = arguments.entityType, cfsqltype = "cf_sql_varchar" },
				eid = { value = arguments.entityId, cfsqltype = "cf_sql_integer" }
			}
		)>
	</cffunction>

</cfcomponent>