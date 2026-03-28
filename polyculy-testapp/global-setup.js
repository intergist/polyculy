/**
 * Global setup for Polyculy test suite.
 * Resets seed data to pristine state before each full test run.
 */
const config = require('./helpers/config');

async function globalSetup() {
  const baseUrl = config.baseUrl;
  console.log(`\n[global-setup] Resetting seed data at ${baseUrl}...`);

  try {
    // Login first to get a session
    const loginResp = await fetch(`${baseUrl}/api/auth.cfm`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: `action=login&email=${encodeURIComponent(config.seeds.admin.email)}&password=${encodeURIComponent(config.seeds.admin.password)}`,
      redirect: 'manual',
    });
    
    // Extract cookies from login response
    const cookies = loginResp.headers.getSetCookie?.() || [];
    const cookieHeader = cookies.map(c => c.split(';')[0]).join('; ');

    // Reset seed with session cookie
    const resp = await fetch(`${baseUrl}/api/reset-seed.cfm`, {
      headers: cookieHeader ? { 'Cookie': cookieHeader } : {},
    });
    
    const text = await resp.text();
    let data;
    try {
      data = JSON.parse(text);
    } catch {
      // If not JSON, the endpoint may not require auth — try again without cookies
      console.log(`[global-setup] Response was not JSON, trying without auth...`);
      const resp2 = await fetch(`${baseUrl}/api/reset-seed.cfm`);
      const text2 = await resp2.text();
      try {
        data = JSON.parse(text2);
      } catch {
        console.log(`[global-setup] Warning: Could not parse reset-seed response. Continuing anyway.`);
        console.log(`[global-setup] Response: ${text2.substring(0, 200)}`);
        return;
      }
    }

    if (data.success) {
      console.log(`[global-setup] Seed reset successful: ${data.message}`);
    } else {
      console.error(`[global-setup] Seed reset FAILED: ${data.message}`);
      // Don't throw — let tests run anyway, they may still work
      console.log(`[global-setup] Continuing despite reset failure...`);
    }
  } catch (err) {
    console.error(`[global-setup] Error resetting seed:`, err.message);
    // Don't throw — let tests run, some may still pass
    console.log(`[global-setup] Continuing despite error...`);
  }
}

module.exports = globalSetup;
