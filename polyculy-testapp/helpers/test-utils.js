/**
 * Shared test utilities — deterministic naming, timestamps, and common assertions.
 */

/**
 * Generate a unique test identifier based on prefix and timestamp.
 * Ensures deterministic, collision-free transient test data.
 */
function uniqueTestId(prefix = 'e2e') {
  const ts = Date.now();
  const rand = Math.random().toString(36).substring(2, 6);
  return `${prefix}_${ts}_${rand}`;
}

/**
 * Generate a test email address.
 */
function testEmail(suffix = '') {
  const id = uniqueTestId('test');
  return `${id}${suffix}@e2etest.polyculy.demo`;
}

/**
 * Format a date as YYYY-MM-DD.
 */
function formatDate(date) {
  return date.toISOString().split('T')[0];
}

/**
 * Get a future date string (YYYY-MM-DD) offset by N days from now.
 */
function futureDate(daysFromNow = 1) {
  const d = new Date();
  d.setDate(d.getDate() + daysFromNow);
  return formatDate(d);
}

/**
 * Sleep for a given number of milliseconds.
 */
function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

/**
 * Wait for network idle after an action (useful post-AJAX).
 */
async function waitForAjax(page, timeoutMs = 3000) {
  try {
    await page.waitForLoadState('networkidle', { timeout: timeoutMs });
  } catch {
    // Acceptable — some pages may not reach full idle
  }
}

/**
 * Wait for an element to appear and be visible.
 */
async function waitForVisible(page, selector, timeoutMs = 5000) {
  const el = page.locator(selector);
  await el.waitFor({ state: 'visible', timeout: timeoutMs });
  return el;
}

/**
 * Assert that a page has no Lucee/CFML error visible.
 */
async function assertNoServerError(page) {
  const body = await page.textContent('body');
  const errorPatterns = [
    'lucee.runtime',
    'coldfusion.runtime',
    'Error Occurred',
    'stack trace',
    'NullPointerException',
  ];
  for (const pattern of errorPatterns) {
    if (body.toLowerCase().includes(pattern.toLowerCase())) {
      throw new Error(`Server error detected on page: found "${pattern}"`);
    }
  }
}

module.exports = {
  uniqueTestId,
  testEmail,
  formatDate,
  futureDate,
  sleep,
  waitForAjax,
  waitForVisible,
  assertNoServerError,
};
