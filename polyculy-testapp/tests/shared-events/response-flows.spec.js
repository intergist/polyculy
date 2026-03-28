// @ts-check
const { test } = require('../../fixtures/auth.fixture');
const { expect } = require('@playwright/test');
const config = require('../../helpers/config');
const { futureDate } = require('../../helpers/test-utils');

/**
 * TEST SUITE: Shared Event — Response Flows
 * Tags: @core-regression @create-and-clean
 *
 * Tests the shared event response lifecycle using two user contexts (admin + Riley):
 * accept, decline, maybe, and their effects on event state.
 *
 * Spec references:
 * - §6.1: Global Event States (Tentative / Active / Cancelled).
 * - §6.3: Per-Viewer Representation.
 * - §6.4: Participant Actions (Accept, Decline, Maybe, Propose New Time).
 * - §6.6: Edit Tiers (Minor vs Material).
 *
 * Dependencies: Seed users (admin, riley). Riley must be connected to admin.
 * Data strategy: Create-and-clean — each test creates a shared event, exercises
 * the response flow, then cancels the event for cleanup.
 */
test.describe('Shared Event Response Flows @core-regression @create-and-clean', () => {
  const fDate = futureDate(14);

  test('Accept response activates a tentative event', async ({ apiClient, apiClientRiley }) => {
    /**
     * Admin creates a shared event with Riley → tentative.
     * Riley accepts → event becomes active.
     * Cleanup: admin cancels the event.
     *
     * Per §6.1: Event is tentative until a non-organizer accepts.
     */
    // Create shared event
    const createResp = await apiClient.createSharedEvent({
      title: 'E2E Accept Test',
      startDate: fDate,
      startHour: '06', startMinute: '00', startAmPm: 'PM',
      endHour: '07', endMinute: '00', endAmPm: 'PM',
      participants: [config.seeds.riley.userId],
    });
    expect(createResp.success).toBe(true);
    const eventId = createResp.id;

    try {
      // Verify tentative
      let getResp = await apiClient.getSharedEvent(eventId);
      expect(getResp.data.global_state).toBe('tentative');

      // Riley accepts
      const acceptResp = await apiClientRiley.respondToSharedEvent(eventId, 'accepted');
      expect(acceptResp.success).toBe(true);

      // Verify now active
      getResp = await apiClient.getSharedEvent(eventId);
      expect(getResp.data.global_state).toBe('active');
    } finally {
      // Cleanup
      await apiClient.cancelSharedEvent(eventId);
    }
  });

  test('Decline response does not activate event', async ({ apiClient, apiClientRiley }) => {
    /**
     * Admin creates shared event with Riley → tentative.
     * Riley declines → event stays tentative.
     *
     * Per §6.4: Decline removes the event from the participant's calendar.
     */
    const createResp = await apiClient.createSharedEvent({
      title: 'E2E Decline Test',
      startDate: fDate,
      startHour: '03', startMinute: '00', startAmPm: 'PM',
      endHour: '04', endMinute: '00', endAmPm: 'PM',
      participants: [config.seeds.riley.userId],
    });
    expect(createResp.success).toBe(true);
    const eventId = createResp.id;

    try {
      // Riley declines
      const declineResp = await apiClientRiley.respondToSharedEvent(eventId, 'declined');
      expect(declineResp.success).toBe(true);

      // Verify still tentative
      const getResp = await apiClient.getSharedEvent(eventId);
      expect(getResp.data.global_state).toBe('tentative');
    } finally {
      await apiClient.cancelSharedEvent(eventId);
    }
  });

  test('Maybe response does not block time or activate event', async ({ apiClient, apiClientRiley }) => {
    /**
     * Admin creates shared event with Riley → tentative.
     * Riley responds with "maybe" → event stays tentative.
     *
     * Per §6.3: Maybe does not block time, does not count toward activation,
     * sends no notification, can be changed later.
     */
    const createResp = await apiClient.createSharedEvent({
      title: 'E2E Maybe Test',
      startDate: fDate,
      startHour: '04', startMinute: '00', startAmPm: 'PM',
      endHour: '05', endMinute: '00', endAmPm: 'PM',
      participants: [config.seeds.riley.userId],
    });
    expect(createResp.success).toBe(true);
    const eventId = createResp.id;

    try {
      // Riley says maybe
      const maybeResp = await apiClientRiley.respondToSharedEvent(eventId, 'maybe');
      expect(maybeResp.success).toBe(true);

      // Verify still tentative
      const getResp = await apiClient.getSharedEvent(eventId);
      expect(getResp.data.global_state).toBe('tentative');

      // Verify Riley's status is maybe
      const riley = getResp.data.participants.find(
        p => p.USER_ID === config.seeds.riley.userId
      );
      expect(riley).toBeTruthy();
      expect(riley.RESPONSE_STATUS).toBe('maybe');
    } finally {
      await apiClient.cancelSharedEvent(eventId);
    }
  });

  test('Maybe can be changed to Accept', async ({ apiClient, apiClientRiley }) => {
    /**
     * Riley says maybe → then accepts. Event should activate.
     *
     * Per §6.3: Participant can later convert Maybe to Accept or Decline.
     */
    const createResp = await apiClient.createSharedEvent({
      title: 'E2E Maybe-to-Accept Test',
      startDate: fDate,
      startHour: '05', startMinute: '00', startAmPm: 'PM',
      endHour: '06', endMinute: '00', endAmPm: 'PM',
      participants: [config.seeds.riley.userId],
    });
    expect(createResp.success).toBe(true);
    const eventId = createResp.id;

    try {
      // Riley says maybe
      await apiClientRiley.respondToSharedEvent(eventId, 'maybe');

      // Riley changes to accept
      const acceptResp = await apiClientRiley.respondToSharedEvent(eventId, 'accepted');
      expect(acceptResp.success).toBe(true);

      // Verify now active
      const getResp = await apiClient.getSharedEvent(eventId);
      expect(getResp.data.global_state).toBe('active');
    } finally {
      await apiClient.cancelSharedEvent(eventId);
    }
  });

  test('Organizer cancellation sets state to cancelled', async ({ apiClient }) => {
    /**
     * Admin creates and then cancels a shared event.
     *
     * Per §6.9: All terminations are treated as Cancelled.
     * Per §6.10: Cancelled events are removed from calendar view.
     */
    const createResp = await apiClient.createSharedEvent({
      title: 'E2E Cancel Test',
      startDate: fDate,
      startHour: '01', startMinute: '00', startAmPm: 'PM',
      endHour: '02', endMinute: '00', endAmPm: 'PM',
      participants: [config.seeds.riley.userId],
    });
    expect(createResp.success).toBe(true);
    const eventId = createResp.id;

    const cancelResp = await apiClient.cancelSharedEvent(eventId);
    expect(cancelResp.success).toBe(true);

    // Verify cancelled state
    const getResp = await apiClient.getSharedEvent(eventId);
    if (getResp.success) {
      expect(getResp.data.global_state).toBe('cancelled');
    }
    // If not found, that's also acceptable — cancelled events may be hidden
  });
});

test.describe('Shared Event — Material vs Minor Edits @core-regression @create-and-clean', () => {
  const fDate = futureDate(15);

  test('Material edit (time change) resets acceptances', async ({ apiClient, apiClientRiley }) => {
    /**
     * Admin creates event → Riley accepts (active) → Admin changes time →
     * all acceptances reset to pending → event goes tentative.
     *
     * Per §6.6: Material edits (time, location) reset all acceptances to Pending.
     */
    const createResp = await apiClient.createSharedEvent({
      title: 'E2E Material Edit Test',
      startDate: fDate,
      startHour: '09', startMinute: '00', startAmPm: 'AM',
      endHour: '10', endMinute: '00', endAmPm: 'AM',
      participants: [config.seeds.riley.userId],
    });
    expect(createResp.success).toBe(true);
    const eventId = createResp.id;

    try {
      // Riley accepts → active
      await apiClientRiley.respondToSharedEvent(eventId, 'accepted');
      let getResp = await apiClient.getSharedEvent(eventId);
      expect(getResp.data.global_state).toBe('active');

      // Admin changes time (material edit)
      const updateResp = await apiClient.updateSharedEvent(eventId, {
        title: 'E2E Material Edit Test',
        startDate: fDate,
        startHour: '11', startMinute: '00', startAmPm: 'AM',
        endHour: '12', endMinute: '00', endAmPm: 'PM',
      });
      expect(updateResp.success).toBe(true);

      // Verify acceptances reset → tentative
      getResp = await apiClient.getSharedEvent(eventId);
      expect(getResp.data.global_state).toBe('tentative');

      // Riley should be back to pending
      const riley = getResp.data.participants.find(
        p => p.USER_ID === config.seeds.riley.userId
      );
      expect(riley.RESPONSE_STATUS).toBe('pending');
    } finally {
      await apiClient.cancelSharedEvent(eventId);
    }
  });
});
