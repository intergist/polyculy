const config = require('../helpers/config');

class RecoveryPage {
  constructor(page) {
    this.page = page;
    this.emailInput = page.locator('[data-testid="recovery-email"]');
    this.messageArea = page.locator('[data-testid="recovery-message"]');
    this.continueButton = page.locator('button:has-text("Continue")');
    this.loginLink = page.locator('a:has-text("Log in")');
  }

  async goto() {
    await this.page.goto(config.urls.recovery);
    await this.page.waitForLoadState('domcontentloaded');
  }

  async submitRecovery(email) {
    await this.emailInput.fill(email);
    await this.continueButton.click();
  }

  async getMessage() {
    try {
      await this.messageArea.waitFor({ state: 'visible', timeout: 3000 });
      return await this.messageArea.textContent();
    } catch {
      return null;
    }
  }
}

module.exports = RecoveryPage;
