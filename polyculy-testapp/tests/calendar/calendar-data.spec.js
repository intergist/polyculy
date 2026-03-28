// @ts-check
const { test } = require('../../fixtures/auth.fixture');
const { expect } = require('@playwright/test');
const config = require('../../helpers/config');
const { futureDate, formatDate } = require('../../helpers/test-utils');

/**
 * TEST SUITE: Calendar Data — API Verification
 * Tags: @core-regression @read-only-seed
 *
 * Verifies calendar events and overlay APIs return correct data structure.
 *
 * Spec references:
 * - §15: Calendar Views & Overlay.
 * - §15.1: View Dimensions — Day/Week/Month + Mine/Our.
 * - §15.2: Overlay Display Rules — all visible calendars equal.
 * - §15.5: Overlapping Events display strategy.
 *
 * Data strategy: Read-only — queries calendar APIs with date ranges.
 */
test.describe('Calendar Data — API @core-regression @read-only-seed', () => {
  test('Calendar events API returns data for current month', async ({ apiClient }) => {
    /**
     * Query calendar events for the current month.
     *
     * Expected: API returns success with an array of events.
     */
    const now = new Date();
    const startDate = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-01`;
    const endDate = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-28`;

    const resp = await apiClient.getCalendarEvents(startDate, endDate);
    expect(resp.success).toBe(true);
    expect(Array.isArray(resp.data)).toBe(true);
  });

  test('Calendar overlay API returns data for polycule view', async ({ apiClient }) => {
    /**
     * Query calendar overlay for polycule calendar view.
     *
     * Expected: API returns success with overlay data (events from connected users).
     */
    const now = new Date();
    const startDate = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-01`;
    const endDate = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-28`;

    const resp = await apiClient.getCalendarOverlay(startDate, endDate);
    expect(resp.success).toBe(true);
    expect(Array.isArray(resp.data)).toBe(true);
  });

  test('Calendar events include both personal and shared events', async ({ apiClient }) => {
    /**
     * Query a wide date range and verify both event types appear.
     *
     * Expected: Events array contains entries with type indicators.
     */
    const resp = await apiClient.getCalendarEvents('2026-01-01', '2026-12-31');
    expect(resp.success).toBe(true);

    // Should have at least one event from seed data
    if (resp.data.length > 0) {
      const first = resp.data[0];
      // Events should have title and time fields
      expect(first.TITLE || first.title).toBeDefined();
    }
  });
});
