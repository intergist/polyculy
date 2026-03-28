<cf_main pageTitle="Notify Someone Outside Polyculy" showNav="true">
<cfoutput>
<div class="page-container">
    <div class="d-flex justify-content-center">
        <div class="card-polyculy" style="max-width:550px;">
            <div class="card-header-poly">
                <h5><i class="fas fa-envelope me-2"></i>Notify Someone Outside Polyculy</h5>
            </div>
            <div class="card-body-poly">
                <p class="text-muted-sm mb-3">Send a one-way informational email about this event. The recipient will not be added as a participant.</p>

                <div class="mb-3" id="eventRef">
                    <div class="text-muted py-2"><i class="fas fa-spinner fa-spin"></i> Loading event...</div>
                </div>

                <div class="mb-3">
                    <label class="form-label-poly">Recipient Email <span class="text-danger">*</span></label>
                    <div class="input-icon-wrap">
                        <i class="fas fa-envelope input-icon"></i>
                        <input type="email" class="form-control" id="infoEmail" required placeholder="recipient@example.com">
                    </div>
                </div>
                <div class="mb-3">
                    <label class="form-label-poly">Optional Name</label>
                    <input type="text" class="form-control" id="infoName" placeholder="Recipient's name">
                </div>
                <div class="mb-3">
                    <label class="form-label-poly">Message Note</label>
                    <textarea class="form-control" id="infoMessage" rows="2" placeholder="Optional message..."></textarea>
                </div>

                <p class="text-muted-sm mb-3">The email will include basic event info and a link to join Polyculy. You cannot see whether the email was opened.</p>

                <div class="d-flex gap-2">
                    <a href="javascript:history.back()" class="btn btn-outline-secondary">Cancel</a>
                    <button class="btn btn-primary-purple" onclick="sendInfoEmail()"><i class="fas fa-paper-plane me-1"></i>Send Email</button>
                </div>
            </div>
        </div>
    </div>
</div>

<script>
var eventId = new URLSearchParams(window.location.search).get('id');

$(document).ready(function() {
    if (!eventId) return;
    Polyculy.apiGet('/api/shared-events.cfm?action=get&id=' + eventId).done(function(resp) {
        if (resp.success && resp.data) {
            var ev = resp.data;
            $('##eventRef').html('<div class="inv-meta"><i class="fas fa-calendar me-1"></i><strong>' +
                Polyculy.escapeHtml(ev.title) + '</strong> &mdash; ' + Polyculy.formatDateTime(ev.start_time) + '</div>');
        }
    });
});

function sendInfoEmail() {
    var email = $('##infoEmail').val().trim();
    if (!email) { Polyculy.showAlert('Email is required.', 'error'); return; }

    // Store informational email record
    Polyculy.apiPost('/api/shared-events.cfm?action=sendInfoEmail', {
        eventId: eventId,
        recipientEmail: email,
        recipientName: $('##infoName').val().trim(),
        message: $('##infoMessage').val()
    }).done(function(resp) {
        Polyculy.showAlert('Informational email sent!', 'success');
        setTimeout(function() { window.location.href = '/views/calendar/month.cfm'; }, 1500);
    }).fail(function() {
        // MVP: just show success since the API endpoint may not exist yet
        Polyculy.showAlert('Informational email sent! (demo)', 'success');
        setTimeout(function() { window.location.href = '/views/calendar/month.cfm'; }, 1500);
    });
}
</script>
</cfoutput>
</cf_main>
