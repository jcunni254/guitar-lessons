# Guitar Lessons — Jacob Cunningham

A static booking site. Availability and booking are handled by
[Cal.com](https://cal.com/jacob-cunningham-geibwx); this repo contains
the public page that embeds it.

Lessons are **online only**, over Cal Video.

## Architecture

    Visitor -> GitHub Pages (CDN) -> Cal.com embed -> Google Calendar

There is no server, no database, and no stored student data. The page is
a single HTML file with inline CSS and one embed script.

## Files

| Path | Purpose |
|---|---|
| `index.html` | The entire site: styles, header, and the Cal.com embed |
| `.github/workflows/pages.yml` | Publishes `index.html` to GitHub Pages on every push to `main` |
| `tools/csp-hash.py` | Keeps the CSP script hash in sync with the inline script |
| `docs/superpowers/specs/` | Design decisions and the reasoning behind them |
| `docs/superpowers/plans/` | Implementation plan |
| `archive/` | The previous Express + Supabase attempt, kept for reference |

## Local development

    python3 -m http.server 8899
    # then open http://localhost:8899/index.html

No build step and no dependencies to install.

## Security notes

GitHub Pages cannot set response headers, so the Content Security Policy
lives in a `<meta>` tag in `index.html`. It allows exactly one inline
script (pinned by SHA-256 hash), scripts and frames from `app.cal.com`,
and fonts from Google; everything else is denied.

**If you edit the inline `<script>` in `index.html`, run:**

    python3 tools/csp-hash.py --write

Without that the browser blocks the script and the calendar never loads.
CI runs `--check` and fails the deploy if the hash is stale, so this
cannot reach production unnoticed.

`frame-ancestors` is not enforceable from a meta tag, so the page cannot
stop others from embedding it. Nothing sensitive is entered on this page
— the booking form is inside Cal.com's own iframe — so the impact is
cosmetic.

## Changing availability, prices, or lesson types

All of it lives in Cal.com, not in this repo. Sign in at cal.com and edit
the event types. Changes are live immediately with no deploy.

## Deploying

Pushing to `main` triggers the GitHub Pages workflow, which publishes
**only `index.html`** (a copy is also written as `404.html`, so any path
serves the site). `archive/` and `docs/` stay in the repo and are never
served.

Live at <https://jcunni254.github.io/guitar-lessons/>.

Actions in the workflow are pinned to full commit SHAs with the release
they correspond to in a trailing comment. A tag can be repointed at
different code; a SHA cannot. Update them deliberately, never automatically.

Note: GitHub's Pages limits page says Pages "is not intended for or allowed
to be used as a free web-hosting service to run your online business,
e-commerce site, or any other website that is primarily directed at either
facilitating commercial transactions." This site takes no payments and
stores no customer data, but it is the booking front door for paid lessons,
so it sits in a grey area. Cloudflare Pages and Netlify permit commercial
use on their free tiers if this ever needs to move.

## Cost

$0/month. GitHub Pages is free for public repositories; the Cal.com
individual plan is free.
