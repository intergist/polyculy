/**
 * Authentication fixtures — provides pre-authenticated page contexts.
 */
const { test: base } = require('@playwright/test');
const config = require('../helpers/config');
const LoginPage = require('../pages/LoginPage');
const ApiClient = require('../helpers/api-client');

/**
 * Extend the base test with authenticated page fixture.
 * - `authenticatedPage`: a page logged in as admin (You)
 * - `apiClient`: API client for direct HTTP calls
 */
const test = base.extend({
  authenticatedPage: async ({ page }, use) => {
    const loginPage = new LoginPage(page);
    await loginPage.goto();
    await loginPage.loginAs('admin');
    // Verify we landed on calendar or setup
    await page.waitForURL(/\/(calendar|setup)/, { timeout: 10000 });
    await use(page);
  },

  rileyPage: async ({ browser }, use) => {
    const context = await browser.newContext();
    const page = await context.newPage();
    const loginPage = new LoginPage(page);
    await loginPage.goto();
    await loginPage.loginAs('riley');
    await page.waitForURL(/\/(calendar|setup)/, { timeout: 10000 });
    await use(page);
    await context.close();
  },

  apiClient: async ({ request }, use) => {
    const client = new ApiClient(request);
    // Login as admin via API
    await client.login(config.seeds.admin.email, config.seeds.admin.password);
    await use(client);
  },

  apiClientRiley: async ({ playwright }, use) => {
    const context = await playwright.request.newContext({ baseURL: config.baseUrl });
    const client = new ApiClient(context);
    await client.login(config.seeds.riley.email, config.seeds.riley.password);
    await use(client);
    await context.dispose();
  },
});

module.exports = { test };
