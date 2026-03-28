<cf_main pageTitle="Invitation Unlocked" showNav="true">
<cfoutput>
<div class="page-container">
    <div class="d-flex justify-content-center">
        <div class="card-polyculy" style="max-width:550px;">
            <div class="card-header-poly" style="background:linear-gradient(135deg,##E9D5FF,##FBCFE8);">
                <h5><i class="fas fa-unlock me-2"></i>Invitation Unlocked</h5>
            </div>
            <div class="card-body-poly" id="indirectCard">
                <div class="text-center text-muted py-3"><i class="fas fa-spinner fa-spin"></i></div>
            </div>
        </div>
    </div>
</div>

<script>
var eventId = new URLSearchParams(window.location.search).get('id');
var linkPerson = new URLSearchParams(window.location.search).get('linkPerson') || 'someone';

$(document).ready(function() {
    if (!eventId) return;
    Polyculy.apiGet('/api/shared-events.cfm?action=get&id=' + eventId).done(function(resp) {
        if (!resp.success || !resp.data) return;
        var ev = resp.data;
        var html = '<div class="alert-inline success mb-3" style="position:static;">' +
            '<i class="fas fa-link me-1"></i>You are now eligible to join this event because <strong>' +
            Polyculy.escapeHtml(linkPerson) + '</strong> accepted and allowed the invitation chain.</div>' +
            '<div class="inv-meta mb-2"><i class="fas fa-calendar me-2"></i>' + Polyculy.escapeHtml(ev.title) + '</div>' +
            '<div class="inv-meta mb-2"><i class="fas fa-user me-2"></i>Organized by ' + Polyculy.escapeHtml(ev.organizer_name || '') + '</div>' +
            '<div class="inv-meta mb-3"><i class="far fa-clock me-2"></i>' + Polyculy.formatDateTime(ev.start_time) +
            (ev.end_time ? ' &ndash; ' + Polyculy.formatTime(ev.end_time) : '') + '</div>' +
            '<p class="text-muted-sm mb-3">If the link person later declines, your invitation remains valid unless the organizer removes you.</p>' +
            '<div class="d-flex gap-2 flex-wrap">' +
            '<button class="btn btn-primary-purple" onclick="respondIndirect(\'accepted\')"><i class="fas fa-check me-1"></i>Accept</button>' +
            '<button class="btn btn-outline-danger" onclick="respondIndirect(\'declined\')"><i class="fas fa-times me-1"></i>Decline</button>' +
            '<button class="btn btn-outline-secondary" onclick="respondIndirect(\'maybe\')"><i class="fas fa-question me-1"></i>Maybe</button>' +
            '<button class="btn btn-outline-purple" onclick="window.location.href=\'/views/events/propose-time.cfm?id=' + eventId + '\'"><i class="fas fa-clock me-1"></i>Propose New Time</button></div>';
        $('##indirectCard').html(html);
    });
});

function respondIndirect(response) {
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
