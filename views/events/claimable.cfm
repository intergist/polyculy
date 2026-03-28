<cf_main pageTitle="Claim This Event" showNav="true">
<cfoutput>
<div class="page-container">
    <div class="d-flex justify-content-center">
        <div class="card-polyculy" style="max-width:550px;">
            <div class="card-header-poly" style="background:linear-gradient(135deg,##C4B5FD,##FBCFE8);">
                <h5><i class="fas fa-hand-pointer me-2"></i>Claim This Event</h5>
            </div>
            <div class="card-body-poly" id="claimCard">
                <div class="text-center text-muted py-3"><i class="fas fa-spinner fa-spin"></i></div>
            </div>
        </div>
    </div>
</div>

<script>
var eventId = new URLSearchParams(window.location.search).get('id');
var hasConnection = new URLSearchParams(window.location.search).get('connected') === 'true';

$(document).ready(function() {
    if (!eventId) return;
    Polyculy.apiGet('/api/shared-events.cfm?action=get&id=' + eventId).done(function(resp) {
        if (!resp.success || !resp.data) {
            $('##claimCard').html('<div class="text-danger">Event not found or not claimable.</div>');
            return;
        }
        var ev = resp.data;
        var html = '';

        if (hasConnection) {
            html += '<div class="alert-inline success mb-3" style="position:static;"><i class="fas fa-check-circle me-1"></i>Ready to claim &mdash; active connection prerequisite satisfied.</div>';
        } else {
            html += '<div class="alert-inline info mb-3" style="position:static;"><i class="fas fa-clock me-1"></i>Pending claim &mdash; matching email found, but no qualifying connection exists yet.</div>';
        }

        html += '<div class="inv-meta mb-2"><i class="fas fa-calendar me-2"></i>' + Polyculy.escapeHtml(ev.title) + '</div>' +
            '<div class="inv-meta mb-2"><i class="fas fa-user me-2"></i>Organized by ' + Polyculy.escapeHtml(ev.organizer_name || '') + '</div>' +
            '<div class="inv-meta mb-3"><i class="far fa-clock me-2"></i>' + Polyculy.formatDateTime(ev.start_time) +
            (ev.end_time ? ' &ndash; ' + Polyculy.formatTime(ev.end_time) : '') + '</div>' +
            '<p class="text-muted-sm mb-3">To claim this event, you must already be connected to at least one participant in the event.</p>' +
            '<div class="d-flex gap-2">' +
            '<button class="btn btn-primary-purple' + (hasConnection ? '' : ' disabled') + '" onclick="claimEvent()" ' +
            (hasConnection ? '' : 'disabled') + '><i class="fas fa-hand-pointer me-1"></i>Claim Event</button>' +
            '<button class="btn btn-outline-secondary" onclick="history.back()">Dismiss</button></div>';
        $('##claimCard').html(html);
    });
});

function claimEvent() {
    Polyculy.respondToInvitation(eventId, 'accepted').done(function(resp) {
        if (resp.success) {
            Polyculy.showAlert('Event claimed! You are now a participant.', 'success');
            setTimeout(function() { window.location.href = '/views/calendar/month.cfm'; }, 1500);
        } else {
            Polyculy.showAlert(resp.message || 'Error.', 'error');
        }
    });
}
</script>
</cfoutput>
</cf_main>
