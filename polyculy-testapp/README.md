# Polyculy Test App — End-to-End Test Suite

Comprehensive Playwright E2E test suite for the Polyculy polyamorous calendar application.

## Overview

- **104 tests** across 22 spec files covering all major features
- Tests run against the live Polyculy instance (local or deployed)
- Automated seed data reset before each run via `global-setup.js`
- Serial execution (1 worker) to avoid state conflicts

## Quick Start

```bash
# Install dependencies
npm install

# Install Playwright browsers
npx playwright install chromium

# Copy .env and configure
cp .env.example .env

# Run all tests
npx playwright test

# Run with visible browser
npx playwright test --headed

# Run specific test suite
npx playwright test tests/auth/login.spec.js

# View HTML report
npx playwright show-report reports/html
```

## Project Structure

```
polyculy-testapp/
├── tests/                     # Test spec files
│   ├── auth/                  # Login, signup, password recovery
│   ├── calendar/              # Calendar views, data, setup
│   ├── connections/           # Connections, licensing, revocation
│   ├── events/                # Personal events lifecycle
│   ├── notifications/         # Notification bell, panel, API
│   ├── proposals/             # Proposal creation, lifecycle
│   ├── settings/              # Timezone, notification preferences
│   └── shared-events/         # Response flows, conflicts, ownership, participants
├── pages/                     # Page Object Models
│   ├── LoginPage.js
│   ├── SignupPage.js
│   ├── RecoveryPage.js
│   ├── CalendarPage.js
│   ├── ConnectionsPage.js
│   └── NavBar.js
├── fixtures/                  # Playwright test fixtures
│   └── auth.fixture.js        # Pre-authenticated page/API contexts
├── helpers/                   # Shared utilities
│   ├── config.js              # Centralized config, seed data contracts
│   ├── api-client.js          # HTTP API client (30+ methods)
│   └── test-utils.js          # Assertion helpers, date utilities
├── docs/                      # Documentation
│   ├── test-data-strategy.md
│   ├── seed-data-contract.md
│   └── maintenance.md
├── reports/                   # Generated test reports
│   ├── html/                  # HTML report (auto-generated)
│   └── junit-results.xml      # JUnit XML (for CI)
├── playwright.config.js       # Playwright configuration
├── global-setup.js            # Seed reset before test runs
├── package.json
├── .env                       # Local environment config
└── .env.example               # Environment template
```

## Test Coverage

| Area | Tests | Type |
|---|---|---|
| Authentication (login, signup, recovery) | 18 | UI + API |
| Calendar (views, data, setup) | 12 | UI + API |
| Connections (list, send, revoke) | 8 | UI + API |
| Licensing (validate, available) | 4 | API |
| Revocation (state, UI) | 4 | UI + API |
| Personal Events (CRUD, visibility) | 9 | API + UI |
| Shared Events (states, responses) | 13 | API |
| Response Flows (accept, decline, maybe, cancel, material edit) | 6 | API |
| Proposals (create, lifecycle, overwrite) | 5 | API |
| Participant Management (remove, visibility, reminders) | 4 | API |
| Ownership Transfer (API verification) | 3 | API |
| Conflict Handling | 2 | API |
| Notifications (list, badge, panel) | 7 | UI + API |
| Settings (timezone, notification prefs) | 9 | UI + API |
| **Total** | **104** | |

## Test Tags

Tests are organized by tags for selective execution:

- `@smoke` — Quick sanity tests (page loads, basic flows)
- `@core-regression` — Full regression coverage
- `@read-only-seed` — Tests that only read seed data (safe to run in any order)
- `@create-and-clean` — Tests that create temporary data and clean up after themselves

## Environment Variables

See `.env.example` for all configurable options:

| Variable | Default | Description |
|---|---|---|
| `POLYCULY_BASE_URL` | `http://localhost:5000` | Base URL of Polyculy instance |
| `POLYCULY_TEST_TIMEOUT` | `60000` | Per-test timeout (ms) |
| `POLYCULY_ACTION_TIMEOUT` | `10000` | Per-action timeout (ms) |
| `POLYCULY_HEADLESS` | `true` | Run browser headless |
| `POLYCULY_SLOW_MO` | `0` | Slow-motion delay (ms) |

## Fixtures

The test suite provides these fixtures via `auth.fixture.js`:

- **`authenticatedPage`** — A browser page logged in as the admin user ("You")
- **`rileyPage`** — A separate browser page logged in as Riley
- **`apiClient`** — HTTP API client authenticated as admin
- **`apiClientRiley`** — HTTP API client authenticated as Riley

## Data Strategy

Tests use three data strategies (see `docs/test-data-strategy.md`):

1. **Read-only seed** — Verifies existing seed data without mutation
2. **Create-and-clean** — Creates temporary test data and cleans up via app actions
3. **Global seed reset** — `reset-seed.cfm` endpoint restores pristine state before each run

No ad hoc SQL cleanup is performed during normal test runs.

## CI Integration

The suite generates JUnit XML at `reports/junit-results.xml` for CI systems. Set `POLYCULY_HEADLESS=true` (default) and `CI=true` for CI environments.

## Documentation

- [Test Data Strategy](docs/test-data-strategy.md) — How tests manage state
- [Seed Data Contract](docs/seed-data-contract.md) — Expected seed data and IDs
- [Maintenance Guide](docs/maintenance.md) — How to add/modify tests
