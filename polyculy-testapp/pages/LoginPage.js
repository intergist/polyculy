const config = require('../helpers/config');

class LoginPage {
  constructor(page) {
    this.page = page;
    this.emailInput = page.locator('[data-testid="login-email"]');
    this.passwordInput = page.locator('[data-testid="login-password"]');
    this.loginButton = page.locator('[data-testid="login-button"]');
    this.messageArea = page.locator('[data-testid="login-message"]');
    this.signupLink = page.locator('[data-testid="signup-link"]');
    this.forgotPasswordLink = page.locator('[data-testid="forgot-password-link"]');
    this.pageTitle = page.locator('.auth-title');
    this.tagline = page.locator('.auth-tagline');
  }

  async goto() {
    await this.page.goto(config.urls.login);
    await this.page.waitForLoadState('domcontentloaded');
  }

  async login(email, password) {
    await this.emailInput.fill(email);
    await this.passwordInput.fill(password);
    await this.loginButton.click();
    // Wait for either navigation or error message
    await Promise.race([
      this.page.waitForURL(/\/(calendar|setup)/, { timeout: 10000 }).catch(() => {}),
      this.messageArea.waitFor({ state: 'visible', timeout: 5000 }).catch(() => {}),
    ]);
  }

  async loginAs(userKey) {
    const user = config.seeds[userKey];
    if (!user || !user.email) throw new Error(`Unknown seed user: ${userKey}`);
    await this.login(user.email, user.password);
  }

  async getErrorMessage() {
    try {
      await this.messageArea.waitFor({ state: 'visible', timeout: 3000 });
      return await this.messageArea.textContent();
    } catch {
      return null;
    }
  }

  async isOnLoginPage() {
    return this.page.url().includes('/login');
  }
}

module.exports = LoginPage;
