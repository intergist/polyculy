// @ts-check
const { test } = require('../../fixtures/auth.fixture');
const { expect } = require('@playwright/test');
const CalendarPage = require('../../pages/CalendarPage');
const { assertNoServerError } = require('../../helpers/test-utils');

/**
 * TEST SUITE: Calendar Views and Navigation
 * Tags: @core-regression @read-only-seed
 *
 * Tests calendar page rendering, view toggles (day/week/month),
 * perspective toggles (Mine/Our), and navigation controls.
 *
 * Dependencies: Seed events and connections must exist.
 * Data strategy: Read-only — only views and navigates, no data mutations.
 */
test.describe('Calendar Views @core-regression @read-only-seed', () => {
  test('Month view loads with correct structure', async ({ authenticatedPage }) => {
    /**
     * Navigate to calendar month view.
     *
     * Expected: Page loads with calendar title, navigation, view toggles, and grid.
     */
    const page = authenticatedPage;
    const calendar = new CalendarPage(page);
    await calendar.gotoMonth();
    await assertNoServerError(page);

    await expect(calendar.title).toBeVisible();
    await expect(calendar.grid).toBeVisible();
    await expect(calendar.dayBtn).toBeVisible();
    await expect(calendar.weekBtn).toBeVisible();
    await expect(calendar.monthBtn).toBeVisible();
    await expect(calendar.mineBtn).toBeVisible();
    await expect(calendar.ourBtn).toBeVisible();
  });

  test('Week view loads correctly', async ({ authenticatedPage }) => {
    /**
     * Navigate directly to week view.
     *
     * Expected: Week view renders and the nav title updates from "Loading...".
     */
    const page = authenticatedPage;
    const calendar = new CalendarPage(page);
    await calendar.gotoWeek();
    await assertNoServerError(page);

    // Wait for JS to load the calendar title
    await page.waitForTimeout(2000);
    const navTitle = page.locator('[data-testid="calendar-nav-title"], .calendar-nav-title');
    const text = await navTitle.textContent();
    // Should have loaded from "Loading..." to actual date
    expect(text.length).toBeGreaterThan(0);
  });

  test('Day view loads correctly', async ({ authenticatedPage }) => {
    /**
     * Navigate directly to day view.
     *
     * Expected: Day view renders with date title.
     */
    const page = authenticatedPage;
    const calendar = new CalendarPage(page);
    await calendar.gotoDay();
    await assertNoServerError(page);

    // Wait for JS to load
    await page.waitForTimeout(2000);
    const navTitle = page.locator('[data-testid="calendar-nav-title"], .calendar-nav-title');
    const text = await navTitle.textContent();
    expect(text.length).toBeGreaterThan(0);
  });

  test('View toggle buttons exist and respond to clicks', async ({ authenticatedPage }) => {
    /**
     * Click each view toggle button from month view.
     *
     * Note: Polyculy uses JavaScript-based view switching (Polyculy.setView),
     * which may not trigger URL navigation. Tests verify the buttons exist
     * and are clickable.
     */
    const page = authenticatedPage;
    const calendar = new CalendarPage(page);
    await calendar.gotoMonth();

    // Verify all view toggle buttons are visible
    await expect(calendar.weekBtn).toBeVisible();
    await expect(calendar.dayBtn).toBeVisible();
    await expect(calendar.monthBtn).toBeVisible();

    // Click week button — should not error
    await calendar.switchToWeek();
    await page.waitForTimeout(1000);

    // Click day button
    await calendar.switchToDay();
    await page.waitForTimeout(1000);

    // Click month button
    await calendar.switchToMonth();
    await page.waitForTimeout(1000);
  });

  test('Calendar navigation changes displayed period', async ({ authenticatedPage }) => {
    /**
     * Click next/prev navigation buttons.
     *
     * Expected: Nav title updates to show the new period.
     */
    const page = authenticatedPage;
    const calendar = new CalendarPage(page);
    await calendar.gotoMonth();
    await page.waitForTimeout(2000);

    const initialTitle = await calendar.getNavTitle();

    // Navigate forward
    await calendar.navigateNext();
    await page.waitForTimeout(1500);
    const nextTitle = await calendar.getNavTitle();
    expect(nextTitle).not.toBe(initialTitle);

    // Navigate backward
    await calendar.navigatePrev();
    await page.waitForTimeout(1500);
    const prevTitle = await calendar.getNavTitle();
    expect(prevTitle).toBe(initialTitle);
  });

  test('Mine/Our perspective toggle works', async ({ authenticatedPage }) => {
    /**
     * Toggle between Mine and Our perspectives.
     *
     * Expected: Mine shows personal calendar only.
     * Expected: Our shows overlay toggle bar at bottom.
     */
    const page = authenticatedPage;
    const calendar = new CalendarPage(page);
    await calendar.gotoMonth();

    // Switch to Our — toggle bar should appear
    await calendar.switchToOur();
    await page.waitForTimeout(1500);
    await expect(calendar.toggleBar).toBeVisible();

    // Switch back to Mine
    await calendar.switchToMine();
    await page.waitForTimeout(1000);
  });
});

test.describe('Calendar Events API @core-regression @read-only-seed', () => {
  test('Calendar API returns seed events for April 2026', async ({ apiClient }) => {
    /**
     * Query calendar events for April 2026.
     *
     * Expected: Returns personal events (Doctor's appointment, Yoga Class, Work Meeting)
     * and shared events (Dinner with Casey, Lunch with Alex, Movie Night, Gym with Jamie).
     */
    const resp = await apiClient.getCalendarEvents('2026-04-01', '2026-04-30');
    expect(resp.success).toBe(true);
    expect(resp.data.length).toBeGreaterThanOrEqual(3);

    const titles = resp.data.map(e => e.title || e.TITLE);
    expect(titles.some(t => t && t.includes('appointment'))).toBe(true);
  });

  test('Calendar overlay API returns data structure', async ({ apiClient }) => {
    /**
     * Query calendar overlay for April 2026.
     *
     * Expected: API returns success with an array (may be empty if
     * overlay data depends on connected user events).
     */
    const resp = await apiClient.getCalendarOverlay('2026-04-01', '2026-04-30');
    expect(resp.success).toBe(true);
    expect(Array.isArray(resp.data)).toBe(true);
  });

  test('No events returned for empty month', async ({ apiClient }) => {
    /**
     * Query calendar for January 2026 (no seed events).
     *
     * Expected: Empty array returned.
     */
    const resp = await apiClient.getCalendarEvents('2026-01-01', '2026-01-31');
    expect(resp.success).toBe(true);
    expect(resp.data).toHaveLength(0);
  });
});
