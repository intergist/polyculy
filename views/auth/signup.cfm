<cf_main pageTitle="Sign Up" showNav="false">
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
 		<div class="row">
			<div class="col">
				<span class="auth-subtitle">Multi-dimensional management of polyamorous relationhips</p>
				<hr />
				<h1 class="auth-title" style="font-size:1.6rem;">Welcome to Polyculy!</h1>
			</div>
		</div>
		
		<!---[ Step 1: Email + License Code ]--->
		<div class="row" id="signupStep1">
	
 		<form id="signupForm1" onsubmit="return handleSignupStep1(event)">
			<span class="auth-subtitle">Enter a license code you received by gift, promo, or purchase</span>
			<div class="row">
				<div class="col">
					<div class="input-group mb-3">
						<div class="input-group-prepend">
							<div class="input-group-text input-icon-wrap">@</div>
						</div>
						<input type="email" id="signupEmail" data-testid="signup-email" class="form-control" placeholder="Email Address" required>
					</div>
						
					<div class="input-group mb-3">
						<div class="input-group-prepend">
							<div class="input-group-text input-icon-wrap"><i class="fas fa-key input-icon"></i></div>
						</div>
						<input type="text" id="signupLicenceCode" data-testid="signup-licence" class="form-control" placeholder="License Code" required>
					</div>
					<div class="form-message" id="signupMessage1" data-testid="signup-message" style="display:none;"></div>
				</div>		
			</div>
			<div class="row justify-content-center">
				<button type="submit" class="btn btn-primary-purple w-50" id="signupBtn1">Continue</button>
			</div>
			<div class="row">
				<div class="col">
					<span style="font-size:0.75rem;">*New users may receive their own license for free during promo/seeding periods.<br />Additional licenses for partners may require a purchased pack.</span>
				</div>
			</div>
		</form>
		</div>
		
		<!---[ Step 2: Set Password + Display Name ]--->
		<div class="row" id="signupStep2" style="display:none;">
			<form id="signupForm2" onsubmit="return handleSignupStep2(event)">
				<div class="row">
					<div class="col">
						<div class="input-group mb-3">
							<div class="input-group-prepend">
								<div class="input-group-text input-icon-wrap"><i class="fas fa-user"></i></div>
							</div>
							<input type="text" id="signupDisplayName" class="form-control" placeholder="Display Name" required>
						</div>
						
						<div class="input-group mb-3">
							<div class="input-group-prepend">
								<div class="input-group-text input-icon-wrap"><i class="fas fa-lock"></i></div>
							</div>
							<input type="password" id="signupPassword" class="form-control" placeholder="Password (min 6 characters)" required minlength="6">
						</div>
	
						<div class="input-group mb-3">
							<div class="input-group-prepend">
								<div class="input-group-text input-icon-wrap"><i class="fas fa-lock"></i></div>
							</div>
							<input type="password" id="signupPasswordConfirm" class="form-control" placeholder="Confirm Password" required minlength="6">
						</div>
					</div>
				</div>
				<div class="row justify-content-center">
					<div class="form-message" id="signupMessage2" style="display:none;"></div>
					<button type="submit" class="btn btn-primary-purple w-50" id="signupBtn2">Create Account</button>
				</div>
			</form>
		</div>


						
		

				
 				<div class="row mt-3">
					<div class="col">
						Already a member? <a href="/views/auth/login.cfm">Log in</a>
					</div>
				</div> <!------>
				
				
				
		
  </div>
</div>		
		
		



<!--- <div class="auth-page">
    <div class="auth-container">
        <div class="auth-logo-area">
            <svg width="48" height="48" viewBox="0 0 40 40" fill="none">
                <path d="M12 8C7 8 3 12 3 17C3 27 20 36 20 36C20 36 37 27 37 17C37 12 33 8 28 8C24.5 8 21.5 10 20 13C18.5 10 15.5 8 12 8Z" fill="url(##hg1)" opacity="0.7"/>
                <path d="M15 6C10 6 6 10 6 15C6 25 23 34 23 34C23 34 40 25 40 15C40 10 36 6 31 6C27.5 6 24.5 8 23 11C21.5 8 18.5 6 15 6Z" fill="url(##hg2)" opacity="0.8"/>
                <defs>
                    <linearGradient id="hg1" x1="3" y1="8" x2="37" y2="36" gradientUnits="userSpaceOnUse"><stop stop-color="##EC4899"/><stop offset="1" stop-color="##8B5CF6"/></linearGradient>
                    <linearGradient id="hg2" x1="6" y1="6" x2="40" y2="34" gradientUnits="userSpaceOnUse"><stop stop-color="##A855F7"/><stop offset="1" stop-color="##7C3AED"/></linearGradient>
                </defs>
            </svg>
            
        </div>


    </div>
</div> --->

<script>
var signupData = {};

function handleSignupStep1(e) {
    e.preventDefault();
    var email = $('##signupEmail').val().trim();
    var code = $('##signupLicenceCode').val().trim();
    $('##signupBtn1').prop('disabled', true).text('Validating...');
    $('##signupMessage1').hide();

    Polyculy.signup(email, code).done(function(resp) {
        if (resp.success && resp.step === 'set_password') {
            signupData.email = resp.email;
            signupData.licenceCode = resp.licencecode;
            $('##signupStep1').hide();
            $('##signupStep2').show();
        } else {
            $('##signupMessage1').text(resp.message || 'Validation failed.').addClass('error').show();
        }
    }).fail(function() {
        $('##signupMessage1').text('Connection error.').addClass('error').show();
    }).always(function() {
        $('##signupBtn1').prop('disabled', false).text('Continue');
    });
    return false;
}

function handleSignupStep2(e) {
    e.preventDefault();
    var password = $('##signupPassword').val();
    var confirm = $('##signupPasswordConfirm').val();
    var displayName = $('##signupDisplayName').val().trim();
    $('##signupMessage2').hide();

    if (password !== confirm) {
        $('##signupMessage2').text('Passwords do not match.').addClass('error').show();
        return false;
    }

    $('##signupBtn2').prop('disabled', true).text('Creating account...');

    Polyculy.completeSignup(signupData.email, password, signupData.licenceCode, displayName).done(function(resp) {
        if (resp.success) {
            window.location.href = '/views/calendar/setup.cfm';
        } else {
            $('##signupMessage2').text(resp.message || 'Signup failed.').addClass('error').show();
        }
    }).fail(function() {
        $('##signupMessage2').text('Connection error.').addClass('error').show();
    }).always(function() {
        $('##signupBtn2').prop('disabled', false).text('Create Account');
    });
    return false;
}
</script>
</cfoutput>
</cf_main>
