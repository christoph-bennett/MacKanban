# 22: About MacKanban

**What to build:** "About MacKanban" in two places, opening the standard About panel, modelled on NSURLSessionMenu's. Requested 2026-11-11. A follow-up to story 38 of spec 0001 (the menu bar extra's menu).

- **Menu bar extra's menu:** the last item before the separator and Quit, right under Settings…, since it's the least important item. The menu reads: New Card…, Open Board, Open Archive, Settings…, About MacKanban, separator, Quit MacKanban.
- **App menu:** the first item, followed by a separator, as on every Mac app (HIG).

The panel shows the app icon, the name, the version (0.1.0) with the build number counting the commits, as NSURLSessionMenu does; then "Copyright © 2026 Christoph Bennett. MIT License." and the credits line "More from me on GitHub: github.com/christoph-bennett", a link. MacKanban gets an MIT licence file in the repo to match. The panel comes to the front even with the Dock icon off and another app in use.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] The menu bar extra's menu shows About MacKanban between Settings… and the separator before Quit
- [x] The app menu shows About MacKanban first, with a separator under it
- [x] Both open the standard About panel with icon, name, version and build number, copyright line and the GitHub link; the link opens the profile in the browser
- [x] The panel comes to the front from the menu bar extra with the Dock icon on and off, while another app is in front
- [x] The repo has an MIT licence file in Christoph's name
- [x] Light and dark look right (screenshots on a sample store)
- [x] Spec 0001 gets a dated note under story 38
- [x] Checked by hand by Christoph

**Notes from implementing:**
- The standard About panel, as in NSURLSessionMenu: copyright from Info.plist, the GitHub link from a credits file, the build number set to the commit count when bundling. The licence file and credits file are copied from NSURLSessionMenu.
- MacKanban activates before opening the panel, so it comes to the front even without the Dock icon.
- No Board tests: nothing in the Board changed. 148 tests pass; a low-effort code review found nothing.
- Checked 2026-11-11 on a sample store (panel screenshot: "Version 0.1.0 (146)", link, copyright).
- Checked by hand by Christoph on 2026-11-11.
