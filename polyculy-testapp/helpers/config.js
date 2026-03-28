/**
 * Centralized configuration for test data, credentials, and environment settings.
 * All values can be overridden via environment variables or .env file.
 */
require('dotenv').config();

const config = {
  baseUrl: process.env.POLYCULY_BASE_URL || 'http://localhost:5000',
  testMode: process.env.POLYCULY_TEST_MODE || 'local',
  testPrefix: process.env.POLYCULY_TEST_USER_PREFIX || 'e2etest_',

  // Seed user credentials — these users are pre-seeded and must not be mutated
  seeds: {
    admin: {
      email: process.env.POLYCULY_SEED_ADMIN_EMAIL || 'you@polyculy.demo',
      password: process.env.POLYCULY_SEED_ADMIN_PASSWORD || 'demo123',
      displayName: 'You',
      userId: 1,
    },
    riley: {
      email: process.env.POLYCULY_SEED_RILEY_EMAIL || 'riley@polyculy.demo',
      password: process.env.POLYCULY_SEED_RILEY_PASSWORD || 'demo123',
      displayName: 'Riley',
      userId: 2,
    },
    jamie: {
      email: process.env.POLYCULY_SEED_JAMIE_EMAIL || 'jamie@polyculy.demo',
      password: process.env.POLYCULY_SEED_JAMIE_PASSWORD || 'demo123',
      displayName: 'Jamie',
      userId: 3,
    },
    alex: {
      email: process.env.POLYCULY_SEED_ALEX_EMAIL || 'alex@polyculy.demo',
      password: process.env.POLYCULY_SEED_ALEX_PASSWORD || 'demo123',
      displayName: 'Alex',
      userId: 4,
    },
    casey: { displayName: 'Casey', userId: 5 },
    morgan: { displayName: 'Morgan', userId: 6 },
    sam: { displayName: 'Sam', userId: 7 },
  },

  // Seed connection statuses (from admin's perspective)
  seedConnections: {
    riley: { status: 'connected', connectionId: 1 },
    jamie: { status: 'awaiting_confirmation', connectionId: 2 },
    alex: { status: 'awaiting_confirmation', connectionId: 3 },
    casey: { status: 'licence_gifted_awaiting_signup', connectionId: 4 },
    morgan: { status: 'awaiting_signup', connectionId: 5 },
    sam: { status: 'revoked', connectionId: 6 },
  },

  // Seed events
  seedEvents: {
    personal: {
      doctorAppointment: { id: 1, title: "Doctor's appointment", visibility: 'full_details' },
      yogaClass: { id: 2, title: 'Yoga Class', visibility: 'invisible' },
      workMeeting: { id: 3, title: 'Work Meeting', visibility: 'full_details' },
    },
    shared: {
      dinnerWithCasey: { id: 1, title: 'Dinner with Casey', state: 'tentative' },
      lunchWithAlex: { id: 2, title: 'Lunch with Alex', state: 'active' },
      gymWithJamie: { id: 3, title: 'Gym with Jamie', state: 'tentative' },
      movieNight: { id: 4, title: 'Movie Night with Riley', state: 'active' },
    },
  },

  // Available licence codes for testing signup
  seedLicences: {
    available: ['BETA-007-FREE', 'BETA-008-FREE', 'PROMO-009-FREE', 'PROMO-010-FREE'],
    giftedPending: 'GIFT-005-CASEY',
  },

  // Notification seed data
  seedNotifications: {
    expectedUnreadCount: 2,
    expectedItems: [
      { type: 'connection_request', title: 'Connection Request' },
      { type: 'shared_event_invitation', title: 'Event Invitation' },
      { type: 'shared_event_accepted', title: 'Event Accepted', isRead: true },
    ],
  },

  // URLs
  urls: {
    login: '/views/auth/login.cfm',
    signup: '/views/auth/signup.cfm',
    recovery: '/views/auth/recovery.cfm',
    calendarMonth: '/views/calendar/month.cfm',
    calendarWeek: '/views/calendar/week.cfm',
    calendarDay: '/views/calendar/day.cfm',
    calendarSetup: '/views/calendar/setup.cfm',
    connections: '/views/connections/connect.cfm',
    connectionResults: '/views/connections/results.cfm',
    settingsTimezone: '/views/settings/timezone.cfm',
    settingsNotifications: '/views/settings/notifications.cfm',
    personalEvents: '/views/events/personal.cfm',
    sharedEvents: '/views/events/shared.cfm',
  },

  // API endpoints
  api: {
    auth: '/api/auth.cfm',
    connections: '/api/connections.cfm',
    events: '/api/events.cfm',
    sharedEvents: '/api/shared-events.cfm',
    calendar: '/api/calendar.cfm',
    notifications: '/api/notifications.cfm',
    preferences: '/api/preferences.cfm',
    proposals: '/api/proposals.cfm',
    licences: '/api/licences.cfm',
    dbInit: '/components/DatabaseInit.cfc?method=init',
  },
};

module.exports = config;
