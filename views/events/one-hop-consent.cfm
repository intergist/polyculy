<cf_main pageTitle="Invite Visibility Consent" showNav="true">
<cfoutput>
<div class="page-container">
    <div class="d-flex justify-content-center">
        <div class="card-polyculy" style="max-width:500px;">
            <div class="card-header-poly">
                <h5><i class="fas fa-link me-2"></i>Invite Visibility Consent</h5>
            </div>
            <div class="card-body-poly" id="consentCard">
                <div class="text-center text-muted py-3"><i class="fas fa-spinner fa-spin"></i></div>
            </div>
        </div>
    </div>
</div>

<script>
var eventId = new URLSearchParams(window.location.search).get('id');
var downstreamName = new URLSearchParams(window.location.search).get('downstream') || 'someone';

$(document).ready(function() {
    if (!eventId) return;
    Polyculy.apiGet('/api/shared-events.cfm?action=get&id=' + eventId).done(function(resp) {
        if (!resp.success || !resp.data) return;
        var ev = resp.data;
        var html = '<p class="mb-3">Your acceptance will make <strong>' + Polyculy.escapeHtml(downstreamName) +
            '</strong> eligible for this invitation. Proceed?</p>' +
            '<div class="inv-meta mb-2"><i class="fas fa-calendar me-2"></i>' + Polyculy.escapeHtml(ev.title) + '</div>' +
            '<div class="inv-meta mb-2"><i class="fas fa-user me-2"></i>Organized by ' + Polyculy.escapeHtml(ev.organizer_name || '') + '</div>' +
            '<div class="inv-meta mb-3"><i class="fas fa-user-plus me-2"></i>Downstream: ' + Polyculy.escapeHtml(downstreamName) + '</div>' +
            '<div class="d-flex gap-2 flex-wrap">' +
            '<button class="btn btn-primary-purple" onclick="acceptAndAllow()"><i class="fas fa-check me-1"></i>Accept and Allow</button>' +
            '<button class="btn btn-outline-purple" onclick="acceptWithout()"><i class="fas fa-check me-1"></i>Accept Without Allowing</button>' +
            '<button class="btn btn-outline-secondary" onclick="history.back()">Cancel</button></div>';
        $('##consentCard').html(html);
    });
});

function acceptAndAllow() {
    Polyculy.respondToInvitation(eventId, 'accepted').done(function(resp) {
        if (resp.success) {
            // In full implementation, also trigger one-hop activation
            Polyculy.showAlert('Accepted! ' + Polyculy.escapeHtml(downstreamName) + ' is now eligible.', 'success');
            setTimeout(function() { window.location.href = '/views/calendar/month.cfm'; }, 1500);
        }
    });
}

function acceptWithout() {
    Polyculy.respondToInvitation(eventId, 'accepted').done(function(resp) {
        if (resp.success) {
            Polyculy.showAlert('Accepted without allowing downstream invitation.', 'success');
            setTimeout(function() { window.location.href = '/views/calendar/month.cfm'; }, 1500);
        }
    });
}
</script>
</cfoutput>
</cf_main>
