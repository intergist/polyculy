<cfsetting showDebugOutput="false">
<cfheader name="Content-Type" value="application/json">

<cfset eventSvc = createObject("component", "model.EventService")>
<cfset auditSvc = createObject("component", "model.AuditService")>

<cfset action   = structKeyExists(url, "action") AND len(url.action) ? url.action : "list">
<cfset response = { "success" = true }>

<cftry>

    <cfswitch expression="#action#">

        <cfcase value="list">
            <cfset startDate = structKeyExists(url, "startDate") ? url.startDate : "">
            <cfset endDate   = structKeyExists(url, "endDate")   ? url.endDate   : "">

            <cfset q = eventSvc.getPersonalEventsForUser(session.userId, startDate, endDate)>
            <cfset events = []>

            <cfloop query="q">
                <!--- push each row as a struct --->
                <cfset rowStruct = {}>
                <cfloop list="#q.columnList#" index="colName">
                    <cfset rowStruct[lCase(colName)] = q[colName][q.currentRow]>
                </cfloop>
                <cfset arrayAppend(events, rowStruct)>
            </cfloop>

            <cfset response["data"] = events>
        </cfcase>

        <cfcase value="get">
            <cfif NOT structKeyExists(url, "id")>
                <cfset response = { "success" = false, "message" = "Event ID required." }>
            <cfelse>
                <cfset q = eventSvc.getPersonalEvent(url.id)>

                <cfif q.recordCount>
                    <cfset row = {}>

                    <cfloop list="#q.columnList#" index="colName">
                        <cfset row[lCase(colName)] = q[colName][1]>
                    </cfloop>

                    <cfset vis    = eventSvc.getVisibilityRecords(url.id)>
                    <cfset visData = []>

                    <cfloop query="vis">
                        <cfset visRow = {}>
                        <cfloop list="#vis.columnList#" index="colName2">
                            <cfset visRow[lCase(colName2)] = vis[colName2][vis.currentRow]>
                        </cfloop>
                        <cfset arrayAppend(visData, visRow)>
                    </cfloop>

                    <cfset row["visibility"] = visData>
                    <cfset response["data"]  = row>
                <cfelse>
                    <cfset response = { "success" = false, "message" = "Event not found." }>
                </cfif>
            </cfif>
        </cfcase>

        <cfcase value="create">
            <cfset startTimeStr = form.startDate & " " & form.startHour & ":" & form.startMinute & " " & form.startAmPm>

            <cfset endDateVal = structKeyExists(form, "endDate") AND len(form.endDate) ? form.endDate : form.startDate>
            <cfset endHourVal = structKeyExists(form, "endHour") AND len(form.endHour) ? form.endHour : form.startHour>
            <cfset endMinVal  = structKeyExists(form, "endMinute") AND len(form.endMinute) ? form.endMinute : form.startMinute>
            <cfset endAmPmVal = structKeyExists(form, "endAmPm") AND len(form.endAmPm) ? form.endAmPm : form.startAmPm>

            <cfset endTimeStr = endDateVal & " " & endHourVal & ":" & endMinVal & " " & endAmPmVal>

            <cfset tzVal = (structKeyExists(session, "timezoneId") AND len(session.timezoneId)) ? session.timezoneId : "America/New_York">

            <cfset eventData = {
                userId          = session.userId,
                title           = form.title,
                startTime       = parseDateTime(startTimeStr),
                endTime         = parseDateTime(endTimeStr),
                allDay          = structKeyExists(form, "allDay"),
                timezoneId      = tzVal,
                eventDetails    = structKeyExists(form, "eventDetails")    ? form.eventDetails    : "",
                address         = structKeyExists(form, "address")         ? form.address         : "",
                reminderMinutes = structKeyExists(form, "reminderMinutes") ? form.reminderMinutes : "",
                visibilityTier  = structKeyExists(form, "visibilityTier")  ? form.visibilityTier  : "invisible"
            }>

            <cfset newId = eventSvc.createPersonalEvent(eventData)>

            <!--- Visibility settings --->
            <cfset fullDetailUsers = []>
            <cfset busyBlockUsers  = []>

            <cfif structKeyExists(form, "fullDetailUsers") AND len(form.fullDetailUsers)>
                <cfset fullDetailUsers = listToArray(form.fullDetailUsers)>
            </cfif>

            <cfif structKeyExists(form, "busyBlockUsers") AND len(form.busyBlockUsers)>
                <cfset busyBlockUsers = listToArray(form.busyBlockUsers)>
            </cfif>

            <cfset eventSvc.setVisibility(
                newId,
                eventData.visibilityTier,
                fullDetailUsers,
                busyBlockUsers
            )>

            <cfset auditSvc.log(
                "event_created",
                "personal_event",
                newId,
                "Created personal event: #form.title#",
                session.userId
            )>

            <cfset response["message"] = "Event created.">
            <cfset response["id"]      = newId>
        </cfcase>

        <cfcase value="update">
            <cfif NOT structKeyExists(form, "eventId")>
                <cfset response = { "success" = false, "message" = "Event ID required." }>
            <cfelse>
                <cfset startTimeStr = form.startDate & " " & form.startHour & ":" & form.startMinute & " " & form.startAmPm>

                <cfset endDateVal = structKeyExists(form, "endDate") AND len(form.endDate) ? form.endDate : form.startDate>
                <cfset endHourVal = structKeyExists(form, "endHour") AND len(form.endHour) ? form.endHour : form.startHour>
                <cfset endMinVal  = structKeyExists(form, "endMinute") AND len(form.endMinute) ? form.endMinute : form.startMinute>
                <cfset endAmPmVal = structKeyExists(form, "endAmPm") AND len(form.endAmPm) ? form.endAmPm : form.startAmPm>

                <cfset endTimeStr = endDateVal & " " & endHourVal & ":" & endMinVal & " " & endAmPmVal>

                <cfset eventData = {
                    userId          = session.userId,
                    title           = form.title,
                    startTime       = parseDateTime(startTimeStr),
                    endTime         = parseDateTime(endTimeStr),
                    allDay          = structKeyExists(form, "allDay"),
                    eventDetails    = structKeyExists(form, "eventDetails")    ? form.eventDetails    : "",
                    address         = structKeyExists(form, "address")         ? form.address         : "",
                    reminderMinutes = structKeyExists(form, "reminderMinutes") ? form.reminderMinutes : "",
                    visibilityTier  = structKeyExists(form, "visibilityTier")  ? form.visibilityTier  : "invisible"
                }>

                <cfset eventSvc.updatePersonalEvent(form.eventId, eventData)>

                <!--- Visibility --->
                <cfset fullDetailUsers = []>
                <cfset busyBlockUsers  = []>

                <cfif structKeyExists(form, "fullDetailUsers") AND len(form.fullDetailUsers)>
                    <cfset fullDetailUsers = listToArray(form.fullDetailUsers)>
                </cfif>

                <cfif structKeyExists(form, "busyBlockUsers") AND len(form.busyBlockUsers)>
                    <cfset busyBlockUsers = listToArray(form.busyBlockUsers)>
                </cfif>

                <cfset eventSvc.setVisibility(
                    form.eventId,
                    eventData.visibilityTier,
                    fullDetailUsers,
                    busyBlockUsers
                )>

                <cfset auditSvc.log(
                    "event_updated",
                    "personal_event",
                    form.eventId,
                    "Updated personal event: #form.title#",
                    session.userId
                )>

                <cfset response["message"] = "Event updated.">
            </cfif>
        </cfcase>

        <cfcase value="delete">
            <cfif NOT structKeyExists(form, "eventId")>
                <cfset response = { "success" = false, "message" = "Event ID required." }>
            <cfelse>
                <cfset eventSvc.deletePersonalEvent(form.eventId, session.userId)>

                <cfset auditSvc.log(
                    "event_deleted",
                    "personal_event",
                    form.eventId,
                    "Deleted personal event",
                    session.userId
                )>

                <cfset response["message"] = "Event deleted.">
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