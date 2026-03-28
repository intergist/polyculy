/**
 * Navigation bar component — shared across authenticated pages.
 */
class NavBar {
  constructor(page) {
    this.page = page;
    this.polyculeLink = page.locator('[data-testid="nav-polycule"]');
    this.settingsLink = page.locator('[data-testid="nav-settings"]');
    this.logoutLink = page.locator('[data-testid="nav-logout"]');
    this.notifBell = page.locator('[data-testid="notification-bell"]');
    this.notifBadge = page.locator('[data-testid="notification-badge"]');
    this.notifPanel = page.locator('[data-testid="notification-panel"]');
    this.notifList = page.locator('[data-testid="notification-list"]');
    this.userAvatar = page.locator('.user-avatar-nav');
  }

  async goToPolycule() {
    await this.polyculeLink.click();
    await this.page.waitForLoadState('domcontentloaded');
  }

  async goToSettings() {
    await this.settingsLink.click();
    await this.page.waitForLoadState('domcontentloaded');
  }

  async logout() {
    await this.logoutLink.click();
    await this.page.waitForLoadState('domcontentloaded');
  }

  async openNotifications() {
    await this.notifBell.click();
    try {
      await this.notifPanel.waitFor({ state: 'visible', timeout: 3000 });
    } catch {
      // Panel may already be visible
    }
  }

  async getNotificationBadgeCount() {
    const visible = await this.notifBadge.isVisible();
    if (!visible) return 0;
    const text = await this.notifBadge.textContent();
    return parseInt(text.trim(), 10) || 0;
  }

  async getNotificationItems() {
    await this.openNotifications();
    return this.notifList.locator('.notif-item').all();
  }

  async isNavbarVisible() {
    return this.polyculeLink.isVisible();
  }
}

module.exports = NavBar;
