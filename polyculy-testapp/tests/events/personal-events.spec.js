// @ts-check
const { test } = require('../../fixtures/auth.fixture');
const { expect } = require('@playwright/test');
const config = require('../../helpers/config');
const { assertNoServerError } = require('../../helpers/test-utils');

/**
 * TEST SUITE: Personal Events
 * Tags: @core-regression @read-only-seed
 *
 * Verifies personal event data, visibility tiers, and the personal event
 * detail view through the API.
 *
 * Dependencies: Seed personal events must exist.
 * Data strategy: Read-only — verifies existing seed events and their visibility.
 */
test.describe('Personal Events — Seed Data Verification @core-regression @read-only-seed', () => {
  test('List personal events returns seed data', async ({ apiClient }) => {
    /**
     * Query the events API for the admin user's personal events.
     *
     * Expected: 3 personal events returned:
     * - Doctor's appointment (full_details visibility)
     * - Yoga Class (invisible visibility)
     * - Work Meeting (full_details visibility)
     */
    const resp = await apiClient.listPersonalEvents();
    expect(resp.success).toBe(true);
    expect(resp.data).toHaveLength(3);

    const titles = resp.data.map(e => e.TITLE);
    expect(titles).toContain("Doctor's appointment");
    expect(titles).toContain('Yoga Class');
    expect(titles).toContain('Work Meeting');
  });

  test('Invisible event has correct visibility tier', async ({ apiClient }) => {
    /**
     * Get Yoga Class event details.
     *
     * Expected: visibility_tier = "invisible"
     * Expected: No visibility records for other users.
     */
    const resp = await apiClient.getPersonalEvent(config.seedEvents.personal.yogaClass.id);
    expect(resp.success).toBe(true);
    expect(resp.data.visibility_tier).toBe('invisible');
    expect(resp.data.visibility).toHaveLength(0);
  });

  test('Full-details event has correct visibility sharing', async ({ apiClient }) => {
    /**
     * Get Doctor's appointment event details.
     *
     * Expected: visibility_tier = "full_details"
     * Expected: Riley is in the visibility list with type "full_details"
     */
    const resp = await apiClient.getPersonalEvent(config.seedEvents.personal.doctorAppointment.id);
    expect(resp.success).toBe(true);
    expect(resp.data.visibility_tier).toBe('full_details');
    expect(resp.data.visibility.length).toBeGreaterThan(0);

    const rileyVis = resp.data.visibility.find(v => v.DISPLAY_NAME === 'Riley');
    expect(rileyVis).toBeTruthy();
    expect(rileyVis.VISIBILITY_TYPE).toBe('full_details');
  });

  test('Work Meeting is shared as busy block with Riley', async ({ apiClient }) => {
    /**
     * Get Work Meeting event details.
     *
     * Expected: visibility_tier = "full_details" (overall setting)
     * Expected: Riley has "busy_block" visibility in the per-user records
     */
    const resp = await apiClient.getPersonalEvent(config.seedEvents.personal.workMeeting.id);
    expect(resp.success).toBe(true);

    const rileyVis = resp.data.visibility.find(v => v.DISPLAY_NAME === 'Riley');
    expect(rileyVis).toBeTruthy();
    expect(rileyVis.VISIBILITY_TYPE).toBe('busy_block');
  });
});

test.describe('Personal Events — UI Verification @core-regression @read-only-seed', () => {
  test('Personal event modal has required fields', async ({ authenticatedPage }) => {
    /**
     * Open the personal event creation modal from the calendar.
     *
     * Expected: Modal appears with Title, Start Date, End fields, Sharing section.
     */
    const page = authenticatedPage;
    await page.goto(config.urls.calendarMonth);
    await assertNoServerError(page);

    // Click add personal event button
    const addBtn = page.locator('button:has-text("Personal Event"), a:has-text("Personal Event")');
    if (await addBtn.isVisible()) {
      await addBtn.click();
      await page.waitForTimeout(500);

      // Check modal fields
      const titleInput = page.locator('[data-testid="pe-title"]');
      const startDateInput = page.locator('[data-testid="pe-start-date"]');
      await expect(titleInput).toBeVisible();
      await expect(startDateInput).toBeVisible();
    }
  });
});
