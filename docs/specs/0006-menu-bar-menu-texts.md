# Spec 0006 — Clearer texts in the menu bar extra's menu

Status: ready-for-agent

Vocabulary follows [GLOSSARY.md](../../GLOSSARY.md) (Capacity, Urgency, Open Card, Doing, Done). It changes two texts from [spec 0001](./0001-mvp.md), story 38, and leaves [ADR 0001](../adr/0001-capacity-and-urgency-rules.md) untouched: the Capacity gauge on the Board still explains where Capacity went. Written on 2026-11-08 from Christoph's request, and checked against Apple's Human Interface Guidelines (snapshot of 2026-09-12). Not grilled. Christoph agreed the Capacity line and the testing approach the same day and chose the guillemet to try first; he saw it on a sample store the same day and kept it.

## Problem Statement

When I open the menu from MacKanban's menu bar icon, its first line says "4 of 16 used, −0,83 from aging". I can't tell what the −0,83 means, even though I built this app. It's the sum of the Urgency of my Open Cards, a number that only makes sense inside the Capacity formula, and without the rest of that formula it explains nothing.

Below it, my Doing Cards are listed in the same plain style as the app's own items. A Card is usually titled like an instruction ("Fix the build script"), so it reads like a command to MacKanban, not like my own words on a Card.

## Solution

The first line says what it counts and nothing else: "Capacity: 4 of 16 used". The full arithmetic stays where it adds up, in the Capacity gauge on the Board.

Doing Cards show their titles behind a guillemet, under the existing "Move to Done" header: » Fix the build script. The header says what choosing one does, and the guillemet says that the words are the Card's. Choosing a Card still moves it to Done.

## User Stories

The Capacity line

1. As a user, I want the menu's first line to read "Capacity: 4 of 16 used", so that I see at a glance how much of my Board's room is taken.
2. As a user, I want no decimal number from the Capacity formula in the menu, so that I'm not left guessing what it means.
3. As a user, I want the line to use the same words as the Capacity gauge's VoiceOver label, so that the app says one thing in one way.
4. As a user, I want the line to show the same two numbers as the gauge on the Board, so that the menu and the Board never seem to disagree.
5. As a user, when I have more Open Cards than Capacity, I want the line to show that as it is ("Capacity: 9 of 7 used"), so that the menu doesn't hide it.
6. As a user, when Capacity is zero or below, I want the line to show it as the gauge does, since Capacity has no floor (ADR 0001).
7. As a user, I want the line to stay dimmed and not choosable, so that it reads as information rather than an action.
8. As a user, I want to still find out where Capacity went in the gauge on the Board, so that the rules stay explained (ADR 0001).

The Doing Cards

9. As a user, I want each Doing Card's title behind a guillemet, with none closing it, so that it reads as the Card's words rather than a command to the app.
10. As a user, I want the guillemet on every Doing Card, so that the group looks uniform whatever the titles say.
11. As a user, I want to be able to change the mark later (for example to quotation marks, the form the app's Restore texts use) without much work, so that the choice isn't locked in.
12. As a user, I want a long title shortened as before (» A very long title…), so that the menu stays narrow.
13. As a user, I want the title otherwise exactly as I wrote it, so that I recognise my Card.
14. As a user, I want the "Move to Done" header to stay, so that it's clear what choosing a quoted Card does.
15. As a user, I want choosing a quoted Card to move it to Done as before, undoable with ⌘Z in the Board window, so that only the look changes.
16. As a user, I want a Card's hover text to stay as it is, with its age and "Choose to move it to Done.", so that nothing I rely on goes away.
17. As a user, I want "Nothing in Doing" without a guillemet, since it's the app's own text and no Card's.
18. As a user, I want the app's own items (New Card…, Open Board, Open Archive, Settings…, Quit MacKanban, and the Sample Cards items) without a guillemet, so that the difference between them and my Cards is what stands out.
19. As a VoiceOver user, I want the menu items' titles to carry the same text, so that the menu doesn't say something different when read out.

## Implementation Decisions

- **The Capacity line** is "Capacity: \<Open Cards\> of \<total\> used". The aging figure is gone from the menu. The line stays a disabled menu item.
- **The Doing Card's menu title** is the title shortened as today (at most 50 characters, the 50th being "…"), behind "» " (a guillemet and a space). The guillemet doesn't count toward the 50.
- **One place for the decoration**, so that changing it touches that one place and its tests.
- **No special case for titles that already contain quotation marks or guillemets.** It's rare and still legible.
- **A typographic mark, not an icon or a font style.** The HIG has no rule for quoting content in a menu, so this is a design choice, with these findings behind it:
  - Menus: labels are "in general a verb or verb phrase for an action", which is why a Card titled like an instruction passes for a command.
  - Menus: "Use icons sparingly and with purpose", which names "user-generated content like folders", and "Treat items in the same group uniformly: icons for all or none". A Card icon would be allowed, but commands can have icons too, so an icon alone wouldn't stop a title reading as a command. A mark acts on the words themselves, and needs no new symbol.
  - Writing: "Build language patterns and reuse them." The app writes Card titles in quotation marks in its Restore texts, which speaks for quotation marks. Christoph looked at the guillemet and kept it: it is shorter, and no closing mark sits after a title.
  - Italics are rejected: the HIG gives no support for them here, and the difference is easy to miss at menu size.
- **The texts move to KanbanCore**, beside the Card's Urgency hover text (MVP 20), so that they can be tested. The menu bar extra only displays them. No change to the Board's rules, the schema or the event log.
- **The status item's own hover text and VoiceOver label** ("4 of 16 used") don't change.

## Testing Decisions

- A good test states what the user reads, for given Capacity numbers or a given title, not how the text is put together.
- Tests for the Capacity line: an ordinary case, no decimals when the aging sum isn't whole, more Open Cards than Capacity, Capacity zero and below, and the cap of 20.
- Tests for the quoted title: a short title; a title of exactly 50 characters stays whole; a title of 51 is shortened and ends in the ellipsis; a title already containing quotation marks.
- Prior art: the Urgency hover text tests (MVP 20) and the Capacity tests.
- By hand on a sample store, as spec 0001 lists the menu bar under "Not automated": a screenshot of the open menu, light and dark, with short and long titles; "Nothing in Doing"; choosing a quoted Card moves it to Done and ⌘Z undoes it; the hover text; the menu items' titles in the accessibility tree.

## Out of Scope

- The Capacity gauge's breakdown on the Board. It still shows "−0.83 from aging Cards", because there it's one line of a sum that adds up.
- Explaining aging in the menu, in words or in a hover text.
- An icon or Urgency colour on the Doing Cards in the menu.
- The status item's hover text and VoiceOver label.
- Changing what the menu offers or its order.

## Further Notes

- The older wording lives on in ticket 11 of the MVP ("5 of 8 used, −2.4 from aging") as a record of what was built then.
- Tickets go in `.scratch/menu-bar-menu/issues/`.
- Decided on 2026-11-08 after a look at a sample store: the guillemet stays. Christoph also checked it with VoiceOver the same day.
