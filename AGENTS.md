# Agent Instructions

## Scope

This repository contains a Garmin Connect IQ watch app targeting only the Forerunner 965 (`fr965`) with API level 5.2.0.

## Architecture

- `manifest.xml`: application identity, device, language, and permission declarations.
- `source/`: Monkey C application and view code.
- `resources/`: shared layouts, strings, and generated launcher resources.
- `resources-zhs/` and `resources-zht/`: Chinese string overrides.
- `artwork/`: editable vector artwork. Do not hand-edit generated PNGs.
- `Makefile`: canonical build, simulator, run, and clean interface.

## Development rules

- Use the CLI workflow; do not add VS Code or Eclipse project metadata.
- Keep the app compatible with the Forerunner 965 runtime. Do not use APIs introduced after 5.2.0.
- Keep signing keys outside the repository. Never commit PEM or DER files.
- Add permissions only when required by an agreed feature. `Positioning` is reserved for the planned GPS-based celestial-time calculation.
- Keep English, Simplified Chinese, and Traditional Chinese strings synchronized.
- Regenerate `resources/drawables/launcher_icon.png` from `artwork/launcher-icon.svg` with `make build`; ImageMagick performs the conversion.

## Verification

- `make build`: compile and sign the app.
- `make simulator`: start Garmin's simulator.
- `make run`: build and launch in an already-running simulator.
- `make clean`: remove generated compiler output.

For UI changes, launch the actual app in the `fr965` simulator and inspect the 454×454 round display.
