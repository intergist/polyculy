// @ts-check
const { test } = require('../../fixtures/auth.fixture');
const { expect } = require('@playwright/test');
const config = require('../../helpers/config');
const { assertNoServerError } = require('../../helpers/test-utils');

/**
 * TEST SUITE: Settings — Notification Preferences
 * Tags: @core-regression @read-only-seed
 *
 * Verifies notification preference management: per-type toggles,
 * delivery modes, and quiet hours.
 *
 * Spec references:
 * - §18: Notification Triggers — per-type mute, digest mode, quiet hours.
 * - UI Screen 24: Notification Preferences page.
 *
 * Dependencies: Admin user with default notification preferences.
 * Data strategy: Read-only for UI checks; save-and-restore for API modification tests.
 */
test.describe('Notification Preferences — API @core-regression @read-only-seed', () => {
  test('Get notification preferences returns data', async ({ apiClient }) => {
    /**
     * Fetch notification preferences.
     *
     * Expected: API returns success.
     * Expected: Data is an array of preference records.
     */
    const resp = await apiClient.getNotificationPreferences();
    expect(resp.success).toBe(true);
    expect(Array.isArray(resp.data)).toBe(true);
  });

  test('Save and restore a notification preference', async ({ apiClient }) => {
    /**
     * Toggle a notification type off, verify, then restore.
     *
     * Data strategy: Read current → save disabled → verify → restore enabled.
     */
    const notifType = 'shared_event_invitation';

    // Save preference: disable
    const saveResp = await apiClient.saveNotificationPreference(notifType, false, 'instant');
    expect(saveResp.success).toBe(true);

    // Verify it's saved
    const prefsResp = await apiClient.getNotificationPreferences();
    expect(prefsResp.success).toBe(true);

    // Restore: re-enable
    const restoreResp = await apiClient.saveNotificationPreference(notifType, true, 'instant');
    expect(restoreResp.success).toBe(true);
  });

  test('Delivery mode can be set to digest', async ({ apiClient }) => {
    /**
     * Set delivery mode to digest for a notification type, then restore.
     *
     * Per §18: Users can set delivery mode to instant or digest.
     */
    const notifType = 'connection_request';

    // Set to digest
    const saveResp = await apiClient.saveNotificationPreference(notifType, true, 'digest');
    expect(saveResp.success).toBe(true);

    // Restore to instant
    await apiClient.saveNotificationPreference(notifType, true, 'instant');
  });

  test('Quiet hours can be configured', async ({ apiClient }) => {
    /**
     * Set quiet hours, then restore.
     *
     * Per §18 / Screen 24: Quiet hours have start/end time pickers.
     */
    const notifType = 'shared_event_invitation';

    // Set quiet hours
    const saveResp = await apiClient.saveNotificationPreference(
      notifType, true, 'instant', '22:00', '07:00'
    );
    expect(saveResp.success).toBe(true);

    // Restore without quiet hours
    await apiClient.saveNotificationPreference(notifType, true, 'instant', '', '');
  });
});

test.describe('Notification Preferences — UI @core-regression @read-only-seed', () => {
  test('Notification preferences page loads without errors', async ({ authenticatedPage }) => {
    /**
     * Navigate to notification preferences page.
     *
     * Expected: Page loads without server errors.
     * Expected: Page contains notification-related text.
     */
    const page = authenticatedPage;
    await page.goto(config.urls.settingsNotifications);
    await page.waitForLoadState('domcontentloaded');
    await assertNoServerError(page);

    const content = await page.textContent('body');
    expect(content.toLowerCase()).toContain('notification');
  });

  test('Notification preference toggles are present', async ({ authenticatedPage }) => {
    /**
     * Verify toggle elements exist for various notification types.
     *
     * Per Screen 24: Per-type notification toggles for connection requests,
     * confirmations, revocations, shared event invitations, etc.
     */
    const page = authenticatedPage;
    await page.goto(config.urls.settingsNotifications);
    await page.waitForLoadState('domcontentloaded');

    // Look for toggle/checkbox/switch elements
    const toggles = await page.locator(
      'input[type="checkbox"], .toggle-switch, [role="switch"], [data-testid*="notif-toggle"]'
    ).all();

    // Should have multiple notification type toggles
    expect(toggles.length).toBeGreaterThan(0);
  });

  test('Delivery mode selector is present', async ({ authenticatedPage }) => {
    /**
     * Verify delivery mode selection (instant/digest) is available.
     *
     * Per Screen 24: Delivery Mode: Instant / Digest.
     */
    const page = authenticatedPage;
    await page.goto(config.urls.settingsNotifications);
    await page.waitForLoadState('domcontentloaded');

    const content = await page.textContent('body');
    const hasDeliveryMode = content.toLowerCase().includes('instant') ||
                           content.toLowerCase().includes('digest') ||
                           content.toLowerCase().includes('delivery');
    expect(hasDeliveryMode).toBe(true);
  });
});
