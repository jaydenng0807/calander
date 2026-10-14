# Jayden Calendar (Calander)

Premium dark **week** calendar for Jayden (Asia/Hong_Kong).

- Header: **Welcome Jayden** / **Calander**
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

## Local preview

```bash
cd /workspace/jayden-calendar
python3 -m http.server 8765
# open http://127.0.0.1:8765
```

Also copied to Windows `Downloads/jayden-calendar/` when available.
