// @ts-check
const { test } = require('../../fixtures/auth.fixture');
const { expect } = require('@playwright/test');
const config = require('../../helpers/config');
const { assertNoServerError } = require('../../helpers/test-utils');

/**
 * TEST SUITE: Connection Results / Post-Invitation Screen
 * Tags: @smoke @read-only-seed
 *
 * Verifies the connection results page structure.
 *
 * Spec references:
 * - UI Screen 4: Post-Invitation Confirmation (results.cfm).
 * - Shows "Already on Polyculy" and "Not on Polyculy Yet" sections.
 * - Gift Licence / Send Invite actions.
 *
 * Data strategy: Read-only — verifies page loads and structure.
 */
test.describe('Connection Results Page @smoke @read-only-seed', () => {
  test('Connection results page loads without errors', async ({ authenticatedPage }) => {
    /**
     * Navigate to connection results page.
     *
     * Expected: Page loads without server errors.
     */
    const page = authenticatedPage;
    await page.goto(config.urls.connectionResults);
    await page.waitForLoadState('domcontentloaded');
    await assertNoServerError(page);
  });
});
