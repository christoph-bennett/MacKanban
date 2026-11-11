#!/bin/sh
# Replaces ~/Applications/MacKanban.app with build/MacKanban.app (from scripts/bundle.sh)
# and starts it. Waits for the running MacKanban to quit first, then retries
# starting it: for a moment after the old process has exited, `open` can fail with
# error -600 (procNotFound), and nothing that can be queried shows when that
# moment is over (found in MacJot, its ticket 27).
set -e
cd "$(dirname "$0")/.."
[ -d build/MacKanban.app ] || { echo "No build/MacKanban.app: run scripts/bundle.sh first." >&2; exit 1; }
# Only the installed copy: one started from build/ on a sample Board keeps running.
INSTALLED="$HOME/Applications/MacKanban.app/Contents/MacOS/MacKanban"
if pkill -f "$INSTALLED"; then  # MacKanban quits normally on SIGTERM
  tries=0
  while pgrep -f "$INSTALLED" >/dev/null; do
    tries=$((tries + 1))
    if [ "$tries" -gt 100 ]; then
      echo "MacKanban hasn't quit after 10 seconds (an alert open?). Quit it, then run this again." >&2
      exit 1
    fi
    sleep 0.1
  done
fi
# Not every Mac has it. `.localized` lets Finder show it in the user's language,
# as with the folder macOS creates ("Programme" in German).
if [ ! -d ~/Applications ]; then
  mkdir ~/Applications
  touch ~/Applications/.localized
fi
rm -rf ~/Applications/MacKanban.app
cp -R build/MacKanban.app ~/Applications/
tries=0
until open ~/Applications/MacKanban.app 2>/dev/null; do
  tries=$((tries + 1))
  if [ "$tries" -ge 10 ]; then
    echo "Installed, but MacKanban didn't start after 5 seconds: open ~/Applications/MacKanban.app yourself." >&2
    exit 1
  fi
  sleep 0.5
done
tries=0
until pgrep -f "$INSTALLED" >/dev/null; do
  tries=$((tries + 1))
  if [ "$tries" -ge 50 ]; then
    echo "Installed, but MacKanban isn't running 5 seconds after opening it." >&2
    exit 1
  fi
  sleep 0.1
done
echo "Installed and started ~/Applications/MacKanban.app"
