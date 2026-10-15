# Jayden Calendar

Jayden's personal **hub** (Asia/Hong_Kong) — Home, Calendar, Debts, Video Editing.

- Header: **Welcome Jayden** / **Home**
- Tabs: Home · Calendar · Debts · Video Editing (`?tab=`)
- Debts from `debts.json` (interest countdown)
- Calendar module keeps week tabs, timetable, school work bots
- Days left → right as **collapsible tabs** (tap to open/close)
- Today starts **open**; other days start **closed**
- Empty days still appear
- School/Toddle events with a `url` open Toddle when tapped

## Stable URL (same site forever)

Do **not** use Netlify Drop for updates.

1. One-time: log in with GitHub CLI on this machine (`gh auth login`), then run:

```bash
cd /workspace/jayden-calendar
./deploy.sh
```

2. That creates/publishes `jaydenng0807/calander` on **GitHub Pages**.
3. Live URL (after Pages builds): **https://jaydenng0807.github.io/calander/**
4. The script writes the URL into `deploy.config` / `SITE_URL.txt`.

Every later redeploy uses **that same URL**.

### Weekly update

```bash
# 1) Edit events only
nano events.json

# 2) If you use file:// offline, also refresh EMBEDDED inside index.html

# 3) Publish to the SAME URL
./deploy.sh
```

Optional Netlify path: set `METHOD=netlify` in `deploy.config` and log in with `netlify login`, then `./deploy.sh`.

## Event fields (`events.json`)

| Field | Meaning |
|-------|---------|
| `date` | `YYYY-MM-DD` (HKT calendar day) |
| `title` | Plain English name |
| `time` | `HH:MM` 24h (optional if `allDay`) |
| `allDay` | true/false |
| `due` | shows Due tag |
| `color` | `blue` or `purple` |
| `type` | `school` or `personal` |
| `url` / `toddleUrl` | optional — if set, tap opens that link (Toddle) |

Toddle todos base: `https://web.toddleapp.com/platform/391418444458869835/todos`

## Video editing jobs (`video-status.json`)

The Video Editing tab keeps clip files in this browser (IndexedDB) and job details in `localStorage`. **Go** downloads `video-job-<id>.zip` (clips named `01-…`, `02-…`, plus `prompt.txt`) and posts a start signal to the same ntfy topic as School work (`school-bot-config.json`).

Starter file:

```json
{ "updated": "2026-10-15T17:40:00+08:00", "jobs": {} }
```

When a job is running or finished, Calander / the video editor writes one entry under `jobs`, keyed by the job id from the start signal:

| Field | Meaning |
|-------|---------|
| `working` | `true` while the edit is in progress |
| `done` | `true` when the finished video is ready |
| `resultPath` | site-relative file, e.g. `videos/<jobId>.mp4` |
| `resultUrl` | full URL, if the file is not a relative path |
| `error` | plain text when the job failed |

Example while working:

```json
{
  "updated": "2026-10-15T18:00:00+08:00",
  "jobs": {
    "vjobid": { "working": true, "done": false, "resultPath": "", "resultUrl": "", "error": "" }
  }
}
```

Example when finished (the page shows a player and a Download button):

```json
{
  "updated": "2026-10-15T18:10:00+08:00",
  "jobs": {
    "vjobid": { "working": false, "done": true, "resultPath": "videos/vjobid.mp4", "resultUrl": "", "error": "" }
  }
}
```

Example when it failed:

```json
{
  "updated": "2026-10-15T18:10:00+08:00",
  "jobs": {
    "vjobid": { "working": false, "done": false, "resultPath": "", "resultUrl": "", "error": "Could not stitch the clips" }
  }
}
```

The page polls `video-status.json` about every 8 seconds while that tab is open, or while a job is still queued or working. `done: true` wins over `working`. A non-empty `error` with `done` not true shows as failed.

## Local preview

```bash
cd /workspace/jayden-calendar
python3 -m http.server 8765
# open http://127.0.0.1:8765
```

Also copied to Windows `Downloads/jayden-calendar/` when available.
