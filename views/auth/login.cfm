 <cf_main pageTitle="Login" showNav="false">
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
		
		<div class="row">
			<div class="col">
				<form id="loginForm" data-testid="login-form" onsubmit="return handleLogin(event)">
					<div class="input-group mb-3">
						<div class="input-group-prepend">
							<div class="input-group-text input-icon-wrap">@</div>
						</div>
						<input type="email" class="form-control" id="loginEmail" data-testid="login-email" placeholder="Email" required autocomplete="email">
					</div>

					<div class="input-group mb-3">
						<span class="input-group-text input-icon-wrap"><i class="fas fa-lock input-icon"></i></span>
						<input type="password" id="loginPassword" data-testid="login-password" class="form-control" placeholder="Password" required autocomplete="current-password">
						<span class="input-group-text input-icon-wrap" class="password-toggle" onclick="togglePasswordVisibility(this)"><i class="fas fa-eye"></i></span>
					</div>
	
					<div class="form-message" id="loginMessage" data-testid="login-message" style="display:none;"></div>
					<div class="row justify-content-center">
						<button type="submit" class="btn btn-primary-purple col-md-5" id="loginBtn" 
							data-testid="login-button">Log In</button>
					</div>
				
					<div class="row auth-links">
						<div class="col-6">
							<a href="/views/auth/recovery.cfm" data-testid="forgot-password-link">Forgot password?</a>
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


  </div>
</div>



 <script>
function handleLogin(e) {
    e.preventDefault();
    var email = $('##loginEmail').val().trim();
    var password = $('##loginPassword').val();
    var $btn = $('##loginBtn');
    $btn.prop('disabled', true).text('Logging in...');
    $('##loginMessage').hide();

    Polyculy.login(email, password).done(function(resp) {
        if (resp.success) {
            var user = resp.user || {};
            if (user.calendarcreated) {
                window.location.href = '/views/calendar/month.cfm';
            } else {
                window.location.href = '/views/calendar/setup.cfm';
            }
        } else {
            $('##loginMessage').text(resp.message || 'Login failed.').addClass('error').show();
        }
    }).fail(function() {
        $('##loginMessage').text('Connection error. Please try again.').addClass('error').show();
    }).always(function() {
        $btn.prop('disabled', false).text('Log In');
    });
    return false;
}

function togglePasswordVisibility(btn) {
    var $input = $(btn).siblings('input');
    var $icon = $(btn).find('i');
    if ($input.attr('type') === 'password') {
        $input.attr('type', 'text');
        $icon.removeClass('fa-eye').addClass('fa-eye-slash');
    } else {
        $input.attr('type', 'password');
        $icon.removeClass('fa-eye-slash').addClass('fa-eye');
    }
}
</script>
</cfoutput>
</cf_main>
