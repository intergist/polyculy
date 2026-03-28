# Polyculy

> **Calendar that keeps up** — Easy management for scheduling complexity of polyamorous relationships.

## Overview

Polyculy is a privacy-first calendar and scheduling app designed specifically for polyamorous people and polycules. It combines personal calendars, shared event invitations, selective calendar overlays, and per-event visibility controls.

## Key Features

- **Licence-based access** — Users join via licence codes (purchased, gifted, or promotional)
- **Connection management** — Mutual connections with 5 status types (Connected, Awaiting Confirmation, Awaiting Signup, Licence Gifted, Revoked)
- **Personal events** — 3-tier visibility: Invisible, Full Details, or Busy Block only
- **Shared event invitations** — Multi-participant events with Required/Optional designations
- **Calendar views** — Day, Week, Month with Mine/Our toggle
- **Polycule overlay** — See all connected calendars with color-coded toggle bar
- **Proposal system** — Participants can propose new times; organizer accepts/rejects
- **One-hop invitations** — Consent-gated indirect invitations through connection graph
- **Revocation engine** — Batch event-impact review when connections are revoked
- **Ownership transfer** — Claim event ownership when organizer is removed
- **Notification preferences** — Per-type toggles, delivery mode, quiet hours

## Tech Stack

- **Backend:** CFML (Lucee 5.4+) with H2 embedded database
- **Server:** CommandBox (port 5000)
- **Frontend:** Bootstrap 5.3.3, jQuery 3.7.1, Font Awesome 6.5.1, DataTables 1.13.8, Chosen 1.8.7, Chart.js 4.4.1
- **Font:** Inter (Google Fonts)
- **Design:** Purple/pink gradient aesthetic with soft lavender tones

## Project Structure

```
polyculy/
├── Application.cfc          # Session management, H2 datasource, auth checks
├── server.json / box.json   # CommandBox config (port 5000)
├── index.cfm                # Entry point (redirects to login)
├── components/
│   └── DatabaseInit.cfc     # Schema + seed data initialization
├── sql/
│   ├── h2_schema.sql        # 15 tables
│   └── seed.sql             # 7 demo users with sample data
├── model/
│   ├── UserService.cfc
│   ├── LicenceService.cfc
│   ├── ConnectionService.cfc
│   ├── EventService.cfc
│   ├── SharedEventService.cfc
│   ├── ProposalService.cfc
│   ├── NotificationService.cfc
│   ├── AuditService.cfc
│   └── RevocationService.cfc
├── api/
│   ├── auth.cfm             # Login, signup, recovery, logout
│   ├── connections.cfm      # List, send, confirm, revoke, hide, gift licence
│   ├── events.cfm           # Personal event CRUD
│   ├── shared-events.cfm    # Shared event CRUD, respond, propose, cancel
│   ├── notifications.cfm    # List, read, preferences
│   ├── calendar.cfm         # Calendar events, overlay, setup, toggle
│   └── preferences.cfm      # Timezone, display preferences
├── views/
│   ├── layouts/main.cfm     # Top navbar layout (custom tag)
│   ├── auth/                # login, signup, recovery
│   ├── connections/         # connect, results, revoke-review
│   ├── calendar/            # setup, month, week, day
│   ├── events/              # personal, shared, invitation-card, propose-time,
│   │                        # proposal-review, one-hop-consent, indirect-invite,
│   │                        # ownership-transfer, info-email, claimable,
│   │                        # remove-participant
│   └── settings/            # timezone, notifications
└── assets/
    ├── css/polyculy.css     # 1080+ lines of custom styling
    └── js/polyculy.js       # 726 lines of client-side logic
```

## Quick Start

1. Install [CommandBox](https://www.ortussolutions.com/products/commandbox)
2. Navigate to this directory: `cd polyculy`
3. Start the server: `box server start`
4. Open `http://localhost:5000`
5. Log in with any demo user (password: `demo123`):
   - you@polyculy.demo
   - riley@polyculy.demo
   - jamie@polyculy.demo
   - alex@polyculy.demo
   - casey@polyculy.demo
   - morgan@polyculy.demo
   - sam@polyculy.demo

## Demo Data

The seed data creates a complete demo scenario:
- **7 users** with various connection statuses
- **Connections** in all 5 status types
- **Personal events** with different visibility settings
- **Shared events** with multiple participants
- **Notifications** and **audit log** entries

## Phase 2 (Deferred)

- Two-way Google Calendar sync backend
- .ics import backend (UI is present, backend stubbed)
- Calendar export as .ics link

## Branding

| Attribute | Value |
|-----------|-------|
| Primary Purple | #7C3AED |
| Heading Purple | #6D28D9 |
| Gradient | linear-gradient(135deg, #E9D5FF, #FBCFE8, #C4B5FD) |
| Font | Inter |
| Tagline | "Calendar that keeps up" |
