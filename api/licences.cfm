<cfscript>
    setting showDebugOutput=false;
    cfheader(name="Content-Type", value="application/json");

    licSvc = new model.LicenceService();
    auditSvc = new model.AuditService();
    notifSvc = new model.NotificationService();

    action = url.action ?: "list";
    response = { "success": true };

    try {
        switch (action) {
            case "list":
                q = licSvc.getByUser(session.userId);
                data = [];
                for (row in q) { arrayAppend(data, row); }
                response["data"] = data;
                break;

            case "validate":
                q = licSvc.validate(url.code ?: form.code ?: "");
                response["data"] = { valid: q.recordCount > 0 };
                if (q.recordCount) {
                    response["data"]["licence_type"] = q.licence_type;
                }
                break;

            case "gift":
                licSvc.giftLicence(session.userId, form.to_email, form.licence_code);
                auditSvc.log(session.userId, "licence_gift", "licence", 0, "Gifted license #form.licence_code# to #form.to_email#");
                notifSvc.create(session.userId, "licence_gifted", "License Gifted", "You gifted a license to #form.to_email#.", "licence", 0);
                response["message"] = "License gifted successfully";
                break;

            case "available":
                q = licSvc.getAvailableForUser(session.userId);
                data = [];
                for (row in q) { arrayAppend(data, row); }
                response["data"] = data;
                break;

            default:
                response = { "success": false, "message": "Unknown action" };
        }
    } catch (any e) {
        response = { "success": false, "message": e.message };
    }

    writeOutput(serializeJSON(response));
</cfscript>
