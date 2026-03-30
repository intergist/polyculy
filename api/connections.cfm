<cfsetting showDebugOutput="false">
<cfheader name="Content-Type" value="application/json">

<cfset connSvc  = createObject("component", "model.ConnectionService")>
<cfset licSvc   = createObject("component", "model.LicenceService")>
<cfset auditSvc = createObject("component", "model.AuditService")>
<cfset notifSvc = createObject("component", "model.NotificationService")>

<cfset action   = structKeyExists(url, "action") AND len(url.action) ? url.action : "list">
<cfset response = { "success" = true }>

<cftry>

    <cfswitch expression="#action#">

        <cfcase value="list">
            <cfset qMembers = connSvc.getGroupMembers(session.userId)>
            <cfset members = []>

            <cfloop query="qMembers">
                <cfset displayName = "">
                <cfif NOT isNull(qMembers.nickname) AND len(trim(qMembers.nickname))>
                    <cfset displayName = qMembers.nickname>
                <cfelseif NOT isNull(qMembers.display_name) AND len(trim(qMembers.display_name))>
                    <cfset displayName = qMembers.display_name>
                <cfelseif NOT isNull(qMembers.invited_display_name) AND len(trim(qMembers.invited_display_name))>
                    <cfset displayName = qMembers.invited_display_name>
                <cfelse>
                    <cfset displayName = "Unknown">
                </cfif>

                <cfset emailVal = "">
                <cfif NOT isNull(qMembers.email) AND len(trim(qMembers.email))>
                    <cfset emailVal = qMembers.email>
                <cfelseif NOT isNull(qMembers.invited_email)>
                    <cfset emailVal = qMembers.invited_email>
                </cfif>

                <cfset colorVal = (isNull(qMembers.calendar_color) OR NOT len(trim(qMembers.calendar_color))) ? "##7C3AED" : qMembers.calendar_color>
                <cfset avatarVal = isNull(qMembers.avatar_override) ? "" : qMembers.avatar_override>
                <cfset hiddenVal = isNull(qMembers.is_hidden) ? false : qMembers.is_hidden>

                <cfset rowStruct = {
                    "connectionId"   = isNull(qMembers.connection_id) ? 0 : qMembers.connection_id,
                    "otherUserId"    = isNull(qMembers.other_user_id) ? 0 : qMembers.other_user_id,
                    "displayName"    = displayName,
                    "email"          = emailVal,
                    "status"         = qMembers.status,
                    "calendarColor"  = colorVal,
                    "avatarOverride" = avatarVal,
                    "isHidden"       = hiddenVal
                }>
                <cfset arrayAppend(members, rowStruct)>
            </cfloop>

            <cfset response["data"] = members>
        </cfcase>

        <cfcase value="connected">
            <cfset q = connSvc.getConnectedUsers(session.userId)>
            <cfset members = []>

            <cfloop query="q">
                <cfset connDisplayName = "">
                <cfif NOT isNull(q.nickname) AND len(trim(q.nickname))>
                    <cfset connDisplayName = q.nickname>
                <cfelseif NOT isNull(q.display_name) AND len(trim(q.display_name))>
                    <cfset connDisplayName = q.display_name>
                <cfelse>
                    <cfset connDisplayName = "Unknown">
                </cfif>

                <cfset colorVal = (isNull(q.calendar_color) OR NOT len(trim(q.calendar_color))) ? "##7C3AED" : q.calendar_color>

                <cfset rowStruct = {
                    "userId"        = q.other_user_id,
                    "displayName"   = connDisplayName,
                    "email"         = q.email,
                    "calendarColor" = colorVal
                }>
                <cfset arrayAppend(members, rowStruct)>
            </cfloop>

            <cfset response["data"] = members>
        </cfcase>

        <cfcase value="send">
            <cfif NOT structKeyExists(form, "email") OR NOT structKeyExists(form, "displayName")>
                <cfset response = { "success" = false, "message" = "Email and display name are required." }>
            <cfelse>
                <cfset result = connSvc.sendRequest(
                    session.userId,
                    trim(form.email),
                    trim(form.displayName)
                )>
                <cfset response = result>

                <cfif structKeyExists(result, "success") AND result.success>
                    <cfset auditSvc.log(
                        "connection_request",
                        "connection",
                        0,
                        "Connection request sent to #trim(form.email)#",
                        session.userId
                    )>
                </cfif>
            </cfif>
        </cfcase>

        <cfcase value="confirm">
            <cfif NOT structKeyExists(form, "connectionId")>
                <cfset response = { "success" = false, "message" = "Connection ID required." }>
            <cfelse>
                <cfset connSvc.confirmConnection(form.connectionId, session.userId)>

                <cfset auditSvc.log(
                    "connection_confirmed",
                    "connection",
                    form.connectionId,
                    "Connection confirmed",
                    session.userId
                )>

                <!--- Notify the other user --->
                <cfset conn = queryExecute(
                    "SELECT user_id_1, user_id_2 FROM polyculy.dbo.connections WHERE connection_id = :cid",
                    { cid = { value = form.connectionId, cfsqltype = "cf_sql_integer" } }
                )>

                <cfif conn.recordCount>
                    <cfset otherUserId = ( conn.user_id_1 EQ session.userId ? conn.user_id_2 : conn.user_id_1 )>

                    <cfset notifSvc.create(
                        otherUserId,
                        "connection_confirmed",
                        "Connection Confirmed",
                        session.displayName & " confirmed your connection.",
                        "connection",
                        form.connectionId
                    )>
                </cfif>

                <cfset response["message"] = "Connection confirmed.">
            </cfif>
        </cfcase>

        <cfcase value="revoke">
            <cfif NOT structKeyExists(form, "connectionId")>
                <cfset response = { "success" = false, "message" = "Connection ID required." }>
            <cfelse>
                <cfset connSvc.revokeConnection(form.connectionId, session.userId)>

                <cfset auditSvc.log(
                    "connection_revoked",
                    "connection",
                    form.connectionId,
                    "Connection revoked",
                    session.userId
                )>

                <cfset response["message"] = "Connection revoked.">
            </cfif>
        </cfcase>

        <cfcase value="hide">
            <cfif NOT structKeyExists(form, "connectionId")>
                <cfset response = { "success" = false, "message" = "Connection ID required." }>
            <cfelse>
                <cfset connSvc.hideConnection(form.connectionId)>
                <cfset response["message"] = "Connection hidden.">
            </cfif>
        </cfcase>

        <cfcase value="giftLicence">
            <cfif NOT structKeyExists(form, "email")>
                <cfset response = { "success" = false, "message" = "Email required." }>
            <cfelse>
                <cfset giftCode = "GIFT-" & uCase(left(hash(createUUID()), 8))>
                <cfset result = licSvc.giftLicence(session.userId, trim(form.email), giftCode)>

                <cfif result.success>
                    <cfset queryExecute(
                        "UPDATE polyculy.dbo.connections
                         SET status = 'licence_gifted_awaiting_signup', updated_at = CURRENT_TIMESTAMP
                         WHERE (invited_email = :email
                                OR user_id_2 IN (SELECT user_id FROM users WHERE email = :email))
                           AND (user_id_1 = :uid OR initiated_by = :uid)
                           AND status = 'awaiting_signup'",
                        {
                            email = { value = trim(form.email), cfsqltype = "cf_sql_varchar" },
                            uid   = { value = session.userId,    cfsqltype = "cf_sql_integer" }
                        }
                    )>

                    <cfset auditSvc.log(
                        "licence_gifted",
                        "licence",
                        0,
                        "License gifted to #trim(form.email)#",
                        session.userId
                    )>
                </cfif>

                <cfset response = result>
            </cfif>
        </cfcase>

        <cfcase value="updatePrefs">
            <cfif NOT structKeyExists(form, "targetUserId")>
                <cfset response = { "success" = false, "message" = "Target user ID required." }>
            <cfelse>
                <cfset nicknameVal       = structKeyExists(form, "nickname")       ? form.nickname       : "">
                <cfset avatarOverrideVal = structKeyExists(form, "avatarOverride") ? form.avatarOverride : "">
                <cfset calendarColorVal  = structKeyExists(form, "calendarColor")  ? form.calendarColor  : "">

                <cfset connSvc.updateDisplayPrefs(
                    session.userId,
                    form.targetUserId,
                    nicknameVal,
                    avatarOverrideVal,
                    calendarColorVal
                )>

                <cfset response["message"] = "Preferences updated.">
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