<cfscript>
    setting showDebugOutput=false;
    cfheader(name="Content-Type", value="application/json");

    userSvc = new model.UserService();
    licSvc = new model.LicenceService();
    auditSvc = new model.AuditService();

    param name="url.action" default="login";
    param name="form.action" default="";
    action = len(form.action) ? form.action : url.action;
    response = { "success": true };

    try {
        switch (action) {
            case "login":
                if (!structKeyExists(form, "email") || !structKeyExists(form, "password")) {
                    response = { "success": false, "message": "Email and password are required." };
                    break;
                }
                q = userSvc.authenticate(trim(form.email), form.password);
                if (q.recordCount > 0) {
                    session.isLoggedIn = true;
                    session.userId = q.user_id;
                    session.userEmail = q.email;
                    session.displayName = q.display_name;
                    session.timezoneId = q.timezone_id;
                    session.calendarCreated = q.calendar_created;
                    response["message"] = "Login successful.";
                    response["user"] = {
                        "userId": q.user_id,
                        "email": q.email,
                        "displayName": q.display_name,
                        "calendarCreated": q.calendar_created
                    };
                } else {
                    response = { "success": false, "message": "Invalid email or password." };
                }
                break;

            case "signup":
                if (!structKeyExists(form, "email") || !structKeyExists(form, "licenceCode")) {
                    response = { "success": false, "message": "Email and license code are required." };
                    break;
                }
                email = trim(form.email);
                code = trim(form.licenceCode);

                existingUser = userSvc.getByEmail(email);
                if (existingUser.recordCount > 0) {
                    response = { "success": false, "message": "An account with this email already exists." };
                    break;
                }

                licence = licSvc.validateCode(code);
                if (licence.recordCount == 0) {
                    response = { "success": false, "message": "Invalid or already redeemed license code." };
                    break;
                }

                if (licence.status == "gifted_pending" && len(licence.gifted_to_email) && licence.gifted_to_email != email) {
                    response = { "success": false, "message": "This license code was gifted to a different email address." };
                    break;
                }

                response["step"] = "set_password";
                response["email"] = email;
                response["licenceCode"] = code;
                break;

            case "completeSignup":
                if (!structKeyExists(form, "email") || !structKeyExists(form, "password") || !structKeyExists(form, "licenceCode") || !structKeyExists(form, "displayName")) {
                    response = { "success": false, "message": "All fields are required." };
                    break;
                }

                email = trim(form.email);
                password = form.password;
                code = trim(form.licenceCode);
                displayName = trim(form.displayName);

                if (len(password) < 6) {
                    response = { "success": false, "message": "Password must be at least 6 characters." };
                    break;
                }

                newUserId = userSvc.create(email, password, displayName);
                licSvc.redeemCode(code, newUserId);

                queryExecute(
                    "UPDATE polyculy.dbo.connections SET user_id_2 = :uid, status = 'awaiting_confirmation', updated_at = CURRENT_TIMESTAMP
                     WHERE invited_email = :email AND status IN ('awaiting_signup','licence_gifted_awaiting_signup')",
                    {
                        uid: { value: newUserId, cfsqltype: "cf_sql_integer" },
                        email: { value: email, cfsqltype: "cf_sql_varchar" }
                    }
                );

                auditSvc.log("user_signup", "user", newUserId, "New user signed up: #displayName#", newUserId);

                session.isLoggedIn = true;
                session.userId = newUserId;
                session.userEmail = email;
                session.displayName = displayName;
                session.timezoneId = "America/New_York";
                session.calendarCreated = false;

                response["message"] = "Account created successfully.";
                response["userId"] = newUserId;
                break;

            case "logout":
                structClear(session);
                session.isLoggedIn = false;
                response["message"] = "Logged out.";
                break;

            case "recovery":
                response["message"] = "If this email exists, a recovery link has been sent.";
                break;

            default:
                response = { "success": false, "message": "Unknown action: #action#" };
        }
    } catch (any e) {
        response = { "success": false, "message": e.message };
    }

    writeOutput(serializeJSON(response));
</cfscript>
