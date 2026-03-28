<cf_main pageTitle="Review Proposals" showNav="true">
<cfoutput>
<div class="page-container">
    <div class="page-header">
        <h2 class="page-title"><i class="fas fa-clipboard-list me-2"></i>Proposed New Times</h2>
    </div>

    <div class="card-polyculy" style="max-width:700px;" id="proposalArea">
        <div class="card-header-poly"><h5 id="eventTitle">Loading event...</h5></div>
        <div class="card-body-poly" id="proposalList">
            <div class="text-center text-muted py-3"><i class="fas fa-spinner fa-spin"></i></div>
        </div>
    </div>

    <div class="alert-inline info mt-3" style="position:static;max-width:700px;">
        <i class="fas fa-exclamation-triangle me-1"></i>Accepting a proposal updates the event time, resets all participant acceptances to Pending, and notifies all participants.
    </div>
</div>

<script>
var eventId = new URLSearchParams(window.location.search).get('id');

$(document).ready(function() {
    if (!eventId) return;
    loadProposals();
});

function loadProposals() {
    Polyculy.apiGet('/api/shared-events.cfm?action=get&id=' + eventId).done(function(resp) {
        if (!resp.success || !resp.data) return;
        var ev = resp.data;
        $('##eventTitle').text(ev.title || 'Shared Event');

        var proposals = ev.proposals || [];
        if (proposals.length === 0) {
            $('##proposalList').html('<div class="text-muted py-3">No active proposals for this event.</div>');
            return;
        }

        var html = '';
        proposals.forEach(function(p) {
            var statusClass = p.status || 'active';
            html += '<div class="proposal-card mb-3">' +
                '<div class="d-flex align-items-center gap-2 mb-2">' +
                '<div class="member-avatar" style="width:32px;height:32px;font-size:0.75rem;">' + Polyculy.escapeHtml((p.proposer_name || '?').charAt(0)) + '</div>' +
                '<div><strong>' + Polyculy.escapeHtml(p.proposer_name || 'Unknown') + '</strong>' +
                '<span class="proposal-status ' + statusClass + ' ms-2">' + statusClass + '</span></div></div>' +
                '<div class="inv-meta"><i class="far fa-clock me-1"></i>Proposed: ' +
                Polyculy.formatDateTime(p.proposed_start) + ' &ndash; ' + Polyculy.formatTime(p.proposed_end) + '</div>';
            if (p.message) html += '<div class="inv-meta"><i class="fas fa-comment me-1"></i>' + Polyculy.escapeHtml(p.message) + '</div>';

            if (statusClass === 'active') {
                html += '<div class="d-flex gap-2 mt-2">' +
                    '<button class="btn btn-sm btn-primary-purple" onclick="acceptProposal(' + p.proposal_id + ')"><i class="fas fa-check me-1"></i>Accept</button>' +
                    '<button class="btn btn-sm btn-outline-danger" onclick="rejectProposal(' + p.proposal_id + ')"><i class="fas fa-times me-1"></i>Reject</button></div>';
            }
            html += '</div>';
        });
        $('##proposalList').html(html);
    });
}

function acceptProposal(proposalId) {
    if (!confirm('Accept this proposal? This will update the event time and reset all participant acceptances.')) return;
    Polyculy.apiPost('/api/shared-events.cfm?action=acceptProposal', { proposalId: proposalId }).done(function(resp) {
        if (resp.success) {
            Polyculy.showAlert('Proposal accepted! Event time updated.', 'success');
            loadProposals();
        } else {
            Polyculy.showAlert(resp.message || 'Error.', 'error');
        }
    });
}

function rejectProposal(proposalId) {
    Polyculy.apiPost('/api/shared-events.cfm?action=rejectProposal', { proposalId: proposalId }).done(function(resp) {
        if (resp.success) {
            Polyculy.showAlert('Proposal rejected.', 'success');
            loadProposals();
        } else {
            Polyculy.showAlert(resp.message || 'Error.', 'error');
        }
    });
}
</script>
</cfoutput>
</cf_main>
