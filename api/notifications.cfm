<cfsetting showDebugOutput="false">
<cfheader name="Content-Type" value="application/json">

<cfset notifSvc = createObject("component", "model.NotificationService")>
<cfset action = structKeyExists(url, "action") AND len(url.action) ? url.action : "list">
<cfset response = { "success" = true }>

<cftry>
	<cfswitch expression="#action#">
		<cfcase value="list">
			<cfset q = notifSvc.getRecent(session.userId, structKeyExists(url, "limit") AND len(url.limit) ? url.limit : 20)>
			<cfset notifications = []>
			<cfloop query="q">
				<cfset arrayAppend(notifications, {
					"notification_id" = q.notification_id,
					"notification_type" = q.notification_type,
					"title" = q.title,
					"message" = q.message,
					"is_read" = q.is_read,
					"related_entity_type" = structKeyExists(q, "related_entity_type") AND len(q.related_entity_type) ? q.related_entity_type : "",
					"related_entity_id" = structKeyExists(q, "related_entity_id") AND len(q.related_entity_id) ? q.related_entity_id : 0,
					"created_at" = dateTimeFormat(q.created_at, "yyyy-MM-dd'T'HH:nn:ss")
				})>
			</cfloop>
			<cfset response["data"] = notifications>
			<cfset response["unreadCount"] = notifSvc.getUnreadCount(session.userId)>
		</cfcase>

		<cfcase value="unreadCount">
			<cfset response["count"] = notifSvc.getUnreadCount(session.userId)>
		</cfcase>

		<cfcase value="markRead">
			<cfif structKeyExists(form, "notificationId")>
				<cfset notifSvc.markAsRead(form.notificationId, session.userId)>
			</cfif>
			<cfset response["message"] = "Marked as read.">
		</cfcase>

		<cfcase value="markAllRead">
			<cfset notifSvc.markAllAsRead(session.userId)>
			<cfset response["message"] = "All marked as read.">
		</cfcase>

		<cfcase value="preferences">
			<cfset q = notifSvc.getPreferences(session.userId)>
			<cfset prefs = []>
			<cfloop query="q">
				<cfset arrayAppend(prefs, q[currentRow])>
			</cfloop>
			<cfset response["data"] = prefs>
		</cfcase>

		<cfcase value="savePreference">
			<cfif NOT structKeyExists(form, "notificationType")>
				<cfset response = { "success" = false, "message" = "Notification type required." }>
			<cfelse>
				<cfset notifSvc.savePreference(
					session.userId,
					form.notificationType,
					structKeyExists(form, "isEnabled") ? form.isEnabled : true,
					structKeyExists(form, "deliveryMode") AND len(form.deliveryMode) ? form.deliveryMode : "instant",
					structKeyExists(form, "quietStart") ? form.quietStart : "",
					structKeyExists(form, "quietEnd") ? form.quietEnd : ""
				)>
				<cfset response["message"] = "Preference saved.">
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