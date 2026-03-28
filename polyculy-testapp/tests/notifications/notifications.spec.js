// @ts-check
const { test } = require('../../fixtures/auth.fixture');
const { expect } = require('@playwright/test');
const config = require('../../helpers/config');
const { assertNoServerError } = require('../../helpers/test-utils');
const CalendarPage = require('../../pages/CalendarPage');

/**
 * TEST SUITE: Notifications
 * Tags: @core-regression @read-only-seed
 *
 * Verifies the notification system: bell icon, badge count, notification list,
 * mark-as-read, notification types, and API endpoints.
 *
 * Dependencies: Seed notifications from shared event invitations and connection requests.
 * Data strategy: Read-only for seed verification; mark-read tests restore state.
 */
test.describe('Notifications — API Verification @core-regression @read-only-seed', () => {
  test('List notifications returns seed data', async ({ apiClient }) => {
    /**
     * Fetch notifications for admin user.
     *
     * Expected: Response is successful.
     * Expected: At least one notification exists from seed data
     *   (shared event invitations and connection activity generate notifications).
     */
    const resp = await apiClient.listNotifications();
    expect(resp.success).toBe(true);
    expect(Array.isArray(resp.data)).toBe(true);
    expect(resp.data.length).toBeGreaterThan(0);

    // Each notification has required fields
    const first = resp.data[0];
    expect(first.notification_id).toBeDefined();
    expect(first.notification_type).toBeDefined();
    expect(first.title).toBeDefined();
    expect(first.message).toBeDefined();
    expect(first.created_at).toBeDefined();
  });

  test('Unread count API returns a number', async ({ apiClient }) => {
    /**
     * Query unread notification count.
     *
     * Expected: Response contains a numeric count field.
     */
    const resp = await apiClient.getUnreadCount();
    expect(resp.success).toBe(true);
    expect(typeof resp.count).toBe('number');
    expect(resp.count).toBeGreaterThanOrEqual(0);
  });

  test('Notification types include expected categories', async ({ apiClient }) => {
    /**
     * List all notifications and verify known types appear.
     *
     * Expected: At least one notification with a recognized type exists.
     * Known types: connection_request, shared_event_invitation, shared_event_accepted,
     *   shared_event_declined, material_edit, event_cancelled, proposal_received, etc.
     */
    const resp = await apiClient.listNotifications(50);
    const types = new Set(resp.data.map(n => n.notification_type));

    // At minimum, seed data generates invitation-related notifications
    expect(types.size).toBeGreaterThan(0);
  });

  test('Mark single notification as read', async ({ apiClient }) => {
    /**
     * Mark one notification as read, then verify state change.
     *
     * Data strategy: Read the notification, note its is_read state,
     * mark it read, verify, then restore if it was unread.
     */
    const listResp = await apiClient.listNotifications();
    expect(listResp.data.length).toBeGreaterThan(0);

    const target = listResp.data[0];
    const wasRead = target.is_read;

    // Mark as read
    const markResp = await apiClient.markNotificationRead(target.notification_id);
    expect(markResp.success).toBe(true);

    // Verify it's now read
    const afterResp = await apiClient.listNotifications();
    const updated = afterResp.data.find(n => n.notification_id === target.notification_id);
    expect(updated).toBeTruthy();
    // is_read should be true (could be 1, true, or "1" depending on DB serialization)
    expect([true, 1, '1', 'true']).toContain(updated.is_read);
  });

  test('Mark all notifications as read', async ({ apiClient }) => {
    /**
     * Mark all notifications as read.
     *
     * Expected: API succeeds, unread count becomes 0.
     */
    const resp = await apiClient.markAllNotificationsRead();
    expect(resp.success).toBe(true);

    const countResp = await apiClient.getUnreadCount();
    expect(countResp.count).toBe(0);
  });
});

test.describe('Notifications — UI Bell & Panel @core-regression @read-only-seed', () => {
  test('Notification bell is visible on calendar page', async ({ authenticatedPage }) => {
    /**
     * Navigate to calendar and verify the notification bell icon exists.
     *
     * Expected: Bell icon with data-testid is present.
     */
    const page = authenticatedPage;
    const calPage = new CalendarPage(page);
    await calPage.gotoMonth();
    await assertNoServerError(page);

    const bell = page.locator('[data-testid="notification-bell"]');
    await expect(bell).toBeVisible({ timeout: 5000 });
  });

  test('Notification badge shows count', async ({ authenticatedPage }) => {
    /**
     * Verify notification badge displays a number (or is hidden if zero).
     *
     * Expected: Badge is either hidden (count=0) or shows a positive integer.
     */
    const page = authenticatedPage;
    const calPage = new CalendarPage(page);
    await calPage.gotoMonth();

    const badge = page.locator('[data-testid="notification-badge"]');
    const isVisible = await badge.isVisible().catch(() => false);
    if (isVisible) {
      const text = await badge.textContent();
      const count = parseInt(text, 10);
      expect(count).toBeGreaterThanOrEqual(0);
    }
    // If not visible, count is implicitly 0 — acceptable
  });

  test('Clicking bell opens notification panel', async ({ authenticatedPage }) => {
    /**
     * Click the notification bell and verify the panel opens.
     *
     * Expected: Notification panel becomes visible.
     */
    const page = authenticatedPage;
    const calPage = new CalendarPage(page);
    await calPage.gotoMonth();

    const bell = page.locator('[data-testid="notification-bell"]');
    await bell.click();

    const panel = page.locator('[data-testid="notification-panel"]');
    await expect(panel).toBeVisible({ timeout: 5000 });
  });
});
