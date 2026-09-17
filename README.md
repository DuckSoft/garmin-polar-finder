<img src="banner.jpg" alt="Polar Finder banner" width="100%">

# Polar Finder

## User manual

**Using the app? Start with the [Polar Finder User Manual](docs/user-manual.md)**
for setup, controls, location entry, reticle guidance, atmospheric settings, and
troubleshooting.

A Garmin Connect IQ watch app for polar alignment on the Forerunner 255 family
(`fr255`, `fr255s`, `fr255m`, and `fr255sm`) and Forerunner 965 (`fr965`).
It acquires or edits an observing location, reviews atmospheric inputs,
calculates observer-corrected Polaris alignment values, and presents a live
dark-site display. The persisted Reticle selector offers the Generic numerical
result, the full iOptron graphic, or the enlarged inner-only Sifo graphic. Both
graphics retain live Polaris placement, clock/offset readouts, and warnings.

On iOptron and Sifo Displays, physical **UP** immediately enters a transient
6× view centered on the live green Polaris marker; physical **DOWN** restores
the normal view. The magnified reticle artwork is clipped to the physical
display edge, all text is hidden, and a full-screen green crosshair marks the
physical center for precise alignment. The state resets on Display entry,
recalculation, an invalid marker, or return from Actions. Generic and touch
wake-only behavior are unchanged;
SELECT/BACK retain their existing actions.

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
make -j5 build-all              # compile all five devices in parallel
make package                    # export one all-device PolarFinder.iq package
make simulator
make DEVICE=fr255 run           # launch in the matching running simulator
make DEVICE=fr255s test         # compile and run tests on one profile
make test-profiles              # test representative 218, 260, and 454 profiles
make clean
```

`make simulator` starts Garmin's simulator. Run it before `make run` or
`make test`. Single-device builds, runs, and tests honor `DEVICE`; artifacts are
written to `bin/<device>/PolarFinder-<device>.prg`, with compiler intermediates
isolated per device so parallel builds do not share generated state.
Test PRGs remain at `bin/PolarFinder-tests-<device>.prg`.
`make test-profiles` serializes all three profiles even when invoked with `-j`,
because MonkeyDo clients share one simulator.
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
[Earth-data generation](docs/earth-data-generation.md) for ownership,
reproducible generation, and the explicit update procedure.
See [CI trust and build contract](docs/ci.md) for workflow triggers, signing
security, simulator tests, and build artifacts.

## Languages

- English (`eng`)
- Simplified Chinese (`zhs`)
- Traditional Chinese (`zht`)
