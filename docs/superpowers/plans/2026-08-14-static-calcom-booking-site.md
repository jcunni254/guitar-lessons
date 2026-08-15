# Static Cal.com Booking Site Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert the guitar lesson site from a non-functional Express app into a static site with an embedded Cal.com booker, so a stranger can actually book a lesson, at $0/month.

**Architecture:** Delete nothing, archive everything unused. `index_artistic.html` becomes `index.html`, keeping its ~990 lines of CSS and its header intact. The custom calendar, forms, and modals — all `localStorage`-backed and non-functional — are replaced by a single themed Cal.com inline embed pointed at the profile page `jacob-cunningham-geibwx`, which lists both lesson lengths. `render.yaml` becomes a static site definition. No server, no database, no secrets.

**Tech Stack:** Static HTML/CSS, Cal.com embed (vanilla JS snippet), Render Static Sites.

## Global Constraints

- **Cal.com username:** `jacob-cunningham-geibwx` (verified live 2026-08-14)
- **Event type slugs:** `1-hour-lesson`, `30min` (both public, both returning slots)
- **Embed target:** `jacob-cunningham-geibwx` (profile page — lists both event types)
- **Palette (must match existing CSS):** `--primary: #1a1a2e`, `--secondary: #d4a574`, `--accent: #e94560`, `--light: #f5f1e8`, `--dark: #0f0f1e`
- **Fonts already loaded by the page:** Playfair Display, Cardo, Outfit, Roboto Mono (Google Fonts)
- **Cost ceiling:** $0/month. Do not introduce any paid service, build step, or dependency.
- **No secrets.** No API keys, tokens, or passwords in any committed file. The embed uses only public identifiers.
- **Preserve the visual identity.** Do not alter the `<head>`, the `:root` CSS variables, the `<header>` block, or any existing CSS rule.

### A note on testing

This repo has no test framework and, after this work, no build step or runtime code to unit-test. Adding Jest to assert on static HTML would be ceremony, not safety. Verification here is therefore **observable behavior**: HTTP status codes, DOM assertions run in a real browser, and a real end-to-end booking. Every verification step below states the exact command and the exact expected output. Do not mark a step complete without seeing that output.

---

### Task 1: Archive unused files

Removes the dead Express app, the unused page variants, and the generated guides describing a system we are not building. Nothing is deleted — everything stays in git history and on disk under `archive/`.

**Files:**
- Create: `archive/` (directory)
- Move: `server.js`, `supabase-setup.sql`, `package.json`, `package-lock.json`, `index.html`, `index_v2.html`, `instructor-schedule.html`, `questionnaire.html`, `LOCAL_SETUP.sh`, `MASTER_DEPLOY.sh`, and the seven generated `*_GUIDE.md` / setup markdown files
- Modify: `.gitignore`

**Interfaces:**
- Consumes: nothing
- Produces: a repo root containing only `index_artistic.html`, `render.yaml`, `README.md`, `.gitignore`, `docs/`, and `archive/`. Task 2 depends on the name `index.html` being free.

- [ ] **Step 1: Confirm the working tree is clean before moving anything**

```bash
cd "/Users/jcunningham/guitar lesson website" && git status --porcelain
```

Expected: no output at all. If anything is listed, stop and commit or stash it first.

- [ ] **Step 2: Create the archive directory and move the dead Express app**

```bash
cd "/Users/jcunningham/guitar lesson website"
mkdir -p archive
git mv server.js supabase-setup.sql package.json package-lock.json archive/
```

Expected: no output. `git mv` preserves history.

- [ ] **Step 3: Move the unused page variants**

`index.html` must move before Task 2 can rename `index_artistic.html` into that name.

```bash
cd "/Users/jcunningham/guitar lesson website"
git mv index.html index_v2.html instructor-schedule.html questionnaire.html archive/
```

Expected: no output.

- [ ] **Step 4: Move the generated guides and shell scripts**

These describe deploying the Supabase/Redis architecture we are abandoning. Keeping them at the root would actively mislead a future reader.

```bash
cd "/Users/jcunningham/guitar lesson website"
git mv ARTISTIC_GUIDE.md AUTOMATION_GUIDE.md DEPLOYMENT_GUIDE.md GET_TO_GITHUB.md \
       QUICK_START.md SECURITY_AUDIT.md SETUP_INSTRUCTIONS.md TERMINAL_WORKFLOW.md \
       LOCAL_SETUP.sh MASTER_DEPLOY.sh archive/
```

Expected: no output.

- [ ] **Step 5: Remove `node_modules` from disk and stop ignoring a now-absent package.json**

The site has no dependencies. Leave the `.gitignore` entries in place (harmless, and `archive/package.json` still exists), but clear the installed tree.

```bash
cd "/Users/jcunningham/guitar lesson website" && rm -rf node_modules && ls -d node_modules 2>&1
```

Expected: `ls: node_modules: No such file or directory`

- [ ] **Step 6: Verify the root now contains only what we intend**

```bash
cd "/Users/jcunningham/guitar lesson website" && ls -1
```

Expected exactly:
```
archive
docs
index_artistic.html
README.md
render.yaml
```

- [ ] **Step 7: Verify no secrets are staged**

```bash
cd "/Users/jcunningham/guitar lesson website" && git add -A && git diff --cached --name-only | head -30 && git diff --cached -S "cal_live_" --name-only
```

Expected: a list of moved files, and **no output** from the second command.

- [ ] **Step 8: Commit**

```bash
cd "/Users/jcunningham/guitar lesson website"
git commit -m "Archive unused Express app and page variants

The Express server, Supabase schema, and four HTML variants were never
connected to each other. Bookings were written to localStorage, so they
were invisible to the instructor and to other visitors. Moving them to
archive/ rather than deleting, so the work remains recoverable.

Also archives eight generated guides describing the Supabase/Redis
deployment we are no longer pursuing.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

Expected: a commit summary listing renames.

---

### Task 2: Build `index.html` with the themed Cal.com embed

The core of the work. Preserves the page's visual identity while replacing every non-functional booking control with one embed.

**Files:**
- Rename: `index_artistic.html` → `index.html`
- Modify: `index.html` (remove booking machinery, remove the entire `<script>` block, insert embed)

**Interfaces:**
- Consumes: the free `index.html` filename from Task 1
- Produces: `index.html` at the repo root containing an element `#cal-booking-embed`, which Task 3's `render.yaml` publishes and Task 4 verifies.

- [ ] **Step 1: Rename the artistic variant into place**

```bash
cd "/Users/jcunningham/guitar lesson website" && git mv index_artistic.html index.html && ls -1 *.html
```

Expected: `index.html`

- [ ] **Step 2: Record the "before" state so the removal can be verified**

```bash
cd "/Users/jcunningham/guitar lesson website"
echo "lines: $(wc -l < index.html)"
echo "script blocks: $(grep -c '<script' index.html)"
echo "localStorage refs: $(grep -c 'localStorage' index.html)"
```

Expected exactly (measured 2026-08-14):
```
lines: 1712
script blocks: 1
localStorage refs: 8
```

`grep -c` counts matching *lines*, not occurrences. Step 8 asserts these drop to zero.

- [ ] **Step 3: Replace the booking machinery markup**

In `index.html`, find the block that begins with the `<!-- Change Booking Button -->` comment and ends with the closing `</div>` of `<div class="button-group">` (approximately lines 1016–1085). Replace that entire block with:

```html
            <!-- Cal.com booking embed -->
            <div id="cal-booking-embed">
                <noscript>
                    <p class="embed-fallback-text">
                        Booking requires JavaScript. You can book directly at
                        <a href="https://cal.com/jacob-cunningham-geibwx">cal.com/jacob-cunningham-geibwx</a>.
                    </p>
                </noscript>
            </div>

            <p class="embed-fallback">
                Trouble loading the calendar?
                <a href="https://cal.com/jacob-cunningham-geibwx">Book directly here</a>.
            </p>
```

Leave the surrounding `<div class="booking-section">`, the `<h2 class="section-title">Book Your Lesson</h2>`, and the closing `</div>` tags untouched.

- [ ] **Step 4: Remove the three now-orphaned modals**

Delete the entire `<div class="change-booking-modal" id="changeBookingModal">` block, the `<div class="modal" id="confirmationModal">` block, and the `<div class="booking-limit-modal" id="bookingLimitModal">` block, including all of their contents. Cal.com handles rescheduling through links in its confirmation email, so the reschedule modal has nothing to do.

- [ ] **Step 5: Remove the entire script block**

Delete everything from the opening `<script>` tag through its matching `</script>`, inclusive. All ~496 lines of it are `localStorage` booking logic that the embed replaces.

- [ ] **Step 6: Add fallback styling before the closing `</style>` tag**

Insert immediately before `</style>`, matching the existing palette:

```css
        #cal-booking-embed {
            min-height: 600px;
            width: 100%;
            overflow: hidden;
            border-radius: 8px;
        }

        .embed-fallback {
            text-align: center;
            margin-top: 1.5rem;
            font-family: 'Outfit', sans-serif;
            font-size: 0.9rem;
            color: var(--primary);
            opacity: 0.75;
        }

        .embed-fallback a,
        .embed-fallback-text a {
            color: var(--accent);
            font-weight: 600;
        }

        .embed-fallback-text {
            text-align: center;
            padding: 2rem;
            font-family: 'Outfit', sans-serif;
            color: var(--primary);
        }

        @media (max-width: 600px) {
            #cal-booking-embed { min-height: 500px; }
        }
```

- [ ] **Step 7: Add the Cal.com embed script before `</body>`**

Insert immediately before the closing `</body>` tag. The `cssVarsPerTheme` block is what themes the booker to the site's palette; it works on the free plan.

```html
    <script>
      (function (C, A, L) {
        let p = function (a, ar) { a.q.push(ar); };
        let d = C.document;
        C.Cal = C.Cal || function () {
          let cal = C.Cal; let ar = arguments;
          if (!cal.loaded) {
            cal.ns = {}; cal.q = cal.q || [];
            d.head.appendChild(d.createElement("script")).src = A;
            cal.loaded = true;
          }
          if (ar[0] === L) {
            const api = function () { p(api, arguments); };
            const namespace = ar[1];
            api.q = api.q || [];
            if (typeof namespace === "string") {
              cal.ns[namespace] = cal.ns[namespace] || api;
              p(cal.ns[namespace], ar);
              p(cal, ["initNamespace", namespace]);
            } else { p(cal, ar); }
            return;
          }
          p(cal, ar);
        };
      })(window, "https://app.cal.com/embed/embed.js", "init");

      Cal("init", "lessons", { origin: "https://cal.com" });

      Cal.ns.lessons("inline", {
        elementOrSelector: "#cal-booking-embed",
        config: { layout: "month_view" },
        calLink: "jacob-cunningham-geibwx"
      });

      Cal.ns.lessons("ui", {
        layout: "month_view",
        cssVarsPerTheme: {
          light: {
            "cal-brand": "#1a1a2e",
            "cal-bg": "#f5f1e8",
            "cal-bg-emphasis": "#e8e0d0",
            "cal-text": "#1a1a2e",
            "cal-text-emphasis": "#0f0f1e",
            "cal-border": "#d4a574",
            "cal-border-emphasis": "#b8860b"
          },
          dark: {
            "cal-brand": "#d4a574",
            "cal-bg": "#1a1a2e",
            "cal-text": "#f5f1e8"
          }
        }
      });
    </script>
```

- [ ] **Step 8: Verify the removals actually happened**

```bash
cd "/Users/jcunningham/guitar lesson website"
echo "localStorage refs: $(grep -c 'localStorage' index.html)"
echo "orphan ids: $(grep -c 'calendarGrid\|timeGrid\|changeBookingModal\|confirmationModal\|bookingLimitModal' index.html)"
echo "embed present: $(grep -c 'cal-booking-embed' index.html)"
echo "calLink present: $(grep -c 'jacob-cunningham-geibwx' index.html)"
```

Expected exactly (these are line counts, not occurrence counts — `cal-booking-embed`
appears on 4 lines: the div, two CSS selectors, and `elementOrSelector`):
```
localStorage refs: 0
orphan ids: 0
embed present: 4
calLink present: 3
```

If `localStorage refs` or `orphan ids` is non-zero, dead code remains — go back to Steps 3–5.

- [ ] **Step 9: Confirm no secrets were introduced**

```bash
cd "/Users/jcunningham/guitar lesson website" && grep -cE "cal_live_|cal_test_|api[_-]?key|Bearer |password" index.html
```

Expected: `0`

- [ ] **Step 10: Serve the page and verify it loads**

```bash
cd "/Users/jcunningham/guitar lesson website"
(python3 -m http.server 8899 >/dev/null 2>&1 &) ; sleep 2
curl -s -o /dev/null -w "index.html -> HTTP %{http_code}\n" http://localhost:8899/index.html
```

Expected: `index.html -> HTTP 200`

- [ ] **Step 11: Verify the embed actually renders in a real browser**

Open `http://localhost:8899/index.html` in the browser tool, wait 5 seconds for the embed to load, then evaluate:

```js
JSON.stringify({
  container: !!document.querySelector('#cal-booking-embed'),
  iframe: document.querySelectorAll('#cal-booking-embed iframe').length,
  height: document.querySelector('#cal-booking-embed')?.getBoundingClientRect().height,
  headerIntact: document.querySelector('header h1')?.textContent.trim()
})
```

Expected: `container: true`, `iframe: 1`, `height` greater than 400, `headerIntact: "JACOB CUNNINGHAM"`.

If `iframe` is 0, the embed failed to initialize — check the browser console for errors before continuing. **Do not proceed on a failed embed.**

- [ ] **Step 12: Verify no console errors**

Read console messages with `onlyErrors: true`.

Expected: no errors. Cal.com may log informational messages; those are fine.

- [ ] **Step 13: Verify mobile rendering at 375px**

Resize the browser to the `mobile` preset, reload, and evaluate:

```js
JSON.stringify({
  bodyScrollWidth: document.body.scrollWidth,
  windowWidth: window.innerWidth,
  overflows: document.body.scrollWidth > window.innerWidth + 1
})
```

Expected: `overflows: false`. Horizontal scroll on mobile is a defect — fix the embed container width before continuing.

- [ ] **Step 14: Verify the no-JavaScript fallback (spec §7 item 8)**

The `<noscript>` block is invisible in a normal browser, so it must be checked in the source rather than the DOM. A visitor with JS disabled must still get a working path to book.

```bash
cd "/Users/jcunningham/guitar lesson website"
python3 -c "
import re
html = open('index.html').read()
m = re.search(r'<noscript>(.*?)</noscript>', html, re.S)
assert m, 'FAIL: no <noscript> block found'
body = m.group(1)
assert 'cal.com/jacob-cunningham-geibwx' in body, 'FAIL: noscript has no booking link'
assert '<a ' in body, 'FAIL: noscript link is not clickable'
print('OK: noscript fallback present with a working booking link')
"
```

Expected: `OK: noscript fallback present with a working booking link`

- [ ] **Step 15: Stop the local server**

```bash
pkill -f "http.server 8899" ; echo stopped
```

Expected: `stopped`

- [ ] **Step 16: Commit**

```bash
cd "/Users/jcunningham/guitar lesson website"
git add index.html
git commit -m "Replace localStorage booking UI with themed Cal.com embed

index_artistic.html becomes index.html, keeping its CSS and header
unchanged. The custom calendar, time grid, learner forms, and three
modals are replaced by a single Cal.com inline embed themed to the
site palette via cssVarsPerTheme.

This removes the double-booking race, the 24h slot-lock expiry, the
spoofable device-fingerprint reschedule check, and the complete absence
of timezone handling, by delegating all of it to Cal.com.

Verified: embed renders an iframe, no console errors, no horizontal
overflow at 375px.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 3: Convert `render.yaml` to a static site and rewrite the README

**Files:**
- Modify: `render.yaml` (full rewrite)
- Modify: `README.md` (full rewrite)

**Interfaces:**
- Consumes: `index.html` at the repo root from Task 2
- Produces: a Render static site definition publishing the repo root. Task 4 verifies the deployed result.

- [ ] **Step 1: Rewrite `render.yaml`**

Replace the entire file with:

```yaml
services:
  - type: web
    name: guitar-lessons
    runtime: static
    branch: main
    buildCommand: ""
    staticPublishPath: .
    pullRequestPreviewsEnabled: false
    headers:
      - path: /*
        name: X-Frame-Options
        value: SAMEORIGIN
      - path: /*
        name: X-Content-Type-Options
        value: nosniff
      - path: /*
        name: Referrer-Policy
        value: strict-origin-when-cross-origin
    routes:
      - type: rewrite
        source: /*
        destination: /index.html
```

There are no `envVars`: the site has no secrets and nothing to configure. That is the point.

- [ ] **Step 2: Verify the YAML parses and has no invalid top-level keys**

```bash
cd "/Users/jcunningham/guitar lesson website" && python3 -c "
import re
s = open('render.yaml').read()
top = re.findall(r'^([a-zA-Z_]+):', s, re.M)
valid = {'services','databases','envVarGroups','previews','version'}
print('top-level keys:', top)
bad = [k for k in top if k not in valid]
print('invalid:', bad if bad else 'none')
assert not bad, f'invalid top-level keys: {bad}'
print('OK')
"
```

Expected:
```
top-level keys: ['services']
invalid: none
OK
```

- [ ] **Step 3: Rewrite `README.md`**

Replace the entire file with:

```markdown
# Guitar Lessons — Jacob Cunningham

A static booking site. Availability and booking are handled by
[Cal.com](https://cal.com/jacob-cunningham-geibwx); this repo contains
the public page that embeds it.

## Architecture

    Visitor -> Render Static Site (CDN) -> Cal.com embed -> Google Calendar

There is no server, no database, and no stored student data. The page is
a single HTML file with inline CSS and one embed script.

## Files

| Path | Purpose |
|---|---|
| `index.html` | The entire site: styles, header, and the Cal.com embed |
| `render.yaml` | Render static site definition |
| `docs/superpowers/specs/` | Design decisions and the reasoning behind them |
| `docs/superpowers/plans/` | Implementation plan |
| `archive/` | The previous Express + Supabase attempt, kept for reference |

## Local development

    python3 -m http.server 8899
    # then open http://localhost:8899/index.html

No build step and no dependencies to install.

## Changing availability, prices, or lesson types

All of it lives in Cal.com, not in this repo. Sign in at cal.com and edit
the event types. Changes are live immediately with no deploy.

## Deploying

Pushing to `main` triggers an automatic deploy on Render.

## Cost

$0/month. Render static sites are free; the Cal.com individual plan is free.
```

- [ ] **Step 4: Verify the README makes no false claims about the repo**

```bash
cd "/Users/jcunningham/guitar lesson website"
test -f index.html && echo "index.html: exists"
test -f render.yaml && echo "render.yaml: exists"
test -d archive && echo "archive/: exists"
test -d docs/superpowers/specs && echo "specs/: exists"
grep -c "server.js\|supabase\|SUPABASE" README.md
```

Expected: three `exists` lines, then `0`.

- [ ] **Step 5: Commit and push**

```bash
cd "/Users/jcunningham/guitar lesson website"
git add render.yaml README.md
git commit -m "Convert render.yaml to a static site and rewrite README

The site no longer needs a Node runtime, a database, or any environment
variables. Static sites are free on Render and are CDN-served with no
spin-down, replacing the \$7/mo starter web service.

Adds baseline security headers. README now describes what the repo
actually contains.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
git push origin main
```

Expected: push succeeds.

---

### Task 4: Verify the deployed site end to end

The previous deploy served `/` as a 404. This task proves that is fixed and that a real booking works.

**Files:** none modified — this task is verification only.

**Interfaces:**
- Consumes: the pushed repo from Task 3
- Produces: a confirmed-working public booking site

- [ ] **Step 1: Hand off the Render service-type change**

The Render service is currently a **Web Service**; it must become a **Static Site**. Changing service type requires the dashboard and cannot be scripted.

Tell the user, in these words:

> In Render, delete the existing `guitar-lesson-api` web service and create a new **Static Site** from the `guitar-lessons` repo. Publish directory: `.` — leave the build command empty. This also removes the $7/mo charge.

Wait for confirmation and the deployed URL before continuing.

- [ ] **Step 2: Verify the deployed root returns 200, not 404**

Substitute the real URL:

```bash
curl -s -o /dev/null -w "/ -> HTTP %{http_code}\n" https://YOUR-SITE.onrender.com/
```

Expected: `/ -> HTTP 200`

This is the single most important check in the plan. The old deploy returned 404 here.

- [ ] **Step 3: Verify the page served is the right one**

```bash
curl -s https://YOUR-SITE.onrender.com/ | grep -c "JACOB CUNNINGHAM\|cal-booking-embed"
```

Expected: `2`

- [ ] **Step 4: Verify no secrets are being served**

```bash
curl -s https://YOUR-SITE.onrender.com/ | grep -cE "cal_live_|api[_-]?key|Bearer |SUPABASE"
```

Expected: `0`

- [ ] **Step 5: Verify the embed renders on the live site**

Open the deployed URL in the browser tool, wait 5 seconds, then evaluate:

```js
JSON.stringify({
  iframes: document.querySelectorAll('#cal-booking-embed iframe').length,
  height: document.querySelector('#cal-booking-embed')?.getBoundingClientRect().height
})
```

Expected: `iframes: 1`, `height` greater than 400.

- [ ] **Step 6: Make a real end-to-end test booking**

Ask the user to book a real slot from a private/incognito window using an email address they control, then confirm all four of the following actually happened:

1. The booking page accepted the slot
2. A confirmation email arrived
3. The lesson appears on the connected Google Calendar
4. That slot no longer appears as available on the public page

Report which of the four succeeded. **Do not report success unless all four did.**

- [ ] **Step 7: Verify the double-booking fix**

Re-query the slots API for the day of the test booking:

```bash
curl -s -H "cal-api-version: 2024-09-04" \
  "https://api.cal.com/v2/slots?eventTypeSlug=1-hour-lesson&username=jacob-cunningham-geibwx&start=BOOKED_DATE&end=BOOKED_DATE&timeZone=America/Chicago"
```

Expected: the booked time is **absent** from the returned slots. This is the concrete proof that the double-booking race in the old code is gone.

- [ ] **Step 8: Verify timezone handling**

Query the same day in a different timezone:

```bash
curl -s -H "cal-api-version: 2024-09-04" \
  "https://api.cal.com/v2/slots?eventTypeSlug=1-hour-lesson&username=jacob-cunningham-geibwx&start=2026-08-17&end=2026-08-18&timeZone=America/New_York" | head -c 300
```

Expected: the same absolute times, rendered with a `-04:00` offset instead of `-05:00`. This proves a student booking from another timezone gets the correct real-world time — something the old code could not do at all.

- [ ] **Step 9: Verify the reschedule link works (spec §7 item 6)**

This replaces the "Already Booked? Change Your Booking" modal that Task 2 removed, so it must be confirmed working rather than assumed.

Ask the user to open the confirmation email from Step 6, click **Reschedule**, and move the test booking to a different time. Then confirm both halves actually happened:

```bash
# The ORIGINAL time should be available again
curl -s -H "cal-api-version: 2024-09-04" \
  "https://api.cal.com/v2/slots?eventTypeSlug=1-hour-lesson&username=jacob-cunningham-geibwx&start=ORIGINAL_DATE&end=ORIGINAL_DATE&timeZone=America/Chicago" | grep -c "ORIGINAL_TIME"

# The NEW time should now be taken
curl -s -H "cal-api-version: 2024-09-04" \
  "https://api.cal.com/v2/slots?eventTypeSlug=1-hour-lesson&username=jacob-cunningham-geibwx&start=NEW_DATE&end=NEW_DATE&timeZone=America/Chicago" | grep -c "NEW_TIME"
```

Expected: `1` from the first command (original slot freed), `0` from the second (new slot taken).

If the original slot is *not* freed, rescheduling is leaking availability — report it rather than proceeding.

- [ ] **Step 10: Clean up the test booking**

Ask the user to cancel the test booking via the link in the confirmation email, then confirm the slot returns to the availability API.

```bash
curl -s -H "cal-api-version: 2024-09-04" \
  "https://api.cal.com/v2/slots?eventTypeSlug=1-hour-lesson&username=jacob-cunningham-geibwx&start=BOOKED_DATE&end=BOOKED_DATE&timeZone=America/Chicago"
```

Expected: the previously booked time is present again.

---

## Definition of done

- [ ] Deployed URL returns HTTP 200 at `/` (previously 404)
- [ ] The Cal.com embed renders and shows real availability
- [ ] A real test booking produced a confirmation email and a calendar entry
- [ ] The booked slot disappeared from public availability, then returned after cancellation
- [ ] Rescheduling from the confirmation email freed the original slot and took the new one
- [ ] The same slot reports correct times in a second timezone
- [ ] The `<noscript>` fallback offers a working booking link
- [ ] No secrets in the repo or in the served HTML
- [ ] No horizontal scroll at 375px
- [ ] Render bill is $0/month

## Deliberately not in this plan

Tracked in the spec, sections 9 and 10:

- **Payments.** Deferred by decision; enable in Cal.com later without touching the site.
- **The custom calendar grid fed by the public slots API.** ~150 lines resting on an endpoint with open bug reports, versus ~15 that essentially cannot break.
- **Bio, photos, lesson descriptions.** The likeliest cause of lost bookings, deferred to keep the look unchanged. Recommended as the first post-launch work.
- **Cal.com account configuration** — setting the location to **Cal Video** on both event types (a launch blocker: without it, a booking tells the student nothing about how to attend), widening the weekday-only 08:00–16:00 availability, and pricing the 30-minute lesson. These require account access and are the user's to do. Lessons are **online only** as of 2026-08-14.
