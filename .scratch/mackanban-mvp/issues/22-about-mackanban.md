# 22: About MacKanban

**What to build:** "About MacKanban" in two places, opening the standard About panel, modelled on NSURLSessionMenu's. Requested 2026-11-11. A follow-up to story 38 of spec 0001 (the menu bar extra's menu).

- **Menu bar extra's menu:** the last item before the separator and Quit, right under Settings…, since it's the least important item. The menu reads: New Card…, Open Board, Open Archive, Settings…, About MacKanban, separator, Quit MacKanban.
- **App menu:** the first item, followed by a separator, as on every Mac app (HIG).

The panel shows the app icon, the name, the version (0.1.0) with the build number counting the commits, as NSURLSessionMenu does; then "Copyright © 2026 Christoph Bennett. MIT License." and the credits line "More from me on GitHub: github.com/christoph-bennett", a link. MacKanban gets an MIT licence file in the repo to match. The panel comes to the front even with the Dock icon off and another app in use.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] The menu bar extra's menu shows About MacKanban between Settings… and the separator before Quit
- [ ] The app menu shows About MacKanban first, with a separator under it
- [ ] Both open the standard About panel with icon, name, version and build number, copyright line and the GitHub link; the link opens the profile in the browser
- [ ] The panel comes to the front from the menu bar extra with the Dock icon on and off, while another app is in front
- [ ] The repo has an MIT licence file in Christoph's name
- [ ] Light and dark look right (screenshots on a sample store)
- [ ] Spec 0001 gets a dated note under story 38
- [ ] Checked by hand by Christoph
