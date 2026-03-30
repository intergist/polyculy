<cfcomponent>

	<cffunction name="create" access="public" returntype="void">
		<cfargument name="eventId" type="numeric" required="true">
		<cfargument name="userId" type="numeric" required="true">
		<cfargument name="proposedStart" type="string" required="true">
		<cfargument name="proposedEnd" type="string" required="true">
		<cfargument name="message" type="string" required="false" default="">

		<!--- Withdraw any existing active proposal by this user for this event --->
		<cfquery datasource="polyculy">
			UPDATE polyculy.dbo.proposals
			SET status = 'withdrawn',
				updated_at = CURRENT_TIMESTAMP
			WHERE
				shared_event_id = <cfqueryparam value="#arguments.eventId#" cfsqltype="cf_sql_integer">
				AND proposer_user_id = <cfqueryparam value="#arguments.userId#" cfsqltype="cf_sql_integer">
				AND status = 'active'
		</cfquery>

		<cfquery datasource="polyculy">
			INSERT INTO polyculy.dbo.proposals
				(shared_event_id, proposer_user_id, proposed_start, proposed_end, message, status)
			VALUES
				(
					<cfqueryparam value="#arguments.eventId#" cfsqltype="cf_sql_integer">,
					<cfqueryparam value="#arguments.userId#" cfsqltype="cf_sql_integer">,
					<cfqueryparam value="#arguments.proposedStart#" cfsqltype="cf_sql_timestamp">,
					<cfqueryparam value="#arguments.proposedEnd#" cfsqltype="cf_sql_timestamp">,
					<cfif len(arguments.message)>
						<cfqueryparam value="#arguments.message#" cfsqltype="cf_sql_varchar">
					<cfelse>
						<cfqueryparam null="true" cfsqltype="cf_sql_varchar">
					</cfif>,
					'active'
				)
		</cfquery>
	</cffunction>

	<cffunction name="getActiveByEvent" access="public" returntype="query">
		<cfargument name="eventId" type="numeric" required="true">

		<cfset var q = "">

		<cfquery name="q" datasource="polyculy">
			SELECT
				p.*,
				u.display_name AS proposer_name,
				u.avatar_url AS proposer_avatar
			FROM polyculy.dbo.proposals p
				JOIN polyculy.dbo.users u ON p.proposer_user_id = u.user_id
			WHERE
				p.shared_event_id = <cfqueryparam value="#arguments.eventId#" cfsqltype="cf_sql_integer">
				AND p.status = 'active'
			ORDER BY p.created_at DESC
		</cfquery>

		<cfreturn q>
	</cffunction>

	<cffunction name="getAllByEvent" access="public" returntype="query">
		<cfargument name="eventId" type="numeric" required="true">

		<cfset var q = "">

		<cfquery name="q" datasource="polyculy">
			SELECT
				p.*,
				u.display_name AS proposer_name,
				u.avatar_url AS proposer_avatar
			FROM polyculy.dbo.proposals p
				JOIN polyculy.dbo.users u ON p.proposer_user_id = u.user_id
			WHERE p.shared_event_id = <cfqueryparam value="#arguments.eventId#" cfsqltype="cf_sql_integer">
			ORDER BY p.created_at DESC
		</cfquery>

		<cfreturn q>
	</cffunction>

	<cffunction name="acceptProposal" access="public" returntype="struct">
		<cfargument name="proposalId" type="numeric" required="true">

		<cfset var proposal = "">
		<cfset var seSvc = "">

		<cfquery name="proposal" datasource="polyculy">
			SELECT *
			FROM polyculy.dbo.proposals
			WHERE
				proposal_id = <cfqueryparam value="#arguments.proposalId#" cfsqltype="cf_sql_integer">
				AND status = 'active'
		</cfquery>

		<cfif NOT proposal.recordCount>
			<cfreturn { success = false, message = "Proposal not found or not active." }>
		</cfif>

		<!--- Mark proposal as accepted --->
		<cfquery datasource="polyculy">
			UPDATE polyculy.dbo.proposals
			SET status = 'accepted',
				updated_at = CURRENT_TIMESTAMP
			WHERE proposal_id = <cfqueryparam value="#arguments.proposalId#" cfsqltype="cf_sql_integer">
		</cfquery>

		<!--- Reject all other active proposals for this event --->
		<cfquery datasource="polyculy">
			UPDATE polyculy.dbo.proposals
			SET status = 'rejected',
				updated_at = CURRENT_TIMESTAMP
			WHERE
				shared_event_id = <cfqueryparam value="#proposal.shared_event_id#" cfsqltype="cf_sql_integer">
				AND proposal_id != <cfqueryparam value="#arguments.proposalId#" cfsqltype="cf_sql_integer">
				AND status = 'active'
		</cfquery>

		<!--- Update event time (material edit) --->
		<cfquery datasource="polyculy">
			UPDATE polyculy.dbo.shared_events
			SET
				start_time = <cfqueryparam value="#proposal.proposed_start#" cfsqltype="cf_sql_timestamp">,
				end_time = <cfqueryparam value="#proposal.proposed_end#" cfsqltype="cf_sql_timestamp">,
				updated_at = CURRENT_TIMESTAMP
			WHERE shared_event_id = <cfqueryparam value="#proposal.shared_event_id#" cfsqltype="cf_sql_integer">
		</cfquery>

		<!--- Reset all participant acceptances to pending --->
		<cfquery datasource="polyculy">
			UPDATE polyculy.dbo.shared_event_participants
			SET response_status = 'pending',
				updated_at = CURRENT_TIMESTAMP
			WHERE
				shared_event_id = <cfqueryparam value="#proposal.shared_event_id#" cfsqltype="cf_sql_integer">
				AND is_removed = FALSE
		</cfquery>

		<!--- Recalculate state --->
		<cfset seSvc = createObject("component", "SharedEventService")>
		<cfset seSvc.recalculateState(proposal.shared_event_id)>

		<cfreturn { success = true, eventId = proposal.shared_event_id }>
	</cffunction>

	<cffunction name="rejectProposal" access="public" returntype="void">
		<cfargument name="proposalId" type="numeric" required="true">

		<cfquery datasource="polyculy">
			UPDATE polyculy.dbo.proposals
			SET status = 'rejected',
				updated_at = CURRENT_TIMESTAMP
			WHERE proposal_id = <cfqueryparam value="#arguments.proposalId#" cfsqltype="cf_sql_integer">
		</cfquery>
	</cffunction>

</cfcomponent>