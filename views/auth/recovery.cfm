<cf_main pageTitle="Password Recovery" showNav="false">
<cfoutput>

<div id="" class="d-flex justify-content-center align-items-center">
	<div class="shadow p-3 mt-5 mb-5 bg-white rounded">
		<div class="row auth-logo-area">
			<div class="col-3">
				<img src="/images/polyculy_logo_xs.png" width="75" height="66" title="Polyculy"/>
			</div>
			<div class="col">
				<span class="auth-title" style="font-size:36px;">Polyculy</span><br />
				<span class="auth-tagline">Calendar that keeps up</span>
			</div>
		</div>
		<p class="auth-subtitle">Multi-dimensional management of polyamorous relationhips</p>
		<hr />
		<h1 class="auth-title" style="font-size:1.5rem;">Let's get you back to Polyculy</h1>
		<div class="form-message" id="recoveryMessage" data-testid="recovery-message" style="display:none;"></div>
		
		<form id="recoveryForm" onsubmit="return handleRecovery(event)">
		<div class="row">
			<div class="col">
				<div class="input-group mb-3">
					<div class="input-group-prepend">
						<div class="input-group-text">@</div>
					</div>
					<input type="email" id="recoveryEmail" data-testid="recovery-email" class="form-control" placeholder="Email" required autocomplete="email">
				</div>
			</div>
		</div>
		<div class="row justify-content-center">
			<button type="submit" class="btn btn-primary-purple col-md-5" id="recoveryBtn">Continue</button>
		</div>
		<div class="row">
			<div class="col">
				Remembered? <a href="/views/auth/login.cfm">Log in</a>
			</div>
			<div class="col-6">
				<p class="float-right">
					<!---? <span class="auth-link-divider">&middot;</span> --->
					Not a member? <a href="/views/auth/signup.cfm" data-testid="signup-link">Sign up</a>
				</p>
			</div>
		</div>
	</form>
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
