# Maintenance Guide

## Adding New Tests

### 1. Choose the right location

| Feature Area | Directory | Example |
|---|---|---|
| Authentication | `tests/auth/` | Login, signup, password reset |
| Calendar | `tests/calendar/` | Views, data, navigation |
| Connections | `tests/connections/` | Send, revoke, licensing |
| Events | `tests/events/` | Personal event CRUD |
| Notifications | `tests/notifications/` | Bell, panel, preferences |
| Proposals | `tests/proposals/` | Create, accept, reject |
| Settings | `tests/settings/` | Timezone, notification prefs |
| Shared Events | `tests/shared-events/` | Response flows, conflicts |

### 2. Use the right fixture

```javascript
const { test } = require('../../fixtures/auth.fixture');
const { expect } = require('@playwright/test');

test('my test', async ({ authenticatedPage, apiClient, apiClientRiley }) => {
  // authenticatedPage = browser page logged in as admin
  // apiClient = HTTP client logged in as admin
  // apiClientRiley = HTTP client logged in as Riley
});
```

### 3. Follow data strategy patterns

**Read-only test:**
```javascript
test('verify seed data', async ({ apiClient }) => {
  const resp = await apiClient.listConnections();
  expect(resp.data).toHaveLength(6);
});
```

**Create-and-clean test:**
```javascript
test('create and clean', async ({ apiClient }) => {
  const createResp = await apiClient.createSharedEvent({ ... });
  const eventId = createResp.id;
  try {
    // Test assertions...
  } finally {
    await apiClient.cancelSharedEvent(eventId);
  }
});
```

### 4. Handle API response key casing

Some endpoints return UPPER_CASE keys, others camelCase or lowercase. Use fallback patterns:

```javascript
// For unpredictable casing
expect(resp.data.valid || resp.data.VALID).toBe(true);

// For shared event IDs
const eventId = event.SHARED_EVENT_ID || event.shared_event_id;
```

## Adding New API Methods

Add methods to `helpers/api-client.js`:

```javascript
async myNewMethod(param1, param2) {
  const resp = await this.request.post(`${config.api.myEndpoint}?action=myAction`, {
    form: { param1, param2 },
  });
  return resp.json();
}
```

## Adding Page Objects

Add page objects to `pages/`:

```javascript
class MyPage {
  constructor(page) {
    this.page = page;
    this.myElement = page.locator('[data-testid="my-element"]');
  }

  async goto() {
    await this.page.goto('/views/my/page.cfm');
    await this.page.waitForLoadState('domcontentloaded');
  }
}
```

## Adding data-testid Attributes

When adding new selectors to the Polyculy app:

1. Use `data-testid="descriptive-name"` format
2. Add to the HTML element in the view file
3. Keep names kebab-case and descriptive
4. Don't change existing data-testid values (tests depend on them)

## Updating Seed Data

If the seed data changes (new users, events, connections):

1. Update `sql/seed.sql` with the new data
2. Update `api/reset-seed.cfm` to handle the new ID ranges
3. Update `helpers/config.js` seed contracts (seedConnections, seedEvents, etc.)
4. Update `docs/seed-data-contract.md`
5. Run full suite to verify

## Running in CI

```yaml
- name: Install dependencies
  run: cd polyculy-testapp && npm ci

- name: Install Playwright browsers
  run: cd polyculy-testapp && npx playwright install chromium --with-deps

- name: Run tests
  run: cd polyculy-testapp && npx playwright test
  env:
    POLYCULY_BASE_URL: http://localhost:5000
    CI: true

- name: Upload report
  if: always()
  uses: actions/upload-artifact@v4
  with:
    name: playwright-report
    path: polyculy-testapp/reports/
```

## Troubleshooting

### Tests fail with "Loading..." text
AJAX-loaded content needs time to render. Use `waitFor()` on specific elements instead of fixed timeouts:
```javascript
await page.locator('.polycule-member').first().waitFor({ state: 'visible', timeout: 10000 });
```

### Tests fail after seed data change
Run `curl http://localhost:5000/api/reset-seed.cfm` to restore pristine state, then re-run.

### Server returns 302 redirects
The user's session expired. The test fixture's `authenticatedPage` handles login automatically, but API tests need the `apiClient` fixture.

### Inconsistent test results
Ensure `workers: 1` in `playwright.config.js`. Parallel execution causes state conflicts.
