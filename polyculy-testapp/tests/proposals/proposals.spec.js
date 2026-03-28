// @ts-check
const { test } = require('../../fixtures/auth.fixture');
const { expect } = require('@playwright/test');
const config = require('../../helpers/config');

/**
 * TEST SUITE: Proposal System (Propose New Time)
 * Tags: @core-regression @create-and-clean
 *
 * Tests the proposal lifecycle: create, list, verify active proposals.
 * Proposals are created as test data and verified, but seed events are used as the base.
 *
 * Dependencies: Seed shared events must exist.
 * Data strategy: Create-and-clean — proposals are created during the test
 * and the database is left in a manageable state. Proposals cannot be deleted
 * through normal UI, so they accumulate. Tests use idempotency checks.
 */
test.describe('Proposals @core-regression @create-and-clean', () => {
  test('Create a proposal on a shared event', async ({ apiClient }) => {
    /**
     * Create a time proposal on "Dinner with Casey" (shared event 1).
     *
     * Expected: Proposal is created successfully.
     * Expected: Proposal appears in active proposals list.
     *
     * Idempotency: If a prior proposal exists from admin, the new one overwrites it
     * (per business rule: one active proposal per participant).
     */
    const eventId = config.seedEvents.shared.dinnerWithCasey.id;

    // Create proposal
    const resp = await apiClient.createProposal(
      eventId,
      '2026-04-20T18:00:00',
      '2026-04-20T20:00:00',
      'E2E test proposal — better time for everyone'
    );
    expect(resp.success).toBe(true);
    expect(resp.message).toContain('Proposal submitted');
  });

  test('List proposals shows active proposal', async ({ apiClient }) => {
    /**
     * List proposals for "Dinner with Casey".
     *
     * Expected: At least one proposal exists (from admin user).
     * Expected: Proposal status is "active".
     */
    const eventId = config.seedEvents.shared.dinnerWithCasey.id;

    // First ensure a proposal exists
    await apiClient.createProposal(
      eventId,
      '2026-04-20T19:00:00',
      '2026-04-20T21:00:00',
      'E2E test proposal v2'
    );

    const resp = await apiClient.listProposals(eventId);
    expect(resp.success).toBe(true);
    expect(resp.data.length).toBeGreaterThan(0);

    const activeProposals = resp.data.filter(p => p.STATUS === 'active');
    expect(activeProposals.length).toBeGreaterThanOrEqual(1);

    // The most recent one should be our v2
    const latest = activeProposals[0];
    expect(latest.PROPOSER_NAME).toBe('You');
  });

  test('One active proposal per participant — revised proposal overwrites prior', async ({ apiClient }) => {
    /**
     * Submit two proposals from the same user for the same event.
     *
     * Expected: Only one active proposal exists for the user.
     * Expected: The second proposal replaces the first.
     */
    const eventId = config.seedEvents.shared.dinnerWithCasey.id;

    // Submit first
    await apiClient.createProposal(
      eventId,
      '2026-04-20T17:00:00',
      '2026-04-20T19:00:00',
      'Proposal A'
    );

    // Submit second (should overwrite)
    await apiClient.createProposal(
      eventId,
      '2026-04-20T18:30:00',
      '2026-04-20T20:30:00',
      'Proposal B — replaces A'
    );

    const resp = await apiClient.listProposals(eventId);
    const activeFromAdmin = resp.data.filter(
      p => p.STATUS === 'active' && p.PROPOSER_USER_ID === config.seeds.admin.userId
    );
    // Should have exactly one active proposal from admin
    expect(activeFromAdmin).toHaveLength(1);
    expect(activeFromAdmin[0].MESSAGE).toContain('Proposal B');
  });
});
