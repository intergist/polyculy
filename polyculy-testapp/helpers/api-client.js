/**
 * API client helper for direct HTTP calls to Polyculy APIs.
 * Used for test data setup/cleanup and state verification without UI interaction.
 */
const config = require('./config');

class ApiClient {
  /**
   * @param {import('@playwright/test').APIRequestContext} request
   */
  constructor(request) {
    this.request = request;
  }

  /** Login via API and return session context */
  async login(email, password) {
    const resp = await this.request.post(config.api.auth, {
      form: { action: 'login', email, password },
    });
    return resp.json();
  }

  /** Logout via API */
  async logout() {
    const resp = await this.request.post(`${config.api.auth}?action=logout`);
    return resp.json();
  }

  /** Re-seed the database to pristine state */
  async reseedDatabase() {
    const resp = await this.request.get(`${config.baseUrl}/api/reset-seed.cfm`);
    return resp.json();
  }

  // ─── Connections ───────────────────────────────────────────────────────────

  /** List connections for the logged-in user */
  async listConnections() {
    const resp = await this.request.get(`${config.api.connections}?action=list`);
    return resp.json();
  }

  /** List connected users only */
  async listConnectedUsers() {
    const resp = await this.request.get(`${config.api.connections}?action=connected`);
    return resp.json();
  }

  /** Send connection request */
  async sendConnectionRequest(email, displayName) {
    const resp = await this.request.post(`${config.api.connections}?action=send`, {
      form: { email, displayName },
    });
    return resp.json();
  }

  /** Confirm connection */
  async confirmConnection(connectionId) {
    const resp = await this.request.post(`${config.api.connections}?action=confirm`, {
      form: { connectionId: String(connectionId) },
    });
    return resp.json();
  }

  /** Revoke connection */
  async revokeConnection(connectionId) {
    const resp = await this.request.post(`${config.api.connections}?action=revoke`, {
      form: { connectionId: String(connectionId) },
    });
    return resp.json();
  }

  // ─── Personal Events ──────────────────────────────────────────────────────

  /** List personal events */
  async listPersonalEvents() {
    const resp = await this.request.get(`${config.api.events}?action=list`);
    return resp.json();
  }

  /** Get a single personal event */
  async getPersonalEvent(id) {
    const resp = await this.request.get(`${config.api.events}?action=get&id=${id}`);
    return resp.json();
  }

  /** Create a personal event */
  async createPersonalEvent({ title, startDate, startHour, startMinute, startAmPm, endHour, endMinute, endAmPm, eventDetails, address, visibilityTier, fullDetailUsers, busyBlockUsers }) {
    const form = {
      title,
      startDate,
      startHour: startHour || '09',
      startMinute: startMinute || '00',
      startAmPm: startAmPm || 'AM',
      endHour: endHour || '10',
      endMinute: endMinute || '00',
      endAmPm: endAmPm || 'AM',
      eventDetails: eventDetails || '',
      address: address || '',
      visibilityTier: visibilityTier || 'invisible',
    };
    if (fullDetailUsers) form.fullDetailUsers = fullDetailUsers;
    if (busyBlockUsers) form.busyBlockUsers = busyBlockUsers;
    const resp = await this.request.post(`${config.api.events}?action=create`, { form });
    return resp.json();
  }

  /** Delete a personal event */
  async deletePersonalEvent(eventId) {
    const resp = await this.request.post(`${config.api.events}?action=delete`, {
      form: { eventId: String(eventId) },
    });
    return resp.json();
  }

  // ─── Shared Events ────────────────────────────────────────────────────────

  /** List shared events */
  async listSharedEvents() {
    const resp = await this.request.get(`${config.api.sharedEvents}?action=list`);
    return resp.json();
  }

  /** Get a single shared event */
  async getSharedEvent(id) {
    const resp = await this.request.get(`${config.api.sharedEvents}?action=get&id=${id}`);
    return resp.json();
  }

  /** Create a shared event with participants */
  async createSharedEvent({ title, startDate, startHour, startMinute, startAmPm, endDate, endHour, endMinute, endAmPm, eventDetails, address, reminderScope, participantVisibility, participants, attendanceMap }) {
    const form = {
      title,
      startDate,
      startHour: startHour || '07',
      startMinute: startMinute || '00',
      startAmPm: startAmPm || 'PM',
      endDate: endDate || startDate,
      endHour: endHour || '08',
      endMinute: endMinute || '00',
      endAmPm: endAmPm || 'PM',
      eventDetails: eventDetails || '',
      address: address || '',
      reminderMinutes: '15',
      reminderScope: reminderScope || 'me',
      participantVisibility: participantVisibility || 'visible',
    };
    if (participants && participants.length) {
      form.participants = participants.join(',');
      for (const pid of participants) {
        form[`attendance_${pid}`] = (attendanceMap && attendanceMap[pid]) || 'required';
      }
    }
    const resp = await this.request.post(`${config.api.sharedEvents}?action=create`, { form });
    return resp.json();
  }

  /** Respond to a shared event invitation */
  async respondToSharedEvent(eventId, response) {
    const resp = await this.request.post(`${config.api.sharedEvents}?action=respond`, {
      form: { eventId: String(eventId), response },
    });
    return resp.json();
  }

  /** Cancel a shared event (organizer only) */
  async cancelSharedEvent(eventId) {
    const resp = await this.request.post(`${config.api.sharedEvents}?action=cancel`, {
      form: { eventId: String(eventId) },
    });
    return resp.json();
  }

  /** Remove a participant from a shared event */
  async removeParticipant(eventId, participantUserId) {
    const resp = await this.request.post(`${config.api.sharedEvents}?action=removeParticipant`, {
      form: { eventId: String(eventId), participantUserId: String(participantUserId) },
    });
    return resp.json();
  }

  /** Update a shared event (organizer only) */
  async updateSharedEvent(eventId, { title, startDate, startHour, startMinute, startAmPm, endDate, endHour, endMinute, endAmPm, eventDetails, address, reminderScope, participantVisibility }) {
    const form = {
      eventId: String(eventId),
      title,
      startDate,
      startHour: startHour || '07',
      startMinute: startMinute || '00',
      startAmPm: startAmPm || 'PM',
      endDate: endDate || startDate,
      endHour: endHour || '08',
      endMinute: endMinute || '00',
      endAmPm: endAmPm || 'PM',
      eventDetails: eventDetails || '',
      address: address || '',
      reminderMinutes: '15',
      reminderScope: reminderScope || 'me',
      participantVisibility: participantVisibility || 'visible',
    };
    const resp = await this.request.post(`${config.api.sharedEvents}?action=update`, { form });
    return resp.json();
  }

  /** Claim ownership of an event */
  async claimOwnership(eventId) {
    const resp = await this.request.post(`${config.api.sharedEvents}?action=claimOwnership`, {
      form: { eventId: String(eventId) },
    });
    return resp.json();
  }

  /** Check conflicts for a time range */
  async checkConflicts(userId, startTime, endTime) {
    const resp = await this.request.get(
      `${config.api.sharedEvents}?action=conflicts&userId=${userId}&startTime=${encodeURIComponent(startTime)}&endTime=${encodeURIComponent(endTime)}`
    );
    return resp.json();
  }

  // ─── Calendar ─────────────────────────────────────────────────────────────

  /** Get calendar events for a date range */
  async getCalendarEvents(startDate, endDate) {
    const resp = await this.request.get(
      `${config.api.calendar}?action=events&startDate=${startDate}&endDate=${endDate}`
    );
    return resp.json();
  }

  /** Get calendar overlay data */
  async getCalendarOverlay(startDate, endDate) {
    const resp = await this.request.get(
      `${config.api.calendar}?action=overlay&startDate=${startDate}&endDate=${endDate}`
    );
    return resp.json();
  }

  // ─── Notifications ────────────────────────────────────────────────────────

  /** List notifications */
  async listNotifications(limit = 20) {
    const resp = await this.request.get(`${config.api.notifications}?action=list&limit=${limit}`);
    return resp.json();
  }

  /** Get notification unread count */
  async getUnreadCount() {
    const resp = await this.request.get(`${config.api.notifications}?action=unreadCount`);
    return resp.json();
  }

  /** Mark a notification as read */
  async markNotificationRead(notificationId) {
    const resp = await this.request.post(`${config.api.notifications}?action=markRead`, {
      form: { notificationId: String(notificationId) },
    });
    return resp.json();
  }

  /** Mark all notifications as read */
  async markAllNotificationsRead() {
    const resp = await this.request.post(`${config.api.notifications}?action=markAllRead`);
    return resp.json();
  }

  /** Get notification preferences */
  async getNotificationPreferences() {
    const resp = await this.request.get(`${config.api.notifications}?action=preferences`);
    return resp.json();
  }

  /** Save a notification preference */
  async saveNotificationPreference(notificationType, isEnabled, deliveryMode = 'instant', quietStart = '', quietEnd = '') {
    const resp = await this.request.post(`${config.api.notifications}?action=savePreference`, {
      form: { notificationType, isEnabled: String(isEnabled), deliveryMode, quietStart, quietEnd },
    });
    return resp.json();
  }

  // ─── Preferences ──────────────────────────────────────────────────────────

  /** Get user preferences */
  async getPreferences() {
    const resp = await this.request.get(`${config.api.preferences}?action=get`);
    return resp.json();
  }

  /** Save timezone preference */
  async saveTimezone(timezoneId) {
    const resp = await this.request.post(`${config.api.preferences}?action=saveTimezone`, {
      form: { timezoneId },
    });
    return resp.json();
  }

  /** Save display preferences for a polymate */
  async saveDisplayPrefs(targetUserId, nickname, avatarOverride = '', calendarColor = '') {
    const resp = await this.request.post(`${config.api.preferences}?action=saveDisplayPrefs`, {
      form: { targetUserId: String(targetUserId), nickname, avatarOverride, calendarColor },
    });
    return resp.json();
  }

  // ─── Proposals ────────────────────────────────────────────────────────────

  /** List proposals for a shared event */
  async listProposals(eventId) {
    const resp = await this.request.get(
      `${config.api.proposals}?action=listForEvent&event_id=${eventId}`
    );
    return resp.json();
  }

  /** List active proposals for a shared event */
  async listActiveProposals(eventId) {
    const resp = await this.request.get(
      `${config.api.proposals}?action=activeForEvent&event_id=${eventId}`
    );
    return resp.json();
  }

  /** Create a proposal */
  async createProposal(eventId, proposedStart, proposedEnd, message = '') {
    const resp = await this.request.post(`${config.api.proposals}?action=create`, {
      form: { event_id: String(eventId), proposed_start: proposedStart, proposed_end: proposedEnd, message },
    });
    return resp.json();
  }

  /** Accept a proposal (organizer only) */
  async acceptProposal(proposalId) {
    const resp = await this.request.post(`${config.api.proposals}?action=accept`, {
      form: { proposal_id: String(proposalId) },
    });
    return resp.json();
  }

  /** Reject a proposal (organizer only) */
  async rejectProposal(proposalId) {
    const resp = await this.request.post(`${config.api.proposals}?action=reject`, {
      form: { proposal_id: String(proposalId) },
    });
    return resp.json();
  }

  // ─── Licences ─────────────────────────────────────────────────────────────

  /** List user's licences */
  async listLicences() {
    const resp = await this.request.get(`${config.api.licences}?action=list`);
    return resp.json();
  }

  /** Validate a licence code */
  async validateLicence(code) {
    const resp = await this.request.get(`${config.api.licences}?action=validate&code=${encodeURIComponent(code)}`);
    return resp.json();
  }

  /** List available licences for gifting */
  async listAvailableLicences() {
    const resp = await this.request.get(`${config.api.licences}?action=available`);
    return resp.json();
  }
}

module.exports = ApiClient;
