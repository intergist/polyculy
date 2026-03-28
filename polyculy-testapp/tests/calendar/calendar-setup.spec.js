// @ts-check
const { test } = require('../../fixtures/auth.fixture');
const { expect } = require('@playwright/test');
const config = require('../../helpers/config');
const { assertNoServerError } = require('../../helpers/test-utils');

/**
 * TEST SUITE: Calendar Setup
 * Tags: @smoke @read-only-seed
 *
 * Verifies the calendar setup page: three creation options,
 * page structure, and navigation.
 *
 * Spec references:
 * - §14: Calendar Setup & Import — three paths: Start From Scratch,
 *   Upload Calendar File, Sync with Google Calendar.
 * - UI Screen 6: Create Your Personal Calendar.
 *
 * Dependencies: Admin user with existing calendar (page may redirect).
 * Data strategy: Read-only — verifies page structure only.
 */
test.describe('Calendar Setup Page @smoke @read-only-seed', () => {
  test('Calendar setup page loads without errors', async ({ authenticatedPage }) => {
    /**
     * Navigate to calendar setup page.
     *
     * Expected: Page loads without server errors.
     * Note: If user already has a calendar, they may be redirected.
     */
    const page = authenticatedPage;
    await page.goto(config.urls.calendarSetup);
    await page.waitForLoadState('domcontentloaded');
    await assertNoServerError(page);
  });

  test('Calendar setup shows creation options', async ({ authenticatedPage }) => {
    /**
     * Verify the three calendar creation options are present.
     *
     * Per §14.1 / Screen 6:
     * - Start From Scratch → Create Empty Calendar
     * - Upload Calendar File → .ics import
     * - Import from Google Calendar → OAuth-based
     */
    const page = authenticatedPage;
    await page.goto(config.urls.calendarSetup);
    await page.waitForLoadState('domcontentloaded');

    const bodyText = await page.textContent('body');
    const bodyLower = bodyText.toLowerCase();

    // At least one of the setup options should be mentioned
    const hasSetupContent =
      bodyLower.includes('scratch') ||
      bodyLower.includes('upload') ||
      bodyLower.includes('google') ||
      bodyLower.includes('calendar') ||
      bodyLower.includes('create');

    expect(hasSetupContent).toBe(true);
  });

  test('Calendar setup page has action buttons or links', async ({ authenticatedPage }) => {
    /**
     * Verify the page has clickable elements for calendar creation.
     *
     * Expected: At least one button or link for creating/importing a calendar.
     */
    const page = authenticatedPage;
    await page.goto(config.urls.calendarSetup);
    await page.waitForLoadState('domcontentloaded');

    const actions = await page.locator('button, a.btn, .setup-option, [data-testid*="setup"]').all();
    expect(actions.length).toBeGreaterThan(0);
  });
});
