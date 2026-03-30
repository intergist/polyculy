<cfsetting showDebugOutput="false">
<cfheader name="Content-Type" value="application/json">

<cfset propSvc = createObject("component", "model.ProposalService")>
<cfset auditSvc = createObject("component", "model.AuditService")>
<cfset notifSvc = createObject("component", "model.NotificationService")>
<cfset sharedSvc = createObject("component", "model.SharedEventService")>

<cfset action = structKeyExists(url, "action") AND len(url.action) ? url.action : "list">
<cfset response = { "success" = true }>

<cftry>
	<cfswitch expression="#action#">
		<cfcase value="listForEvent">
			<cfset q = propSvc.getAllByEvent(url.event_id)>
			<cfset data = []>
			<cfloop query="q">
				<cfset arrayAppend(data, q[currentRow])>
			</cfloop>
			<cfset response["data"] = data>
		</cfcase>

		<cfcase value="activeForEvent">
			<cfset q = propSvc.getActiveByEvent(url.event_id)>
			<cfset data = []>
			<cfloop query="q">
				<cfset arrayAppend(data, q[currentRow])>
			</cfloop>
			<cfset response["data"] = data>
		</cfcase>

		<cfcase value="create">
			<cfset propSvc.create(
				form.event_id,
				session.userId,
				form.proposed_start,
				form.proposed_end,
				structKeyExists(form, "message") ? form.message : ""
			)>

			<cfset evt = sharedSvc.getById(form.event_id)>
			<cfif evt.organizer_user_id NEQ session.userId>
				<cfset notifSvc.create(
					evt.organizer_user_id,
					"proposal_received",
					"New Time Proposal",
					"#session.displayName# proposed a new time for ""#evt.title#"".",
					"shared_event",
					form.event_id
				)>
			</cfif>

			<cfset auditSvc.log(
				"proposal_create",
				"shared_event",
				form.event_id,
				"Proposed new time",
				session.userId
			)>
			<cfset response["message"] = "Proposal submitted">
		</cfcase>

		<cfcase value="accept">
			<cfset result = propSvc.acceptProposal(form.proposal_id)>
			<cfif structKeyExists(result, "success") AND NOT result.success>
				<cfset response = result>
			<cfelse>
				<cfset response["message"] = "Proposal accepted — event time updated, acceptances reset">
			</cfif>
		</cfcase>

		<cfcase value="reject">
			<cfset propSvc.rejectProposal(form.proposal_id)>
			<cfset response["message"] = "Proposal rejected">
		</cfcase>

		<cfcase value="withdraw">
			<cfset propSvc.rejectProposal(form.proposal_id)>
			<cfset response["message"] = "Proposal withdrawn">
		</cfcase>

		<cfdefaultcase>
			<cfset response = { "success" = false, "message" = "Unknown action" }>
		</cfdefaultcase>
	</cfswitch>

	<cfcatch type="any">
		<cfset response = { "success" = false, "message" = cfcatch.message }>
	</cfcatch>
</cftry>

<cfoutput>#serializeJSON(response)#</cfoutput>