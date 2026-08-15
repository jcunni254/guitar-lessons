# Guitar Lessons — Jacob Cunningham

A static booking site. Availability and booking are handled by
[Cal.com](https://cal.com/jacob-cunningham-geibwx); this repo contains
the public page that embeds it.

Lessons are **online only**, over Cal Video.

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
