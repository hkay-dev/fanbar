---
type: log
summary: Changed - The Mac now measures its CPU, memory, network and busiest processes for the phone, only while the phone watches, and Fanbar can hand its fan, heat and power readings to Spyglass without its panel open.
project: fanbar
sprint: apex-monitor
window: 2026-11-01T09:34:16Z/2026-11-01T09:53:46Z
tickets: [fanbar#n0q4]
---

# Spyglass: a system monitor for Apex

Changed: The Mac now measures its CPU, memory, network and busiest processes for the phone, only while the phone watches, and Fanbar can hand its fan, heat and power readings to Spyglass without its panel open. The Monitor screen and its cards left this run for their Lab look (you picked A); the screen's data side is already on main, and a branch holds the agents card's daemon work.
Try: not tried yet; nothing shows on the phone until the Monitor screen is built.

## What changed

- New: Spyglass can ask Fanbar for its fan, heat and power readings while the panel is closed. (fanbar#n0q4)

## Calls

- The readings file's fan mode is the same text the panel shows under Fans (like Stock or Manual 2000 rpm), not Fanbar's internal mode name. (fanbar#n0q4)
