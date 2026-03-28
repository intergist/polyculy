<cf_main pageTitle="Password Recovery" showNav="false">
<cfoutput>
<div class="auth-page">
    <div class="auth-container">
        <div class="auth-logo-area">
            <svg width="48" height="48" viewBox="0 0 40 40" fill="none">
                <path d="M15 6C10 6 6 10 6 15C6 25 23 34 23 34C23 34 40 25 40 15C40 10 36 6 31 6C27.5 6 24.5 8 23 11C21.5 8 18.5 6 15 6Z" fill="url(##hg2)" opacity="0.8"/>
                <defs>
                    <linearGradient id="hg2" x1="6" y1="6" x2="40" y2="34" gradientUnits="userSpaceOnUse"><stop stop-color="##A855F7"/><stop offset="1" stop-color="##7C3AED"/></linearGradient>
                </defs>
            </svg>
            <h1 class="auth-title" style="font-size:1.5rem;">Let's get you back to Polyculy</h1>
        </div>

        <form id="recoveryForm" onsubmit="return handleRecovery(event)">
            <div class="form-floating-group">
                <div class="input-icon-wrap">
                    <i class="fas fa-envelope input-icon"></i>
                    <input type="email" id="recoveryEmail" data-testid="recovery-email" class="form-control" placeholder="Email" required>
                </div>
            </div>
            <div class="form-message" id="recoveryMessage" data-testid="recovery-message" style="display:none;"></div>
            <button type="submit" class="btn btn-primary-purple w-100" id="recoveryBtn">Continue</button>
        </form>

        <div class="auth-links">
            Remembered? <a href="/views/auth/login.cfm"><strong>Log in</strong></a>
        </div>
    </div>
</div>

<script>
function handleRecovery(e) {
    e.preventDefault();
    var email = $('##recoveryEmail').val().trim();
    $('##recoveryBtn').prop('disabled', true).text('Sending...');
    $('##recoveryMessage').hide();

    Polyculy.apiPost('/api/auth.cfm?action=recovery', { email: email }).done(function(resp) {
        $('##recoveryMessage').text(resp.message || 'If this email exists, a recovery link has been sent.').removeClass('error').addClass('success').show();
    }).fail(function() {
        $('##recoveryMessage').text('Connection error.').addClass('error').show();
    }).always(function() {
        $('##recoveryBtn').prop('disabled', false).text('Continue');
    });
    return false;
}
</script>
</cfoutput>
</cf_main>
