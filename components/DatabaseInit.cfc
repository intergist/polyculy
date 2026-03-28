component {

    function initialize() {
        try {
            var qCheck = queryExecute(
                "SELECT COUNT(*) AS cnt FROM INFORMATION_SCHEMA.TABLES WHERE UPPER(TABLE_NAME) = 'USERS' AND TABLE_SCHEMA = 'PUBLIC'",
                {},
                { datasource: "polyculy" }
            );
            if (qCheck.cnt > 0) return;
        } catch (any e) { /* proceed with init */ }

        // Run schema
        var schemaStatements = getSchemaStatements();
        for (var stmt in schemaStatements) {
            stmt = trim(stmt);
            if (len(stmt) > 0) {
                try {
                    queryExecute(stmt, {}, { datasource: "polyculy" });
                } catch (any e) {
                    writeLog(text="DBInit Schema: #e.message# | SQL: #left(stmt,200)#", type="warning");
                }
            }
        }

        // Run seed data
        var seedStatements = getSeedStatements();
        for (var stmt in seedStatements) {
            stmt = trim(stmt);
            if (len(stmt) > 0) {
                try {
                    queryExecute(stmt, {}, { datasource: "polyculy" });
                } catch (any e) {
                    writeLog(text="DBInit Seed: #e.message# | SQL: #left(stmt,200)#", type="warning");
                }
            }
        }
    }

    private array function getSchemaStatements() {
        var sqlFile = getDirectoryFromPath(getCurrentTemplatePath()) & "../sql/h2_schema.sql";
        var sqlContent = fileRead(sqlFile);
        return splitSQL(sqlContent);
    }

    private array function getSeedStatements() {
        var sqlFile = getDirectoryFromPath(getCurrentTemplatePath()) & "../sql/seed.sql";
        var sqlContent = fileRead(sqlFile);
        return splitSQL(sqlContent);
    }

    private array function splitSQL(required string sqlContent) {
        var lines = listToArray(arguments.sqlContent, chr(10));
        var statements = [];
        var currentStmt = "";

        for (var line in lines) {
            line = trim(line);
            // Skip empty lines and comments
            if (len(line) == 0 || left(line, 2) == "--") continue;

            currentStmt = currentStmt & " " & line;

            if (right(line, 1) == ";") {
                currentStmt = trim(replace(currentStmt, ";", "", "ALL"));
                if (len(currentStmt)) {
                    arrayAppend(statements, currentStmt);
                }
                currentStmt = "";
            }
        }

        // Handle any remaining statement without trailing semicolon
        currentStmt = trim(replace(currentStmt, ";", "", "ALL"));
        if (len(currentStmt)) {
            arrayAppend(statements, currentStmt);
        }

        return statements;
    }

}
