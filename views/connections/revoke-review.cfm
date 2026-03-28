<cf_main pageTitle="Review Revocation Impact" showNav="true">
<cfoutput>
<div class="page-container">
    <div class="page-header">
        <h2 class="page-title"><i class="fas fa-exclamation-triangle me-2 text-warning"></i>Review Event Impact Before Revoking</h2>
    </div>

    <div class="card-polyculy">
        <div class="card-header-poly">
            <h5 id="revokeHeader">You are revoking a connection. The following events are affected.</h5>
        </div>
        <div class="card-body-poly">
            <!--- Batch Decision Table --->
            <div class="table-responsive">
                <table class="table table-polyculy" id="revokeTable">
                    <thead>
                        <tr>
                            <th>Event Title</th>
                            <th>Event Type</th>
                            <th>Connection Path Exists?</th>
                            <th>Default Action</th>
                            <th>Override</th>
                        </tr>
                    </thead>
                    <tbody id="revokeTableBody">
                        <tr><td colspan="5" class="text-center text-muted">Loading affected events...</td></tr>
                    </tbody>
                </table>
            </div>

            <div class="d-flex gap-2 mt-3 mb-3">
                <button class="btn btn-outline-purple btn-sm" onclick="keepDefaultAll()">
                    <i class="fas fa-check me-1"></i>Keep Default for All
                </button>
                <button class="btn btn-outline-purple btn-sm" onclick="overrideIndividually()">
                    <i class="fas fa-edit me-1"></i>Override Individually
                </button>
            </div>

            <p class="auth-helper-text">Two-person events will be cancelled automatically. Group-event access is re-evaluated based on remaining connections and event ownership.</p>

            <div class="d-flex gap-2 mt-3">
                <a href="/views/connections/connect.cfm" class="btn btn-outline-secondary">Cancel</a>
                <button class="btn btn-danger" onclick="confirmRevocation()">
                    <i class="fas fa-ban me-1"></i>Confirm Revocation
                </button>
            </div>
        </div>
    </div>
</div>

<script>
var connectionId = new URLSearchParams(window.location.search).get('connectionId');
var targetName = new URLSearchParams(window.location.search).get('name') || 'this person';

$(document).ready(function() {
    $('##revokeHeader').text('You are revoking ' + targetName + '. The following events are affected.');
    loadAffectedEvents();
});

function loadAffectedEvents() {
    // In a full implementation, this would call a revocation-preview API
    // For MVP, we show a simulated batch decision screen
    var html = '';
    html += '<tr>' +
        '<td>Dinner with ' + Polyculy.escapeHtml(targetName) + '</td>' +
        '<td><span class="badge bg-info">Two-person</span></td>' +
        '<td><span class="text-danger">No</span></td>' +
        '<td><span class="text-danger">Cancel Event</span></td>' +
        '<td><select class="form-select form-select-sm revoke-action" disabled><option>Cancel Event</option></select></td>' +
        '</tr>';
    html += '<tr>' +
        '<td>Group Hangout</td>' +
        '<td><span class="badge bg-warning text-dark">Group</span></td>' +
        '<td><span class="text-success">Yes</span></td>' +
        '<td>Remove ' + Polyculy.escapeHtml(targetName) + '</td>' +
        '<td><select class="form-select form-select-sm revoke-action">' +
        '<option value="remove">Remove ' + Polyculy.escapeHtml(targetName) + '</option>' +
        '<option value="keep">Keep ' + Polyculy.escapeHtml(targetName) + '</option>' +
        '</select></td></tr>';

    $('##revokeTableBody').html(html);
}

function keepDefaultAll() {
    $('.revoke-action').each(function() {
        $(this).val($(this).find('option:first').val());
    });
}

function overrideIndividually() {
    $('.revoke-action').prop('disabled', false);
}

function confirmRevocation() {
    if (!connectionId) {
        Polyculy.showAlert('No connection specified.', 'error');
        return;
    }
    Polyculy.revokeConnection(connectionId).done(function(resp) {
        if (resp.success) {
            Polyculy.showAlert('Connection revoked.', 'success');
            setTimeout(function() { window.location.href = '/views/connections/connect.cfm'; }, 1500);
        } else {
            Polyculy.showAlert(resp.message || 'Error.', 'error');
        }
    });
}
</script>
</cfoutput>
</cf_main>
