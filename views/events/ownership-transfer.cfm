<cf_main pageTitle="Claim Event Ownership" showNav="true">
<cfoutput>
<div class="page-container">
    <div class="d-flex justify-content-center">
        <div class="card-polyculy" style="max-width:550px;">
            <div class="card-header-poly" style="background:linear-gradient(135deg,##FDE68A,##FBCFE8);">
                <h5><i class="fas fa-crown me-2"></i>Claim Event Ownership</h5>
            </div>
            <div class="card-body-poly" id="ownershipCard">
                <div class="text-center text-muted py-3"><i class="fas fa-spinner fa-spin"></i></div>
            </div>
        </div>
    </div>
</div>

<script>
var eventId = new URLSearchParams(window.location.search).get('id');

$(document).ready(function() {
    if (!eventId) return;
    Polyculy.apiGet('/api/shared-events.cfm?action=get&id=' + eventId).done(function(resp) {
        if (!resp.success || !resp.data) return;
        var ev = resp.data;
        var html = '<p class="mb-3"><strong>This event needs a new organizer to continue.</strong></p>' +
            '<div class="inv-meta mb-2"><i class="fas fa-calendar me-2"></i>' + Polyculy.escapeHtml(ev.title) + '</div>' +
            '<div class="inv-meta mb-2"><i class="far fa-clock me-2"></i>' + Polyculy.formatDateTime(ev.start_time) +
            (ev.end_time ? ' &ndash; ' + Polyculy.formatTime(ev.end_time) : '') + '</div>';

        // Show current participants
        if (ev.participants && ev.participants.length > 0) {
            html += '<div class="mt-2 mb-3"><strong class="text-purple" style="font-size:0.85rem;">Current Participants</strong>';
            ev.participants.forEach(function(p) {
                html += '<div class="invite-row py-1"><span class="invite-color" style="background:' + (p.calendar_color || '##7C3AED') + ';"></span>' +
                    '<span class="invite-name">' + Polyculy.escapeHtml(p.display_name) + '</span>' +
                    '<span class="proposal-status ' + p.response_status + '">' + p.response_status + '</span></div>';
            });
            html += '</div>';
        }

        html += '<div class="alert-inline info mb-3" style="position:static;"><i class="fas fa-lock me-1"></i>During this transfer window, no one can edit the event.</div>';

        html += '<div class="d-flex gap-2">' +
            '<button class="btn btn-primary-purple" onclick="claimOwnership()"><i class="fas fa-crown me-1"></i>Claim Ownership</button>' +
            '<button class="btn btn-outline-secondary" onclick="history.back()">Decline</button></div>';
        $('##ownershipCard').html(html);
    });
});

function claimOwnership() {
    Polyculy.apiPost('/api/shared-events.cfm?action=claimOwnership', { eventId: eventId }).done(function(resp) {
        if (resp.success) {
            Polyculy.showAlert('You are now the organizer!', 'success');
            setTimeout(function() { window.location.href = '/views/calendar/month.cfm'; }, 1500);
        } else {
            Polyculy.showAlert(resp.message || 'Error.', 'error');
        }
    });
}
</script>
</cfoutput>
</cf_main>
