// @ts-check
const { test } = require('../../fixtures/auth.fixture');
const { expect } = require('@playwright/test');
const config = require('../../helpers/config');

/**
 * TEST SUITE: Connection Revocation
 * Tags: @core-regression @read-only-seed
 *
 * Verifies the revocation engine behavior at the API level.
 * Uses seed data with an already-revoked connection (Sam) to verify
 * revoked state rendering and access rules.
 *
 * Spec references:
 * - §9: Revocation Engine.
 *   - §9.1: Two-Person Events → cancelled.
 *   - §9.2: Multi-Person Events with remaining connections → decision maker logic.
 *   - §9.3: Multi-Person Events without remaining connections → auto-lose visibility.
 *   - §9.4: Non-Participant Visibility After Revocation.
 *   - §9.5: Re-Evaluation at Every Revocation.
 *
 * Dependencies: Sam's revoked connection (connectionId 6) exists in seed data.
 * Data strategy: Read-only — verifies revoked state without modifying active connections.
 *
 * NOTE: Full revocation workflow testing (revoke an active connection and evaluate
 * event impact) would require creating temporary connections and events, which is
 * covered in the response-flows and participant-management suites.
 */
test.describe('Revocation — Seed State Verification @core-regression @read-only-seed', () => {
  test('Revoked connection (Sam) has correct status in API', async ({ apiClient }) => {
    /**
     * Verify Sam's connection shows as revoked.
     *
     * Expected: Sam's status = "revoked" in the connections list.
     */
    const resp = await apiClient.listConnections();
    expect(resp.success).toBe(true);

    const sam = resp.data.find(c => c.displayName === 'Sam');
    expect(sam).toBeTruthy();
    expect(sam.status).toBe('revoked');
  });

  test('Revoked connection does not appear in connected-only list', async ({ apiClient }) => {
    /**
     * Verify Sam is excluded from the connected-users-only API.
     *
     * Expected: Sam does not appear in the connected list.
     */
    const resp = await apiClient.listConnectedUsers();
    expect(resp.success).toBe(true);

    const sam = resp.data.find(c => c.displayName === 'Sam');
    expect(sam).toBeFalsy();
  });

  test('Revoked user cannot be invited to shared events', async ({ apiClient }) => {
    /**
     * Verify that the connected-only list (used for participant selection)
     * correctly excludes revoked connections.
     *
     * Per §8.1: Only users with status = Connected can be directly invited.
     * Per §6.7: "All" means all currently Connected polymates only, excluding
     * Awaiting Signup, Awaiting Confirmation, Revoked.
     */
    const resp = await apiClient.listConnectedUsers();
    const displayNames = resp.data.map(c => c.displayName);

    // Only Riley should be connected
    expect(displayNames).toContain('Riley');
    // Others should not appear
    expect(displayNames).not.toContain('Sam');
    expect(displayNames).not.toContain('Jamie');
    expect(displayNames).not.toContain('Casey');
    expect(displayNames).not.toContain('Morgan');
  });
});

test.describe('Revocation — UI Display @core-regression @read-only-seed', () => {
  test('Revoked connection shows revoked status in connections UI', async ({ authenticatedPage }) => {
    /**
     * Navigate to connections page and verify Sam shows as revoked.
     *
     * Per UI Screen 3/5: Revoked status shown in red.
     * Context menu for Revoked: Hide, Send Invitation to Reconnect.
     */
    const page = authenticatedPage;
    await page.goto(config.urls.connections);
    await page.waitForLoadState('domcontentloaded');

    // Wait for AJAX to populate the polycule list
    const polyculeList = page.locator('[data-testid="polycule-list"]');
    await polyculeList.locator('.polycule-member').first().waitFor({ state: 'visible', timeout: 10000 });

    const listText = await polyculeList.textContent();

    expect(listText).toContain('Sam');
    expect(listText).toContain('Revoked');
  });
});
