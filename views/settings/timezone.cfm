<cf_main pageTitle="Timezone & Display Preferences" showNav="true">
<cfoutput>
<div class="page-container">
    <div class="page-header">
        <h2 class="page-title"><i class="fas fa-globe me-2"></i>Timezone & Display Preferences</h2>
    </div>

    <div class="row g-4">
        <div class="col-lg-6">
            <div class="card-polyculy">
                <div class="card-header-poly"><h5><i class="fas fa-clock me-2"></i>Timezone Selection</h5></div>
                <div class="card-body-poly">
                    <div class="mb-3">
                        <label class="form-label-poly">Display Timezone</label>
                        <select class="form-select" id="tzSelect">
                            <option value="America/New_York">America/New_York (Eastern)</option>
                            <option value="America/Chicago">America/Chicago (Central)</option>
                            <option value="America/Denver">America/Denver (Mountain)</option>
                            <option value="America/Los_Angeles">America/Los_Angeles (Pacific)</option>
                            <option value="America/Anchorage">America/Anchorage (Alaska)</option>
                            <option value="Pacific/Honolulu">Pacific/Honolulu (Hawaii)</option>
                            <option value="Europe/London">Europe/London (GMT)</option>
                            <option value="Europe/Berlin">Europe/Berlin (CET)</option>
                            <option value="Europe/Paris">Europe/Paris (CET)</option>
                            <option value="Asia/Tokyo">Asia/Tokyo (JST)</option>
                            <option value="Asia/Shanghai">Asia/Shanghai (CST)</option>
                            <option value="Asia/Kolkata">Asia/Kolkata (IST)</option>
                            <option value="Australia/Sydney">Australia/Sydney (AEST)</option>
                            <option value="UTC">UTC</option>
                        </select>
                    </div>
                    <p class="text-muted-sm">Event times automatically adjust for DST using timezone-aware rules.</p>

                    <div class="mt-3 mb-3">
                        <label class="form-label-poly">Preview</label>
                        <div class="card-polyculy" style="background:var(--gray-50);">
                            <div class="card-body-poly" id="tzPreview">
                                <div class="inv-meta"><i class="far fa-clock me-1"></i>Current time in selected timezone: <strong id="previewTime">--</strong></div>
                            </div>
                        </div>
                    </div>

                    <div class="d-flex gap-2">
                        <button class="btn btn-outline-secondary" onclick="window.location.href='/views/calendar/month.cfm'">Cancel</button>
                        <button class="btn btn-primary-purple" onclick="saveTimezone()"><i class="fas fa-save me-1"></i>Save Preferences</button>
                    </div>
                </div>
            </div>
        </div>

        <div class="col-lg-6">
            <div class="card-polyculy">
                <div class="card-header-poly"><h5><i class="fas fa-palette me-2"></i>Polymate Display Preferences</h5></div>
                <div class="card-body-poly" id="displayPrefs">
                    <div class="text-center text-muted py-3"><i class="fas fa-spinner fa-spin"></i> Loading...</div>
                </div>
            </div>
        </div>
    </div>
</div>

<script>
$(document).ready(function() {
    // Set current timezone
    Polyculy.apiGet('/api/preferences.cfm?action=get').done(function(resp) {
        if (resp.success && resp.data) {
            $('##tzSelect').val(resp.data.timezoneid || 'America/New_York');
        }
    });
    updatePreview();
    $('##tzSelect').on('change', updatePreview);
    loadDisplayPrefs();
});

function updatePreview() {
    var tz = $('##tzSelect').val();
    try {
        var now = new Date().toLocaleString('en-US', { timeZone: tz, dateStyle: 'full', timeStyle: 'short' });
        $('##previewTime').text(now);
    } catch (e) {
        $('##previewTime').text(new Date().toLocaleString());
    }
}

function saveTimezone() {
    var tz = $('##tzSelect').val();
    Polyculy.apiPost('/api/preferences.cfm?action=saveTimezone', { timezoneId: tz }).done(function(resp) {
        if (resp.success) {
            Polyculy.showAlert('Timezone saved.', 'success');
        } else {
            Polyculy.showAlert(resp.message || 'Error.', 'error');
        }
    });
}

function loadDisplayPrefs() {
    Polyculy.loadConnectedMembers().done(function(resp) {
        if (!resp.success) return;
        var members = resp.data || [];
        if (members.length === 0) {
            $('##displayPrefs').html('<div class="text-muted py-3">No connected members to customize.</div>');
            return;
        }
        var html = '';
        members.forEach(function(m) {
            html += '<div class="polycule-member mb-3" style="flex-direction:column;align-items:stretch;">' +
                '<div class="d-flex align-items-center gap-2 mb-2">' +
                '<div class="member-avatar" style="width:36px;height:36px;font-size:0.8rem;">' + Polyculy.escapeHtml((m.displayname || '?').charAt(0)) + '</div>' +
                '<strong>' + Polyculy.escapeHtml(m.displayname) + '</strong></div>' +
                '<div class="row g-2">' +
                '<div class="col-6"><label class="form-label-poly" style="font-size:0.75rem;">Nickname</label>' +
                '<input type="text" class="form-control form-control-sm nickname-input" data-uid="' + m.userid + '" placeholder="' + Polyculy.escapeHtml(m.displayname) + '"></div>' +
                '<div class="col-6"><label class="form-label-poly" style="font-size:0.75rem;">Calendar Color</label>' +
                '<input type="color" class="form-control form-control-sm form-control-color color-input" data-uid="' + m.userid + '" value="' + (m.calendarcolor || '##7C3AED') + '"></div></div>' +
                '<button class="btn btn-sm btn-outline-purple mt-2" onclick="saveDisplayPref(' + m.userid + ')">Save</button></div>';
        });
        $('##displayPrefs').html(html);
    });
}

function saveDisplayPref(uid) {
    var nickname = $('.nickname-input[data-uid="' + uid + '"]').val();
    var color = $('.color-input[data-uid="' + uid + '"]').val();
    Polyculy.apiPost('/api/preferences.cfm?action=saveDisplayPrefs', {
        targetUserId: uid,
        nickname: nickname,
        calendarColor: color
    }).done(function(resp) {
        if (resp.success) Polyculy.showAlert('Preferences saved.', 'success');
        else Polyculy.showAlert(resp.message || 'Error.', 'error');
    });
}
</script>
</cfoutput>
</cf_main>
