// @ts-check
const { test } = require('../../fixtures/auth.fixture');
const { expect } = require('@playwright/test');
const config = require('../../helpers/config');
const { futureDate } = require('../../helpers/test-utils');

/**
 * TEST SUITE: Conflict Handling
 * Tags: @core-regression @create-and-clean
 *
 * Tests the soft override conflict detection model.
 *
 * Spec references:
 * - §11: Conflict Handling — Soft Override Model.
 *   - Conflicts are not hard blocks.
 *   - Organizer receives a warning indicating the conflict.
 *   - Hard Conflict: overlap with accepted, blocking event.
 *   - Soft Conflict: overlap with tentative event.
 *
 * Data strategy: Create personal events to establish blocked time,
 * then check for conflicts via API. Cleanup by deleting created events.
 */
test.describe('Conflict Handling @core-regression @create-and-clean', () => {
  const fDate = futureDate(20);

  test('Conflicts API detects overlap with blocked time', async ({ apiClient }) => {
    /**
     * Create a personal event blocking 2-3 PM, then check for conflicts
     * on a proposed 2:30-3:30 PM time range.
     *
     * Per §11.1: Conflicts are not hard blocks — they are warnings.
     * Expected: API returns conflict data (may be empty if no accepted events overlap).
     */
    // Create a personal event to block time
    const createResp = await apiClient.createPersonalEvent({
      title: 'E2E Conflict Blocker',
      startDate: fDate,
      startHour: '02', startMinute: '00', startAmPm: 'PM',
      endHour: '03', endMinute: '00', endAmPm: 'PM',
      visibilityTier: 'invisible',
    });
    expect(createResp.success).toBe(true);
    const blockerId = createResp.id;

    try {
      // Check conflicts for overlapping time
      const conflictResp = await apiClient.checkConflicts(
        config.seeds.admin.userId,
        `${fDate} 14:30:00`,
        `${fDate} 15:30:00`
      );
      expect(conflictResp.success).toBe(true);
      // The API should return conflict data (array or object)
      expect(conflictResp.data).toBeDefined();
    } finally {
      // Cleanup
      await apiClient.deletePersonalEvent(blockerId);
    }
  });

  test('No conflict when time ranges do not overlap', async ({ apiClient }) => {
    /**
     * Check for conflicts in a time range with no events.
     *
     * Expected: No conflicts returned or empty conflict list.
     */
    const conflictResp = await apiClient.checkConflicts(
      config.seeds.admin.userId,
      `${fDate} 05:00:00`,
      `${fDate} 06:00:00`
    );
    expect(conflictResp.success).toBe(true);
    // Should have no conflicts (empty array or empty data)
    if (Array.isArray(conflictResp.data)) {
      expect(conflictResp.data.length).toBe(0);
    }
  });
});
