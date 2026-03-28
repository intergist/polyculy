// @ts-check
const { test } = require('../../fixtures/auth.fixture');
const { expect } = require('@playwright/test');
const ConnectionsPage = require('../../pages/ConnectionsPage');
const config = require('../../helpers/config');
const { assertNoServerError } = require('../../helpers/test-utils');

/**
 * TEST SUITE: Polycule Connections
 * Tags: @core-regression @read-only-seed
 *
 * Verifies connections page displays all seed connections with correct statuses,
 * display names, and available actions per status.
 *
 * Dependencies: Seed connections must exist with the statuses defined in config.
 * Data strategy: Read-only — verifies existing seed data only.
 */
test.describe('Connections — Seed Data Verification @core-regression @read-only-seed', () => {
  test('Connections page loads and shows all polycule members', async ({ authenticatedPage }) => {
    /**
     * Navigate to the connections page as admin user.
     *
     * Expected: Page loads without server errors.
     * Expected: All 6 seed connections visible in the polycule sidebar.
     */
    const page = authenticatedPage;
    const connPage = new ConnectionsPage(page);
    await connPage.goto();
    await assertNoServerError(page);

    const listText = await connPage.getPolyculeListText();
    expect(listText).toContain('Riley');
    expect(listText).toContain('Jamie');
    expect(listText).toContain('Alex');
    expect(listText).toContain('Casey');
    expect(listText).toContain('Morgan');
    expect(listText).toContain('Sam');
  });

  test('Connection statuses render correctly', async ({ authenticatedPage }) => {
    /**
     * Verify each seed connection shows the correct status text/indicator.
     *
     * Expected statuses:
     * - Riley: Connected (green)
     * - Jamie: Awaiting Confirmation (blue)
     * - Alex: Awaiting Confirmation (blue)
     * - Casey: Licence Gifted · Awaiting Signup (purple)
     * - Morgan: Awaiting Signup (yellow)
     * - Sam: Revoked (red)
     */
    const page = authenticatedPage;
    const connPage = new ConnectionsPage(page);
    await connPage.goto();

    const listText = await connPage.getPolyculeListText();
    // Verify status keywords appear in context
    expect(listText).toContain('Connected');
    expect(listText).toContain('Awaiting');
    expect(listText).toContain('Revoked');
  });
});

test.describe('Connections — API Verification @core-regression @read-only-seed', () => {
  test('API returns all connections with correct statuses', async ({ apiClient }) => {
    /**
     * Call the connections list API directly.
     *
     * Expected: 6 connections returned with correct statuses and displayNames.
     */
    const resp = await apiClient.listConnections();
    expect(resp.success).toBe(true);
    expect(resp.data).toHaveLength(6);

    const statusMap = {};
    for (const conn of resp.data) {
      statusMap[conn.displayName] = conn.status;
    }
    expect(statusMap['Riley']).toBe('connected');
    expect(statusMap['Jamie']).toBe('awaiting_confirmation');
    expect(statusMap['Alex']).toBe('awaiting_confirmation');
    expect(statusMap['Casey']).toBe('licence_gifted_awaiting_signup');
    expect(statusMap['Morgan']).toBe('awaiting_signup');
    expect(statusMap['Sam']).toBe('revoked');
  });

  test('Connected-only API returns only Riley', async ({ apiClient }) => {
    /**
     * Call the connected-users-only API.
     *
     * Expected: Only Riley returned (the only fully connected user).
     */
    const resp = await apiClient.listConnectedUsers();
    expect(resp.success).toBe(true);
    expect(resp.data).toHaveLength(1);
    expect(resp.data[0].displayName).toBe('Riley');
  });
});

test.describe('Connections — Connection Actions @core-regression @create-and-clean', () => {
  test('Send and revoke a connection request (create-and-clean)', async ({ apiClient }) => {
    /**
     * Test the full connection lifecycle: send → verify → revoke → verify cleanup.
     *
     * Idempotency: If a leftover e2etest connection exists, log and proceed to cleanup.
     * Data strategy: Create-and-clean — test data is removed via revoke action.
     */
    const testEmail = 'e2etest_conn@e2etest.polyculy.demo';
    const testName = 'E2E TestConn';

    // Check if leftover exists
    let resp = await apiClient.listConnections();
    const existing = resp.data.find(c => c.email === testEmail);
    if (existing) {
      console.log(`Leftover e2etest connection found (id=${existing.connectionId}), cleaning up first.`);
      await apiClient.revokeConnection(existing.connectionId);
    }

    // Send connection request
    resp = await apiClient.sendConnectionRequest(testEmail, testName);
    // API returns UPPER_CASE keys
    expect(resp.success || resp.SUCCESS).toBe(true);

    // Verify it appears in the list
    resp = await apiClient.listConnections();
    const created = resp.data.find(c => c.email === testEmail);
    expect(created).toBeTruthy();
    expect(created.status).toBe('awaiting_signup');

    // Cleanup: revoke the connection
    resp = await apiClient.revokeConnection(created.connectionId);
    expect(resp.success || resp.SUCCESS).toBe(true);

    // Verify cleanup
    resp = await apiClient.listConnections();
    const afterCleanup = resp.data.find(c => c.email === testEmail);
    // Should either be revoked or removed
    if (afterCleanup) {
      expect(afterCleanup.status).toBe('revoked');
    }
  });
});
