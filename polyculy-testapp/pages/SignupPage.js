const config = require('../helpers/config');

class SignupPage {
  constructor(page) {
    this.page = page;
    this.emailInput = page.locator('[data-testid="signup-email"]');
    this.licenceInput = page.locator('[data-testid="signup-licence"]');
    this.messageArea = page.locator('[data-testid="signup-message"]');
    this.continueButton = page.locator('button:has-text("Continue")');
    this.loginLink = page.locator('a:has-text("Log in")');
    this.pageHeading = page.locator('h1, h2').first();
  }

  async goto() {
    await this.page.goto(config.urls.signup);
    await this.page.waitForLoadState('domcontentloaded');
  }

  async fillSignupForm(email, licenceCode) {
    await this.emailInput.fill(email);
    await this.licenceInput.fill(licenceCode);
    await this.continueButton.click();
  }

  async getMessage() {
    try {
      await this.messageArea.waitFor({ state: 'visible', timeout: 5000 });
      return await this.messageArea.textContent();
    } catch {
      // Fallback: check if the form-message element appeared with a different selector
      const fallback = this.page.locator('.form-message.error:visible, .form-message:visible');
      try {
        await fallback.first().waitFor({ state: 'visible', timeout: 2000 });
        return await fallback.first().textContent();
      } catch {
        return null;
      }
    }
  }
}

module.exports = SignupPage;
