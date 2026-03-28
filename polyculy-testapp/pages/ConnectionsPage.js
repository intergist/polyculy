const config = require('../helpers/config');

class ConnectionsPage {
  constructor(page) {
    this.page = page;
    this.connectionRows = page.locator('[data-testid="connection-rows"]');
    this.polyculeList = page.locator('[data-testid="polycule-list"]');
    this.messageArea = page.locator('[data-testid="connection-message"]');

    // Form fields for adding connection
    this.emailInput = page.locator('#connEmail');
    this.displayNameInput = page.locator('#connDisplayName');
    this.sendButton = page.locator('#sendConnBtn, button:has-text("Send Connection")');
    this.addAnotherLink = page.locator('a:has-text("Add Another")');
  }

  async goto() {
    await this.page.goto(config.urls.connections);
    await this.page.waitForLoadState('domcontentloaded');
  }

  /** Get all polycule member entries in the sidebar */
  async getPolyculeMembers() {
    await this.page.waitForTimeout(1000); // Let AJAX load
    const items = await this.polyculeList.locator('.polycule-member, .member-item, .member-row, [class*="member"]').all();
    return items;
  }

  /** Get text content of the polycule sidebar */
  async getPolyculeListText() {
    // Wait for AJAX to populate the polycule list
    await this.polyculeList.locator('.polycule-member').first().waitFor({ state: 'visible', timeout: 10000 });
    return this.polyculeList.textContent();
  }

  /** Send a new connection request via form */
  async sendConnectionRequest(email, displayName) {
    await this.emailInput.fill(email);
    await this.displayNameInput.fill(displayName);
    await this.sendButton.click();
    await this.page.waitForTimeout(1500);
  }

  /** Get message text */
  async getMessage() {
    try {
      await this.messageArea.waitFor({ state: 'visible', timeout: 3000 });
      return await this.messageArea.textContent();
    } catch {
      return null;
    }
  }
}

module.exports = ConnectionsPage;
