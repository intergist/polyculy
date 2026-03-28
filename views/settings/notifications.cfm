<cf_main pageTitle="Notification Preferences" showNav="true">
<cfoutput>
<div class="page-container">
    <div class="page-header">
        <h2 class="page-title"><i class="fas fa-bell me-2"></i>Notification Preferences</h2>
    </div>

    <div class="card-polyculy" style="max-width:700px;">
        <div class="card-header-poly"><h5>Per-Type Notification Toggles</h5></div>
        <div class="card-body-poly">
            <div class="table-responsive">
                <table class="table table-polyculy" id="notifPrefsTable">
                    <thead>
                        <tr>
                            <th>Notification Type</th>
                            <th style="width:80px;">Enabled</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr><td>Connection requests</td><td><div class="form-check form-switch"><input class="form-check-input notif-toggle" type="checkbox" data-type="connection_request" checked></div></td></tr>
                        <tr><td>Connection confirmations</td><td><div class="form-check form-switch"><input class="form-check-input notif-toggle" type="checkbox" data-type="connection_confirmed" checked></div></td></tr>
                        <tr><td>Revocations</td><td><div class="form-check form-switch"><input class="form-check-input notif-toggle" type="checkbox" data-type="connection_revoked" checked></div></td></tr>
                        <tr><td>Shared event invitations</td><td><div class="form-check form-switch"><input class="form-check-input notif-toggle" type="checkbox" data-type="shared_event_invitation" checked></div></td></tr>
                        <tr><td>Accepted responses</td><td><div class="form-check form-switch"><input class="form-check-input notif-toggle" type="checkbox" data-type="shared_event_accepted" checked></div></td></tr>
                        <tr><td>Declines</td><td><div class="form-check form-switch"><input class="form-check-input notif-toggle" type="checkbox" data-type="shared_event_declined" checked></div></td></tr>
                        <tr><td>New time proposals</td><td><div class="form-check form-switch"><input class="form-check-input notif-toggle" type="checkbox" data-type="new_time_proposed" checked></div></td></tr>
                        <tr><td>Proposal decisions</td><td><div class="form-check form-switch"><input class="form-check-input notif-toggle" type="checkbox" data-type="proposal_accepted" checked></div></td></tr>
                        <tr><td>Ownership transfer events</td><td><div class="form-check form-switch"><input class="form-check-input notif-toggle" type="checkbox" data-type="ownership_claimed" checked></div></td></tr>
                        <tr><td>Cancellations</td><td><div class="form-check form-switch"><input class="form-check-input notif-toggle" type="checkbox" data-type="event_cancelled" checked></div></td></tr>
                        <tr><td>Material edits</td><td><div class="form-check form-switch"><input class="form-check-input notif-toggle" type="checkbox" data-type="material_edit" checked></div></td></tr>
                        <tr><td>Manual removals</td><td><div class="form-check form-switch"><input class="form-check-input notif-toggle" type="checkbox" data-type="participant_removed" checked></div></td></tr>
                    </tbody>
                </table>
            </div>

            <div class="row g-3 mt-3">
                <div class="col-md-4">
                    <label class="form-label-poly">Delivery Mode</label>
                    <div class="view-toggle-group">
                        <button class="view-toggle-btn active" id="modeInstant" onclick="setDeliveryMode('instant')">Instant</button>
                        <button class="view-toggle-btn" id="modeDigest" onclick="setDeliveryMode('digest')">Digest</button>
                    </div>
                </div>
                <div class="col-md-4">
                    <label class="form-label-poly">Quiet Hours Start</label>
                    <input type="time" class="form-control" id="quietStart" value="22:00">
                </div>
                <div class="col-md-4">
                    <label class="form-label-poly">Quiet Hours End</label>
                    <input type="time" class="form-control" id="quietEnd" value="07:00">
                </div>
            </div>

            <p class="text-muted-sm mt-3">Some critical system updates may still appear in-app even if email delivery is muted.</p>

            <div class="d-flex gap-2 mt-3">
                <a href="/views/calendar/month.cfm" class="btn btn-outline-secondary">Cancel</a>
                <button class="btn btn-primary-purple" onclick="saveAllPrefs()"><i class="fas fa-save me-1"></i>Save Preferences</button>
            </div>
        </div>
    </div>
</div>

<script>
var deliveryMode = 'instant';

$(document).ready(function() {
    loadExistingPrefs();
});

function loadExistingPrefs() {
    Polyculy.apiGet('/api/notifications.cfm?action=preferences').done(function(resp) {
        if (!resp.success) return;
        (resp.data || []).forEach(function(p) {
            var $toggle = $('.notif-toggle[data-type="' + p.notification_type + '"]');
            if ($toggle.length) {
                $toggle.prop('checked', p.is_enabled);
            }
            if (p.delivery_mode) deliveryMode = p.delivery_mode;
            if (p.quiet_start) $('##quietStart').val(p.quiet_start);
            if (p.quiet_end) $('##quietEnd').val(p.quiet_end);
        });
        setDeliveryMode(deliveryMode);
    });
}

function setDeliveryMode(mode) {
    deliveryMode = mode;
    $('##modeInstant, ##modeDigest').removeClass('active');
    if (mode === 'instant') $('##modeInstant').addClass('active');
    else $('##modeDigest').addClass('active');
}

function saveAllPrefs() {
    var promises = [];
    $('.notif-toggle').each(function() {
        var type = $(this).data('type');
        var enabled = $(this).is(':checked');
        promises.push(Polyculy.apiPost('/api/notifications.cfm?action=savePreference', {
            notificationType: type,
            isEnabled: enabled,
            deliveryMode: deliveryMode,
            quietStart: $('##quietStart').val(),
            quietEnd: $('##quietEnd').val()
        }));
    });

    $.when.apply($, promises).done(function() {
        Polyculy.showAlert('Notification preferences saved.', 'success');
    }).fail(function() {
        Polyculy.showAlert('Some preferences may not have saved.', 'error');
    });
}
</script>
</cfoutput>
</cf_main>
