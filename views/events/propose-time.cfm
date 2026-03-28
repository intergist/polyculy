<cf_main pageTitle="Propose New Time" showNav="true">
<cfoutput>
<div class="page-container">
    <div class="page-header">
        <h2 class="page-title"><i class="fas fa-clock me-2"></i>Propose New Time</h2>
    </div>

    <div class="card-polyculy" style="max-width:600px;">
        <div class="card-header-poly">
            <h5 id="referenceHeader">Loading event details...</h5>
        </div>
        <div class="card-body-poly">
            <div class="alert-inline info mb-3" style="position:static;">
                <i class="fas fa-info-circle me-1"></i>You can have one active proposal per event at a time. Submitting a new one replaces your prior active proposal.
            </div>

            <div class="row g-2 mb-3">
                <div class="col-md-4"><label class="form-label-poly">Proposed Start Date</label><input type="date" class="form-control" id="propStartDate" required></div>
                <div class="col-md-2"><label class="form-label-poly">Hour</label>
                    <select class="form-select" id="propStartHour"><cfloop from="1" to="12" index="h"><option value="#h#"<cfif h eq 7> selected</cfif>>#h#</option></cfloop></select></div>
                <div class="col-md-2"><label class="form-label-poly">Min</label>
                    <select class="form-select" id="propStartMinute"><option value="00">00</option><option value="15">15</option><option value="30">30</option><option value="45">45</option></select></div>
                <div class="col-md-2"><label class="form-label-poly">AM/PM</label>
                    <select class="form-select" id="propStartAmPm"><option value="AM">AM</option><option value="PM" selected>PM</option></select></div>
            </div>
            <div class="row g-2 mb-3">
                <div class="col-md-4"><label class="form-label-poly">Proposed End Date</label><input type="date" class="form-control" id="propEndDate"></div>
                <div class="col-md-2"><label class="form-label-poly">Hour</label>
                    <select class="form-select" id="propEndHour"><cfloop from="1" to="12" index="h"><option value="#h#"<cfif h eq 8> selected</cfif>>#h#</option></cfloop></select></div>
                <div class="col-md-2"><label class="form-label-poly">Min</label>
                    <select class="form-select" id="propEndMinute"><option value="00">00</option><option value="15">15</option><option value="30">30</option><option value="45">45</option></select></div>
                <div class="col-md-2"><label class="form-label-poly">AM/PM</label>
                    <select class="form-select" id="propEndAmPm"><option value="AM">AM</option><option value="PM" selected>PM</option></select></div>
            </div>
            <div class="mb-3">
                <label class="form-label-poly">Optional Message</label>
                <textarea class="form-control" id="propMessage" rows="2" placeholder="Explain your preferred time..."></textarea>
            </div>

            <div class="d-flex gap-2">
                <a href="javascript:history.back()" class="btn btn-outline-secondary">Cancel</a>
                <button class="btn btn-primary-purple" onclick="sendProposal()"><i class="fas fa-paper-plane me-1"></i>Send Proposal</button>
            </div>
        </div>
    </div>
</div>

<script>
var eventId = new URLSearchParams(window.location.search).get('id');

$(document).ready(function() {
    if (!eventId) return;
    var today = Polyculy.formatDateISO(new Date());
    $('##propStartDate').val(today);
    $('##propEndDate').val(today);

    Polyculy.apiGet('/api/shared-events.cfm?action=get&id=' + eventId).done(function(resp) {
        if (resp.success && resp.data) {
            var ev = resp.data;
            $('##referenceHeader').html(Polyculy.escapeHtml(ev.title) + ' <span class="text-muted" style="font-size:0.85rem;">by ' + Polyculy.escapeHtml(ev.organizer_name || '') + '</span>');
        }
    });
});

function sendProposal() {
    var formData = {
        eventId: eventId,
        proposedStartDate: $('##propStartDate').val(),
        proposedStartHour: $('##propStartHour').val(),
        proposedStartMinute: $('##propStartMinute').val(),
        proposedStartAmPm: $('##propStartAmPm').val(),
        proposedEndDate: $('##propEndDate').val() || $('##propStartDate').val(),
        proposedEndHour: $('##propEndHour').val(),
        proposedEndMinute: $('##propEndMinute').val(),
        proposedEndAmPm: $('##propEndAmPm').val(),
        proposalMessage: $('##propMessage').val()
    };

    Polyculy.apiPost('/api/shared-events.cfm?action=propose', formData).done(function(resp) {
        if (resp.success) {
            Polyculy.showAlert('Proposal submitted!', 'success');
            setTimeout(function() { window.location.href = '/views/calendar/month.cfm'; }, 1500);
        } else {
            Polyculy.showAlert(resp.message || 'Error.', 'error');
        }
    });
}
</script>
</cfoutput>
</cf_main>
