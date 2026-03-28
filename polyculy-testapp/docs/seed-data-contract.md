# Seed Data Contract

This document defines the expected seed data state for the Polyculy test suite. All seed data is created by `sql/seed.sql` and restored by `api/reset-seed.cfm`.

## Users (IDs 1–7)

| ID | Email | Display Name | Has Account | Password |
|---|---|---|---|---|
| 1 | you@polyculy.demo | You | Yes | demo123 |
| 2 | riley@polyculy.demo | Riley | Yes | demo123 |
| 3 | jamie@polyculy.demo | Jamie | Yes | demo123 |
| 4 | alex@polyculy.demo | Alex | Yes | demo123 |
| 5 | casey@polyculy.demo | Casey | No (invited) | — |
| 6 | morgan@polyculy.demo | Morgan | No (invited) | — |
| 7 | sam@polyculy.demo | Sam | No (invited) | — |

## Connections (IDs 1–6, from User 1's perspective)

| ID | Partner | Status | Notes |
|---|---|---|---|
| 1 | Riley (2) | `connected` | Fully connected, can share events |
| 2 | Jamie (3) | `awaiting_confirmation` | Sent, awaiting Jamie's approval |
| 3 | Alex (4) | `awaiting_confirmation` | Sent, awaiting Alex's approval |
| 4 | Casey (5) | `licence_gifted_awaiting_signup` | Licence gifted, Casey hasn't signed up |
| 5 | Morgan (6) | `awaiting_signup` | Invited, Morgan hasn't signed up |
| 6 | Sam (7) | `revoked` | Previously connected, now revoked |

## Personal Events (IDs 1–3, owned by User 1)

| ID | Title | Start Date | Visibility |
|---|---|---|---|
| 1 | Doctor's appointment | April 15, 2026 | `full_details` (shared with Riley) |
| 2 | Yoga Class | April 18, 2026 | `invisible` |
| 3 | Work Meeting | April 20, 2026 | `full_details` (busy block to Riley) |

## Shared Events (IDs 1–4)

| ID | Title | Organizer | Participants | State |
|---|---|---|---|---|
| 1 | Dinner with Casey | You (1) | Riley (pending) | `tentative` |
| 2 | Lunch with Alex | You (1) | Alex (accepted) | `active` |
| 3 | Gym with Jamie | You (1) | Jamie (pending) | `tentative` |
| 4 | Movie Night with Riley | Riley (2) | You (accepted), Alex (maybe) | `active` |

## Licences (IDs 1–10)

| ID | Code | Type | Status |
|---|---|---|---|
| 1 | ALPHA-001-FREE | alpha | `redeemed` (by User 1) |
| 2 | ALPHA-002-FREE | alpha | `redeemed` (by User 2) |
| 3 | ALPHA-003-FREE | alpha | `redeemed` (by User 3) |
| 4 | ALPHA-004-FREE | alpha | `redeemed` (by User 4) |
| 5 | GIFT-005-CASEY | gifted | `gifted_pending` (to Casey) |
| 6 | BETA-006-FREE | beta | `redeemed` |
| 7 | BETA-007-FREE | beta | `available` |
| 8 | BETA-008-FREE | beta | `available` |
| 9 | PROMO-009-FREE | purchased | `available` |
| 10 | PROMO-010-FREE | purchased | `available` |

## Notifications (IDs 1–3)

| ID | Type | Title | Read |
|---|---|---|---|
| 1 | `connection_request` | Connection Request | No |
| 2 | `shared_event_invitation` | Event Invitation | No |
| 3 | `shared_event_accepted` | Event Accepted | Yes |

## Reset Endpoint

`GET /api/reset-seed.cfm` — Public endpoint (no auth required) that:

1. Deletes all proposals
2. Deletes non-seed shared event participants (shared_event_id > 4)
3. Deletes non-seed shared events (shared_event_id > 4)
4. Deletes non-seed connections (connection_id > 6)
5. Deletes non-seed personal events (event_id > 3)
6. Deletes non-seed notifications (notification_id > 3)
7. Deletes non-seed licences (licence_id > 10)
8. Deletes non-seed audit entries (audit_id > 10)
9. Resets all seed connection statuses to original values
10. Resets all seed shared event states to original values
11. Resets seed notification read states
12. Resets available licence statuses

Returns `{ "success": true, "message": "Seed data reset to pristine state." }` on success.
