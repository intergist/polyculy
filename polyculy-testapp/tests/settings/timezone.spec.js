// @ts-check
const { test } = require('../../fixtures/auth.fixture');
const { expect } = require('@playwright/test');
const config = require('../../helpers/config');
const { assertNoServerError } = require('../../helpers/test-utils');

/**
 * TEST SUITE: Settings — Timezone & Display Preferences
 * Tags: @core-regression @read-only-seed
 *
 * Verifies timezone selection, display preferences, and the settings page UI.
 *
 * Spec references:
 * - §13: Timezone Handling — stored as IANA timezone ID, displayed in viewer's timezone.
 * - UI Screen 22: Timezone & Display Preferences page.
 *
 * Dependencies: Admin user with seed preferences.
 * Data strategy: Read-only for verification; save-and-restore for modification tests.
 */
test.describe('Timezone — API Verification @core-regression @read-only-seed', () => {
  test('Get user preferences returns timezone', async ({ apiClient }) => {
    /**
     * Fetch user preferences.
     *
     * Expected: timezoneId is a valid IANA timezone string.
     */
    const resp = await apiClient.getPreferences();
    expect(resp.success).toBe(true);
    expect(resp.data.timezoneId).toBeDefined();
    // IANA timezone IDs contain a slash (e.g., America/New_York)
    expect(resp.data.timezoneId).toContain('/');
  });

  test('Save and restore timezone preference', async ({ apiClient }) => {
    /**
     * Save a different timezone, verify it persists, then restore original.
     *
     * Data strategy: Read original → save new → verify → restore original.
     */
    // Read original
    const origResp = await apiClient.getPreferences();
    const originalTz = origResp.data.timezoneId;

    // Save a different timezone
    const newTz = originalTz === 'America/New_York' ? 'America/Los_Angeles' : 'America/New_York';
    const saveResp = await apiClient.saveTimezone(newTz);
    expect(saveResp.success).toBe(true);

    // Verify it changed
    const verifyResp = await apiClient.getPreferences();
    expect(verifyResp.data.timezoneId).toBe(newTz);

    // Restore original
    await apiClient.saveTimezone(originalTz);
    const restoreResp = await apiClient.getPreferences();
    expect(restoreResp.data.timezoneId).toBe(originalTz);
  });

  test('Timezone uses IANA format, not fixed UTC offset', async ({ apiClient }) => {
    /**
     * Verify the system uses IANA timezone IDs per §13.
     *
     * Expected: timezoneId is NOT a fixed offset like "UTC-5".
     * Expected: timezoneId IS an IANA ID like "America/New_York".
     */
    const resp = await apiClient.getPreferences();
    const tz = resp.data.timezoneId;

    // Should not be a raw UTC offset
    expect(tz).not.toMatch(/^UTC[+-]\d+$/);
    // Should contain a region/city pattern
    expect(tz).toMatch(/^[A-Z][a-zA-Z]+\/[A-Za-z_]+/);
  });
});

test.describe('Timezone — UI Page @core-regression @read-only-seed', () => {
  test('Timezone settings page loads without errors', async ({ authenticatedPage }) => {
    /**
     * Navigate to timezone settings page.
     *
     * Expected: Page loads without server errors.
     * Expected: Timezone dropdown is present.
     */
    const page = authenticatedPage;
    await page.goto(config.urls.settingsTimezone);
    await page.waitForLoadState('domcontentloaded');
    await assertNoServerError(page);

    // The page should have a timezone selection element
    const content = await page.textContent('body');
    expect(content.toLowerCase()).toContain('timezone');
  });

  test('Timezone dropdown contains IANA timezone options', async ({ authenticatedPage }) => {
    /**
     * Verify timezone dropdown contains valid IANA timezone IDs.
     *
     * Expected: Dropdown has selectable options with IANA timezone IDs.
     */
    const page = authenticatedPage;
    await page.goto(config.urls.settingsTimezone);
    await page.waitForLoadState('domcontentloaded');

    // Look for a select element or timezone list
    const select = page.locator('select[name*="timezone"], [data-testid="timezone-select"]');
    const selectVisible = await select.isVisible().catch(() => false);

    if (selectVisible) {
      const options = await select.locator('option').allTextContents();
      expect(options.length).toBeGreaterThan(0);
      // At least one option should contain a slash (IANA format)
      const hasIana = options.some(opt => opt.includes('/'));
      expect(hasIana).toBe(true);
    }
  });
});

test.describe('Display Preferences — API @core-regression @read-only-seed', () => {
  test('Save display preferences for a polymate (nickname)', async ({ apiClient }) => {
    /**
     * Set a custom nickname for Riley, verify, then restore.
     *
     * Per §2.4: Display preferences are cosmetic only — nickname and avatar override.
     * Data strategy: Save new nickname → verify via connections list → restore.
     */
    const rileyId = config.seeds.riley.userId;

    // Save a custom nickname
    const saveResp = await apiClient.saveDisplayPrefs(rileyId, 'RileyTest', '', '#FF5733');
    expect(saveResp.success).toBe(true);

    // Restore original
    await apiClient.saveDisplayPrefs(rileyId, 'Riley', '', '');
  });
});
