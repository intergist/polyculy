const config = require('../helpers/config');

class CalendarPage {
  constructor(page) {
    this.page = page;
    this.title = page.locator('[data-testid="calendar-title"]');
    this.navTitle = page.locator('[data-testid="calendar-nav-title"]');
    this.grid = page.locator('[data-testid="calendar-grid"]');
    this.toggleBar = page.locator('[data-testid="toggle-bar"]');

    // View toggles
    this.dayBtn = page.locator('[data-testid="view-day"]');
    this.weekBtn = page.locator('[data-testid="view-week"]');
    this.monthBtn = page.locator('[data-testid="view-month"]');
    this.mineBtn = page.locator('[data-testid="perspective-mine"]');
    this.ourBtn = page.locator('[data-testid="perspective-our"]');

    // Navigation
    this.prevBtn = page.locator('.calendar-nav button').first();
    this.nextBtn = page.locator('.calendar-nav button').last();

    // Action buttons
    this.addPersonalEventBtn = page.locator('button:has-text("Personal Event"), a:has-text("Personal Event")');
    this.addSharedEventBtn = page.locator('button:has-text("Shared Event"), a:has-text("Shared Event")');

    // Notification bell
    this.notifBell = page.locator('[data-testid="notification-bell"]');
    this.notifBadge = page.locator('[data-testid="notification-badge"]');
    this.notifPanel = page.locator('[data-testid="notification-panel"]');

    // Personal event modal fields
    this.peModal = page.locator('[data-testid="personal-event-modal"]');
    this.peTitleInput = page.locator('[data-testid="pe-title"]');
    this.peStartDateInput = page.locator('[data-testid="pe-start-date"]');
    this.peDetailsInput = page.locator('[data-testid="pe-details"]');
    this.peAddressInput = page.locator('[data-testid="pe-address"]');
  }

  async gotoMonth() {
    await this.page.goto(config.urls.calendarMonth);
    await this.page.waitForLoadState('domcontentloaded');
  }

  async gotoWeek() {
    await this.page.goto(config.urls.calendarWeek);
    await this.page.waitForLoadState('domcontentloaded');
  }

  async gotoDay() {
    await this.page.goto(config.urls.calendarDay);
    await this.page.waitForLoadState('domcontentloaded');
  }

  async switchToDay() { await this.dayBtn.click(); }
  async switchToWeek() { await this.weekBtn.click(); }
  async switchToMonth() { await this.monthBtn.click(); }
  async switchToMine() { await this.mineBtn.click(); }
  async switchToOur() { await this.ourBtn.click(); }

  async navigateNext() { await this.nextBtn.click(); }
  async navigatePrev() { await this.prevBtn.click(); }

  async getNavTitle() {
    return this.navTitle.textContent();
  }

  async getCalendarTitle() {
    return this.title.textContent();
  }

  /** Get event elements on the calendar grid */
  async getEventElements() {
    return this.grid.locator('.calendar-event, .event-block, .event-dot').all();
  }

  /** Click the notification bell */
  async openNotifications() {
    await this.notifBell.click();
    await this.notifPanel.waitFor({ state: 'visible', timeout: 3000 });
  }

  /** Get notification badge count */
  async getNotificationBadgeCount() {
    const visible = await this.notifBadge.isVisible();
    if (!visible) return 0;
    const text = await this.notifBadge.textContent();
    return parseInt(text, 10) || 0;
  }

  /** Get notification items from the panel */
  async getNotificationItems() {
    return this.notifPanel.locator('.notif-item').all();
  }
}

module.exports = CalendarPage;
