# Guitar Lesson Booking Platform — Production Design

**Date:** 2026-08-14
**Owner:** Jacob Cunningham (non-engineer)
**Goal:** A stranger can visit the site and book a guitar lesson, reliably and securely.
**Hard constraint:** $0/month ongoing cost.

---

## 1. Verified current state

Everything below was confirmed by reading the code and running the server, not inferred.

**The frontend and backend have never been connected.**

| Finding | Evidence |
|---|---|
| Bookings are stored per-browser, not on a server | All `*.html` write to `localStorage` (`bookedSlots`, `bookingData`, `deviceBookingCount_`) |
| Three of five pages make zero network calls | `index_v2.html`, `index_artistic.html`, `instructor-schedule.html` contain no `fetch()` |
| `index.html` calls a nonexistent endpoint | Calls `/api/send-email`; not defined in `server.js` |
| `questionnaire.html` calls a near-miss endpoint | Calls `/api/questionnaire`; server defines `/api/questionnaires` (plural) |
| The server serves no pages | Ran it: `/health` → 200, `/` → 404, `/index.html` → 404. No `express.static`. |

**Consequence:** if deployed as-is, a stranger's booking would be saved in *their own browser*. Jacob would never see it. Multiple people could book the same slot. Clearing cookies erases it.

**Additional defects found in `server.js`:**

- `jsonwebtoken@^9.1.2` does not exist (highest v9 is 9.0.3) — failed the Render build. *(Fixed, commit e132a2c.)*
- `rate-limit-redis` was imported but never declared in `package.json`, so the server crashed on boot even after a green build. It is also incompatible with `@upstash/redis`, which has no node-redis `sendCommand`. *(Fixed.)*
- Node 18 was EOL. *(Bumped to 22.x.)*
- **No timezone handling anywhere.** Times are stored as strings like `"3:00 PM"` with no zone. Ambiguous the moment anyone books from another timezone.
- Booking creation is not atomic: check-then-set race between the slot check and the slot lock. Two simultaneous requests both succeed.
- Redis slot locks expire after 24h (`ex: 86400`), but lessons can be booked months out. After 24h the slot silently frees up.
- Device booking limit uses `redis.incr` with no expiry — a permanent lifetime cap of 2 lessons per browser, which conflicts with wanting repeat students.
- Reschedule authorization relies on a client-supplied `deviceFingerprint`. Trivially spoofable.
- `console.error('Update error:', error)` in the reschedule handler references an undefined `error`; the in-scope variable is `updateError`. Throws a `ReferenceError` that the outer catch swallows into a generic 500.
- `SUPABASE_ANON_KEY` used server-side for admin queries. Either admin reads fail under RLS, or RLS is off and the key exposes every student's booking.
- `INSTRUCTOR_PASSWORD` hardcoded in client-side JS at `instructor-schedule.html:465`. Readable by anyone via view-source.
- The CSP (`scriptSrc: 'self'`, no `fontSrc`) would block the site's own inline scripts and its Google Fonts, so the pages could not have rendered correctly even if they had been served.

**Assessment:** the backend is a reasonable sketch, but roughly 80% of it solves problems that a free hosted scheduler solves better. The genuine asset is the visual design in `index_artistic.html` (~990 lines of CSS).

---

## 2. Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Architecture | Static site + embedded Cal.com | $0/mo, eliminates whole bug classes |
| Scheduler | Cal.com free tier | Unlimited event types, intake questions, embed, Stripe-ready |
| Payments | **None at launch** | First lesson is a free consultation; money handled in person |
| Homepage | `index_artistic.html` | Chosen as the real design |
| Lesson format | **Both in-person and online** | Two Cal.com event types |
| Booking UI | Themed inline embed only | Simplest thing that works; minimum maintenance |
| Hosting | Render **Static Site** (free) | CDN-served, no spin-down, $0 |

### Why Cal.com over the alternatives

| | Cal.com free | Square Appts free | Google Appt | Calendly free |
|---|---|---|---|---|
| Multiple lesson lengths | Unlimited | Multiple | Limited | **1 only** |
| Intake questions | Yes | Basic | **None** | Limited |
| Auto timezone | Yes | Reportedly weak | Yes | Yes |
| Embed on own site | Yes, responsive | Yes | **No booking page** | Yes |
| Payments later | Stripe 2.9%+30¢ | Square only, 3.3%+30¢ | None | Paid tier |
| True cost | **$0** | $0 | **$6/mo Workspace** | $0 |

Calendly is disqualified by the single-event-type cap. Google needs a paid Workspace seat and has no intake forms. Square is the credible runner-up but locks payments to a higher rate and has weaker timezone handling.

**Known risk:** in 2026 Cal.com moved its main product closed-source, spinning the OSS code out as a separate community edition, so "self-host as an escape hatch" is weaker than it once was. This claim comes from competitor-run comparison blogs and should be held loosely. It does not change the decision, because under this design Cal.com occupies ~15 lines on one page — swapping to Square or Calendly later is an afternoon, not a rebuild. **Replaceability, not perfection, is the argument.**

---

## 3. Architecture

```
Visitor's browser
      |
      v
Render Static Site (free, CDN)
  index.html  <- renamed from index_artistic.html
      |
      | inline embed (~15 lines)
      v
Cal.com (free tier)
  - availability, atomic booking, timezones
  - confirmation + reminder emails
  - reschedule/cancel links
  - intake questions for first-timers
      |
      v
Jacob's Google Calendar
```

**No server. No database. No Redis. No secrets in the repo.**

The entire class of vulnerabilities in the current code — exposed keys, client-side passwords, spoofable auth, injection into Supabase — stops existing because there is nothing to attack. The site is static files on a CDN.

### File disposition

| File | Action |
|---|---|
| `index.html`, `index_v2.html` | → `archive/` **first**, to free the `index.html` name |
| `index_artistic.html` | Then **renamed to `index.html`** — keep CSS + header; replace booking machinery with embed |
| `instructor-schedule.html` | → `archive/` (replaced by Cal.com dashboard + Google Calendar) |
| `questionnaire.html` | → `archive/` (replaced by Cal.com booking questions) |
| `server.js`, `supabase-setup.sql` | → `archive/` |
| `package.json`, `package-lock.json` | → `archive/` (no build step needed) |
| 8 generated `*_GUIDE.md`, `*.sh` | → `archive/` (they describe a system we are not building) |
| `render.yaml` | Rewritten as a static site |
| `README.md` | Rewritten to describe what actually exists |

Archived, not deleted — recoverable in git and on disk if a decision is revisited.

### Changes within the page

Keep: `<head>`, all CSS (lines 8–999), the `<header>` block, `.container`, `.booking-section` wrapper, the `Book Your Lesson` title.

Remove: `.calendar-wrapper`, `.time-selection`, `.learner-type-selector`, both learner forms, `.button-group`, `#changeBookingModal`, `#confirmationModal`, `#bookingLimitModal`, and the entire `<script>` block (lines 1214–1710).

Add: two Cal.com inline embeds (in-person and online) themed with `cssVarsPerTheme` to `--primary: #1a1a2e`, `--secondary: #d4a574`, `--light: #f5f1e8`.

Note that "Already Booked? Change Your Booking Time/Date Here" goes away — Cal.com puts reschedule and cancel links directly in the confirmation email, which is both more reliable and more familiar to users than a modal that asks them to retype their booking.

---

## 4. Data flow

1. Visitor loads the static page from Render's CDN.
2. Cal.com's embed script loads and renders availability, in **the visitor's own timezone**.
3. Visitor picks in-person or online, then a slot.
4. Visitor fills name, email, and the intake questions (skill level, goals, guitar type). First-timers see extra questions; returning students do not.
5. Cal.com writes the booking atomically — no double-booking is possible.
6. Cal.com emails the visitor a confirmation with reschedule/cancel links, and emails Jacob a notification.
7. The lesson appears on Jacob's Google Calendar. For online lessons, a Cal Video link is generated and included automatically.
8. Cal.com sends an automated reminder before the lesson.

---

## 5. Error handling

Because the site is static, there are only two realistic failure modes.

**Cal.com is unreachable or the embed fails to load.** The embed container includes fallback markup, visible only if the embed does not initialize: a direct link to the Cal.com booking page plus an email address. A visitor is never left staring at an empty box.

**A visitor has JavaScript disabled.** Same fallback, inside a `<noscript>` block.

There is no server to return 500s, no database to fail, and no secrets to leak.

---

## 6. Security posture

| Current risk | Status after |
|---|---|
| Instructor password in page source | **Gone** — Cal.com handles auth |
| Supabase anon key used for admin reads | **Gone** — no database |
| Spoofable device-fingerprint auth | **Gone** — Cal.com owns reschedule links |
| Booking race condition | **Gone** — Cal.com books atomically |
| Student PII stored by us | **Gone** — Cal.com is the data processor |
| Secrets in env vars | **Gone** — nothing to configure |

Remaining surface: the repo stays private, and Jacob's Cal.com and Google accounts should have strong unique passwords with 2FA. That is the whole list.

---

## 7. Verification plan

Each item must be *observed*, not assumed:

1. `index.html` loads locally with no console errors.
2. Both embeds render and display real availability.
3. A test booking from an incognito window produces: a confirmation email, an entry on Google Calendar, and the slot disappearing from the public page.
4. That same slot is confirmed unavailable in a second browser (proves the double-booking fix).
5. A booking made with the browser timezone set to a different zone lands at the correct absolute time (proves the timezone fix).
6. The reschedule link in the confirmation email works.
7. The page renders correctly at 375px mobile width.
8. The fallback link is visible with JavaScript disabled.
9. Deployed Render URL serves `/` with HTTP 200 (the current server returns 404).

---

## 8. Setup steps Jacob must perform himself

These require account creation or credentials, which cannot be delegated:

1. Create a free Cal.com account and pick a username (it appears in the booking URL).
2. Connect Google Calendar so real-life commitments block lesson slots.
3. Create two event types: in-person (with address) and online (Cal Video).
4. Set weekly availability.
5. Add booking questions for first-time students.
6. In Render, change the service type from Web Service to **Static Site**, which also drops the $7/mo charge.

Once the Cal.com username and event-type slugs exist, they get wired into the page.

---

## 9. Explicitly out of scope

- **Payments.** Deferred by choice. Cal.com can enable Stripe later without touching the site.
- **The custom calendar grid fed by Cal.com's public slots API.** Technically viable — `https://api.cal.com/v2/slots` is readable without an API key for public event types — but it is ~150 lines of custom JS resting on an endpoint with open bug reports, versus ~15 lines that essentially cannot break. Revisit only if the embed's appearance proves unsatisfactory in practice.
- **Bio, photos, testimonials, lesson descriptions.** Flagged as the likeliest cause of lost bookings: a stranger currently sees a name, a price, and a calendar, with no indication of who Jacob is or where lessons happen. Deliberately deferred to keep the look unchanged. Recommended as the first improvement after launch.
- **SMS reminders.** Email reminders are free and sufficient at this stage.

---

## 10. Risks

| Risk | Likelihood | Mitigation |
|---|---|---|
| Cal.com restricts its free tier | Low | ~15 lines to swap to Square/Calendly |
| Cal.com branding looks unprofessional | Medium | Small footer mark; removal costs $15/mo if it matters |
| Embed styling can't fully match the design | Medium | `cssVarsPerTheme` + surrounding page chrome; accepted tradeoff |
| Strangers book and no-show | **Medium-high** | No payment means no commitment. Revisit deposits if it becomes a problem. |
| Site gets no traffic | High | Out of scope here, but the real constraint on getting students |

---

## 11. Success criteria

A stranger, on a phone, in a different timezone, can find the page, understand whether the lesson is in person or online, book a slot, receive a confirmation email, and have that lesson appear on Jacob's calendar — with no possibility of double-booking and no data stored by us. At $0/month.
