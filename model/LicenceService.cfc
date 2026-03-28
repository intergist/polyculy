component {

    function validateCode(required string licenceCode) {
        return queryExecute(
            "SELECT licence_id, licence_code, licence_type, status, gifted_to_email
             FROM polyculy.dbo.licences WHERE licence_code = :code AND status IN ('available','gifted_pending')",
            { code: { value: arguments.licenceCode, cfsqltype: "cf_sql_varchar" } }
        );
    }

    function redeemCode(required string licenceCode, required numeric userId) {
        queryExecute(
            "UPDATE polyculy.dbo.licences SET redeemed_by_user_id = :uid, status = 'redeemed', redeemed_at = CURRENT_TIMESTAMP
             WHERE licence_code = :code AND status IN ('available','gifted_pending')",
            {
                uid: { value: arguments.userId, cfsqltype: "cf_sql_integer" },
                code: { value: arguments.licenceCode, cfsqltype: "cf_sql_varchar" }
            }
        );
    }

    function giftLicence(required numeric fromUserId, required string toEmail, required string licenceCode) {
        // Check if already gifted to this email
        var existing = queryExecute(
            "	SELECT polyculy.dbo.licence_id FROM licences 
							WHERE gifted_to_email = :email AND status = 'gifted_pending'",
            { email: { value: arguments.toEmail, cfsqltype: "cf_sql_varchar" } }
        );
        if (existing.recordCount > 0) {
            return { success: false, message: "A license has already been gifted to this person." };
        }

        queryExecute(
            "INSERT INTO polyculy.dbo.licences (licence_code, licence_type, gifted_to_email, gifted_by_user_id, status)
             VALUES (:code, 'gifted', :email, :uid, 'gifted_pending')",
            {
                code: { value: arguments.licenceCode, cfsqltype: "cf_sql_varchar" },
                email: { value: arguments.toEmail, cfsqltype: "cf_sql_varchar" },
                uid: { value: arguments.fromUserId, cfsqltype: "cf_sql_integer" }
            }
        );
        return { success: true, message: "License gifted successfully." };
    }

    function isGiftedTo(required string email) {
        var q = queryExecute(
            "SELECT polyculy.dbo.licence_id FROM licences WHERE gifted_to_email = :email AND status = 'gifted_pending'",
            { email: { value: arguments.email, cfsqltype: "cf_sql_varchar" } }
        );
        return q.recordCount > 0;
    }

    function getByUser(required numeric userId) {
        return queryExecute(
            "SELECT l.*, u.display_name AS gifted_by_name
             FROM polyculy.dbo.licences l LEFT JOIN users u ON l.gifted_by_user_id = u.user_id
             WHERE l.redeemed_by_user_id = :uid OR l.gifted_by_user_id = :uid ORDER BY l.created_at DESC",
            { uid: { value: arguments.userId, cfsqltype: "cf_sql_integer" } }
        );
    }

    /** Alias used by licences.cfm API handler */
    function validate(required string code) {
        return validateCode(arguments.code);
    }

    /** Get available (unredeemed, ungifted) licences for a user to gift */
    function getAvailableForUser(required numeric userId) {
        return queryExecute(
            "SELECT licence_id, licence_code, licence_type, status, created_at
             FROM polyculy.dbo.licences
             WHERE status = 'available'
             ORDER BY created_at DESC",
            {}
        );
    }

}
