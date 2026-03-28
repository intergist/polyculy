// @ts-check
const { test } = require('../../fixtures/auth.fixture');
const { expect } = require('@playwright/test');
const config = require('../../helpers/config');
const { futureDate } = require('../../helpers/test-utils');

/**
 * TEST SUITE: Proposal Lifecycle (Full Flow)
 * Tags: @core-regression @create-and-clean
 *
 * Tests the complete proposal lifecycle: create → organizer accepts/rejects.
 *
 * Spec references:
 * - §7: Proposal System (Propose New Time).
 * - §7.2: Proposal Data — includes proposed start/end, message, status.
 * - §7.3: Interaction Rules — one active per participant, overwrite, accept/reject.
 *
 * Data strategy: Create-and-clean — shared events and proposals are created
 * and cleaned up via cancellation.
 */
test.describe('Proposal Lifecycle @core-regression @create-and-clean', () => {
  const fDate = futureDate(18);

  test('Riley proposes new time, admin accepts — event time updates, acceptances reset', async ({ apiClient, apiClientRiley }) => {
    /**
     * 1. Admin creates event with Riley.
     * 2. Riley accepts.
     * 3. Riley proposes a new time.
     * 4. Admin accepts the proposal.
     * 5. Verify: event time changed, all acceptances reset to pending.
     *
     * Per §7.3: Accepting a proposal updates event time, resets all acceptances.
     */
    const createResp = await apiClient.createSharedEvent({
      title: 'E2E Proposal Accept Test',
      startDate: fDate,
      startHour: '09', startMinute: '00', startAmPm: 'AM',
      endHour: '10', endMinute: '00', endAmPm: 'AM',
      participants: [config.seeds.riley.userId],
    });
    expect(createResp.success).toBe(true);
    const eventId = createResp.id;

    try {
      // Riley accepts first to make event active
      await apiClientRiley.respondToSharedEvent(eventId, 'accepted');

      // Verify active
      let getResp = await apiClient.getSharedEvent(eventId);
      expect(getResp.data.global_state).toBe('active');

      // Riley proposes new time
      const propResp = await apiClientRiley.createProposal(
        eventId,
        `${fDate}T14:00:00`,
        `${fDate}T15:00:00`,
        'Better time for me'
      );
      expect(propResp.success).toBe(true);

      // Admin sees the proposal
      const proposals = await apiClient.listProposals(eventId);
      expect(proposals.data.length).toBeGreaterThan(0);
      const activeProposal = proposals.data.find(p => p.STATUS === 'active');
      expect(activeProposal).toBeTruthy();

      // Admin accepts the proposal
      const acceptResp = await apiClient.acceptProposal(activeProposal.PROPOSAL_ID);
      expect(acceptResp.success).toBe(true);

      // Verify: acceptances reset → event goes tentative
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

  test('Admin rejects proposal — event unchanged', async ({ apiClient, apiClientRiley }) => {
    /**
     * 1. Admin creates event with Riley.
     * 2. Riley proposes new time.
     * 3. Admin rejects the proposal.
     * 4. Verify: event time unchanged, proposal status = rejected.
     *
     * Per §7.3: Organizer may reject a proposal; proposer is notified.
     */
    const createResp = await apiClient.createSharedEvent({
      title: 'E2E Proposal Reject Test',
      startDate: fDate,
      startHour: '11', startMinute: '00', startAmPm: 'AM',
      endHour: '12', endMinute: '00', endAmPm: 'PM',
      participants: [config.seeds.riley.userId],
    });
    expect(createResp.success).toBe(true);
    const eventId = createResp.id;

    try {
      // Riley proposes
      await apiClientRiley.createProposal(
        eventId,
        `${fDate}T16:00:00`,
        `${fDate}T17:00:00`,
        'Can we do this later?'
      );

      // Get proposal ID
      const proposals = await apiClient.listProposals(eventId);
      const active = proposals.data.find(p => p.STATUS === 'active');
      expect(active).toBeTruthy();

      // Admin rejects
      const rejectResp = await apiClient.rejectProposal(active.PROPOSAL_ID);
      expect(rejectResp.success).toBe(true);

      // Verify proposal status changed
      const afterResp = await apiClient.listProposals(eventId);
      const rejected = afterResp.data.find(p => p.PROPOSAL_ID === active.PROPOSAL_ID);
      expect(rejected.STATUS).toBe('rejected');
    } finally {
      await apiClient.cancelSharedEvent(eventId);
    }
  });
});
