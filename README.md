# Polar Finder

A Garmin Connect IQ watch app for polar alignment on the Forerunner 965.

The current skeleton displays a localized readiness screen. It declares Garmin's `Positioning` permission because GPS coordinates will drive local celestial-time calculations, but it does not access location data yet.

## Requirements

- Garmin Connect IQ SDK managed by Garmin SDK Manager
- A signing key at `~/Library/Application Support/Garmin/ConnectIQ/developer_key.der`
- GNU Make
- ImageMagick (`magick`) when regenerating the launcher icon

The Makefile reads the active SDK from `~/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg`. Override `DEVELOPER_KEY` or `DEVICE` on the command line when needed.

## Commands

```sh
make build
make simulator
make run
make clean
```

`make simulator` starts Garmin's simulator. Run it before `make run`, which builds, signs, installs, and launches the app for `fr965`.

The launcher PNG is regenerated from `artwork/launcher-icon.svg` automatically when the SVG changes.

## Languages

- English (`eng`)
- Simplified Chinese (`zhs`)
- Traditional Chinese (`zht`)
