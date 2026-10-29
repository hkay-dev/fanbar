---
type: reference
summary: Lab item for fanbar#3yqa, which app icon Fanbar uses.
ref: fanbar#3yqa
kind: picture
mode: pick
question: Which icon should Fanbar have?
takes:
  - id: A
    name: Fan blades
    line: A three-blade fan in white on a deep blue backdrop.
    file: takes/A.svg
  - id: B
    name: Gauge
    line: A dial going from cool green to warm orange, for the live readings.
    file: takes/B.svg
  - id: C
    name: Airflow
    line: Two curling wind lines on a mint backdrop.
    file: takes/C.svg
recommended: A
approve: Install the take he picked
round: 1
status: waiting
---

# Which icon should Fanbar have?

Fanbar has no icon yet. Each take is a full-bleed 1024 px SVG; macOS and Deck add the rounded corners. The PNG beside each take shows it rounded at 256, Dock (128) and sidebar (32) size, and all three still read at 32.

- **A, Fan blades**: the app's own object, the same fan you click in the menu bar.
- **B, Gauge**: the readings side (power, clocks, temps) more than the fan itself.
- **C, Airflow**: the feel of the fan, with the least detail of the three.

I recommend A: it says "fan" at any size and matches the menu bar glyph that you already know.
