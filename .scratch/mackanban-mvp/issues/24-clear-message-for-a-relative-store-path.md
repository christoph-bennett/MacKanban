# 24: A clear message for a relative sample-store path

**What to build:** When MacKanban is started with a sample store given as a relative path, it refuses it, as before, but its alert now says why: the path must be absolute, and which path it got. Today the alert shows an unrelated file-system error ("You can't save the file … because the volume is read only") and the reason only reaches the log. Seen on 2026-11-11; a follow-up from the ponytail review of that day. Only affects trying things on sample stores; the real Board is unchanged.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] Started with a relative store path, MacKanban shows "MacKanban can't open its Board." with a text that says the path must be absolute and names the path it got, then quits as before
- [x] An absolute path or a path starting with ~ opens the sample store as before
- [x] Other store errors show the same alert text as before

**Notes from implementing:**
- The alert's text names the refused path; the log line that used to carry it is gone. The relative path is still refused the same way.
- Checked 2026-11-11 on a copy from the build folder: a relative path shows "MACKANBAN_STORE must be an absolute path, got relative.sqlite."; an absolute path and one starting with ~ open their sample Boards. 148 tests pass.
