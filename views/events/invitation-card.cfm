<cf_main pageTitle="Shared Event Invitation" showNav="true">
<cfoutput>
<div class="page-container">
    <div class="page-header">
        <h2 class="page-title"><i class="fas fa-envelope-open me-2"></i>Shared Event Invitation</h2>
    </div>

    <div class="card-polyculy" style="max-width:600px;" id="invitationCard">
        <div class="text-center text-muted py-4"><i class="fas fa-spinner fa-spin fa-2x"></i></div>
    </div>
</div>

<script>
var eventId = new URLSearchParams(window.location.search).get('id');

$(document).ready(function() {
    if (!eventId) { Polyculy.showAlert('No event specified.', 'error'); return; }
    loadInvitationCard();
});

function loadInvitationCard() {
    Polyculy.apiGet('/api/shared-events.cfm?action=get&id=' + eventId).done(function(resp) {
        if (!resp.success) { $('##invitationCard').html('<div class="card-body-poly text-danger">' + (resp.message || 'Event not found.') + '</div>'); return; }
        var ev = resp.data;
        var html = '<div class="card-body-poly">';

        // Header with organizer
        html += '<div class="inv-header mb-3">' +
            '<div class="member-avatar" style="width:42px;height:42px;">' + Polyculy.escapeHtml((ev.organizer_name || 'O').charAt(0)) + '</div>' +
            '<div><div class="inv-title">' + Polyculy.escapeHtml(ev.title) + '</div>' +
            '<div class="text-muted-sm">Organized by ' + Polyculy.escapeHtml(ev.organizer_name || '') + '</div></div></div>';

        // Event info
        html += '<div class="inv-meta"><i class="far fa-clock me-2"></i>' + Polyculy.formatDateTime(ev.start_time) +
            (ev.end_time ? ' &ndash; ' + Polyculy.formatTime(ev.end_time) : '') + '</div>';
        if (ev.address) html += '<div class="inv-meta"><i class="fas fa-map-marker-alt me-2"></i>' + Polyculy.escapeHtml(ev.address) + '</div>';
        if (ev.event_details) html += '<div class="inv-meta"><i class="fas fa-info-circle me-2"></i>' + Polyculy.escapeHtml(ev.event_details) + '</div>';

        // Participants (if visible)
        if (ev.participant_visibility !== 'hidden' && ev.participants && ev.participants.length > 0) {
            html += '<div class="mt-3"><strong class="text-purple" style="font-size:0.85rem;">Participants</strong>';
            ev.participants.forEach(function(p) {
                html += '<div class="invite-row py-1"><span class="invite-color" style="background:' + (p.calendar_color || '##7C3AED') + ';"></span>' +
                    '<span class="invite-name">' + Polyculy.escapeHtml(p.display_name) + '</span>' +
                    '<span class="proposal-status ' + p.response_status + '">' + p.response_status + '</span></div>';
            });
            html += '</div>';
        }

        // Status note
        html += '<div class="alert-inline info mt-3" style="position:static;"><i class="fas fa-info-circle me-1"></i>This invitation does not block your time until you accept.</div>';

        // Conflict note (simulated)
        html += '<div id="conflictNote"></div>';

        // Action buttons
        html += '<div class="d-flex gap-2 mt-3 flex-wrap">' +
            '<button class="btn btn-primary-purple" onclick="respondEvent(\'accepted\')"><i class="fas fa-check me-1"></i>Accept</button>' +
            '<button class="btn btn-outline-danger" onclick="respondEvent(\'declined\')"><i class="fas fa-times me-1"></i>Decline</button>' +
            '<button class="btn btn-outline-secondary" onclick="respondEvent(\'maybe\')"><i class="fas fa-question me-1"></i>Maybe</button>' +
            '<button class="btn btn-outline-purple" onclick="window.location.href=\'/views/events/propose-time.cfm?id=' + eventId + '\'"><i class="fas fa-clock me-1"></i>Propose New Time</button>' +
            '</div>';

        html += '</div>';
        $('##invitationCard').html(html);
    });
}

function respondEvent(response) {
    Polyculy.respondToInvitation(eventId, response).done(function(resp) {
        if (resp.success) {
            Polyculy.showAlert('Response recorded: ' + response, 'success');
            setTimeout(function() { window.location.href = '/views/calendar/month.cfm'; }, 1500);
        } else {
            Polyculy.showAlert(resp.message || 'Error.', 'error');
        }
    });
}
</script>
</cfoutput>
</cf_main>
