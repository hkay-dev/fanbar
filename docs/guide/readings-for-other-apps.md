---
title: Readings for other apps
feature: readings-file
covers:
  - Sources/Fanbar/Fanbar.swift
since: 2026-11-01
---

Other apps, such as Spyglass, can ask Fanbar for its readings while the panel
is closed. Fanbar only samples when it is asked, so it does nothing while the
panel is closed and nobody is asking.

## Ask for readings

Touch the file `~/.fanbar/watch` (create it if it isn't there). Fanbar checks
that file once a second. While its modification time is less than 10 seconds
old, Fanbar samples the fans, temperatures, CPU power, clocks and thermal
pressure, and writes them to `~/.fanbar/readings.json` once a second. Keep
touching the file to keep the readings coming. About 10 seconds after the last
touch, Fanbar stops sampling and stops powermetrics, and the readings file
stops updating.

Opening the panel samples too, and writes the same file, as long as the panel
stays open.

## The readings file

Fanbar replaces the file whole each time (it writes a temporary file in
`~/.fanbar/` and renames it), so a reader never sees half a file. The last
file stays on disk after sampling stops, so check `t` before trusting it.

```json
{"t": 1793525813000,
 "fans": [{"rpm": 1800, "min": 1200, "max": 5800}],
 "dieTempC": 52.5, "batteryTempC": 31.2, "cpuWatts": 4.3,
 "pClusterMHz": 1800, "sClusterMHz": 1200,
 "thermalPressure": "Nominal",
 "fanMode": "Stock (Apple's curve)"}
```

- `t` is the time of the reading in milliseconds since 1970.
- `thermalPressure` is the name powermetrics gives: Nominal, Moderate, Heavy,
  Trapping or Sleeping.
- `fanMode` is the text the panel shows under Fans: "Stock (Apple's curve)",
  "Max" or "Manual 2000 rpm".
- Any value Fanbar doesn't know yet is `null`. The power, clock and pressure
  values come from powermetrics, so they are `null` for the first second or
  two after sampling starts, and stay `null` if Fanbar can't run powermetrics.
