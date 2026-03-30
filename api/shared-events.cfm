<cfsetting showDebugOutput="false">
<cfheader name="Content-Type" value="application/json">

<cfset seSvc = createObject("component", "model.SharedEventService")>
<cfset proposalSvc = createObject("component", "model.ProposalService")>
<cfset auditSvc = createObject("component", "model.AuditService")>
<cfset notifSvc = createObject("component", "model.NotificationService")>

<cfset action = structKeyExists(url, "action") AND len(url.action) ? url.action : "list">
<cfset response = { "success" = true }>

<cftry>
	<cfswitch expression="#action#">
		<!--- list --->
		<cfcase value="list">
			<cfset q = seSvc.getEventsForUser(
				session.userId,
				structKeyExists(url, "startDate") ? url.startDate : "",
				structKeyExists(url, "endDate") ? url.endDate : ""
			)>
			<cfset events = []>
			<cfloop query="q">
				<cfset arrayAppend(events, q[currentRow])>
			</cfloop>
			<cfset response["data"] = events>
		</cfcase>

		<!--- get --->
		<cfcase value="get">
			<cfif NOT structKeyExists(url, "id")>
				<cfset response = { "success" = false, "message" = "Event ID required." }>
			<cfelse>
				<cfset q = seSvc.getById(url.id)>
				<cfif q.recordCount>
					<cfset row = {}>
					<cfset cols = listToArray(q.columnList)>
					<cfloop array="#cols#" index="col">
						<cfset row[lCase(col)] = q[col][1]>
					</cfloop>

					<cfset participants = seSvc.getParticipants(url.id)>
					<cfset pList = []>
					<cfloop query="participants">
						<cfset arrayAppend(pList, participants[currentRow])>
					</cfloop>
					<cfset row["participants"] = pList>

					<cfset proposals = proposalSvc.getAllByEvent(url.id)>
					<cfset propList = []>
					<cfloop query="proposals">
						<cfset arrayAppend(propList, proposals[currentRow])>
					</cfloop>
					<cfset row["proposals"] = propList>

					<cfset response["data"] = row>
				<cfelse>
					<cfset response = { "success" = false, "message" = "Event not found." }>
				</cfif>
			</cfif>
		</cfcase>

		<!--- create --->
		<cfcase value="create">
			<cfset startTimeStr = form.startDate & " " & form.startHour & ":" & form.startMinute & " " & form.startAmPm>
			<cfset endDateVal = structKeyExists(form, "endDate") AND len(form.endDate) ? form.endDate : form.startDate>
			<cfset endHourVal = structKeyExists(form, "endHour") AND len(form.endHour) ? form.endHour : form.startHour>
			<cfset endMinuteVal = structKeyExists(form, "endMinute") AND len(form.endMinute) ? form.endMinute : form.startMinute>
			<cfset endAmPmVal = structKeyExists(form, "endAmPm") AND len(form.endAmPm) ? form.endAmPm : form.startAmPm>
			<cfset endTimeStr = endDateVal & " " & endHourVal & ":" & endMinuteVal & " " & endAmPmVal>

			<cfset tzId = structKeyExists(session, "timezoneId") AND len(session.timezoneId) ? session.timezoneId : "America/New_York">
			<cfset eventData = {
				organizerId = session.userId,
				title = form.title,
				startTime = parseDateTime(startTimeStr),
				endTime = parseDateTime(endTimeStr),
				allDay = structKeyExists(form, "allDay"),
				timezoneId = tzId,
				eventDetails = structKeyExists(form, "eventDetails") ? form.eventDetails : "",
				address = structKeyExists(form, "address") ? form.address : "",
				reminderMinutes = structKeyExists(form, "reminderMinutes") ? form.reminderMinutes : "",
				reminderScope = structKeyExists(form, "reminderScope") ? form.reminderScope : "me",
				participantVisibility = structKeyExists(form, "participantVisibility") ? form.participantVisibility : "visible"
			}>

			<cfset newId = seSvc.create(eventData)>

			<!--- participants --->
			<cfif structKeyExists(form, "participants") AND len(form.participants)>
				<cfset participantList = listToArray(form.participants)>
				<cfloop array="#participantList#" index="pid">
					<cfset aType = structKeyExists(form, "attendance_#pid#") AND len(form["attendance_#pid#"]) ? form["attendance_#pid#"] : "required">
					<cfset seSvc.addParticipant(newId, pid, aType)>

					<cfset notifSvc.create(
						pid,
						"shared_event_invitation",
						"Event Invitation",
						session.displayName & " invited you to " & form.title,
						"shared_event",
						newId
					)>
				</cfloop>
			</cfif>

			<cfset auditSvc.log(
				"event_created",
				"shared_event",
				newId,
				"Created shared event: #form.title#",
				session.userId
			)>

			<cfset response["message"] = "Shared event created and invitations sent.">
			<cfset response["id"] = newId>
		</cfcase>

		<!--- respond --->
		<cfcase value="respond">
			<cfif NOT structKeyExists(form, "eventId") OR NOT structKeyExists(form, "response")>
				<cfset response = { "success" = false, "message" = "Event ID and response required." }>
			<cfelse>
				<cfset seSvc.respondToInvitation(form.eventId, session.userId, form.response)>

				<cfset event = seSvc.getById(form.eventId)>
				<cfif event.recordCount AND form.response NEQ "maybe">
					<cfset notifSvc.create(
						event.organizer_user_id,
						"shared_event_#form.response#",
						"Event #form.response#",
						session.displayName & " " & form.response & " your invitation to " & event.title,
						"shared_event",
						form.eventId
					)>
				</cfif>

				<cfset auditSvc.log(
					"event_#form.response#",
					"shared_event",
					form.eventId,
					"#session.displayName# #form.response# the invitation",
					session.userId
				)>
				<cfset response["message"] = "Response recorded.">
			</cfif>
		</cfcase>

		<!--- update --->
		<cfcase value="update">
			<cfif NOT structKeyExists(form, "eventId")>
				<cfset response = { "success" = false, "message" = "Event ID required." }>
			<cfelse>
				<cfset startTimeStr = form.startDate & " " & form.startHour & ":" & form.startMinute & " " & form.startAmPm>
				<cfset endDateVal = structKeyExists(form, "endDate") AND len(form.endDate) ? form.endDate : form.startDate>
				<cfset endHourVal = structKeyExists(form, "endHour") AND len(form.endHour) ? form.endHour : form.startHour>
				<cfset endMinuteVal = structKeyExists(form, "endMinute") AND len(form.endMinute) ? form.endMinute : form.startMinute>
				<cfset endAmPmVal = structKeyExists(form, "endAmPm") AND len(form.endAmPm) ? form.endAmPm : form.startAmPm>
				<cfset endTimeStr = endDateVal & " " & endHourVal & ":" & endMinuteVal & " " & endAmPmVal>

				<cfset eventData = {
					title = form.title,
					startTime = parseDateTime(startTimeStr),
					endTime = parseDateTime(endTimeStr),
					allDay = structKeyExists(form, "allDay"),
					eventDetails = structKeyExists(form, "eventDetails") ? form.eventDetails : "",
					address = structKeyExists(form, "address") ? form.address : "",
					reminderMinutes = structKeyExists(form, "reminderMinutes") ? form.reminderMinutes : "",
					reminderScope = structKeyExists(form, "reminderScope") ? form.reminderScope : "me",
					participantVisibility = structKeyExists(form, "participantVisibility") ? form.participantVisibility : "visible"
				}>

				<cfset result = seSvc.updateEvent(form.eventId, eventData, session.userId)>
				<cfif NOT result.success>
					<cfset response = result>
				<cfelse>
					<cfif result.isMaterialEdit>
						<cfset participants = seSvc.getParticipants(form.eventId)>
						<cfloop query="participants">
							<cfif participants.user_id NEQ session.userId>
								<cfset notifSvc.create(
									participants.user_id,
									"material_edit",
									"Event Updated",
									"The event '" & form.title & "' has been updated. Please re-confirm your attendance.",
									"shared_event",
									form.eventId
								)>
							</cfif>
						</cfloop>
					</cfif>

					<cfset auditSvc.log(
						"event_updated",
						"shared_event",
						form.eventId,
						"Updated shared event: #form.title# (material=#result.isMaterialEdit#)",
						session.userId
					)>
					<cfset response["message"] = result.isMaterialEdit ? "Event updated. All acceptances have been reset." : "Event updated.">
				</cfif>
			</cfif>
		</cfcase>

		<!--- cancel --->
		<cfcase value="cancel">
			<cfif NOT structKeyExists(form, "eventId")>
				<cfset response = { "success" = false, "message" = "Event ID required." }>
			<cfelse>
				<cfset seSvc.cancelEvent(form.eventId, "organizer_cancelled")>
				<cfset participants = seSvc.getParticipants(form.eventId)>
				<cfloop query="participants">
					<cfset notifSvc.create(
						participants.user_id,
						"event_cancelled",
						"Event Cancelled",
						"An event has been cancelled.",
						"shared_event",
						form.eventId
					)>
				</cfloop>
				<cfset auditSvc.log(
					"event_cancelled",
					"shared_event",
					form.eventId,
					"Shared event cancelled by organizer",
					session.userId
				)>
				<cfset response["message"] = "Event cancelled.">
			</cfif>
		</cfcase>

		<!--- removeParticipant --->
		<cfcase value="removeParticipant">
			<cfif NOT structKeyExists(form, "eventId") OR NOT structKeyExists(form, "participantUserId")>
				<cfset response = { "success" = false, "message" = "Event and participant IDs required." }>
			<cfelse>
				<cfset seSvc.removeParticipant(form.eventId, form.participantUserId)>
				<cfset notifSvc.create(
					form.participantUserId,
					"participant_removed",
					"Removed from Event",
					"You have been removed from a shared event.",
					"shared_event",
					form.eventId
				)>
				<cfset auditSvc.log(
					"participant_removed",
					"shared_event",
					form.eventId,
					"Participant removed from event",
					session.userId
				)>
				<cfset response["message"] = "Participant removed.">
			</cfif>
		</cfcase>

		<!--- propose --->
		<cfcase value="propose">
			<cfif NOT structKeyExists(form, "eventId") OR NOT structKeyExists(form, "proposedStartDate")>
				<cfset response = { "success" = false, "message" = "Event ID and proposed time required." }>
			<cfelse>
				<cfset pStartStr = form.proposedStartDate & " " & form.proposedStartHour & ":" & form.proposedStartMinute & " " & form.proposedStartAmPm>

				<cfset pEndDateVal = structKeyExists(form, "proposedEndDate") AND len(form.proposedEndDate) ? form.proposedEndDate : form.proposedStartDate>
				<cfset pEndHourVal = structKeyExists(form, "proposedEndHour") AND len(form.proposedEndHour) ? form.proposedEndHour : form.proposedStartHour>
				<cfset pEndMinuteVal = structKeyExists(form, "proposedEndMinute") AND len(form.proposedEndMinute) ? form.proposedEndMinute : form.proposedStartMinute>
				<cfset pEndAmPmVal = structKeyExists(form, "proposedEndAmPm") AND len(form.proposedEndAmPm) ? form.proposedEndAmPm : form.proposedStartAmPm>
				<cfset pEndStr = pEndDateVal & " " & pEndHourVal & ":" & pEndMinuteVal & " " & pEndAmPmVal>

				<cfset proposalSvc.create(
					form.eventId,
					session.userId,
					parseDateTime(pStartStr),
					parseDateTime(pEndStr),
					structKeyExists(form, "proposalMessage") ? form.proposalMessage : ""
				)>

				<cfset event = seSvc.getById(form.eventId)>
				<cfif event.recordCount>
					<cfset notifSvc.create(
						event.organizer_user_id,
						"new_time_proposed",
						"New Time Proposed",
						session.displayName & " proposed a new time for " & event.title,
						"shared_event",
						form.eventId
					)>
				</cfif>

				<cfset auditSvc.log(
					"time_proposed",
					"shared_event",
					form.eventId,
					"New time proposed by " & session.displayName,
					session.userId
				)>
				<cfset response["message"] = "Proposal submitted.">
			</cfif>
		</cfcase>

		<!--- acceptProposal --->
		<cfcase value="acceptProposal">
			<cfif NOT structKeyExists(form, "proposalId")>
				<cfset response = { "success" = false, "message" = "Proposal ID required." }>
			<cfelse>
				<cfset result = proposalSvc.acceptProposal(form.proposalId)>
				<cfif result.success>
					<cfset participants = seSvc.getParticipants(result.eventId)>
					<cfloop query="participants">
						<cfset notifSvc.create(
							participants.user_id,
							"proposal_accepted",
							"Time Changed",
							"The event time has been updated based on a proposal. Please re-confirm.",
							"shared_event",
							result.eventId
						)>
					</cfloop>
					<cfset auditSvc.log(
						"proposal_accepted",
						"shared_event",
						result.eventId,
						"Proposal accepted, event time updated",
						session.userId
					)>
				</cfif>
				<cfset response = result>
			</cfif>
		</cfcase>

		<!--- rejectProposal --->
		<cfcase value="rejectProposal">
			<cfif NOT structKeyExists(form, "proposalId")>
				<cfset response = { "success" = false, "message" = "Proposal ID required." }>
			<cfelse>
				<cfset proposalSvc.rejectProposal(form.proposalId)>
				<cfset auditSvc.log(
					"proposal_rejected",
					"proposal",
					form.proposalId,
					"Proposal rejected",
					session.userId
				)>
				<cfset response["message"] = "Proposal rejected.">
			</cfif>
		</cfcase>

		<!--- conflicts --->
		<cfcase value="conflicts">
			<cfif NOT structKeyExists(url, "userId") OR NOT structKeyExists(url, "startTime") OR NOT structKeyExists(url, "endTime")>
				<cfset response = { "success" = false, "message" = "User ID and time range required." }>
			<cfelse>
				<cfset conflicts = seSvc.getConflicts(url.userId, url.startTime, url.endTime)>
				<cfset response["data"] = conflicts>
			</cfif>
		</cfcase>

		<!--- claimOwnership --->
		<cfcase value="claimOwnership">
			<cfif NOT structKeyExists(form, "eventId")>
				<cfset response = { "success" = false, "message" = "Event ID required." }>
			<cfelse>
				<cfset seSvc.transferOwnership(form.eventId, session.userId)>
				<cfset participants = seSvc.getParticipants(form.eventId)>
				<cfloop query="participants">
					<cfset notifSvc.create(
						participants.user_id,
						"ownership_claimed",
						"New Organizer",
						session.displayName & " has claimed ownership of the event.",
						"shared_event",
						form.eventId
					)>
				</cfloop>
				<cfset auditSvc.log(
					"ownership_claimed",
					"shared_event",
					form.eventId,
					"Ownership claimed by " & session.displayName,
					session.userId
				)>
				<cfset response["message"] = "You are now the organizer.">
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