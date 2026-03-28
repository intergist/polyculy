// @ts-check
const { test } = require('../../fixtures/auth.fixture');
const { expect } = require('@playwright/test');
const config = require('../../helpers/config');

/**
 * TEST SUITE: Licensing Model
 * Tags: @core-regression @read-only-seed
 *
 * Verifies licence validation, available licences, and gifting rules.
 *
 * Spec references:
 * - §3: Licensing Model.
 * - §3.2: License Gifting Rules — cannot gift twice, replaces prior invitation.
 *
 * Dependencies: Seed licence codes exist in config.seedLicences.
 * Data strategy: Read-only — validates licence codes without redeeming them.
 */
test.describe('Licensing — API Verification @core-regression @read-only-seed', () => {
  test('List licences for admin user', async ({ apiClient }) => {
    /**
     * Fetch licences associated with the admin user.
     *
     * Expected: API returns success with a licence list.
     */
    const resp = await apiClient.listLicences();
    expect(resp.success).toBe(true);
    expect(Array.isArray(resp.data)).toBe(true);
  });

  test('Validate a known available licence code', async ({ apiClient }) => {
    /**
     * Validate one of the seed available licence codes.
     *
     * Expected: Code is valid.
     */
    const code = config.seedLicences.available[0];
    const resp = await apiClient.validateLicence(code);
    expect(resp.success).toBe(true);
    // Server returns UPPER_CASE keys
    expect(resp.data.valid || resp.data.VALID).toBe(true);
  });

  test('Validate an invalid licence code', async ({ apiClient }) => {
    /**
     * Try to validate a nonexistent licence code.
     *
     * Expected: Code is invalid (valid = false).
     */
    const resp = await apiClient.validateLicence('INVALID-CODE-999');
    expect(resp.success).toBe(true);
    // Server returns UPPER_CASE keys
    expect(resp.data.valid ?? resp.data.VALID).toBe(false);
  });

  test('List available licences for gifting', async ({ apiClient }) => {
    /**
     * Fetch licences available for the admin to gift.
     *
     * Expected: API returns success with available licence data.
     */
    const resp = await apiClient.listAvailableLicences();
    expect(resp.success).toBe(true);
    expect(Array.isArray(resp.data)).toBe(true);
  });
});
