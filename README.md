# Polar Finder

A Garmin Connect IQ watch app for polar alignment on the Forerunner 255 family
(`fr255`, `fr255s`, `fr255m`, and `fr255sm`) and Forerunner 965 (`fr965`).
It acquires or edits an observing location, reviews atmospheric inputs,
calculates observer-corrected Polaris alignment values, and presents a live
dark-site display. The persisted Reticle selector offers the Generic numerical
result, the full iOptron graphic, or the enlarged inner-only Sifo graphic. Both
graphics retain live Polaris placement, clock/offset readouts, and warnings.

## Requirements

- Garmin Connect IQ SDK managed by Garmin SDK Manager
- A signing key at `~/Library/Application Support/Garmin/ConnectIQ/developer_key.der`
- GNU Make
- ImageMagick (`magick`) when regenerating the launcher icon
- [uv](https://docs.astral.sh/uv/) when checking, regenerating, or updating IERS data

The Makefile reads the active SDK from `~/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg`. Override `DEVELOPER_KEY` or `DEVICE` on the command line when needed.

## Commands

```sh
make lint                       # check project XML formatting
make check-generated            # verify checked-in IERS output without refreshing data
make generate-iers              # regenerate IERS source from the checked-in snapshot
make update-iers                # explicitly download and replace the IERS snapshot
make build                      # compile DEVICE (fr965 by default)
make DEVICE=fr255s build        # compile one selected profile
make build-all                  # compile collision-free PRGs for all five devices
make package                    # export one all-device PolarFinder.iq package
make simulator
make DEVICE=fr255 run           # launch in the matching running simulator
make DEVICE=fr255s test         # compile and run tests on one profile
make test-profiles              # test representative 218, 260, and 454 profiles
make clean
```

`make simulator` starts Garmin's simulator. Run it before `make run` or
`make test`. Single-device builds, runs, and tests honor `DEVICE`; artifacts are
device-qualified under `bin/`, so profiles do not overwrite one another.
`make lint` needs no install step; `npx` runs the exactly pinned Prettier and
XML plugin versions. Launcher PNGs are regenerated from
`artwork/launcher-icon.svg` when it changes: 65×65 for the 965 and dithered
40×40 family-qualified resources for the 64-color Forerunner 255 displays.

## Bundled Earth data

The astrometry calculation uses bundled, read-only reference data:

- **Geoid:** NGA EGM96 (`us_nga_egm96_15.tif`) reduced to a global 15° lattice
  and bilinearly interpolated for MSL-to-ellipsoid height conversion.
- **Earth orientation:** IERS Bulletin A `finals2000A` prediction rows, MJD
  **61292–61659** (**2026-09-09–2027-09-11**), with DUT1 and polar motion
  (`xp`, `yp`) interpolated at the fractional UTC MJD. Dates outside this
  interval are rejected; the final 30 days are marked as nearing expiry.

`source/GeoidData.mc` is handwritten; `source/IersEopData.mc` is generated from
the single checked-in `data/iers/finals2000A-YYYY-MM-DD.txt` snapshot. Ordinary
builds and CI do not refresh IERS data. See
[Earth-data generation and CI](docs/earth-data-generation-and-ci.md) for ownership,
reproducible generation, the explicit update procedure, and CI signing security.

## Languages

- English (`eng`)
- Simplified Chinese (`zhs`)
- Traditional Chinese (`zht`)
