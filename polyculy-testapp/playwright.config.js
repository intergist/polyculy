// @ts-check
const { defineConfig, devices } = require('@playwright/test');
require('dotenv').config();

const BASE_URL = process.env.POLYCULY_BASE_URL || 'http://localhost:5000';
const REPORT_DIR = process.env.POLYCULY_REPORT_DIR || 'reports/html';
const HEADLESS = process.env.POLYCULY_HEADLESS !== 'false';
const SLOW_MO = parseInt(process.env.POLYCULY_SLOW_MO || '0', 10);
const ACTION_TIMEOUT = parseInt(process.env.POLYCULY_ACTION_TIMEOUT || '10000', 10);
const NAV_TIMEOUT = parseInt(process.env.POLYCULY_NAVIGATION_TIMEOUT || '15000', 10);
const TEST_TIMEOUT = parseInt(process.env.POLYCULY_TEST_TIMEOUT || '60000', 10);

module.exports = defineConfig({
  globalSetup: require.resolve('./global-setup'),
  testDir: './tests',
  timeout: TEST_TIMEOUT,
  expect: {
    timeout: ACTION_TIMEOUT,
  },
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  workers: 1, // Serial execution to avoid state conflicts between tests
  reporter: [
    ['html', { outputFolder: REPORT_DIR, open: 'never' }],
    ['list'],
    ['junit', { outputFile: 'reports/junit-results.xml' }],
  ],
  use: {
    baseURL: BASE_URL,
    headless: HEADLESS,
    launchOptions: {
      slowMo: SLOW_MO,
    },
    actionTimeout: ACTION_TIMEOUT,
    navigationTimeout: NAV_TIMEOUT,
    screenshot: process.env.POLYCULY_SCREENSHOT_ON_FAILURE !== 'false' ? 'only-on-failure' : 'off',
    trace: process.env.POLYCULY_TRACE_ON_FAILURE !== 'false' ? 'on-first-retry' : 'off',
    video: process.env.POLYCULY_VIDEO || 'off',
    viewport: { width: 1280, height: 800 },
    ignoreHTTPSErrors: true,
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
});
