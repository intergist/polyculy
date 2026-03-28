<cf_main pageTitle="Remove Participant" showNav="true">
<cfoutput>
<div class="page-container">
    <div class="d-flex justify-content-center">
        <div class="card-polyculy" style="max-width:500px;">
            <div class="card-header-poly">
                <h5><i class="fas fa-user-minus me-2 text-danger"></i>Remove Participant</h5>
            </div>
            <div class="card-body-poly" id="removeCard">
                <div class="text-center text-muted py-3"><i class="fas fa-spinner fa-spin"></i></div>
            </div>
        </div>
    </div>
</div>

<script>
var eventId = new URLSearchParams(window.location.search).get('id');
var participantId = new URLSearchParams(window.location.search).get('participantId');
var participantName = new URLSearchParams(window.location.search).get('name') || 'this participant';

$(document).ready(function() {
    if (!eventId || !participantId) return;

    Polyculy.apiGet('/api/shared-events.cfm?action=get&id=' + eventId).done(function(resp) {
        if (!resp.success || !resp.data) return;
        var ev = resp.data;
        var html = '<p class="mb-3">Remove <strong>' + Polyculy.escapeHtml(participantName) + '</strong> from this shared event?</p>' +
            '<div class="inv-meta mb-2"><i class="fas fa-calendar me-2"></i>' + Polyculy.escapeHtml(ev.title) + '</div>' +
            '<div class="inv-meta mb-2"><i class="fas fa-user me-2"></i>' + Polyculy.escapeHtml(participantName) + '</div>' +
            '<div class="mt-3 mb-3"><strong class="text-purple" style="font-size:0.85rem;">Effect of Removal:</strong>' +
            '<ul class="mt-1" style="font-size:0.85rem;color:var(--gray-600);">' +
            '<li>Loses visibility immediately</li>' +
            '<li>Can no longer respond, propose new time, or receive updates</li>' +
            '<li>Will receive a removal notification</li></ul></div>' +
            '<div class="d-flex gap-2">' +
            '<button class="btn btn-outline-secondary" onclick="history.back()">Cancel</button>' +
            '<button class="btn btn-danger" onclick="removeParticipant()"><i class="fas fa-user-minus me-1"></i>Remove Participant</button></div>';
        $('##removeCard').html(html);
    });
});

function removeParticipant() {
    Polyculy.apiPost('/api/shared-events.cfm?action=removeParticipant', {
        eventId: eventId,
        participantUserId: participantId
    }).done(function(resp) {
        if (resp.success) {
            Polyculy.showAlert(participantName + ' removed from event.', 'success');
            setTimeout(function() { window.location.href = '/views/calendar/month.cfm'; }, 1500);
        } else {
            Polyculy.showAlert(resp.message || 'Error.', 'error');
        }
    });
}
</script>
</cfoutput>
</cf_main>
