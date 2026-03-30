<cfcomponent>

    <cffunction name="authenticate" access="public" returntype="query" output="false">
        <cfargument name="email" type="string" required="true">
        <cfargument name="password" type="string" required="true">

        <cfset local.passwordHash = hash(Arguments.password, "SHA-256")>
        <cfquery name="qAuth" datasource="#application.datasource#">
            SELECT user_id, email, display_name, avatar_url, timezone_id, calendar_created
            FROM polyculy.dbo.users
            WHERE email = <cfqueryparam value="#Arguments.email#" cfsqltype="cf_sql_varchar">
              AND password_hash = <cfqueryparam value="#local.passwordHash#" cfsqltype="cf_sql_varchar">
              AND isNull(is_active,0) = 1
        </cfquery>

        <cfreturn qAuth>
    </cffunction>

    <cffunction name="getById" access="public" returntype="query" output="false">
        <cfargument name="userId" type="numeric" required="true">

        <cfquery name="qUser" datasource="#application.datasource#">
            SELECT user_id, email, display_name, avatar_url, timezone_id, calendar_created, is_active, created_at
            FROM polyculy.dbo.users
            WHERE user_id = <cfqueryparam value="#VAL(Arguments.userId)#" cfsqltype="cf_sql_integer">
        </cfquery>

        <cfreturn qUser>
    </cffunction>

    <cffunction name="getByEmail" access="public" returntype="query" output="false">
        <cfargument name="email" type="string" required="true">

        <cfquery name="qUserByEmail" datasource="#application.datasource#">
            SELECT user_id, email, display_name, avatar_url, timezone_id, calendar_created
            FROM polyculy.dbo.users
            WHERE email = <cfqueryparam value="#Arguments.email#" cfsqltype="cf_sql_varchar">
        </cfquery>

        <cfreturn qUserByEmail>
    </cffunction>

    <cffunction name="create" access="public" returntype="any" output="false">
        <cfargument name="email" type="string" required="true">
        <cfargument name="password" type="string" required="true">
        <cfargument name="displayName" type="string" required="true">

        <cfset local.passwordHash = hash(Arguments.password, "SHA-256")>
        <cfquery datasource="#application.datasource#" result="insUser">
            INSERT INTO polyculy.dbo.users (email, password_hash, display_name)
            VALUES (
                <cfqueryparam value="#Arguments.email#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#local.passwordHash#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#Arguments.displayName#" cfsqltype="cf_sql_varchar">
            )
        </cfquery>

        <cfreturn listFirst(insUser.generatedKey)>
    </cffunction>

    <cffunction name="updateTimezone" access="public" returntype="void" output="false">
        <cfargument name="userId" type="numeric" required="true">
        <cfargument name="timezoneId" type="string" required="true">

        <cfquery datasource="#application.datasource#">
            UPDATE polyculy.dbo.users
            SET timezone_id = <cfqueryparam value="#Arguments.timezoneId#" cfsqltype="cf_sql_varchar">,
                updated_at = getdate()
            WHERE user_id = <cfqueryparam value="#VAL(Arguments.userId)#" cfsqltype="cf_sql_integer">
        </cfquery>
    </cffunction>

    <cffunction name="setCalendarCreated" access="public" returntype="void" output="false">
        <cfargument name="userId" type="numeric" required="true">

        <cfquery datasource="#application.datasource#">
            UPDATE polyculy.dbo.users
            SET 	calendar_created = 1,
                	updated_at = getdate()
            WHERE user_id = <cfqueryparam value="#VAL(Arguments.userId)#" cfsqltype="cf_sql_integer">
        </cfquery>
    </cffunction>

    <cffunction name="updateProfile" access="public" returntype="void" output="false">
        <cfargument name="userId" type="numeric" required="true">
        <cfargument name="displayName" type="string" required="true">
        <cfargument name="avatarUrl" type="string" required="false" default="">

        <cfquery datasource="#application.datasource#">
            UPDATE polyculy.dbo.users
            SET display_name = <cfqueryparam value="#Arguments.displayName#" cfsqltype="cf_sql_varchar">,
                avatar_url = <cfqueryparam value="#Arguments.avatarUrl#" cfsqltype="cf_sql_varchar" null="#NOT len(Arguments.avatarUrl)#">,
                updated_at = getdate()
            WHERE user_id = <cfqueryparam value="#Arguments.userId#" cfsqltype="cf_sql_integer">
        </cfquery>
    </cffunction>

</cfcomponent>