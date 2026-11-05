---
type: log
summary: Changed - All ten Mac apps now build with the one shared Xcode setup and ship through the shared ship steps, and each has the same check, dev and ship scripts that Deck runs.
project: fanbar
sprint: build-std-3-mac
window: 2026-11-05T06:28:01Z/2026-11-05T06:43:29Z
tickets: [fanbar#ebvp]
---

# Build standard: Mac apps

Changed: All ten Mac apps now build with the one shared Xcode setup and ship through the shared ship steps, and each has the same check, dev and ship scripts that Deck runs.
Try: not tried yet. Ship any one Mac app from Deck and watch its build page: a clean, identity, lock and requirement step come before the install.

## What changed

- Improved: Fanbar builds with the full Xcode toolchain and ships through the shared install steps. (fanbar#ebvp)

## Calls

- Fanbar Dev is its own app bundle (Fanbar Dev, its own bundle id) in the build folder, so a Dev run never replaces or collides with the installed Fanbar (fanbar#ebvp)
