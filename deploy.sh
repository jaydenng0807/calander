#!/usr/bin/env bash
# Always republish THIS calendar folder to the SAME stable URL.
# Weekly update flow: edit events.json (and EMBEDDED in index.html if needed), then:
#   ./deploy.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"
CONFIG="$ROOT/deploy.config"
# shellcheck disable=SC1090
source "$CONFIG" 2>/dev/null || true

METHOD="${METHOD:-github-pages}"
OWNER="${GITHUB_OWNER:-jaydenng0807}"
REPO="${GITHUB_REPO:-calander}"
BRANCH="${GITHUB_BRANCH:-main}"

sync_embedded() {
  # Keep offline EMBEDDED roughly in sync by noting events.json mtime
  echo "→ events.json updated: $(python3 -c "import json;print(json.load(open('events.json')).get('updated',''))")"
}

write_site_url() {
  local url="$1"
  if grep -q '^SITE_URL=' "$CONFIG" 2>/dev/null; then
    sed -i "s|^SITE_URL=.*|SITE_URL=$url|" "$CONFIG"
  else
    echo "SITE_URL=$url" >> "$CONFIG"
  fi
  echo "$url" > "$ROOT/SITE_URL.txt"
  echo "✓ Stable URL: $url"
}

deploy_github_pages() {
  if ! command -v gh >/dev/null; then
    echo "ERROR: gh CLI missing" >&2
    return 1
  fi
  if ! gh auth status >/dev/null 2>&1; then
    echo "BLOCKER: gh not logged in. Run: gh auth login" >&2
    echo "Then re-run ./deploy.sh — it will create/push $OWNER/$REPO and enable Pages." >&2
    return 2
  fi

  if ! gh repo view "$OWNER/$REPO" >/dev/null 2>&1; then
    echo "→ Creating public repo $OWNER/$REPO"
    gh repo create "$OWNER/$REPO" --public --description "Jayden Calander — stable week calendar" --source=. --remote=origin --push || {
      # repo may exist empty; init push path
      git init
      git checkout -B "$BRANCH"
      git add index.html events.json timetable.json school-status.json school-bot-config.json manifest.webmanifest sw.js README.md calendar-standalone.html deploy.sh deploy.config
      git -c user.email="calander@local" -c user.name="Calander" commit -m "Initial Calander site" || true
      gh repo create "$OWNER/$REPO" --public --source=. --remote=origin --push
    }
  fi

  if [ ! -d .git ]; then
    git init
    git checkout -B "$BRANCH"
    git remote remove origin 2>/dev/null || true
    git remote add origin "https://github.com/$OWNER/$REPO.git"
  fi

  # Only publish site files (not previews / netlify drop screenshots)
  git add -A
  git reset HEAD -- preview.png preview-mobile.png live-unlocked.png netlify-drop-done.png 2>/dev/null || true
  git add index.html events.json timetable.json school-status.json school-bot-config.json manifest.webmanifest sw.js README.md calendar-standalone.html deploy.sh deploy.config SITE_URL.txt 2>/dev/null || true
  git -c user.email="calander@local" -c user.name="Calander" commit -m "Update Calander $(date -Iseconds)" || echo "(no new commit)"
  git push -u origin "$BRANCH"

  # Enable GitHub Pages from / (root) on main
  gh api -X POST "repos/$OWNER/$REPO/pages" \
    -f "build_type=legacy" \
    -f "source[branch]=$BRANCH" \
    -f "source[path]=/" 2>/dev/null \
    || gh api -X PUT "repos/$OWNER/$REPO/pages" \
         -f "build_type=legacy" \
         -f "source[branch]=$BRANCH" \
         -f "source[path]=/" 2>/dev/null \
    || true

  local url="https://${OWNER}.github.io/${REPO}/"
  write_site_url "$url"
}

deploy_netlify() {
  if [ -n "${NETLIFY_AUTH_TOKEN:-}" ] || netlify status >/dev/null 2>&1; then
    if [ -n "${NETLIFY_SITE_ID:-}" ]; then
      netlify deploy --prod --dir="$ROOT" --site="$NETLIFY_SITE_ID"
    elif [ -f "$ROOT/.netlify/state.json" ]; then
      netlify deploy --prod --dir="$ROOT"
    else
      echo "→ First Netlify link: creating site 'jayden-calander'"
      netlify sites:create --name jayden-calander || true
      netlify link --name jayden-calander || netlify init
      netlify deploy --prod --dir="$ROOT"
    fi
    local url
    url="$(netlify status --json 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('siteData',d).get('url','') or d.get('site',{}).get('url',''))" 2>/dev/null || true)"
    if [ -n "$url" ]; then write_site_url "$url"; fi
  else
    echo "BLOCKER: Netlify not logged in. Prefer GitHub Pages (METHOD=github-pages)." >&2
    return 2
  fi
}

sync_embedded

case "$METHOD" in
  github-pages) deploy_github_pages ;;
  netlify) deploy_netlify ;;
  *) echo "Unknown METHOD=$METHOD" >&2; exit 1 ;;
esac

echo "Done. Weekly updates: edit events.json → ./deploy.sh (same URL)."
