# UI/UX Design

## Status

Confirmed design baseline for the Polar Finder watch app.

Target:

- Garmin Forerunner 965
- Connect IQ API 5.2.0
- 454×454 round AMOLED display
- English, Simplified Chinese, and Traditional Chinese
- Complete touch and physical-button operation

## Product flow

The app has three user-visible phases:

1. **Locate** — acquire, enter, review, and confirm the observing location.
2. **Calculate** — run the astronomical transformations in watchdog-safe chunks while reporting genuine progress.
3. **Display** — show the current Polaris hour angle, pole distance, and local time.

The primary state flow is:

```text
Locate/Review ──> Acquire GPS ──> Locate/Review
      │
      ├────────> Manual editor ─> Locate/Review
      │
      └────────> Calculate ─────> Display
                       │              │
                       ├─ cancel ─────> Locate/Review
                       └─ failure ────> Calculation error
```

## Global interaction model

The complete workflow must work with touch or physical buttons.

Standard button behavior:

- **Up/Down**: move focus or change the selected component.
- **Start/Select**: open or confirm the focused action.
- **Back**: cancel the current edit or move one navigation level upward.
- **Tap**: select or confirm.
- **Swipe/touch scrolling**: move through rows.

Focused controls use more than color: a high-contrast outline, a slight background fill, and a shape or positional marker. No important state is communicated through color alone.

Back navigation is hierarchical:

- Value editor: discard the provisional field edit.
- Location review: return to the source choice or exit when already at the root.
- Calculation: cancel at the next safe chunk boundary.
- Display: return to location review.

When confirmed location changes would otherwise be lost, Back asks whether to discard them. Untouched screens do not show redundant confirmation prompts.

## Visual direction

Calculate and Display use a dark-site presentation:

- black background;
- dim red primary text;
- subdued gray secondary text;
- warnings and focus states distinguishable without color alone;
- no white full-screen flashes.

The Display layout remains fixed. No burn-in mitigation movement is required.

All screens and messages ship in English, Simplified Chinese, and Traditional Chinese. Layouts must accommodate the longest translation. Numerical notation and astronomical symbols may remain language-neutral.

## Locate phase

### Location review

Manual entry, GPS acquisition, and persisted locations converge on one canonical review screen. The screen contains:

- latitude;
- longitude;
- elevation above mean sea level;
- location source;
- GPS quality when applicable;
- coordinate-format toggle;
- Atmosphere row;
- Calculate action.

The first launch starts with empty location fields. It must not present `0°, 0°` as though it were a valid default. A compact first-use explanation says that GPS or an entered observing location is needed to calculate Polaris alignment. It disappears after the first successful calculation and remains available through Help.

Later launches preload the last confirmed location, visibly identify it as saved, and show its saved time and source. The user must explicitly confirm it or acquire a fresh fix before calculation. Saved coordinates do not expire merely because they are old; permanent observing sites remain valid.

The app persists only confirmed inputs and preferences:

- last confirmed location;
- coordinate-format preference;
- atmospheric overrides and pressure mode;
- calculation-alert preference.

It does not persist active GPS acquisition, partial edits, progress, calculated results, or transient warnings. Relaunch always returns to Locate rather than restoring time-sensitive results.

### GPS acquisition

GPS acquisition is a dedicated full-screen view. It shows:

- acquisition state;
- elapsed search time;
- latest coordinates and MSL elevation;
- Garmin's reported quality category;
- actions to use the location, enter it manually, or cancel.

The app displays Garmin's actual categorical quality values rather than inventing accuracy in meters:

- Good GPS;
- Usable GPS;
- Poor GPS;
- Last known;
- Unavailable.

The first current valid fix enables **Use Location**, and acquisition continues improving the fix until the user confirms it. Poor or Last Known positions require an explicit warning acknowledgement. A Last Known position may be previewed immediately and includes its age when a timestamp is available.

GPS failure states remain distinct:

- Searching for GPS;
- Location unavailable;
- Permission required;
- No fix yet after 60 seconds.

Acquisition does not terminate at 60 seconds, and manual entry remains available in every state.

Confirming a fix stops acquisition. Later GPS updates never overwrite user edits. A modified GPS position is labeled **GPS, adjusted**.

### Manual coordinate editing

Latitude and longitude each open a dedicated component editor.

Decimal mode contains:

- hemisphere;
- integer digits;
- fractional digits.

DMS mode contains:

- hemisphere;
- degrees;
- minutes;
- seconds.

Latitude uses `N/S`; longitude uses `E/W`. Signed values are internal only. Elevation uses a signed numeric editor and displays meters.

Edits remain provisional until **Done** validates and commits the complete value. Back discards every change made since opening that editor. Impossible component values are prevented where practical, but temporary incomplete input is allowed. Full validation occurs on Done and returns focus to the first invalid component.

Validation rules:

- latitude degrees: `0–90`;
- longitude degrees: `0–180`;
- minutes and seconds: `0–59`;
- latitude at `90°` requires zero minutes and seconds;
- longitude at `180°` requires zero minutes and seconds.

Invalid components are rejected rather than silently normalized.

Display and edit precision:

- decimal coordinates: five fractional degrees;
- DMS coordinates: whole arcseconds;
- elevation: whole meters.

A canonical signed coordinate retains higher precision internally. Decimal and DMS are views of that value. Switching formats never changes it; only an explicit edit commits a new coordinate. The format applies to both coordinates and persists across launches. Decimal is the fresh-install default.

### Elevation datum

The user-facing elevation is **Elevation (MSL)** in meters because Garmin Position altitude is documented as elevation above mean sea level. Manual and GPS inputs use the same datum.

The calculation converts MSL elevation to ellipsoidal height through a documented bundled global geoid grid with bilinear interpolation. It must not silently treat MSL height as ellipsoidal height.

## Atmosphere settings

The Atmosphere screen contains:

- Pressure: Automatic, Manual, or Refraction off;
- Temperature;
- Relative humidity;
- Wavelength: Polaris visible preset.

Defaults:

- temperature: `10°C`;
- relative humidity: `50%`;
- wavelength: approximately `0.55 µm`, using documented typical Polaris/visible-light data.

Temperature and humidity may be manually overridden and persist. Wrist temperature is not treated as ambient air temperature.

### Pressure

Live pressure uses the watch's built-in barometer through `Toybox.Sensor`. This requires the manifest's `Sensor` permission in addition to the existing `Positioning` permission.

`Sensor.Info.pressure` is documented as sea-level-calibrated pressure in pascals, not local observer pressure. Automatic mode derives local observer pressure from:

- measured sea-level pressure;
- reviewed MSL elevation;
- configured temperature.

During each calculation, the app attempts to collect valid pressure samples for approximately 3–5 seconds. Null samples are rejected and valid samples are smoothed. A reading older than five minutes is stale.

Fallback order:

1. fresh barometer samples;
2. a recent valid barometer reading;
3. manually entered local observer pressure;
4. a standard-atmosphere estimate from elevation.

Estimated or reused pressure is visibly marked but does not require a blocking acknowledgement. Manual mode accepts **local observer pressure in hPa**, which maps directly to the astronomical routine. Refraction-off mode passes zero pressure.

Details shows both the measured sea-level pressure and the derived observer pressure, together with elevation, temperature, sample time, and fallback source.

Cached `Toybox.Weather.CurrentConditions.pressure` is weather data and is not a substitute for the onboard barometer.

## Calculate phase

The calculation is computationally significant and must keep the Connect IQ watchdog satisfied. It is divided into safe chunks that yield often enough for event and UI processing. Progress reflects real completed work; the app does not insert artificial delay.

The screen contains:

- **Calculating** title;
- determinate weighted progress bar;
- localized current-stage label;
- Back/cancel hint.

User-facing stages:

1. Reading pressure;
2. Loading Earth data;
3. Converting time;
4. Calculating Polaris;
5. Applying observer corrections;
6. Preparing display.

Calculation checkpoints may yield more frequently than visible progress redraws. The UI is redrawn at a readable cadence. No time-remaining estimate is shown.

Back requests cancellation. Cancellation is observed between safe chunks, all partial results are discarded, and the app returns to the reviewed location. There is no resumable computation checkpoint.

If the app becomes inactive during calculation, it discards the run. Returning with still-valid inputs automatically restarts calculation from the beginning at zero progress and briefly reports **Restarting calculation**. If the inputs or Earth data are no longer valid, it shows the applicable error instead.

Immediately before the final astrometric transformation, the app captures the authoritative UTC timestamp. Display uses elapsed time from that timestamp so pressure sampling and table work do not make the initial result stale.

On success, the app transitions automatically to Display and may issue one short vibration. Failure uses a distinct brief pattern. Haptics respect the system setting and an app-level **Calculation alert** toggle.

### Calculation failures

A failure replaces progress on the same screen. It shows the specific cause and appropriate actions:

- Back to location;
- Try again for transient failures;
- Details for table validity and technical diagnostics.

Retries are never automatic except for the defined restart after app interruption.

## Display phase

### Information hierarchy

The fixed result layout contains:

1. **Hour angle** — largest value, `HH:MM:SS` modulo 12 hours;
2. **Pole distance** — `MM′ SS″`;
3. **Local date and time** — smaller, with time following the watch's 12/24-hour preference;
4. compact location, provenance, or warning status.

In 12-hour local-time mode, a localized AM/PM marker is shown. The hour-angle format is independent of the watch clock preference.

Hour angle is normalized to `[00:00:00, 12:00:00)`. The shared zero/twelve reticle position is labeled consistently with the eventual physical-reticle convention; no hidden AM/PM bit is retained.

Short localized labels take precedence over verbose headings. Primary numerical values must not be shrunk merely to fit long labels.

### Live updates

While visible:

- local time updates once per second;
- hour angle advances from the authoritative calculation timestamp at the sidereal rate, approximately `1.0027379` hour-angle seconds per SI second;
- pole distance remains fixed for the display session;
- a periodic full recalculation re-anchors the result and prevents timer drift.

A system UTC discontinuity discards accumulated offsets and triggers recalculation. A timezone change affects local-time formatting immediately.

When returning from an inactive state, the app does not briefly present stale values as current. It dims or marks them unavailable, performs a full recalculation, and restores them only when fresh.

The app remains active while foregrounded, permits normal dimming, and restores normal power behavior when leaving Display. No continuous animation or layout shifting is required.

### Actions

Tap or Select opens a compact action menu:

- Recalculate;
- Location;
- Atmosphere;
- Details.

There are no hidden per-value tap shortcuts. Back returns directly to the location review.

## Astronomical output contract

The calculation ports the required SOFA `iauAtco13` transformations and uses a documented Polaris catalog record including epoch, proper motion, parallax, and radial velocity.

Main results:

- **Hour angle**: observer-corrected local apparent hour angle of Polaris, displayed modulo 12 hours as `HH:MM:SS`.
- **Pole distance**: `90° − observed declination`, displayed as arcminutes and arcseconds.

The main screen uses concise user-facing labels. Details names the precise reference frames and transformation outputs so pole distance is not confused with catalog polar distance.

### Geographic validity

Coordinate entry is global, but the Polaris result is operationally constrained:

- modeled apparent altitude above `5°`: calculate normally;
- apparent altitude above `0°` and below `5°`: calculate with **Polaris is very low; alignment may be unreliable**;
- apparent altitude at or below `0°`: block with **Polaris is not visible from this location**.

A mathematically computable but unusable Southern Hemisphere result is not presented as valid alignment guidance.

### Earth-orientation data

The app bundles a date-indexed Earth-orientation table containing current and future dates only. It interpolates inside the supported interval and never clamps, extrapolates, or silently substitutes zero polar motion.

Behavior:

- more than 30 days before expiry: normal;
- within 30 days of expiry: visible warning with the exact expiry date;
- before the first row or after the final row: calculation blocked.

An unsupported-date error shows the watch date and supported interval and directs the user to check the watch date or update the app. There is no in-app clock override.

## Details screen

Details is read-only and contains:

- full-precision coordinates and MSL elevation;
- location source and GPS quality;
- coordinate display using the user's Decimal/DMS and hemisphere preference;
- calculation UTC timestamp;
- measured sea-level pressure;
- derived local observer pressure passed to `iauAtco13`;
- temperature, humidity, and their sources;
- geoid model identity;
- Earth-orientation table row/date and validity interval;
- Polaris catalog provenance and epoch;
- full-precision hour angle and pole distance;
- explanations for active warnings.

Internal radians are not exposed in the normal Details view.

## Help content

Contextual Help explains:

- acquiring and editing location;
- Decimal and DMS formats;
- MSL elevation;
- Garmin GPS quality categories;
- atmospheric defaults and Refraction off;
- hour angle modulo 12;
- pole distance;
- Earth-data expiry.

Implementation-level SOFA documentation does not appear in the primary help flow.
