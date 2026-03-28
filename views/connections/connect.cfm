<cf_main pageTitle="Connect to Your Polycule" showNav="true">
<cfoutput>
<div class="page-container">
    <div class="page-header">
        <h2 class="page-title"><i class="fas fa-users me-2"></i>Connect to Your Polycule</h2>
    </div>

    <div class="row g-4">
        <!--- Left Panel: Link Me Up Form --->
        <div class="col-lg-7">
            <div class="card-polyculy">
                <div class="card-header-poly">
                    <h5><i class="fas fa-user-plus me-2"></i>Link me up to</h5>
                </div>
                <div class="card-body-poly">
                    <div id="connectionRows" data-testid="connection-rows">
                        <div class="connection-row">
                            <div class="row g-2 align-items-end">
                                <div class="col-md-5">
                                    <label class="form-label-poly">Email Address</label>
                                    <div class="input-icon-wrap">
                                        <i class="fas fa-envelope input-icon"></i>
                                        <input type="email" class="form-control conn-email" placeholder="Email address" required>
                                    </div>
                                </div>
                                <div class="col-md-4">
                                    <label class="form-label-poly">Display Name</label>
                                    <div class="input-icon-wrap">
                                        <i class="fas fa-user input-icon"></i>
                                        <input type="text" class="form-control conn-display" placeholder="Display name" required>
                                    </div>
                                </div>
                                <div class="col-md-3 d-flex align-items-end">
                                    <div class="member-avatar" style="width:36px;height:36px;font-size:0.8rem;background:var(--purple-200);color:var(--purple-700);">?</div>
                                </div>
                            </div>
                        </div>
                    </div>
                    <a href="##" class="add-another-link" onclick="addConnectionRow(); return false;">
                        <i class="fas fa-plus me-1"></i>Add Another Member
                    </a>
                    <div class="form-message" id="connMessage" data-testid="connection-message" style="display:none;"></div>
                    <button class="btn btn-primary-purple mt-3" onclick="sendAllConnectionRequests()">
                        <i class="fas fa-paper-plane me-1"></i>Send Connection Requests
                    </button>
                    <p class="auth-helper-text mt-2">Connections are mutual &mdash; both people must approve before the relationship becomes Connected.</p>
                </div>
            </div>
        </div>

        <!--- Right Sidebar: Your Polycule --->
        <div class="col-lg-5">
            <div class="card-polyculy">
                <div class="card-header-poly">
                    <h5><i class="fas fa-heart me-2"></i>Your Polycule</h5>
                </div>
                <div class="card-body-poly" id="polyculeList" data-testid="polycule-list">
                    <div class="text-center text-muted py-3"><i class="fas fa-spinner fa-spin"></i> Loading...</div>
                </div>
            </div>
        </div>
    </div>
</div>

<script>
$(document).ready(function() {
    loadPolyculeList();
});

function addConnectionRow() {
    var html = '<div class="connection-row mt-2">' +
        '<div class="row g-2 align-items-end">' +
        '<div class="col-md-5"><div class="input-icon-wrap"><i class="fas fa-envelope input-icon"></i>' +
        '<input type="email" class="form-control conn-email" placeholder="Email address" required></div></div>' +
        '<div class="col-md-4"><div class="input-icon-wrap"><i class="fas fa-user input-icon"></i>' +
        '<input type="text" class="form-control conn-display" placeholder="Display name" required></div></div>' +
        '<div class="col-md-3 d-flex align-items-end gap-2">' +
        '<div class="member-avatar" style="width:36px;height:36px;font-size:0.8rem;background:var(--purple-200);color:var(--purple-700);">?</div>' +
        '<button type="button" class="btn btn-sm btn-outline-danger" onclick="$(this).closest(\'.connection-row\').remove();">' +
        '<i class="fas fa-times"></i></button></div></div></div>';
    $('##connectionRows').append(html);
}

function sendAllConnectionRequests() {
    var rows = $('.connection-row');
    var requests = [];
    rows.each(function() {
        var email = $(this).find('.conn-email').val().trim();
        var display = $(this).find('.conn-display').val().trim();
        if (email && display) requests.push({ email: email, displayName: display });
    });

    if (requests.length === 0) {
        $('##connMessage').text('Please enter at least one email and display name.').addClass('error').show();
        return;
    }

    var completed = 0;
    var results = [];
    requests.forEach(function(req) {
        Polyculy.sendConnectionRequest(req.email, req.displayName).done(function(resp) {
            results.push({ email: req.email, success: resp.success, message: resp.message });
        }).fail(function() {
            results.push({ email: req.email, success: false, message: 'Network error' });
        }).always(function() {
            completed++;
            if (completed === requests.length) {
                // Show results and redirect
                window.location.href = '/views/connections/results.cfm';
            }
        });
    });
}

function loadPolyculeList() {
    Polyculy.loadPolycule().done(function(resp) {
        if (!resp.success) return;
        var members = resp.data || [];
        if (members.length === 0) {
            $('##polyculeList').html('<div class="text-center text-muted py-3">No connections yet. Start by inviting your polycule!</div>');
            return;
        }
        var html = '';
        members.forEach(function(m) {
            if (m.ishidden) return;
            var statusClass = getStatusClass(m.status);
            var statusLabel = getStatusLabel(m.status);
            var initial = m.displayname ? m.displayname.charAt(0).toUpperCase() : '?';

            html += '<div class="polycule-member">' +
                '<div class="member-info">' +
                '<div class="member-avatar">' + Polyculy.escapeHtml(initial) + '</div>' +
                '<div><div class="member-name">' + Polyculy.escapeHtml(m.displayname) + '</div>' +
                '<div class="member-status"><span class="status-dot ' + statusClass + '"></span>' + statusLabel + '</div></div>' +
                '</div>';

            // Context menu actions based on status
            html += '<div class="member-actions">';
            if (m.status === 'connected') {
                html += '<button class="btn btn-sm btn-outline-danger" onclick="revokeConn(' + (m.connectionid || 0) + ')">Revoke</button>';
            } else if (m.status === 'awaiting_confirmation') {
                html += '<button class="btn btn-sm btn-outline-danger me-1" onclick="revokeConn(' + (m.connectionid || 0) + ')">Revoke</button>';
                html += '<button class="btn btn-sm btn-outline-purple">Resend</button>';
            } else if (m.status === 'awaiting_signup') {
                html += '<button class="btn btn-sm btn-outline-danger me-1" onclick="revokeConn(' + (m.connectionid || 0) + ')">Revoke</button>';
                html += '<button class="btn btn-sm btn-outline-purple me-1">Resend</button>';
                html += '<button class="btn btn-sm btn-primary-purple" onclick="giftLic(\'' + Polyculy.escapeHtml(m.email) + '\')">Gift Licence</button>';
            } else if (m.status === 'licence_gifted_awaiting_signup') {
                // No actions per spec
            } else if (m.status === 'revoked') {
                html += '<button class="btn btn-sm btn-outline-secondary me-1" onclick="hideConn(' + (m.connectionid || 0) + ')">Hide</button>';
                html += '<button class="btn btn-sm btn-outline-purple">Reconnect</button>';
            }
            html += '</div></div>';
        });
        $('##polyculeList').html(html);
    });
}

function getStatusClass(status) {
    switch(status) {
        case 'connected': return 'connected';
        case 'awaiting_confirmation': return 'awaiting-confirmation';
        case 'awaiting_signup': return 'awaiting-signup';
        case 'licence_gifted_awaiting_signup': return 'licence-gifted';
        case 'revoked': return 'revoked';
        default: return '';
    }
}

function getStatusLabel(status) {
    switch(status) {
        case 'connected': return 'Connected';
        case 'awaiting_confirmation': return 'Awaiting Confirmation';
        case 'awaiting_signup': return 'Awaiting Signup';
        case 'licence_gifted_awaiting_signup': return 'Licence Gifted &middot; Awaiting Signup';
        case 'revoked': return 'Revoked';
        default: return status;
    }
}

function revokeConn(connId) {
    if (!confirm('Are you sure you want to revoke this connection?')) return;
    Polyculy.revokeConnection(connId).done(function(resp) {
        if (resp.success) {
            Polyculy.showAlert('Connection revoked.', 'success');
            loadPolyculeList();
        } else {
            Polyculy.showAlert(resp.message || 'Error.', 'error');
        }
    });
}

function hideConn(connId) {
    Polyculy.apiPost('/api/connections.cfm?action=hide', { connectionId: connId }).done(function(resp) {
        if (resp.success) {
            Polyculy.showAlert('Connection hidden.', 'success');
            loadPolyculeList();
        }
    });
}

function giftLic(email) {
    if (!confirm('Gift a license to ' + email + '?')) return;
    Polyculy.giftLicence(email).done(function(resp) {
        if (resp.success) {
            Polyculy.showAlert('License gifted!', 'success');
            loadPolyculeList();
        } else {
            Polyculy.showAlert(resp.message || 'Error gifting license.', 'error');
        }
    });
}
</script>
</cfoutput>
</cf_main>
