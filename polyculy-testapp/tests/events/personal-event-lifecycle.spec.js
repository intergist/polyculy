// @ts-check
const { test } = require('../../fixtures/auth.fixture');
const { expect } = require('@playwright/test');
const config = require('../../helpers/config');
const { futureDate } = require('../../helpers/test-utils');

/**
 * TEST SUITE: Personal Event Lifecycle (Create-and-Clean)
 * Tags: @core-regression @create-and-clean
 *
 * Tests the full personal event lifecycle: create, verify, update visibility, delete.
 *
 * Spec references:
 * - §4.1: Personal Events — blocks time immediately, not an invitation.
 * - §5: Personal Event Sharing (Visibility) Logic — three tiers.
 * - §5.2: Interaction Rules Between Tiers.
 * - §5.3: Sharing Precedence (Destructive Reset).
 *
 * Data strategy: Create-and-clean — all events created are deleted at the end.
 */
test.describe('Personal Event Lifecycle @core-regression @create-and-clean', () => {
  const fDate = futureDate(17);

  test('Create and delete a personal event', async ({ apiClient }) => {
    /**
     * Full lifecycle: create → verify → delete → confirm deleted.
     *
     * Per §4.1: Personal events block time immediately.
     */
    const createResp = await apiClient.createPersonalEvent({
      title: 'E2E Personal Lifecycle Test',
      startDate: fDate,
      startHour: '09', startMinute: '00', startAmPm: 'AM',
      endHour: '10', endMinute: '00', endAmPm: 'AM',
      visibilityTier: 'invisible',
    });
    expect(createResp.success).toBe(true);
    expect(createResp.id).toBeDefined();
    const eventId = createResp.id;

    // Verify it exists
    const getResp = await apiClient.getPersonalEvent(eventId);
    expect(getResp.success).toBe(true);
    expect(getResp.data.title).toBe('E2E Personal Lifecycle Test');

    // Delete
    const deleteResp = await apiClient.deletePersonalEvent(eventId);
    expect(deleteResp.success).toBe(true);

    // Verify deleted
    const afterResp = await apiClient.getPersonalEvent(eventId);
    expect(afterResp.success).toBe(false);
  });

  test('Create personal event with full-details visibility', async ({ apiClient }) => {
    /**
     * Create event visible to Riley with full details.
     *
     * Per §5.1 Tier B: Share full event details with specific people.
     */
    const createResp = await apiClient.createPersonalEvent({
      title: 'E2E Visible Event',
      startDate: fDate,
      startHour: '11', startMinute: '00', startAmPm: 'AM',
      endHour: '12', endMinute: '00', endAmPm: 'PM',
      visibilityTier: 'full_details',
      fullDetailUsers: String(config.seeds.riley.userId),
    });
    expect(createResp.success).toBe(true);
    const eventId = createResp.id;

    try {
      const getResp = await apiClient.getPersonalEvent(eventId);
      expect(getResp.success).toBe(true);
      expect(getResp.data.visibility_tier).toBe('full_details');
    } finally {
      await apiClient.deletePersonalEvent(eventId);
    }
  });

  test('Create personal event with busy-block visibility', async ({ apiClient }) => {
    /**
     * Create event shared as busy block only.
     *
     * Per §5.1 Tier C: Share as busy block only with specific people.
     */
    const createResp = await apiClient.createPersonalEvent({
      title: 'E2E Busy Block Event',
      startDate: fDate,
      startHour: '01', startMinute: '00', startAmPm: 'PM',
      endHour: '02', endMinute: '00', endAmPm: 'PM',
      visibilityTier: 'busy_block',
      busyBlockUsers: String(config.seeds.riley.userId),
    });
    expect(createResp.success).toBe(true);
    const eventId = createResp.id;

    try {
      const getResp = await apiClient.getPersonalEvent(eventId);
      expect(getResp.success).toBe(true);
      expect(getResp.data.visibility_tier).toBe('busy_block');
    } finally {
      await apiClient.deletePersonalEvent(eventId);
    }
  });

  test('Invisible event has no visibility records', async ({ apiClient }) => {
    /**
     * Create invisible event and verify no sharing records exist.
     *
     * Per §5.1 Tier A: Fully private, no one else can see it.
     * Per §5.3: Switching to invisible wipes all prior audience data.
     */
    const createResp = await apiClient.createPersonalEvent({
      title: 'E2E Invisible Event',
      startDate: fDate,
      startHour: '03', startMinute: '00', startAmPm: 'PM',
      endHour: '04', endMinute: '00', endAmPm: 'PM',
      visibilityTier: 'invisible',
    });
    expect(createResp.success).toBe(true);
    const eventId = createResp.id;

    try {
      const getResp = await apiClient.getPersonalEvent(eventId);
      expect(getResp.success).toBe(true);
      expect(getResp.data.visibility_tier).toBe('invisible');
      // No visibility records for invisible events
      if (getResp.data.visibility) {
        expect(getResp.data.visibility).toHaveLength(0);
      }
    } finally {
      await apiClient.deletePersonalEvent(eventId);
    }
  });
});
