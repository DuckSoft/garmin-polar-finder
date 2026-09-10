# Polar Finder

A Garmin Connect IQ watch app for polar alignment on the Forerunner 965. It
acquires or edits an observing location, reviews atmospheric inputs, calculates
observer-corrected Polaris alignment values, and presents a live dark-site display.
The persisted Reticle selector offers the Generic numerical result or an iOptron
SkyGuider Pro graphic with a live Polaris placement marker.

## Requirements

- Garmin Connect IQ SDK managed by Garmin SDK Manager
- A signing key at `~/Library/Application Support/Garmin/ConnectIQ/developer_key.der`
- GNU Make
- ImageMagick (`magick`) when regenerating the launcher icon

The Makefile reads the active SDK from `~/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg`. Override `DEVELOPER_KEY` or `DEVICE` on the command line when needed.

## Commands

```sh
make lint    # check two-space formatting for every project XML file
make build   # compile and sign for fr965
make simulator
make run     # launch in the running simulator
make test    # compile and run SOFA vector tests in the simulator
make clean
```

`make simulator` starts Garmin's simulator. Run it before `make run` or
`make test`. The Makefile reads the active SDK path and uses `fr965` by default.
`make lint` needs no install step; `npx` runs the exactly pinned Prettier and XML plugin versions.
The launcher PNG is regenerated from `artwork/launcher-icon.svg` automatically when the SVG changes.

## Bundled Earth data

The astrometry calculation uses bundled, read-only reference data:

- **Geoid:** NGA EGM96 (`us_nga_egm96_15.tif`) reduced to a global 15° lattice
  and bilinearly interpolated for MSL-to-ellipsoid height conversion.
- **Earth orientation:** IERS Bulletin A `finals2000A` prediction rows, MJD
  **61292–61659** (**2026-09-09–2027-09-11**), with DUT1 and polar motion
  (`xp`, `yp`) interpolated at the fractional UTC MJD. Dates outside this
  interval are rejected; the final 30 days are marked as nearing expiry.

## Languages

- English (`eng`)
- Simplified Chinese (`zhs`)
- Traditional Chinese (`zht`)
