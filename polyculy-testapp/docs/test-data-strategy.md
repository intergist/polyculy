# Test Data Strategy

## Principles

1. **No direct SQL cleanup in normal test runs** — All cleanup happens through supported app behavior (API calls, cancellation, revocation).
2. **Idempotency** — Each test that creates data first checks if that data already exists. If found, it logs the condition and proceeds to cleanup.
3. **Seed data is the foundation** — The database seed provides all baseline data. Tests verify this data in read-only mode.
4. **Global reset before each run** — The `global-setup.js` script calls `reset-seed.cfm` to restore pristine seed state before the test suite executes.

## Data Strategies

### 1. Read-Only Seed (`@read-only-seed`)

Tests that only read existing seed data. These tests:
- Never create, update, or delete data
- Rely on the seed data contract (see `seed-data-contract.md`)
- Can run in any order without affecting other tests
- Are the safest and most stable tests

**Examples:** Login page loads, connections list shows 6 members, notification bell is visible.

### 2. Create-and-Clean (`@create-and-clean`)

Tests that create temporary data and clean up after themselves:
- Create test data via API (e.g., shared events, proposals)
- Exercise the feature under test
- Clean up via app actions (cancel event, revoke connection)
- Use `try/finally` blocks to ensure cleanup runs even on test failure

**Examples:** Accept response flow, proposal lifecycle, personal event CRUD.

### 3. Global Seed Reset

The `reset-seed.cfm` endpoint restores the database to pristine seed state:
- Deletes all non-seed data (connections > 6, events > 4, etc.)
- Resets seed data to original states (connection statuses, event states)
- Clears test-generated notifications, proposals, and audit log entries
- Called automatically by `global-setup.js` before each test run

## API Response Key Casing

Polyculy's CFML backend returns different key casing depending on the endpoint:

| Endpoint | Key Style | Example |
|---|---|---|
| Connections list | camelCase | `displayName`, `connectionId`, `status` |
| Connected users | camelCase | `userId`, `displayName`, `email` |
| Connection send | UPPER_CASE | `SUCCESS`, `MESSAGE`, `STATUS` |
| Shared events list | UPPER_CASE | `SHARED_EVENT_ID`, `TITLE`, `GLOBAL_STATE` |
| Shared event detail | lowercase | `global_state`, `participant_visibility`, `title` |
| Shared event participants | UPPER_CASE | `DISPLAY_NAME`, `RESPONSE_STATUS`, `USER_ID` |
| Notifications list | lowercase | `notification_id`, `notification_type`, `is_read` |
| Licences list | UPPER_CASE | `LICENCE_ID`, `LICENCE_CODE`, `STATUS` |
| Licence validate | mixed | `VALID` (uppercase), `licence_type` (lowercase) |
| Proposals | UPPER_CASE | `PROPOSAL_ID`, `STATUS`, `MESSAGE` |

Tests use fallback patterns like `resp.data.valid || resp.data.VALID` where necessary.

## Test Isolation

- **Serial execution** — Tests run with `workers: 1` to prevent state conflicts.
- **Fixture-scoped sessions** — Each test gets its own authenticated page/API context.
- **No shared mutable state** — Tests do not communicate through global variables.
