<cf_main pageTitle="Invitation Results" showNav="true">
<cfoutput>
<div class="page-container">
    <div class="page-header">
        <h2 class="page-title"><i class="fas fa-check-circle me-2"></i>Invitation Results</h2>
    </div>

    <div class="row g-4">
        <!--- Left Panel: Results --->
        <div class="col-lg-7">
            <div id="resultsArea">
                <!--- Already on Polyculy --->
                <div class="card-polyculy mb-3">
                    <div class="card-header-poly">
                        <h5><i class="fas fa-user-check me-2 text-success"></i>Already on Polyculy</h5>
                    </div>
                    <div class="card-body-poly" id="existingUserResults">
                        <div class="text-center text-muted py-3"><i class="fas fa-spinner fa-spin"></i> Loading...</div>
                    </div>
                </div>

                <!--- Not on Polyculy Yet --->
                <div class="card-polyculy">
                    <div class="card-header-poly">
                        <h5><i class="fas fa-user-plus me-2 text-warning"></i>Not on Polyculy Yet</h5>
                    </div>
                    <div class="card-body-poly" id="newUserResults">
                        <div class="text-center text-muted py-3"><i class="fas fa-spinner fa-spin"></i> Loading...</div>
                    </div>
                </div>

                <p class="auth-helper-text mt-3">As soon as they confirm, you'll be able to start making plans together. Remember: existing events remain invisible by default. Update visibility settings if you'd like them to see already scheduled events.</p>

                <p class="auth-helper-text mt-2">Choose "Gift Licence" to purchase a Polyculy licence for them. Or, select "Send Invite" to email them a signup invitation. If a licence is gifted later, any prior signup-only invitation is automatically cancelled and replaced by the gifted flow. A licence cannot be gifted twice to the same person.</p>

                <a href="/views/connections/connect.cfm" class="btn btn-primary-purple mt-3">
                    <i class="fas fa-arrow-left me-1"></i>Back to Connections
                </a>
            </div>
        </div>

        <!--- Right Sidebar: Your Polycule --->
        <div class="col-lg-5">
            <div class="card-polyculy">
                <div class="card-header-poly">
                    <h5><i class="fas fa-heart me-2"></i>Your Polycule</h5>
                </div>
                <div class="card-body-poly" id="polyculeList">
                    <div class="text-center text-muted py-3"><i class="fas fa-spinner fa-spin"></i></div>
                </div>
            </div>
        </div>
    </div>
</div>

<script>
$(document).ready(function() {
    loadResults();
});

function loadResults() {
    Polyculy.loadPolycule().done(function(resp) {
        if (!resp.success) return;
        var members = resp.data || [];
        var existingHtml = '';
        var newHtml = '';
        var sidebarHtml = '';

        members.forEach(function(m) {
            var initial = m.displayname ? m.displayname.charAt(0).toUpperCase() : '?';
            var statusClass = '';
            var statusLabel = '';

            switch(m.status) {
                case 'connected': statusClass = 'connected'; statusLabel = 'Connected'; break;
                case 'awaiting_confirmation': statusClass = 'awaiting-confirmation'; statusLabel = 'Awaiting Confirmation'; break;
                case 'awaiting_signup': statusClass = 'awaiting-signup'; statusLabel = 'Awaiting Signup'; break;
                case 'licence_gifted_awaiting_signup': statusClass = 'licence-gifted'; statusLabel = 'Licence Gifted &middot; Awaiting Signup'; break;
                case 'revoked': statusClass = 'revoked'; statusLabel = 'Revoked'; break;
                default: statusLabel = m.status;
            }

            // Sidebar
            if (!m.ishidden) {
                sidebarHtml += '<div class="polycule-member">' +
                    '<div class="member-info"><div class="member-avatar">' + Polyculy.escapeHtml(initial) + '</div>' +
                    '<div><div class="member-name">' + Polyculy.escapeHtml(m.displayname) + '</div>' +
                    '<div class="member-status"><span class="status-dot ' + statusClass + '"></span>' + statusLabel + '</div></div></div></div>';
            }

            // Results
            if (m.status === 'awaiting_confirmation' || m.status === 'connected') {
                existingHtml += '<div class="polycule-member">' +
                    '<div class="member-info"><div class="member-avatar">' + Polyculy.escapeHtml(initial) + '</div>' +
                    '<div><div class="member-name">' + Polyculy.escapeHtml(m.displayname) + '</div>' +
                    '<div class="member-status"><span class="status-dot connected"></span>Invitation Sent</div></div></div></div>';
            } else if (m.status === 'awaiting_signup') {
                newHtml += '<div class="polycule-member">' +
                    '<div class="member-info"><div class="member-avatar">' + Polyculy.escapeHtml(initial) + '</div>' +
                    '<div><div class="member-name">' + Polyculy.escapeHtml(m.displayname) + '</div>' +
                    '<div class="member-status"><span class="status-dot awaiting-signup"></span>Awaiting Signup</div></div></div>' +
                    '<div class="member-actions">' +
                    '<button class="btn btn-sm btn-primary-purple me-1" onclick="giftLic(\'' + Polyculy.escapeHtml(m.email) + '\')"><i class="fas fa-gift me-1"></i>Gift Licence</button>' +
                    '<button class="btn btn-sm btn-outline-purple">Send Invite</button></div></div>';
            } else if (m.status === 'licence_gifted_awaiting_signup') {
                newHtml += '<div class="polycule-member">' +
                    '<div class="member-info"><div class="member-avatar">' + Polyculy.escapeHtml(initial) + '</div>' +
                    '<div><div class="member-name">' + Polyculy.escapeHtml(m.displayname) + '</div>' +
                    '<div class="member-status"><span class="status-dot licence-gifted"></span>Licence Gifted</div></div></div>' +
                    '<div class="member-actions">' +
                    '<button class="btn btn-sm btn-outline-secondary" disabled>Send Invite</button></div></div>';
            }
        });

        $('##existingUserResults').html(existingHtml || '<div class="text-muted py-2">No existing users found.</div>');
        $('##newUserResults').html(newHtml || '<div class="text-muted py-2">All invited users already have accounts.</div>');
        $('##polyculeList').html(sidebarHtml || '<div class="text-muted py-2">No connections yet.</div>');
    });
}

function giftLic(email) {
    if (!confirm('Gift a licence to ' + email + '?')) return;
    Polyculy.giftLicence(email).done(function(resp) {
        if (resp.success) {
            Polyculy.showAlert('Licence gifted!', 'success');
            loadResults();
        } else {
            Polyculy.showAlert(resp.message || 'Error.', 'error');
        }
    });
}
</script>
</cfoutput>
</cf_main>
