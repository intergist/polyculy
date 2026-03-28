// @ts-check
const { test, expect } = require('@playwright/test');
const SignupPage = require('../../pages/SignupPage');
const config = require('../../helpers/config');
const { assertNoServerError } = require('../../helpers/test-utils');

/**
 * TEST SUITE: Authentication — Signup
 * Tags: @core-regression @read-only-seed
 *
 * Tests licence-code-gated signup flow with valid/invalid codes.
 *
 * Dependencies: Seed licences must exist. Signup with available codes
 * is tested as read-only verification (checking form behavior and validation
 * without completing account creation to avoid consuming seed licences).
 *
 * Data strategy: Read-only. Does not complete signup to preserve seed licence codes.
 */
test.describe('Signup @core-regression @read-only-seed', () => {
  let signupPage;

  test.beforeEach(async ({ page }) => {
    signupPage = new SignupPage(page);
    await signupPage.goto();
  });

  test('Signup page loads with correct structure', async ({ page }) => {
    /**
     * Verify the signup page renders with:
     * - "Welcome to Polyculy!" heading
     * - Email field
     * - Licence code field
     * - Continue button
     * - "Already a member? Log in" link
     *
     * Expected: All elements present and visible.
     */
    await assertNoServerError(page);
    await expect(signupPage.emailInput).toBeVisible();
    await expect(signupPage.licenceInput).toBeVisible();
    await expect(signupPage.continueButton).toBeVisible();
    await expect(signupPage.loginLink).toBeVisible();
  });

  test('Invalid licence code shows error', async ({ page }) => {
    /**
     * Submit signup form with an invalid licence code.
     *
     * Expected: Error message about invalid or redeemed licence code.
     */
    await signupPage.fillSignupForm('test@example.com', 'INVALID-LICENCE-999');
    const msg = await signupPage.getMessage();
    expect(msg).toBeTruthy();
    expect(msg.toLowerCase()).toMatch(/invalid|redeemed|failed/);
  });

  test('Already-redeemed licence code shows error', async ({ page }) => {
    /**
     * Submit signup with a licence code that has already been redeemed.
     *
     * Assumptions: ALPHA-001-FREE is already redeemed by user 1.
     * Expected: Error message about invalid or already redeemed code.
     */
    await signupPage.fillSignupForm('newuser@test.com', 'ALPHA-001-FREE');
    const msg = await signupPage.getMessage();
    expect(msg).toBeTruthy();
    expect(msg.toLowerCase()).toMatch(/invalid|redeemed|failed/);
  });

  test('Duplicate email shows error', async ({ page }) => {
    /**
     * Submit signup with an email that already has an account.
     *
     * Assumptions: you@polyculy.demo already exists.
     * Expected: Error message about existing account.
     */
    await signupPage.fillSignupForm(config.seeds.admin.email, config.seedLicences.available[0]);
    const msg = await signupPage.getMessage();
    expect(msg).toBeTruthy();
    expect(msg.toLowerCase()).toMatch(/already exists|already|duplicate/);
  });

  test('Log in link navigates back to login page', async ({ page }) => {
    /**
     * Click "Already a member? Log in" link.
     *
     * Expected: Navigation to login page.
     */
    await signupPage.loginLink.click();
    await expect(page).toHaveURL(/login/);
  });
});
