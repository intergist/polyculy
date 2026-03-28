// @ts-check
const { test, expect } = require('@playwright/test');
const RecoveryPage = require('../../pages/RecoveryPage');
const { assertNoServerError } = require('../../helpers/test-utils');
const config = require('../../helpers/config');

/**
 * TEST SUITE: Authentication — Password Recovery
 * Tags: @core-regression @read-only-seed
 *
 * Tests the password recovery flow UI.
 * Recovery does not actually send emails in demo mode, but the UI and API should respond correctly.
 *
 * Data strategy: Read-only — no data is mutated.
 */
test.describe('Password Recovery @core-regression @read-only-seed', () => {
  let recoveryPage;

  test.beforeEach(async ({ page }) => {
    recoveryPage = new RecoveryPage(page);
    await recoveryPage.goto();
  });

  test('Recovery page loads with correct structure', async ({ page }) => {
    /**
     * Verify the recovery page renders with:
     * - Heading text about getting back to Polyculy
     * - Email input field
     * - Continue button
     * - "Remembered? Log in" link
     *
     * Expected: All elements present and visible.
     */
    await assertNoServerError(page);
    await expect(recoveryPage.emailInput).toBeVisible();
    await expect(recoveryPage.continueButton).toBeVisible();
    await expect(recoveryPage.loginLink).toBeVisible();
  });

  test('Submit recovery shows confirmation message', async ({ page }) => {
    /**
     * Submit recovery form with an existing email.
     *
     * Expected: Message "If this email exists, a recovery link has been sent."
     * (Generic message to prevent user enumeration.)
     */
    await recoveryPage.submitRecovery(config.seeds.admin.email);
    const msg = await recoveryPage.getMessage();
    expect(msg).toContain('recovery link');
  });

  test('Submit recovery with unknown email shows same generic message', async ({ page }) => {
    /**
     * Submit recovery with a non-existent email.
     *
     * Expected: Same generic message (no user enumeration).
     */
    await recoveryPage.submitRecovery('unknown@doesnotexist.com');
    const msg = await recoveryPage.getMessage();
    expect(msg).toContain('recovery link');
  });

  test('Log in link navigates back to login page', async ({ page }) => {
    await recoveryPage.loginLink.click();
    await expect(page).toHaveURL(/login/);
  });
});
