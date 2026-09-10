# Forerunner 255 Compatibility Research

## Status and scope

This document began as the factual compatibility research for adding the
Forerunner 255 family (`fr255`, `fr255s`, `fr255m`, and `fr255sm`) alongside
the Forerunner 965 (`fr965`). Sections describing “current” repository state,
experiments, open decisions, and non-claims preserve the pre-implementation
snapshot so their evidence remains auditable.

Implementation subsequently enabled all five products at API 5.2.0, added
collision-free per-device and package workflows, moved tests behind a
test-only Jungle overlay, introduced one cached adaptive display profile, and
parameterized reticle center/radius geometry. The 218×218 and 260×260 MIP
families use qualified, dithered 40×40 launcher resources; the 454×454 AMOLED
target retains the shared 65×65 resource. Automated multi-profile compilation,
geometry/input tests, and simulator launch/runtime checks are recorded in the
implementation delivery; human visual signoff remains required.

All compiler experiments below that required changed manifests or sources used
temporary copies under `${TMPDIR:-/tmp}`. The randomized directory names were
intentionally omitted because they were machine-specific and no longer exist.

## Local evidence

### Selected SDK and tools

The active SDK is selected by:

```text
$HOME/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg
```

Its value during the investigation was:

```text
$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/<installed-sdk>/
```

Compiler version command and result:

```sh
"$(cat "$HOME/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg")/bin/monkeyc" -v
```

```text
Connect IQ Compiler version: 9.1.0
```

The SDK documentation footer identifies itself as “Connect IQ System 9 API 9.1.0 Documentation,” copyright 2026.

### Documentation inspected

All paths below are rooted in the selected SDK directory above:

```text
doc/docs/Core_Topics/Build_Configuration.html
doc/docs/Core_Topics/Manifest_and_Permissions.html
doc/docs/Reference_Guides/Jungle_Reference.html
doc/docs/Device_Reference/fr255.html
doc/docs/Device_Reference/fr255s.html
doc/docs/Device_Reference/fr255m.html
doc/docs/Device_Reference/fr255sm.html
doc/docs/Device_Reference/fr965.html
bin/default.jungle
```

The supplied `Build_Configuration.html` was read directly. Its main topics are resource qualifiers, device/family/localization specificity, Jungle per-device paths, and annotation exclusions.

### Installed device metadata and simulator profiles

Each target has an installed profile under:

```text
$HOME/Library/Application Support/Garmin/ConnectIQ/Devices/<device-id>/
```

The following evidence files were inspected or confirmed for each device:

```text
compiler.json
simulator.json
<device-id>.api.debug.xml
<device-id>.bin
personality.mss
<device image and system assets>
```

Complete installed directories exist for all five exact IDs:

```text
fr255
fr255s
fr255m
fr255sm
fr965
```

This proves that local simulator profiles are available. It does not prove that the application has been visually or interactively verified in those profiles.

The SDK also contains device-reference resources under:

```text
$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/<installed-sdk>/resources/device-reference/<device-id>/
```

## Exact product IDs and device matrix

All five IDs below were accepted by SDK 9.1.0 when enabled in a temporary manifest and passed to `monkeyc -d`.

| Product ID | Display name | Part number | Screen | Display | Input | Launcher icon | Device API metadata | Watch-app memory |
|---|---|---|---|---|---|---:|---|---:|
| `fr255` | Forerunner 255 | `006-B3992-00` | 260×260, round | MIP, 64 colors | No touch; enter, up, menu, down, esc | 40×40 | API level 5.2; `connectIQVersion` 5.2.0; firmware 2502 | 524,288 B |
| `fr255s` | Forerunner 255s | `006-B3993-00` | 218×218, round | MIP, 64 colors | No touch; enter, up, menu, down, esc | 40×40 | API level 5.2; `connectIQVersion` 5.2.0; firmware 2502 | 524,288 B |
| `fr255m` | Forerunner 255 Music | `006-B3990-00` | 260×260, round | MIP, 64 colors | No touch; enter, up, menu, down, esc | 40×40 | API level 5.2; `connectIQVersion` 5.2.0; firmware 2502 | 786,432 B |
| `fr255sm` | Forerunner 255s Music | `006-B3991-00` | 218×218, round | MIP, 64 colors | No touch; enter, up, menu, down, esc | 40×40 | API level 5.2; `connectIQVersion` 5.2.0; firmware 2502 | 786,432 B |
| `fr965` | Forerunner 965 | `006-B4315-00` | 454×454, round | AMOLED, 65,536 colors | Touch plus enter, up, menu, down, esc | 65×65 | API level 5.2; `connectIQVersion` 5.2.0; firmware 2502 | 786,432 B |

### Display representation

The installed `compiler.json` files add the following detail:

| Products | `bitsPerPixel` | `pixelFormat` | Alpha blending | Enhanced graphics |
|---|---:|---|---|---|
| All Forerunner 255 variants | 8 | `ARGB2222` | `false` | Not declared |
| Forerunner 965 | 16 | Not separately declared in the inspected metadata | `true` | `true` |

The device-reference pages describe the 255 displays as 64-color displays. Although `ARGB2222` has eight stored bits, alpha blending is explicitly unsupported; the durable compatibility fact is the documented 64 display colors, not a claim of 256 independently usable blended values.

Screen rotation support is `false` and orientation is `0` for all five profiles.

### Other app-type memory limits

All five profiles document:

| App type | Limit |
|---|---:|
| Background | 65,536 B |
| Data field | 262,144 B |
| Glance | 65,536 B |
| Watch face | 131,072 B |

The non-Music `fr255` and `fr255s` profiles document 524,288 B for watch apps/widgets and do not list an audio-content-provider app type.

The Music variants and `fr965` document 786,432 B for watch apps/widgets and 524,288 B for audio-content-provider apps.

The app in this repository is a watch app, so the important compatibility floor is the 524,288-byte limit on `fr255` and `fr255s`.

## API compatibility

The current manifest declares:

```xml
minApiLevel="5.2.0"
```

All five installed target profiles are grouped as “API level 5.2” and have a part-number entry whose `connectIQVersion` is exactly `5.2.0`. Thus, the current minimum exactly matches the locally documented target API level.

The SDK documentation says the manifest’s `minApiLevel` prevents selection of incompatible devices. A three-component value such as `1.2.1` may be written, but only its major and minor components are considered when determining device support.

The complete current production source compiled successfully against each of the five device API profiles after the four products were enabled in a temporary manifest. This proves that the production symbols used by the current source are accepted for those profiles.

The local metadata does **not** expose a separate minimum/maximum runtime API range for these devices. It exposes one profile value, 5.2.0. The installed compiler and documentation being version 9.1.0 does not imply that these target profiles provide API 9.1 at runtime. No distinct later device-runtime maximum is claimed here.

## Input implications

The four 255 variants have no touch support. Their documented inputs are:

```text
enter, up, menu, down, esc
```

The `fr965` has those same buttons plus touch.

Consequences to investigate during implementation include:

- Every reachable action must be operable using the five buttons on the 255 family.
- Touch affordances may remain useful on `fr965`, but cannot be the sole route to an action.
- Focus order, scroll behavior, cancel/back handling, and long-menu behavior need actual simulator verification.
- The presence of the same five buttons does not prove that a layout designed around a 454×454 touch screen is legible or navigable at 218×218.

No physical-button or naturally delivered touch event was exercised. A later isolated `fr255` unit-test run manually invoked the delegate methods; that narrower evidence is described under “Tests and simulator runs.”

## Font differences

The device-reference pages document materially different built-in font metrics. Code that uses `Graphics.FONT_*` therefore cannot assume the `fr965` pixel heights.

### Worldwide font set

| Symbol | `fr255` / `fr255m` | `fr255s` / `fr255sm` | `fr965` |
|---|---:|---:|---:|
| `FONT_XTINY` | 19, Roboto Condensed | 19, Roboto Condensed | 37, Roboto |
| `FONT_TINY` | 28 | 23 | 47 |
| `FONT_SMALL` | 31 | 26 | 53 |
| `FONT_MEDIUM` | 37 | 31 | 61 |
| `FONT_LARGE` | 40 | 31 | 71 |
| `FONT_NUMBER_MILD` | 45 | 40 | 103 |
| `FONT_NUMBER_MEDIUM` | 53 | 53 | 128 |
| `FONT_NUMBER_HOT` | 89, Roboto Black | 74, Roboto Black | 152 |
| `FONT_NUMBER_THAI_HOT` | 102 | 86 | 176 |
| `FONT_GLANCE` | 23 | 19 | 42 |
| `FONT_GLANCE_NUMBER` | 31 | 23 | 53 |

The `fr965` also documents `FONT_AUX1`/`FONT_AUX2` at 46/41 and scalable font faces. The inspected 255 tables do not document an equivalent scalable-font set.

### Chinese font set

For `zhs` and `zht`:

| Symbol | 260px 255 models | 218px 255s models | `fr965` |
|---|---:|---:|---:|
| `FONT_XTINY` | 16 | 16 | 31 |
| `FONT_TINY` | 23 | 18 | 39 |
| `FONT_SMALL` | 26 | 22 | 44 |
| `FONT_MEDIUM` | 31 | 26 | 51 |
| `FONT_LARGE` | 34 | 26 | 59 |

The 255 models use Noto Sans SC Bold-94 for these entries. The `fr965` uses Noto Sans SC Medium.

Japanese and Korean likewise have size-specific MotoyaLCedar/Kosugi and NanumGothic mappings. Thai’s basic font sequence is documented as 16/16/16/21/27 even on `fr965`, making locale-specific fit checks important. Vietnamese on the 255 family has its own Roboto Condensed mappings.

## Launcher icon requirements

The current generated launcher image is 65×65, matching `fr965`. The 255 family’s documented launcher size is 40×40.

`Manifest_and_Permissions.html` states that when `launcherIcon` is specified, the resource compiler automatically sizes the resource for the target product’s icon size. A missing launcher icon receives a default icon. The documentation also advises against reusing the launcher icon resource inside the app; a duplicate resource should be used for in-app display.

The temporary builds successfully consumed the existing shared resource for every 255 target, establishing that a separate 40×40 source is not required merely to compile. This does not establish that automatic downscaling produces the desired visual quality on 64-color MIP displays.

Implementation options remain open:

- Keep the 65×65 generated bitmap and rely on documented per-product auto-sizing.
- Generate a shared source at a different resolution while still relying on auto-sizing.
- Supply family- or device-qualified 40×40 launcher artwork tuned for MIP/downsampling.

A visual simulator comparison would discriminate between these options.

## Pre-implementation repository assumptions

### Manifest

`manifest.xml` currently:

- Declares manifest version 3.
- Declares a `watch-app` named by `@Strings.AppName`.
- Uses entry point `PolarFinderApp`.
- Uses `@Drawables.LauncherIcon`.
- Sets `minApiLevel="5.2.0"`.
- Enables only `<iq:product id="fr965" />`.
- Requests `Positioning` and `Sensor`.
- Declares `eng`, `zhs`, and `zht`.
- Has an empty `<iq:barrels />`.

A negative-control build with the unmodified repository manifest showed the exact current blocker:

```sh
monkeyc -d fr255 -f monkey.jungle -o /tmp/current-fr255.prg -y developer_key.der
```

```text
ERROR: Target device id 'fr255' is not enabled in the application manifest file.
```

The compiler exited with status 102.

The necessary manifest-level compatibility change, when implementation begins, is to add exact product IDs `fr255`, `fr255s`, `fr255m`, and `fr255sm`. The current `minApiLevel` can remain 5.2.0 based on the local profiles.

### Jungle

`monkey.jungle` currently contains only:

```text
project.manifest = manifest.xml
```

This means the SDK’s `default.jungle` supplies source, resources, personalities, family qualifiers, device qualifiers, and localization paths.

Relevant default-Jungle mappings are:

```text
fr255   -> round-260x260
fr255m  -> round-260x260
fr255s  -> round-218x218
fr255sm -> round-218x218
fr965   -> round-454x454
```

The default base source path is effectively all `.mc` files under the project, while the default base resource path is `resources`. The default Jungle also defines inherited paths such as `resources-round`, `resources-round-218x218`, `resources-fr255s`, and language-suffixed variants.

### Makefile

The current Makefile:

- Reads the SDK path from `current-sdk.cfg`.
- Defines `DEVICE ?= fr965`.
- Writes normal builds to `bin/PolarFinder.prg`.
- Writes unit-test builds to `bin/PolarFinder-tests.prg`.
- Uses `-d "$(DEVICE)" -f monkey.jungle` for builds/tests.
- Runs `monkeydo` using the same `DEVICE`.
- Generates one 65×65 launcher PNG from the SVG before build/test.
- Has no package/export target and no all-device compile matrix.

After manifest enablement, the existing Makefile form could already build one alternate device at a time:

```sh
make DEVICE=fr255 build
make DEVICE=fr255 test
make DEVICE=fr255 run
```

No Makefile change is strictly necessary for single-device-at-a-time operation. However, the fixed output paths mean sequential device builds overwrite each other. An all-device workflow would need device-qualified loose output names/directories, or a package target.

### Exact affected source and test callsites

The current compatibility boundary is concentrated in these locations:

- `manifest.xml:3-23`: application type, entry point, minimum API, product list, permissions, languages, and barrels. Product enablement changes the product list at lines 11-13 only unless later experiments demonstrate another requirement.
- `monkey.jungle:1`: the only project-specific build configuration. Any family source paths, resource paths, or annotation exclusions would be added here.
- `Makefile:6-8,12-16,34-47`: default device, fixed production/test artifact paths, device passed to the compiler and simulator, and the single 65×65 icon recipe.
- `source/PolarFinderApp.mc:14-18`: creates `PolarFinderView` and `PolarFinderDelegate`; this is the construction seam for a target-selected view, delegate, factory, or geometry profile.
- `source/PolarFinderApp.mc:21-30`: starts/stops continuous positioning and forwards `Position.Info`.
- `source/PolarFinderView.mc:55-69`: screen constants, fr965 geometry constants/state, and the currently empty `onLayout`.
- `source/PolarFinderView.mc:75-85`: title, center, fit, footer, focus visibility, and row primitives. These embed center `227`, footer `414`, drawable bounds `58..390`, and fixed row/highlight widths.
- `source/PolarFinderView.mc:89-145`: every screen renderer has fixed fr965 coordinates or widths. The affected functions are `drawLocate`, `drawReticleChoice`, `drawGps`, `drawEditor`, `drawAtmos`, `drawCalc`, `drawError`, `drawDisplay`, `drawIoptronDisplay`, `drawIoptronReadout`, `drawIoptronWarning`, `drawIoptronTick`, `drawActions`, `drawDetails`, `drawHelp`, `drawWrapped`, `drawWrappedWidth`, `drawGpsWarning`, and `drawDiscard`.
- `source/PolarFinderView.mc:147-155`: focus range/navigation, tap-to-row coordinate conversion, and focused Locate restoration depend on the same row geometry.
- `source/PolarFinderView.mc:159-176`: GPS, pressure, Earth data, astrometry, alerts, and display timers are behavior rather than layout, but must remain shared or be migrated into every selected view. `samplePressure` at 168 is the Sensor-permission callsite. `loadEarthData`, `beginAstronomy`, and `stepAstronomy` at 170-172 define the production Earth/Astrometry contract.
- `source/PolarFinderView.mc:179-200`: one delegate maps physical keys and all touch callbacks. `onKey`/`handleKey` at 188-189 are required on all targets; `onSwipe`, `onTap`, `onHold`, `onRelease`, `onDrag`, `onFlick`, and `onSelectable` at 190-199 are touch-specific delivery paths.
- `source/IoptronReticle.mc:7-8,70-77`: `IOPTRON_CENTER=227`, `IOPTRON_R70=170`, and `ioptronMarkerPosition` independently pin fr965 geometry. Changing the view alone is insufficient.
- `source/PolarFinderModel.mc:12-28`: storage/preferences are target-independent and have no observed geometry dependency.
- `source/Astrometry.mc:2227,2286-2522`: `unixSecondsToJulianDate`, `begin`, `step`, and `cancel` are production-reachable through the view.
- `source/EarthData.mc:396-430`: `geoidOffset`, `mslToEllipsoid`, and `eop` are production-reachable; `firstDate` and `lastDate` have no repository caller.
- `source/AstrometryTests.mc:151-218`: fixed fr965 menu bounds/row positions.
- `source/AstrometryTests.mc:222-403`: reticle geometry tests pin radius 170 and center 227.
- `resources/layouts/layout.xml:1-23`: contains a dynamic centered layout, but no `MainLayout`, `Rez.Layouts`, `setLayout`, or `findDrawableById` callsite exists. It cannot adapt the current custom-drawn UI unless source is deliberately migrated to use it.
- `resources/drawables/drawables.xml:5`, `resources/drawables/launcher_icon.png`, and `artwork/launcher-icon.svg`: launcher declaration, generated output, and editable source.
- `resources/strings/strings.xml`, `resources-zhs/strings/strings.xml`, and `resources-zht/strings/strings.xml`: shared localized content whose actual width must be checked at each font family.

This inventory favors keeping calculation, storage, navigation, and input semantics shared even if rendering becomes family-specific. Duplicating a full view would duplicate many non-visual behaviors as well.

## Baseline build experiment

A temporary manifest enabled exactly:

```text
fr965, fr255, fr255s, fr255m, fr255sm
```

It retained `minApiLevel="5.2.0"`, permissions, languages, application identity, and entry point. A temporary Jungle pointed to the repository’s unchanged source and resources.

Representative command shape:

```sh
"$(cat "$HOME/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg")/bin/monkeyc" \
  -d fr255 \
  -f research.jungle \
  -o fr255.prg \
  -y "$HOME/Library/Application Support/Garmin/ConnectIQ/developer_key.der" \
  --build-stats 0
```

The command was repeated for all five device IDs. Every build ended with `BUILD SUCCESSFUL`.

### Baseline compiler results

| Device | Foreground data | Foreground code | Data + code | Extended code | PRG size | Watch-app limit | Arithmetic headroom |
|---|---:|---:|---:|---:|---:|---:|---:|
| `fr255` | 152,168 | 47,168 | 199,336 | 0 pages / 0 B | 350,956 | 524,288 | 324,952 B (62.0%) |
| `fr255s` | 152,168 | 47,168 | 199,336 | 0 pages / 0 B | 350,956 | 524,288 | 324,952 B (62.0%) |
| `fr255m` | 152,168 | 47,168 | 199,336 | 0 pages / 0 B | 350,956 | 786,432 | 587,096 B (74.6%) |
| `fr255sm` | 152,168 | 47,168 | 199,336 | 0 pages / 0 B | 350,956 | 786,432 | 587,096 B (74.6%) |
| `fr965` | 152,168 | 47,168 | 199,336 | 0 pages / 0 B | 359,756 | 786,432 | 587,096 B (74.6%) |

“Arithmetic headroom” is simply the documented app limit minus compiler-reported foreground data and code. It is not a measured runtime heap high-water mark and is not a guarantee against runtime allocation failure.

The four 255 builds produced equal reported statistics and equal file sizes. `fr965` differed only in total PRG size in this experiment. Target-specific resource encoding is a plausible cause because the profiles differ in launcher size, display depth, and resource personality, but that cause was not isolated or measured.

An independent temporary harness later reported the same `152,168` foreground Data and `47,168` foreground Code for `fr255`, but a loose PRG size of `351,260` rather than `350,956`. The 304-byte PRG difference was not resolved; the harnesses used independently prepared temporary manifests/Jungles/output contexts. Static Data/Code is therefore the reconciled baseline. PRG **deltas are comparable only among variants built within the same experiment series**, not across the two harnesses.

## Multi-device package/export experiment

Command:

```sh
"$(cat "$HOME/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg")/bin/monkeyc" \
  -e \
  -f research.jungle \
  -o PolarFinder.iq \
  -y "$HOME/Library/Application Support/Garmin/ConnectIQ/developer_key.der" \
  --build-stats 0
```

Observed progress and result:

```text
0 OUT OF 5 DEVICES BUILT
...
5 OUT OF 5 DEVICES BUILT
BUILD SUCCESSFUL
```

The package was 416,333 bytes. `file PolarFinder.iq` reported:

```text
PolarFinder.iq: 7-zip archive data, version 0.2
```

A `7z l PolarFinder.iq` listing showed 13 entries:

- `manifest.xml`
- `manifest.sig2`
- `dev_key.pub`
- One `PolarFinder.prg` and `debug.xml` under each part-number directory

| Part-number directory | Device | Export PRG size |
|---|---|---:|
| `006-B3993-00` | `fr255s` | 218,364 B |
| `006-B3992-00` | `fr255` | 218,364 B |
| `006-B3990-00` | `fr255m` | 218,364 B |
| `006-B3991-00` | `fr255sm` | 218,364 B |
| `006-B4315-00` | `fr965` | 227,164 B |

The package-mode PRGs were smaller than the loose development PRGs. The command results establish that size difference; no isolated compiler-option experiment was performed to attribute every byte specifically to debug stripping or another package-mode transformation.

Output naming implications:

- A `-d` build writes exactly the `-o` path and therefore overwrites a fixed `bin/PolarFinder.prg` during a device matrix.
- An `-e` build handles every product listed in the manifest and stores one common program basename under separate part-number directories inside one `.iq` package.
- A loose all-device build should use paths such as `bin/fr255/PolarFinder.prg` or names such as `bin/PolarFinder-fr255.prg`.
- A package target should produce a separate `.iq` output and should not need a manual per-device loop.

## Resource qualifiers

`Build_Configuration.html` documents resource-directory qualifiers as the simplest way to specialize resources.

### Device qualifiers

Examples for this project would be:

```text
resources-fr255/
resources-fr255s/
resources-fr255m/
resources-fr255sm/
resources-fr965/
```

A resource with the same ID in a device-qualified directory overrides the base resource for that device. Device qualifiers outrank family qualifiers.

### Family qualifiers

The relevant family paths are:

```text
resources-round/
resources-round-218x218/
resources-round-260x260/
resources-round-454x454/
```

Rules documented by the SDK:

- Screen shape must be present.
- Shape comes before size.
- `resources-218x218` is invalid.
- `resources-218x218-round` is invalid.
- A more-specific family qualifier overrides a less-specific qualifier for matching resource IDs.
- A device qualifier overrides family qualifiers.
- A device qualifier and family qualifier may not coexist in the same directory name; for example, a folder analogous to `resources-round-fr255` is skipped by the resource compiler.

The 218px family qualifier naturally groups `fr255s` and `fr255sm`. The 260px family qualifier naturally groups `fr255` and `fr255m`. Geometry-specific layouts can therefore avoid Music/non-Music duplication.

### Localization qualifiers

Localization qualifiers use ISO 639-2 codes and come last:

```text
resources-zhs/
resources-round-zhs/
resources-round-218x218-zhs/
resources-fr255s-zht/
```

Language-specific resource paths are ignored unless that language is also declared in the manifest. The current manifest declares `eng`, `zhs`, and `zht`.

### Resource precedence

In Jungle path lists, resources are processed left to right, so later paths can override earlier resources with the same ID. Preserving inherited paths with `$(qualifier.resourcePath)` allows unmatched resources to fall back. Replacing a resource path without dereferencing the inherited value removes that fallback.

Directory qualifiers are likely sufficient if differences are limited to layouts, bitmap resources, fonts, or styles with shared IDs. They do not require adding custom path rules because `default.jungle` already recognizes the relevant directories.

## Jungle source and resource alternatives

Jungle files support global, shape/family, and exact-product configuration. Relevant properties documented in `Jungle_Reference.html` are:

```text
sourcePath
resourcePath
personality
lang
excludeAnnotations
barrelPath
annotations
```

Allowed scopes include:

```text
base
round
round-218x218
round-260x260
round-454x454
fr255
fr255s
fr255m
fr255sm
fr965
```

Examples, presented as alternatives rather than a recommendation:

```text
# Preserve inherited resources, then add a shared small-screen override.
round-218x218.resourcePath = $(round-218x218.resourcePath);resources-small

# Add source only to the 260px family.
round-260x260.sourcePath = $(round-260x260.sourcePath);source-260

# Add a device-specific AMOLED implementation.
fr965.sourcePath = $(fr965.sourcePath);source-amoled
```

Important behavior:

- Source paths control which `.mc` files are compiled and can omit whole implementations from a target.
- Resource paths control resources considered for a target.
- Relative paths resolve against the custom Jungle’s parent directory.
- Relative paths in `default.jungle` resolve against the manifest’s parent.
- Multiple `-f` Jungle files may be separated by semicolons or colons.
- Later Jungle files have precedence over earlier files.
- Exactly one project manifest may be resolved across the Jungle set.
- The default Jungle is applied before custom Jungles.
- `-m`, `-x`, `-z`, and direct source-path command-line approaches are deprecated; mixing them with `-f` is an error.

There is no documented display-technology qualifier such as “MIP” or “AMOLED.” If a distinction follows resolution, family qualifiers are sufficient. If it specifically follows display technology, exact product mappings or explicit shared paths are needed.

## Annotation exclusions

Monkey C declarations can be annotated, for example:

```monkeyc
(:smallScreen)
function implementation() {
}
```

A Jungle can exclude annotated declarations:

```text
base.excludeAnnotations = smallScreen
round-218x218.excludeAnnotations = largeScreen
```

The documentation allows exclusions on modules, classes, methods/functions, and variables. This is finer-grained than source-path selection and can remove dead declarations for a target, including alternative implementations of the same symbol.

Potential implications:

- Annotation exclusions can recover code/data space without splitting an entire source file.
- Source-path separation is clearer when whole implementations or datasets differ.
- Runtime feature/dimension checks keep one source path but ordinarily retain both code paths unless the compiler proves a target constant and removes one.
- Any exclusion design must ensure each target retains exactly one required implementation.

The deprecated command-line `-x` exclusion option should not be introduced; custom Jungle properties are the supported mechanism.

## Geometry architecture options, without a selected design

The screen ratios alone do not select an architecture. Relative to 454px, 260px is about 0.573 and 218px is about 0.480, while built-in font metrics do not scale by those same factors. For example, worldwide `FONT_XTINY` is 19px on both 255 sizes but 37px on `fr965`; scaling the current 42px row pitch to 218px would yield about 20px, smaller than the font plus current padding. Any “normalized geometry” option therefore needs font-aware layout/reflow rather than blind scalar multiplication.

| Option | Viability and prerequisites | Advantages | Costs and risks | Migration impact | Reversibility | Discriminating check |
|---|---|---|---|---|---|---|
| Shared adaptive `PolarFinderView` with normalized/font-derived geometry | Viable if `onLayout` computes and caches center, safe bounds, row pitch, widths, and screen-specific vertical anchors. Reticle helpers must accept center/radius. Avoid allocating profile dictionaries/arrays every `onUpdate`. | One behavior/state implementation; future-resolution friendly; lowest long-term drift. | Largest initial refactor; 218px needs semantic reflow/scrolling, not simple scaling; translated strings and circular clipping complicate formulas. | Touches every renderer/helper/tap mapping listed in the callsite audit, but leaves model/calculation/delegate behavior shared. | High if geometry is isolated behind a small profile interface. | Prototype a cached profile for 218/260/454; capture every screen/state in eng/zhs/zht; check selected-row visibility, editor density, Details wrapping, generic result, and complete iOptron display. |
| Shared view plus three per-resolution geometry providers | Viable through `round-218x218.sourcePath`, `round-260x260.sourcePath`, and `round-454x454.sourcePath`, each providing exactly one implementation of the same compact profile contract. Specialized roots must not sit below recursively scanned `source/`. | Explicit tuned values; no per-frame target branch; only three families, not five models; shared behavior remains single-copy. | Profile/view boundary can become leaky; must prove source-path selection avoids duplicate/missing symbols. | Moderate: refactor hard-coded values to profile access, add three small source roots and Jungle mappings. | High; providers can later collapse into one adaptive profile. | Temporary providers containing only center, safe bounds, row/highlight metrics, and reticle radius; compile all five and compare screenshots plus build stats. |
| Three per-resolution complete view classes | Technically viable through family source paths and the construction seam at `PolarFinderApp.mc:14-18`. | Maximum freedom where 218px requires different information density or interaction. Each binary can include only its selected class. | High duplication of GPS, editing, focus, cancellation, timers, errors, calculation, and input semantics; fixes can drift across three views. XML resources do not remove this cost because current rendering is custom. | High; tests and construction/factory logic split by family. | Low to medium. | Attempt only one difficult screen first. Choose this only if profile prototypes cannot express genuinely different content/interaction requirements. |
| Annotation-selected geometry/functions in one source | Viable for a few compact declarations if Jungle exclusions leave exactly one implementation per target. | Co-locates alternatives; compiler omits excluded declarations; useful for small constants or touch/non-touch delegate fragments. | Configuration is less transparent; duplicate/no-symbol failures are easy; whole-view alternatives become unreadable. Exact multiple-exclusion syntax should be proven locally. | Low for tiny seams, high and unattractive for full views. | High for small seams; low for large annotated duplicates. | Minimal temp project with three same-symbol annotated implementations and all five targets; inspect selected symbols and sizes before applying the pattern. |
| Family/device resource-qualified layouts | Immediately viable for launcher icons. UI viability requires deliberately wiring `MainLayout`/drawables into the source first. | Resource compiler already defines specificity/fallback; strong fit for static assets and XML-driven drawables. | Current `onLayout` is empty and no layout resource is loaded, so layout XML overrides alone change nothing. A full resource-backed UI migration is a separate design. | Low for icons; very high for the entire current custom-drawn UI. | High for asset overrides; medium after UI rewrite. | Compare shared auto-scaled icon with 40×40 family overrides; separately prototype one resource-backed screen before considering wholesale migration. |

Touch handling is orthogonal to geometry. The 27/27 FR255 test run shows a single delegate containing touch methods is compatible. Annotation- or source-selected non-touch delegates remain an optional size/clarity experiment, not a prerequisite.

### Alternative resulting directory trees

**Adaptive shared view/profile:**

```text
manifest.xml
monkey.jungle
Makefile
source/
  PolarFinderApp.mc
  PolarFinderView.mc
  PolarFinderDelegate.mc        # optional split; one shared implementation
  DisplayProfile.mc             # adaptive cached geometry
  PolarFinderModel.mc
  IoptronReticle.mc             # center/radius supplied by caller/profile
  Astrometry.mc
  EarthData.mc
resources/
  strings/strings.xml
  drawables/drawables.xml
resources-round-218x218/
  drawables/launcher_icon.png    # generated/tuned 40x40
resources-round-260x260/
  drawables/launcher_icon.png    # generated/tuned 40x40
resources-zhs/strings/strings.xml
resources-zht/strings/strings.xml
tests/
  AstrometryTests.mc
artwork/launcher-icon.svg
```

**Shared view with selected family providers:**

```text
manifest.xml
monkey.jungle
Makefile
source/
  PolarFinderApp.mc
  PolarFinderView.mc
  PolarFinderDelegate.mc
  PolarFinderModel.mc
  IoptronReticle.mc
  Astrometry.mc
  EarthData.mc
source-round-218x218/
  DisplayProfile.mc
source-round-260x260/
  DisplayProfile.mc
source-round-454x454/
  DisplayProfile.mc
resources/
  strings/strings.xml
  drawables/drawables.xml
resources-round-218x218/drawables/launcher_icon.png
resources-round-260x260/drawables/launcher_icon.png
resources-zhs/strings/strings.xml
resources-zht/strings/strings.xml
tests/
  AstrometryTests.mc
artwork/launcher-icon.svg
```

**Complete family views, retained only as an alternative:**

```text
source/                       # model, app/factory, calculation, shared helpers
source-round-218x218/PolarFinderView.mc
source-round-260x260/PolarFinderView.mc
source-round-454x454/PolarFinderView.mc
```

This last tree is clean only if non-visual behavior is first extracted from the view; otherwise it institutionalizes three copies of the same state machine.

Moving tests out of `source/` requires a test-only Jungle/source path. The local compiler’s source discovery is recursive, so target-specific roots must be siblings of `source/`, not children. The existing unused `resources/layouts/layout.xml` should eventually be either wired into a deliberate resource-backed design or removed in a clean cutover; retaining it beside a second layout convention is misleading.

## Monkey Barrels

The current manifest has an empty `<iq:barrels />`, and no barrel is needed merely to add these four product IDs.

For completeness, the SDK documents:

- `base.barrelPath` or device/family `barrelPath` for directories, `.barrel` files, or dependent barrel-project Jungle files.
- Bracket grouping for multiple Jungle files from a barrel project.
- `<qualifier>.<BarrelModule>.annotations` for importing selected annotated barrel portions.
- A corresponding manifest dependency such as `<iq:depends name="..." version="..." />`.
- Exact, minimum (`>=`), pessimistic (`~>`), or unspecified version constraints.

Barrel paths alone are insufficient; dependencies must also be declared in the manifest.

## Build-system options, without a selected design

### Option A: retain single-device builds

- Add the four product IDs to the manifest.
- Retain `DEVICE ?= fr965`.
- Build or test another target through `make DEVICE=<id> ...`.
- Keep fixed output names because only one target is built at a time.

Implication: minimal build-system change, but no automatic compatibility matrix and artifacts are overwritten between devices.

### Option B: add loose per-device artifacts

- Define a product list containing all five IDs.
- Produce device-qualified outputs.
- Preserve a single-device target for simulator/run workflows.

Implication: each target can be inspected or deployed independently, but loops/rules and cleanup become more involved.

### Option C: add an export/package target

- Invoke `monkeyc -e` once.
- Produce a `.iq` package containing every manifest product.

Implication: matches store/export packaging and avoids loose-name collisions. It is not a substitute for individual simulator verification.

### Option D: combine matrix and package workflows

- Use per-device builds as compatibility checks/development artifacts.
- Use one package target for distribution.

Implication: strongest build coverage, with additional build time and Makefile surface.

### Tests and simulator runs

The original research did not establish automated profile switching or visually inspect a simulator. A later isolated manifest-expanded run did compile a unit-test PRG with `-t -d fr255` and execute it using `monkeydo ... fr255 -t`. All 27 tests printed `PASS`, ending with:

```text
PASSED (passed=27, failed=0, errors=0)
```

This included `displayDelegateSeparatesTouchFromPhysicalButtons` from `source/AstrometryTests.mc:424-457`. That test constructs `PolarFinderDelegate` on the FR255 runtime and manually invokes behavior callbacks, `handleTap`, `handleSwipe`, and physical-key handling. It proves that the touch callback declarations compile and can exist/invoke safely against the API-5.2 FR255 profile. It does **not** prove that non-touch hardware delivers touch events; installed `simulator.json` says `display.isTouch=false`, so natural touch delivery is not expected. It also does not prove visual fit, complete button-only reachability, pressure/GPS behavior, production calculation, or runtime heap headroom. `monkeydo` returned status 1 after the validated passing summary, matching the Makefile’s documented test-runner quirk.

## Code-space removability audit

The user requested isolated experiments concerning dated Earth-orientation data, the test-only synchronous astrometry path, and obvious unreferenced SOFA routines/data. All modifications below were made only in temporary source copies.

### Baseline

The baseline is the production build described above:

```text
Foreground data: 152,168 B
Foreground code: 47,168 B
Combined:        199,336 B
PRG:             350,956 B on fr255
                 359,756 B on fr965
```

### Experiment 1: remove EOP rows before 2026-09-10

`source/EarthData.mc` documents its EOP data as IERS Bulletin A predictions downloaded 2026-09-09 and covering 2026-09-09 through 2027-09-11.

The first row was:

```text
MJD 61292.0 — 2026-09-09
```

Only that row precedes 2026-09-10. The temporary experiment:

- Removed MJD 61292.
- Changed the lower accepted bound from 61292 to 61293.
- Changed result `:first` and `firstDate()` to 61293.
- Left the upper bound 61659 unchanged.

Results:

| Target | Data | Code | Combined | Combined delta | PRG | PRG delta |
|---|---:|---:|---:|---:|---:|---:|
| `fr255` | 152,129 | 47,159 | 199,288 | −48 | 351,276 | **+320** |
| `fr965` | 152,129 | 47,159 | 199,288 | −48 | 360,076 | **+320** |

Both production builds succeeded. The behavioral change is explicit: MJD 61292 becomes unsupported instead of interpolable, and reported coverage starts at MJD 61293.

This was not a PRG-size win. Removing one record reduced compiler-reported foreground memory by 48 bytes but increased the serialized PRG by 320 bytes, plausibly because of representation/alignment/compression layout. That explanation is an inference; the measured fact is the counter-directional delta.

The experiment was explicitly rebuilt on representative `fr255` and `fr965` targets. Since all four 255 baselines had identical stats and PRG sizes, the same delta is expected across the 255 variants, but it was not separately measured on `fr255s`, `fr255m`, and `fr255sm`.

### Experiment 2: remove `atco13` and `calculate`

`source/Astrometry.mc` contains:

- A full synchronous `atco13` implementation beginning at the then-current source line 2535.
- A one-line `calculate` wrapper at line 2622.
- A resumable production API, `begin` and `step`, beginning at lines 2286 and 2469.

Production callers in `source/PolarFinderView.mc` use:

```text
Astrometry.unixSecondsToJulianDate
Astrometry.begin
Astrometry.step
Astrometry.cancel
```

No production source calls `Astrometry.calculate` or `Astrometry.atco13`. `source/AstrometryTests.mc` calls `calculate` at lines 58, 86, and 126.

The temporary experiment removed only `atco13` and `calculate`, retaining their helper routines.

| Target | Data | Code | Combined | Combined delta | PRG | PRG delta |
|---|---:|---:|---:|---:|---:|---:|
| `fr255` | 152,150 | 45,386 | 197,536 | −1,800 | 348,140 | −2,816 |
| `fr965` | 152,150 | 45,386 | 197,536 | −1,800 | 356,940 | −2,816 |

Production builds succeeded.

A unit-test compile was intentionally attempted to identify the contract impact:

```text
ERROR: .../source/AstrometryTests.mc:58,4: Undefined symbol ':calculate' detected.
ERROR: .../source/AstrometryTests.mc:86,4: Undefined symbol ':calculate' detected.
ERROR: .../source/AstrometryTests.mc:126,4: Undefined symbol ':calculate' detected.
```

The compiler exited with status 100. Removing this path therefore requires migrating or removing tests that depend on the synchronous oracle. It must not be described as a behavior-free test cleanup without addressing that loss of reference coverage.

### Experiment 3: remove the now-unreferenced synchronous helper chain

After removing `atco13` and `calculate`, a declaration/call scan found the following synchronous-only routines with no remaining callers:

```text
epv00
pnm06a
s06
nut06a
s06ev
nut00a
```

The temporary experiment removed those six routines as well.

| Target | Data | Code | Combined | Combined delta from baseline | PRG | PRG delta from baseline |
|---|---:|---:|---:|---:|---:|---:|
| `fr255` | 152,096 | 42,433 | 194,529 | −4,807 | 343,724 | −7,232 |
| `fr965` | 152,096 | 42,433 | 194,529 | −4,807 | 352,524 | −7,232 |

Incremental savings beyond removing `atco13`/`calculate` alone were:

```text
Data:     54 B
Code:  2,953 B
PRG:   4,416 B
```

Production builds succeeded. The test incompatibility remained because tests still referenced `calculate`.

### Experiment 4: production inclusion of `(:test)` declarations

`source/AstrometryTests.mc` lives under the production `source/` tree. Its test functions carry `(:test)`, but a normal build without `-t` still included measurable declaration/code/data weight; `(:test)` marks discoverable tests and is not itself a production exclusion annotation.

In the second experiment series, removing only `AstrometryTests.mc` from the source tree produced:

| Variant | Data | Code | Combined | PRG |
|---|---:|---:|---:|---:|
| Same-series baseline | 152,168 | 47,168 | 199,336 | 351,260 |
| No test source | 152,025 | 47,015 | 199,040 | 350,508 |
| Savings | **143** | **153** | **296** | **752** |

This is a modest but real production saving. A clean migration can move `AstrometryTests.mc` to a sibling `tests/` directory and append that directory only for test builds. It should not place tests below `source/`, because source discovery is recursive. This organizational change is independent of whether the synchronous oracle is retained.

### Experiment 5: flattened EOP with implicit MJD

The dated `EOP` table has 368 daily rows. Each row stores four values: MJD, DUT1, xp, and yp. Because MJD increases by exactly one per row, a temporary candidate stored only a flat sequence of 1,104 values:

```text
[dut1_0, xp_0, yp_0, dut1_1, xp_1, yp_1, ...]
```

The row index was derived from `floor(mjd - 61292)`, the interpolation weight from the fractional remainder, and the flat offsets from `index * 3`. Bounds, `:first`, `:last`, and warning semantics remained explicit.

This was measured relative to the **same no-synchronous-chain baseline** in the second harness:

| Variant | Data | Code | Combined | PRG |
|---|---:|---:|---:|---:|
| No synchronous chain, original row arrays | 151,953 | 42,280 | 194,233 | 342,892 |
| Same candidate plus flat implicit-MJD EOP | 143,140 | 39,104 | 182,244 | 330,892 |
| Savings attributable to representation | **8,813** | **3,176** | **11,989** | **12,000** |

The surprisingly large code saving indicates that nested literal construction/indexing has material compiled cost, not just four versus three stored numeric values per row. Production compilation succeeded. For a narrow smoke check, the original 27-test suite was restored around the flattened `EarthData.mc`; all 27 tests passed, including the existing Earth-data boundary/interpolation test. That is encouraging but not exhaustive: the current test samples only selected boundaries/interpolation/rejection behavior, and it does not compare every row boundary and fractional interval against the original table.

Before adopting this representation, generate or run an exhaustive equivalence harness covering all 368 exact MJDs, representative fractional positions in all 367 intervals, first/last/warning bounds, and values immediately outside the range. Compare every returned key and numeric value to the original implementation within a tolerance justified by identical inputs/arithmetic. Also inspect allocation behavior: flattening removes hundreds of nested row arrays and is likely favorable, but no runtime heap measurement was made.

### Reduction safety matrix

“Safe” below means evidence supports considering the change with the stated prerequisite; it does not pre-decide adoption.

| Candidate | Reachability/evidence | Safety category | Required proof or constraint |
|---|---|---|---|
| Move `AstrometryTests.mc` to test-only source path | Normal builds measurably include it; production has no calls to test declarations. | Safe organizational reduction | Production build all five; test build/run at least representative 218/260/454 targets; ensure test Jungle adds the sibling `tests/` root. |
| Remove `calculate`, `atco13`, and synchronous-only chain | No production calls; measured production savings. Tests use `calculate` as an oracle. | Conditionally safe | First replace with durable independent SOFA/ERFA expected vectors and exercise production `begin`/`step`; then remove the entire dead chain in one clean cutover. |
| Remove `EarthData.firstDate`/`lastDate` | No repository callers; constants are also returned from `eop`. | Likely safe but tiny | Compile tests/production and verify no external/public compatibility promise requires them. Do not confuse accessor removal with data-window truncation. |
| Flatten EOP and infer MJD | Daily spacing is contiguous; measured 12,000-byte PRG reduction against same no-sync baseline. | Promising, conditionally safe | Exhaustive old/new equivalence, boundary/warning checks, and runtime/allocation smoke test. Preserve explicit first/last constants and documented provenance. |
| Prune expired EOP rows | Rows are forecast records and old coverage may cease to be useful. One-row removal saved 48 static bytes but grew PRG 320 bytes. | Policy-dependent, not automatically useful | Define supported date window first; compare meaningful windows within one build series; test boundary behavior. |
| Remove or truncate `LEAPS` | Historical rows feed UTC→TAI via `dat`/`utctai`, which is production-reachable. Old effective dates are algorithmic history, not expired forecast rows. | Unsafe without a mathematically proven replacement | Preserve the value applicable throughout every supported UTC date, pre-1972 handling if part of the adopted algorithm, and leap-boundary semantics; exhaustive reference vectors required. Current audit does not justify removal. |
| Remove or coarsen `GEOID` | `mslToEllipsoid` is production-reachable and observing height affects astrometry. | Unsafe as deletion; quantization is an accuracy/product decision | Establish acceptable final pointing error, test all lattice cells/boundaries/poles/wrap, and compare end-to-end output—not only geoid meters. |
| Prune returned result keys | `PolarFinderView` consumes status, progress, altitude, hour angle, pole distance, warning, and errors across calculation/display paths. A temporary key-pruning build saved little relative to mathematical data changes. | Unsafe unless complete consumer contract is remapped | Search symbol-key consumers and tests, then exercise success/error/cancel/display. Do not drop a key merely because one renderer does not use it. |
| Truncate SOFA coefficient series | Arrays remain reachable from production `begin`/`step`; coefficients encode epoch mathematics, not stale rows. | Unsafe absent a defined accuracy budget | Compare against authoritative SOFA/ERFA vectors over full supported dates/locations, propagate error to displayed pole position, and test worst cases. |
| Binary-pack coefficients/EOP | Could reduce literal/object overhead, but would add decoding code and possibly transient allocation. No measurement was made. | Experimental | Prototype in a same-series build; compare static/PRG/runtime heap/time and exhaustive numerical equivalence. Prefer direct indexed decoding without per-call reconstructed arrays. |
| Quantize EOP/GEOID/coefficients | May reduce data only if compiler representation actually changes; numerical error can accumulate nonlinearly. | Experimental/high risk | Specify units and worst-case error budget first; sweep full domains and compare final observable alignment values. Avoid decimal truncation justified solely by PRG size. |

Coefficient-array source text size is not the same as compiled memory. The large `xls`/`xpl` and `e*/s*` arrays dominate source text, but compiler stats and end-to-end numerical behavior—not textual byte counts—must decide any representation experiment.

### Arrays and data that were not removable

The large arrays named `e0*`, `e1*`, `e2*`, `s0*`, `s1*`, `s2*`, `xls`, `xpl`, and `s06_s*` remain directly consumed by the resumable `begin`/`step` calculation path. They did not become unreferenced when the synchronous helpers were removed.

These coefficient arrays encode mathematical ephemeris, nutation, and CIO model series. They are not dated forecast records and must not be pruned merely because they contain date-like or old-looking coefficients. Their mathematics is intended to evaluate epochs rather than represent a downloaded day-by-day freshness window.

Other audited items:

- `unixSecondsToJulianDate` has no internal Astrometry caller but is used by production UI code.
- `cancel` has no internal caller but is used by production UI code.
- `GEOID`, `geoidOffset`, and `mslToEllipsoid` are used in production.
- `EOP` and `eop` are used in production.
- `LEAPS` is historical UTC conversion data used through `dat`/`utctai`; its old rows are semantically necessary for conversion over the accepted date range, not stale forecasts.

No obviously unreferenced coefficient array or production Earth dataset emerged from the static scan.

### Runtime limits of the code-space experiments

The FR255 simulator executed the unchanged 27-test suite, and the flattened-EOP candidate later passed those same tests. No complete production calculation was executed, no numerical old/new comparison covered every EOP row/interval, and no runtime comparison was run after synchronous-chain removal. Production compilation does not establish runtime equivalence.

The existing synchronous path serves as a test oracle/reference. If it is removed, preserve meaningful numerical regression coverage through independent expected values rather than merely deleting failing tests. A test that compares resumable output only with code derived from the same implementation may share the same defect and is not an independent oracle.

## Open decisions

The research intentionally does not choose among these decisions:

1. Whether to retain a one-device Makefile workflow or add a five-device build matrix.
2. Whether to add a store-style `.iq` package target.
3. Whether loose artifacts should use per-device names or directories.
4. Whether geometry should use one adaptive view, one view plus per-resolution providers, complete per-resolution views, or narrowly annotated declarations.
5. Whether MIP/AMOLED differences justify separate resources despite shared round geometry.
6. Whether a single auto-scaled launcher source is visually adequate on 40×40, 64-color MIP targets.
7. Whether the two 218×218 models can share one complete resource/layout set and the two 260×260 models another.
8. Whether touch callbacks should remain in the shared delegate—the tested-compatible simplest option—or be excluded for a measured reason.
9. Whether to move `AstrometryTests.mc` to test-only source selection, preserving the measured 752-byte production PRG saving.
10. Whether to retain the synchronous astrometry reference path or replace its oracle before removing it.
11. Whether to adopt flat implicit-MJD EOP after exhaustive equivalence testing.
12. Whether trimming dated EOP rows is worthwhile given that one-row removal increased PRG size.
13. Whether to package locale-specific layout/font overrides for Chinese and other font sets.
14. How much static compiler headroom is sufficient before runtime heap profiling.

## Discriminating experiments

The following experiments would provide evidence needed for those decisions:

### UI and input

- Launch and inspect the actual app in `fr255s`/`fr255sm` at 218×218, including every screen, dialog, error state, progress state, and reticle view.
- Repeat at 260×260 on one non-Music and one Music profile.
- Verify all actions using buttons only: focus order, selection, scrolling, back, menu, cancellation, and recovery after app inactive/active transitions.
- Inspect `fr965` afterward to ensure family-specific resources do not regress its 454×454 touch layout.
- Repeat critical text screens in `eng`, `zhs`, and `zht` because the built-in font metrics differ.

### Graphics and color

- Compare auto-scaled shared launcher output against a hand-tuned 40×40 resource in both 218px and 260px MIP simulators.
- Inspect every semantic color under the 64-color palette, especially antialiasing, thin lines, muted labels, and transparency assumptions.
- Exercise any drawing path that relies on alpha or enhanced graphics; those features are explicitly unavailable on the 255 profiles.

### Build configuration

- Create minimal temporary prototypes for pure directory qualifiers versus explicit Jungle paths and compare the compiler’s selected resource IDs.
- Build all five products after each candidate organization and inspect output sizes to determine whether shared-family resources actually reduce duplication or only improve organization.
- Test annotation/source-path alternatives with build stats to quantify recovered code/data, not merely source-line differences.
- For geometry specifically, build the same two hardest screens (dense editor/details and iOptron reticle) using (a) cached adaptive formulas and (b) selected family providers. Compare code/data, per-frame allocations, screenshots, and complexity; use complete family views only if both fail to express necessary interaction differences.
- Prove that specialized sibling source roots—not nested roots—select exactly one geometry implementation on every device.

### Runtime and memory

- Run a complete production calculation on `fr255` and `fr255s`, including pressure sampling, EOP lookup, resumable astrometry, cancel, restart, and result display.
- Measure runtime heap/high-water behavior if the simulator/tooling exposes it; static Data+Code headroom does not cover transient allocations.
- Compare calculation completion time and number of resumable steps across `fr255`, `fr255s`, and `fr965`.

### Astrometry cleanup

- Migrate synchronous-reference tests to fixed independent SOFA/ERFA vectors or another durable oracle in a temporary copy, then remove the synchronous chain and run the targeted test suite.
- Exercise the production resumable path before and after cleanup with identical inputs and compare every result field and status.
- Rebuild all five device profiles to confirm that the representative size deltas generalize exactly.
- If moving tests to `tests/`, separately prove production exclusion and test inclusion; do not rely on `(:test)` alone.
- For flattened EOP, compare all exact rows and multiple fractions per interval against the original implementation, including returned metadata keys and warning threshold.

### EOP retention

- Test larger, meaningful EOP retention windows rather than assuming row count correlates monotonically with PRG size.
- Compare compiler data/code, PRG size, and useful coverage for several lower bounds.
- Verify exact boundary and interpolation behavior at first row, interior row, last row, warning threshold, and one instant outside each bound.

## Phased implementation possibilities

These paths are alternatives and may be combined only after their decision gates pass. None is selected here.

### Path A: minimal compatibility, maximum reversibility

1. Add only the four exact product IDs to `manifest.xml`; retain API 5.2, app type, permissions, languages, and existing source/resources.
2. Compile all five products with current `DEVICE=<id>` operation. Keep loose artifacts temporary or device-qualified so evidence is not overwritten.
3. Run the existing test suite on representative 218px, 260px, and 454px profiles; retain the shared delegate unless a real input failure appears.
4. Launch the unchanged app at 218px and 260px and inventory clipping/unreachable actions screen by screen in all three locales.
5. Make no structural UI choice until that inventory distinguishes scaling/reflow from truly different content.

This path has the smallest initial diff and is easiest to revert, but “manifest builds” must not be mistaken for usable compatibility.

### Path B: shared adaptive geometry

1. Complete Path A’s visual/input inventory.
2. Extract center, circular safe bounds, font-derived row metrics, content widths, footer, and reticle radius into one cached `DisplayProfile`; pass center/radius into `IoptronReticle`.
3. Convert shared drawing/focus/tap helpers first, then migrate one screen at a time without duplicating navigation, GPS, storage, timers, or calculation.
4. Reflow/scroll dense 218px screens instead of multiplying every coordinate by `218/454`.
5. Verify each migrated screen on 218/260/454 and eng/zhs/zht, then remove all obsolete hard-coded geometry in a clean cutover.

This is future-resolution friendly and keeps behavior single-copy, but has the broadest coordinated source refactor.

### Path C: shared view with family-selected providers

1. Define the same minimal geometry contract as Path B.
2. Put exactly one provider in each sibling `source-round-218x218`, `source-round-260x260`, and `source-round-454x454` root; configure family `sourcePath` selection in `monkey.jungle`.
3. Compile all five targets immediately to catch duplicate/missing implementation selection.
4. Migrate shared renderers to the provider while keeping semantic behavior centralized.
5. If the three profiles converge after validation, fold them back into one adaptive provider; if not, retain explicit tuned values.

This makes resolution differences explicit and is highly reversible. It adds build configuration and can become brittle if profile-specific conditionals leak throughout the view.

### Path D: resource/visual-quality first

1. Keep current custom drawing while creating only proven launcher overrides for the 40×40, 64-color MIP profiles.
2. Compare auto-scaled and hand-tuned icons in both 218px and 260px simulators.
3. Prototype one XML/resource-backed difficult screen before proposing a full layout-resource migration; the current unused `layout.xml` provides no behavior by itself.
4. Add exact-device resources only for demonstrated Music/non-Music differences; installed metadata currently supports resolution-family grouping.

This isolates low-risk visual assets. It does not solve hard-coded source geometry.

### Path E: build/repository hygiene

1. Move `AstrometryTests.mc` to sibling `tests/` and give test compilation an explicit test source path; verify the measured production exclusion and 27-test discovery.
2. Optionally split `PolarFinderDelegate.mc` or `DisplayProfile.mc` only when that creates a real selection seam; do not split files for cosmetic symmetry.
3. Add device-qualified loose outputs if multi-device builds are needed, then a five-target compile target.
4. Add a separate store-style `-e` package target only if release workflow needs it; keep simulator/run single-device selectable.
5. Decide the fate of unused `resources/layouts/layout.xml`: wire it as part of an intentional design or delete it rather than maintaining a false second convention.

These changes can precede or follow UI work, but each should be independently buildable and reversible.

### Path F: astrometry/data reduction, isolated from compatibility

1. Preserve output contracts and establish independent SOFA/ERFA vectors for production `begin`/`step`.
2. Remove `calculate`, `atco13`, and all six synchronous-only helpers together; run targeted production calculations before/after and rebuild all five products.
3. Evaluate flat implicit-MJD EOP as a separate commit/experiment. Exhaustively compare all rows, fractions, bounds, metadata, and warning behavior; measure runtime allocations/time as well as the same-series 12,000-byte PRG saving.
4. Decide EOP retention policy separately from representation. A compact full window may eliminate the incentive to prune useful days.
5. Do not truncate `LEAPS`, GEOID, or SOFA coefficient series without an explicit accuracy/support contract and authoritative end-to-end evidence.

This path offers the largest measured space reduction but is not required for FR255 memory limits and must not be bundled with geometry changes; isolation preserves attribution and makes rollback possible.

## Uncertainties and non-claims

- No application screen was visually inspected in a 255 simulator during this research.
- No naturally delivered button or touch interaction was exercised. The FR255 tests manually invoked delegate key/touch methods; that is API/logic evidence, not hardware-delivery or end-to-end navigation evidence.
- No production calculation was run on a simulator or physical device.
- No runtime heap peak was measured.
- Compiler-reported foreground Data+Code and arithmetic headroom are static evidence, not runtime guarantees.
- The local profiles expose `connectIQVersion` 5.2.0 but do not document a distinct later maximum runtime API.
- SDK 9.1.0 is the compiler/documentation version and must not be reported as the 255 devices’ runtime API level.
- Per-pruning builds were run on representative `fr255` and `fr965`; they were not repeated on all three other 255 variants.
- Equal baseline stats across all four 255 profiles support, but do not prove, identical pruning deltas.
- The EOP PRG-growth explanation is inferred; only the measured size increase is factual.
- Successful compilation after synchronous-path removal does not prove numerical runtime equivalence.
- The flattened EOP candidate passed the existing 27 tests, but those tests are not exhaustive old/new equivalence over all rows and intervals.
- Loose PRG totals differed by 304 bytes between independent harnesses despite identical reported Data/Code; only within-series PRG deltas are treated as comparable.
- Installed simulator profiles establish availability, not visual or behavioral correctness.

## Concise factual boundary

The local SDK accepts `fr255`, `fr255s`, `fr255m`, `fr255sm`, and `fr965`.
The implemented app now declares and compiles all five while preserving API
5.2.0. One shared behavior/view implementation adapts cached geometry for the
218×218, 260×260, and 454×454 round profiles, including fully parameterized
iOptron marker geometry and button access to every action. Family-qualified
40×40 launcher resources serve the 64-color MIP targets. Automated tests cover
adaptive focus visibility, button/touch delegate semantics, and reticle
geometry; simulator appearance, natural hardware event delivery, and runtime
heap peak still require human or physical-device verification.
