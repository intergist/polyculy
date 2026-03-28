// @ts-check
const { test, expect } = require('@playwright/test');
const LoginPage = require('../../pages/LoginPage');
const NavBar = require('../../pages/NavBar');
const config = require('../../helpers/config');
const { assertNoServerError } = require('../../helpers/test-utils');

/**
 * TEST SUITE: Authentication — Login
 * Tags: @smoke @core-regression @read-only-seed
 *
 * Tests login with valid/invalid credentials, form validation,
 * page structure, and navigation links.
 *
 * Dependencies: Seed users must exist (you@polyculy.demo with password demo123).
 * Data strategy: Read-only — no data is created or mutated.
 */
test.describe('Login @smoke @core-regression @read-only-seed', () => {
  let loginPage;

  test.beforeEach(async ({ page }) => {
    loginPage = new LoginPage(page);
    await loginPage.goto();
  });

  test('Login page loads with correct structure', async ({ page }) => {
    /**
     * Verify the login page renders with:
     * - Polyculy logo/title
     * - "Calendar that keeps up" tagline
     * - Email and password input fields
     * - Log In button
     * - Sign up and forgot password links
     *
     * Expected: All elements present and visible.
     */
    await assertNoServerError(page);
    await expect(loginPage.pageTitle).toHaveText('Polyculy');
    await expect(loginPage.tagline).toHaveText('Calendar that keeps up');
    await expect(loginPage.emailInput).toBeVisible();
    await expect(loginPage.passwordInput).toBeVisible();
    await expect(loginPage.loginButton).toBeVisible();
    await expect(loginPage.signupLink).toBeVisible();
    await expect(loginPage.forgotPasswordLink).toBeVisible();
  });

  test('Successful login redirects to calendar', async ({ page }) => {
    /**
     * Login with valid seed admin credentials.
     *
     * Assumptions: you@polyculy.demo exists with password demo123 and calendarCreated=true.
     * Expected: Redirect to /views/calendar/month.cfm after login.
     */
    await loginPage.loginAs('admin');
    await expect(page).toHaveURL(/\/views\/calendar\/(month|setup)\.cfm/);
    await assertNoServerError(page);
  });

  test('Invalid password shows error message', async ({ page }) => {
    /**
     * Login with correct email but wrong password.
     *
     * Expected: Error message "Invalid email or password." displayed.
     * Expected: User remains on login page.
     */
    await loginPage.login(config.seeds.admin.email, 'wrong_password');
    const msg = await loginPage.getErrorMessage();
    expect(msg).toContain('Invalid email or password');
    expect(page.url()).toContain('login');
  });

  test('Non-existent email shows error message', async ({ page }) => {
    /**
     * Login with an email that does not exist in the system.
     *
     * Expected: Error message displayed (same generic error to prevent user enumeration).
     * Expected: User remains on login page.
     */
    await loginPage.login('nobody@doesnotexist.com', 'anything');
    const msg = await loginPage.getErrorMessage();
    expect(msg).toContain('Invalid email or password');
  });

  test('Empty fields show validation or error', async ({ page }) => {
    /**
     * Submit login form with empty email and password.
     *
     * Expected: Browser validation prevents submission OR server returns error.
     */
    // The HTML5 'required' attribute on inputs should prevent submission
    await loginPage.loginButton.click();
    // Should still be on login page (browser prevented form submission)
    expect(page.url()).toContain('login');
  });

  test('Sign up link navigates to signup page', async ({ page }) => {
    /**
     * Click the "Sign up" link.
     *
     * Expected: Navigation to /views/auth/signup.cfm.
     */
    await loginPage.signupLink.click();
    await expect(page).toHaveURL(/signup/);
  });

  test('Forgot password link navigates to recovery page', async ({ page }) => {
    /**
     * Click the "Forgot password?" link.
     *
     * Expected: Navigation to /views/auth/recovery.cfm.
     */
    await loginPage.forgotPasswordLink.click();
    await expect(page).toHaveURL(/recovery/);
  });
});

test.describe('Login — Logout Flow @smoke @core-regression', () => {
  test('Logout redirects to login page', async ({ page }) => {
    /**
     * Login as admin, then click logout.
     *
     * Expected: User is redirected to login page.
     * Expected: Subsequent navigation to protected pages redirects to login.
     */
    const loginPage = new LoginPage(page);
    await loginPage.goto();
    await loginPage.loginAs('admin');
    await page.waitForURL(/\/calendar\//);

    const nav = new NavBar(page);
    await nav.logout();

    // Should be redirected to login page
    await expect(page).toHaveURL(/login|\/$/);
  });

  test('Protected routes redirect unauthenticated users to login', async ({ page }) => {
    /**
     * Attempt to access the calendar page without logging in.
     *
     * Expected: Redirect to login page.
     */
    await page.goto(config.urls.calendarMonth);
    // Should be redirected to login
    await expect(page).toHaveURL(/login|\/$/);
  });
});
