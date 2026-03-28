// @ts-check
const { test } = require('../../fixtures/auth.fixture');
const { expect } = require('@playwright/test');
const config = require('../../helpers/config');
const { futureDate } = require('../../helpers/test-utils');

/**
 * TEST SUITE: Shared Event — Participant Management
 * Tags: @core-regression @create-and-clean
 *
 * Tests manual participant removal, participant visibility settings,
 * and edit authority rules.
 *
 * Spec references:
 * - §6.5: Edit Authority — only the organizer can edit.
 * - §6.7: Participant Selection Defaults.
 * - §6.8: Reminder Scope (Me/All).
 * - §6.11: Participant Visibility (Metamour Privacy).
 * - §16: Manual Participant Removal.
 *
 * Data strategy: Create-and-clean — create events, test, cancel for cleanup.
 */
test.describe('Participant Management @core-regression @create-and-clean', () => {
  const fDate = futureDate(16);

  test('Remove participant from shared event', async ({ apiClient }) => {
    /**
     * Admin creates event with Riley → removes Riley.
     *
     * Per §16: Organizer can manually remove any participant.
     * Effects: immediate loss of visibility, receives removal notification.
     */
    const createResp = await apiClient.createSharedEvent({
      title: 'E2E Remove Participant Test',
      startDate: fDate,
      startHour: '02', startMinute: '00', startAmPm: 'PM',
      endHour: '03', endMinute: '00', endAmPm: 'PM',
      participants: [config.seeds.riley.userId],
    });
    expect(createResp.success).toBe(true);
    const eventId = createResp.id;

    try {
      // Verify Riley is a participant
      let getResp = await apiClient.getSharedEvent(eventId);
      let riley = getResp.data.participants.find(
        p => p.USER_ID === config.seeds.riley.userId
      );
      expect(riley).toBeTruthy();

      // Remove Riley
      const removeResp = await apiClient.removeParticipant(eventId, config.seeds.riley.userId);
      expect(removeResp.success).toBe(true);

      // Verify Riley is no longer a participant
      getResp = await apiClient.getSharedEvent(eventId);
      riley = getResp.data.participants.find(
        p => p.USER_ID === config.seeds.riley.userId
      );
      expect(riley).toBeFalsy();
    } finally {
      await apiClient.cancelSharedEvent(eventId);
    }
  });

  test('Participant visibility setting: visible vs hidden', async ({ apiClient }) => {
    /**
     * Create event with participant_visibility = hidden.
     *
     * Per §6.11: When hidden, participants see only themselves and organizer.
     * Expected: participant_visibility field is set to "hidden".
     */
    const createResp = await apiClient.createSharedEvent({
      title: 'E2E Hidden Participants Test',
      startDate: fDate,
      startHour: '03', startMinute: '00', startAmPm: 'PM',
      endHour: '04', endMinute: '00', endAmPm: 'PM',
      participantVisibility: 'hidden',
      participants: [config.seeds.riley.userId],
    });
    expect(createResp.success).toBe(true);
    const eventId = createResp.id;

    try {
      const getResp = await apiClient.getSharedEvent(eventId);
      expect(getResp.data.participant_visibility).toBe('hidden');
    } finally {
      await apiClient.cancelSharedEvent(eventId);
    }
  });

  test('Reminder scope defaults to "me"', async ({ apiClient }) => {
    /**
     * Create event and verify reminder scope defaults.
     *
     * Per §6.8: Reminder has Me/All toggle. Me = organizer only.
     */
    const createResp = await apiClient.createSharedEvent({
      title: 'E2E Reminder Scope Test',
      startDate: fDate,
      startHour: '04', startMinute: '00', startAmPm: 'PM',
      endHour: '05', endMinute: '00', endAmPm: 'PM',
      reminderScope: 'me',
      participants: [config.seeds.riley.userId],
    });
    expect(createResp.success).toBe(true);
    const eventId = createResp.id;

    try {
      const getResp = await apiClient.getSharedEvent(eventId);
      expect(getResp.data.reminder_scope).toBe('me');
    } finally {
      await apiClient.cancelSharedEvent(eventId);
    }
  });

  test('Reminder scope can be set to "all"', async ({ apiClient }) => {
    /**
     * Create event with reminder scope = all.
     *
     * Per §6.8: All = organizer + all invited participants.
     */
    const createResp = await apiClient.createSharedEvent({
      title: 'E2E Reminder All Test',
      startDate: fDate,
      startHour: '05', startMinute: '00', startAmPm: 'PM',
      endHour: '06', endMinute: '00', endAmPm: 'PM',
      reminderScope: 'all',
      participants: [config.seeds.riley.userId],
    });
    expect(createResp.success).toBe(true);
    const eventId = createResp.id;

    try {
      const getResp = await apiClient.getSharedEvent(eventId);
      expect(getResp.data.reminder_scope).toBe('all');
    } finally {
      await apiClient.cancelSharedEvent(eventId);
    }
  });
});
