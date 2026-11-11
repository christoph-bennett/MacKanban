# 23: Installing leaves sample Boards alone

**What to build:** The install script replaces only the installed MacKanban. Today it quits every running MacKanban, including copies started from the build folder on a sample Board. A sample copy with a sheet open doesn't quit, so the script gives up after 10 seconds, after the real MacKanban has already quit, and nothing restarts it. Found on 2026-11-11 while taking the README screenshots; a follow-up from the ponytail review of that day. Developer tooling only, no change for users of the app.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] With a sample-Board copy from the build folder running (a sheet open), installing quits and restarts only the installed MacKanban, and the sample copy keeps running
- [x] Without any other copy running, installing works as before
- [x] Waiting for the old copy to quit and for the new one to start looks only at the installed MacKanban

**Notes from implementing:**
- The script now quits, waits for and checks only the MacKanban it installs, matched by the installed app's path. A copy started from the build folder is left alone; a sample copy started from the installed app is still quit with it, as before.
- Checked 2026-11-11: with a build-folder copy running and its alert open, installing restarted only the installed MacKanban and the other copy kept running.
