# Agent Instructions

## Scope

This repository contains a Garmin Connect IQ watch app targeting the Forerunner 255 family (`fr255`, `fr255s`, `fr255m`, and `fr255sm`) and Forerunner 965 (`fr965`) with API level 5.2.0.

## Architecture

- `manifest.xml`: application identity, device, language, and permission declarations.
- `source/`: shared Monkey C application, adaptive display profile, model, and view code.
- `tests/`: test-only Monkey C sources selected through `test.jungle`.
- `resources/`: shared strings and generated 65×65 launcher resources.
- `resources-round-218x218/` and `resources-round-260x260/`: generated, dithered 40×40 launcher overrides for the 64-color Forerunner 255 displays.
- `resources-zhs/` and `resources-zht/`: Chinese string overrides.
- `artwork/`: editable vector artwork. Do not hand-edit generated PNGs.
- `docs/user-manual.md`: user-facing English instructions linked prominently from `README.md`.
- `Makefile`: canonical single-device, all-device, package, simulator, run, and test interface.

## Development rules

- Use the CLI workflow; do not add VS Code or Eclipse project metadata.
- Keep the app compatible with all five declared products. Do not use APIs introduced after 5.2.0.
- Keep signing keys outside the repository. Never commit PEM or DER files.
- Add permissions only when required by an agreed feature. `Positioning` is reserved for the planned GPS-based celestial-time calculation.
- Keep English, Simplified Chinese, and Traditional Chinese strings synchronized.
- Before adding a non-ASCII character to any watch-visible string, verify that Garmin's runtime font renders it on every supported display family and language. Do not infer glyph coverage from desktop fonts or successful compilation; use an existing verified glyph or an ASCII fallback otherwise.
- Regenerate launcher PNGs from `artwork/launcher-icon.svg` with `make build`; ImageMagick produces the 65×65 AMOLED resource and family-qualified dithered 40×40 MIP resources.
- Whenever code, resources, or the manifest change user-visible behavior, controls, screens, settings, supported devices, permissions, warnings, errors, or limitations, update `docs/user-manual.md` in the same change. Keep it written for app users rather than developers, and preserve its prominent link near the start of `README.md`.
- Do not duplicate changing runtime data, such as the bundled Earth-data validity dates, in the user manual. Direct users to the app interface that owns and displays those values so the information remains single-sourced.

## Formatting and validation workflow

- `monkeyc-fmt` is a required tool, not an optional SDK component. Install the exact pinned version before editing or checking Monkey C: `cargo install --locked --version 0.1.1 monkeyc-fmt`.
- Run `make format` (or `monkeyc-fmt --write` on the changed `.mc` files) before committing, then run `make lint`.
- Do not remove whitespace from blank lines after `monkeyc-fmt`; the formatter intentionally preserves indentation on blank lines, and stripping it makes an otherwise formatted file fail the formatter check.
- `make lint` does not require a Connect IQ SDK or `current-sdk.cfg`; an SDK configuration warning from Make is harmless for lint. SDK-dependent commands (`build`, `test`, `package`, and simulator commands) do require a valid `SDK_HOME`.

## Verification

Do not set `JAVA_TOOL_OPTIONS` when running any `make` command.

- `make lint`: check XML with the pinned formatter.
- `make test`: run tests for `DEVICE`; allow at most a one-minute timeout.
- `make test-profiles`: run tests for representative 218×218, 260×260, and 454×454 profiles.
- `make build`: compile and sign the app for `DEVICE`; allow at most a one-minute timeout.
- `make build-all`: compile collision-free artifacts for all five devices.
- `make package`: export one all-device `.iq` package.
- `make simulator`: start Garmin's simulator; allow at most a one-minute timeout.
- `make run`: build and launch `DEVICE` in an already-running matching simulator.
- `make clean`: remove generated compiler output.

For UI changes, inspect 218×218 (`fr255s`/`fr255sm`), 260×260
(`fr255`/`fr255m`), and 454×454 (`fr965`) round displays. Exercise every flow
with buttons; additionally inspect touch behavior on `fr965`.
