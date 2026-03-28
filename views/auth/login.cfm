<cf_main pageTitle="Login" showNav="false">
<cfquery name="q1" datasource="polyculyTest">
select * from polyculy.dbo.users
</cfquery>
<cfdump var="#q1#" expand="no"/>
<cfdump var="#application#" expand="no"/>
 <!--- --->
<!--- <cfdump var="#cgi#"/> --->
<cfoutput>
<div class="row justify-content-center">
	<div class="col-md-5">
		<div class="auth-page justify-content-center">
			<div class="auth-container">
				<div class="auth-logo-area justify-content-center">
					<svg width="56" height="56" viewBox="0 0 40 40" fill="none">
						<path d="M12 8C7 8 3 12 3 17C3 27 20 36 20 36C20 36 37 27 37 17C37 12 33 8 28 8C24.5 8 21.5 10 20 13C18.5 10 15.5 8 12 8Z" fill="url(##hg1)" opacity="0.7"/>
						<path d="M15 6C10 6 6 10 6 15C6 25 23 34 23 34C23 34 40 25 40 15C40 10 36 6 31 6C27.5 6 24.5 8 23 11C21.5 8 18.5 6 15 6Z" fill="url(##hg2)" opacity="0.8"/>
						<defs>
							<linearGradient id="hg1" x1="3" y1="8" x2="37" y2="36" gradientUnits="userSpaceOnUse"><stop stop-color="##EC4899"/><stop offset="1" stop-color="##8B5CF6"/></linearGradient>
							<linearGradient id="hg2" x1="6" y1="6" x2="40" y2="34" gradientUnits="userSpaceOnUse"><stop stop-color="##A855F7"/><stop offset="1" stop-color="##7C3AED"/></linearGradient>
						</defs>
					</svg>
					<h1 class="auth-title">Polyculy</h1>
					<p class="auth-tagline">Calendar that keeps up</p>
				</div>

			<div class="auth-hero">
					<div class="hero-illustration">
							<i class="fas fa-heart" style="color:##EC4899;font-size:2rem;margin:0 -5px;opacity:0.6;"></i>
							<i class="fas fa-heart" style="color:##A855F7;font-size:2.5rem;margin:0 -5px;opacity:0.7;"></i>
							<i class="fas fa-heart" style="color:##7C3AED;font-size:2rem;margin:0 -5px;opacity:0.6;"></i>
					</div>
					<p class="auth-subtitle">Multi-dimensional management of polyamorous relationhips</p>
			</div>
			<!--- Easy management for scheduling complexity of polyamorous relationships --->
		
			<form id="loginForm" data-testid="login-form" onsubmit="return handleLogin(event)">
				<div class="input-group mb-3">
					<div class="input-group-prepend">
						<div class="input-group-text">@</div>
					</div>
					<input type="email" class="form-control" id="loginEmail" data-testid="login-email" placeholder="Email" required autocomplete="email">
				</div>
		<!---             <div class="form-floating-group">
										<div class="input-icon-wrap">
												<i class="fas fa-envelope input-icon"></i>
												<input type="email" id="loginEmail" data-testid="login-email" class="form-control" placeholder="Email" required autocomplete="email">
										</div>
								</div> --->	
			
			<div class="input-group mb-3">
				<span class="input-group-text"><i class="fas fa-lock input-icon"></i></span>
				<input type="password" id="loginPassword" data-testid="login-password" class="form-control" placeholder="Password" required autocomplete="current-password">
				<span class="input-group-text" class="password-toggle" onclick="togglePasswordVisibility(this)"><i class="fas fa-eye"></i></span>
			</div>

		<!---             <div class="form-floating-group">
										<div class="input-icon-wrap">
												<i class="fas fa-lock input-icon"></i>
												<input type="password" id="loginPassword" data-testid="login-password" class="form-control" placeholder="Password" required autocomplete="current-password">
												<button type="button" class="password-toggle" onclick="togglePasswordVisibility(this)">
														<i class="fas fa-eye"></i>
												</button>
										</div>
								</div> --->
			<div class="form-message" id="loginMessage" data-testid="login-message" style="display:none;"></div>
			<div class="row justify-content-center">
				<button type="submit" class="btn btn-purple col-md-5" id="loginBtn" 
					data-testid="login-button">Log In</button>
			</div>
		</form>
			<div class="auth-links" style="text-align:center;"><br />
				<a href="/views/auth/recovery.cfm" data-testid="forgot-password-link">Forgot password?</a>
				<span class="auth-link-divider">&middot;</span>
				Not a member? <a href="/views/auth/signup.cfm" data-testid="signup-link">Sign up</a>
			</div>
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
