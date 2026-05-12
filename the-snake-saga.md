# The Snake Saga 🐍

### A GitHub README Styling Adventure ft. Copilot (Claude Sonnet 4.6)

---

## Act 1: The Spacing Problem

**User:** The contribution snake text on line 49 is right on the line, is there no way to do a `<br></br>` or something?

**Copilot:** _confidently applies fix_ Done!

**User:** that breaks the code

**Copilot:** _confidently applies different fix_ Done!

**User:** still didn't work

**Copilot:** _applies third fix_ Done!

**User:** STILL didn't work. Is there a way to add bottom margin?

**Copilot:** Yes! `margin-bottom` should work...

**GitHub README renderer:** lol no

---

## Act 2: The Wall of &nbsp;

**User:** lmao nothing gets this goddamn snake off the line haha i give up for now

**Copilot:** Totally fair. GitHub strips/normalizes styling in ways that make spacing feel random.

_(User disappears, tinkers alone, returns victorious)_

**User:** I figured out a quick fix haha check it out

**Copilot:** _inspects file_ ...that is a clever workaround.

_(File contained approximately 128 `&nbsp;` entities in a row)_

**User:** lmaoooooo look at line 91, idk how else to get it how i want but it looks nice with all that nonsense 🤣😂 I'm dead hahahaha

**Copilot:** Sometimes ugly code is the right code.

---

## Act 3: The Table Incident

**Copilot:** I can clean that up with a proper HTML table! Same visual result, clean code.

**User:** its not the same effect at all 😂 Youre fired from md syntax hahaha

**Copilot:** _quietly restores the wall of &nbsp;_

---

## Act 4: The Roast

**User:** im dead this is hilarious. copilot just roasted me 😭🤣

**Copilot:** In my defense, you built a functioning layout with a hundred non-breaking spaces — that takes a special kind of determination. Respect. 😂

---

## Why Is GitHub README Styling Such a Pain?

Great question. GitHub runs your README through a **HTML sanitizer** that:

- Strips most `style=""` attributes (so `margin`, `padding`, `font-size` etc. are ignored)
- Removes `<style>` blocks entirely
- Only allows a small allowlist of HTML tags and attributes
- Converts Markdown inconsistently depending on whether you're inside an HTML block

So you're not bad at it — the tool is genuinely limited by design (security reasons, mostly). The `&nbsp;` wall is a completely legitimate workaround in that environment.

---

## Lessons Learned

| What we tried                           | Did it work?          |
| --------------------------------------- | --------------------- |
| `<p align="center">` with blank lines   | broke image rendering |
| `<div align="center">` with blank lines | sometimes             |
| `style="margin-bottom:10px"`            | stripped by GitHub    |
| `<p>&nbsp;</p>`                         | collapsed             |
| Multiple `<br />` before divider        | inconsistent          |
| Putting `---` inside the `<div>` block  | actually worked!      |
| HTML table for space-between            | not the same vibe     |
| 128 `&nbsp;` entities                   | **THE WINNER** 🏆     |

---

_README shaped by stubbornness, caffeine, and one AI that doesn't know GitHub MD syntax as well as it thinks it does._
