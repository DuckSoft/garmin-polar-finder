# UI/UX Design

## Status

Implemented multi-device baseline for the Polar Finder watch app. Automated
tests cover numerical, adaptive navigation, and parameterized reticle geometry
contracts; simulator appearance and physical-eyepiece alignment remain manual
release checks.

Targets:

- Forerunner 255 / 255 Music: 260×260 round, 64-color MIP, buttons
- Forerunner 255s / 255s Music: 218×218 round, 64-color MIP, buttons
- Forerunner 965: 454×454 round AMOLED, touch and buttons
- Connect IQ API 5.2.0 on every target
- English, Simplified Chinese, and Traditional Chinese
- Complete physical-button operation on every target

## Product flow

The app has three user-visible phases:

1. **Locate** — acquire, enter, review, and confirm the observing location.
2. **Calculate** — run the astronomical transformations in watchdog-safe chunks while reporting genuine progress.
3. **Display** — show either the current Generic numerical result or the selected reticle guidance.

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

The complete workflow must work with physical buttons on every target. The
Forerunner 965 additionally supports touch; the Forerunner 255 family does not.

Standard button behavior:

- **Up/Down**: move focus or change the selected component.
- **Start/Select**: open or confirm the focused action.
- **Back**: cancel the current edit or move one navigation level upward.

On the Forerunner 965:

- **Tap**: select or confirm.
- **Swipe/touch scrolling**: move through rows.
- On the result Display (Generic, iOptron, and Sifo), touch is wake-only and triggers
  no app action. Actions still open with Start/Select, and Back still returns to
  Locate.

Focused controls use more than color: a high-contrast outline, a slight background fill, and a shape or positional marker. No important state is communicated through color alone.

Back navigation is hierarchical:

- Value editor: discard the provisional field edit.
- Location review: return to the source choice or exit when already at the root.
- Calculation: cancel at the next safe chunk boundary.
- Display, either variant: return to location review.

When confirmed location changes would otherwise be lost, Back asks whether to discard them. Untouched screens do not show redundant confirmation prompts.

## Visual direction

Calculate and all three Display variants use a dark-site presentation:

- black background;
- Generic keeps its existing dim-red primary-text styling; iOptron and Sifo
  reticle geometry use Garmin full red `0xFF0000`, relying on the watch's
  nighttime dimming;
- subdued gray secondary text;
- warnings and focus states distinguishable without color alone;
- no white full-screen flashes.

Each Display variant has a fixed layout. No burn-in mitigation movement is required.

All screens and messages ship in English, Simplified Chinese, and Traditional Chinese. Layouts must accommodate the longest translation. Numerical notation and astronomical symbols may remain language-neutral.

One shared view and input state machine serves all devices. `DisplayProfile` is
cached from the drawing context during layout and supplies the display center,
circular safe bounds, font-aware row pitch, content widths, footer, and reticle
scale. Compact 218×218 and 260×260 profiles preserve content through scrolling
rather than duplicating or removing flows. The 454×454 profile retains the
roomier AMOLED presentation.

## Locate phase

### Location review

Manual entry, GPS acquisition, and persisted locations converge on one canonical review screen. The screen contains:

- latitude;
- longitude;
- elevation above mean sea level;
- location source;
- GPS quality when applicable;
- Coordinate Format row;
- Reticle row;
- Atmosphere row;
- Calculate action.

Reticle appears between Coordinate Format and Atmosphere. Up/Down or scrolling moves focus through the rows; Start/Select or tap opens the focused row's choices. Reticle offers **Generic**, **iOptron**, and **Sifo** (`一思佛` in both Chinese locales). Committing a choice returns focus to the Reticle row, while Back from an uncommitted choice discards it and returns to that row.

The first launch starts with empty location fields. It must not present `0°, 0°` as though it were a valid default. A compact first-use explanation says that GPS or an entered observing location is needed to calculate Polaris alignment. It disappears after the first successful calculation and remains available through Help.

Later launches preload the last confirmed location, visibly identify it as saved, and show its saved time and source. The user must explicitly confirm it or acquire a fresh fix before calculation. Saved coordinates do not expire merely because they are old; permanent observing sites remain valid.

The app persists only confirmed inputs and preferences:

- last confirmed location;
- coordinate-format preference;
- reticle preference;
- atmospheric overrides and pressure mode;
- calculation-alert preference.

It does not persist active GPS acquisition, partial edits, progress, calculated results, or transient warnings. Relaunch always returns to Locate rather than restoring time-sensitive results.

Generic is the reticle preference default. If the preference is absent, including after upgrade from a version that did not store it, the app resolves it to Generic.

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

The selected Reticle preference determines the fixed result layout:

- **Generic** retains the current numerical Display unchanged: hour angle as the largest value, pole distance, local date and time, and compact location, provenance, or warning status.
- **iOptron** uses the full static reticle, including both tick bands and the 1–12 numerals, with a live marker and two compact knocked-out readouts.
- **Sifo** uses the same shared graphic renderer but omits the complete outer 60–70 arcminute ring/tick band and all 1–12 numerals. Its angular scale expands so the retained 44′ circle occupies the same safe screen radius as iOptron's 70′ circle.

The Generic numerical Display presents hour angle as `HH:MM:SS` modulo 12 hours, pole distance as `MM′ SS″`, and local time according to the watch's 12/24-hour preference. In 12-hour local-time mode, a localized AM/PM marker is shown. The Generic hour-angle text format is independent of the watch clock preference.

The iOptron and Sifo markers use the full observed hour angle rather than the modulo-12 formatted text. Their upper readout reports the true polar-scope clock position, `normalize12(6 h − H / 2)`, corresponding to the marker direction; the lower readout presents fixed pole distance. Their shared geometry, optical transform, styling, and verification contract are defined in [Equatorial Mount Reticle Displays](ioptron-skyguider-pro-reticle.md).

Short localized labels take precedence over verbose headings on the Generic Display. Primary numerical values must not be shrunk merely to fit long labels.

### Live updates

While visible:

- local time on the Generic Display updates once per second;
- Generic hour-angle text and both graphical markers advance from the authoritative calculation timestamp at the sidereal rate, approximately `1.0027379` hour-angle seconds per SI second;
- pole distance remains fixed for the display session;
- a periodic full recalculation re-anchors the result and prevents timer drift.

A system UTC discontinuity discards accumulated offsets and triggers recalculation. A timezone change affects local-time formatting immediately.

When returning from an inactive state, the app does not briefly present stale values as current. It dims or marks them unavailable, performs a full recalculation, and restores them only when fresh.

The app remains active while foregrounded, permits normal dimming, and restores normal power behavior when leaving Display. Both graphical reticles are static; their marker and clock-position readout update once per second.

### Actions

On any Display variant, START/Select opens the existing compact action menu. Touch (tap or swipe) on the Display is wake-only and triggers no app action:

- Recalculate;
- Location;
- Atmosphere;
- Details.

There are no hidden per-value tap shortcuts. Back returns directly to the location review.

On a valid iOptron or Sifo result with an active warning, the graphic must render exactly one short overlay at the top, and the overlay must not cover the marker. The full warning and diagnostic explanation appears in Details. Pole distance outside the selected reticle's inclusive range is an explicit calculation error: `[0, 70]` arcminutes for iOptron and `[0, 44]` for Sifo. It is not clamped, and no result or silently clipped marker is shown. This range error uses the existing calculation-error actions—Back to location, Try again where applicable, and Details—rather than introducing another screen.

## Astronomical output contract

The calculation ports the required SOFA `iauAtco13` transformations and uses a documented Polaris catalog record including epoch, proper motion, parallax, and radial velocity.

Main results:

- **Hour angle**: observer-corrected local apparent hour angle of Polaris. Generic displays it modulo 12 hours as `HH:MM:SS`; graphical marker mapping consumes the full observed angle, while the upper readout converts it to true polar-scope clock position.
- **Pole distance**: `90° − observed declination`, displayed as arcminutes and arcseconds on Generic and used as the radial input on iOptron and Sifo.

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
- temperature, humidity, and wavelength, each shown with its source: temperature and humidity as the configured value, and wavelength as the Polaris-visible preset;
- geoid model identity;
- Earth-orientation table row/date and validity interval;
- Polaris catalog provenance and epoch;
- full-precision hour angle and pole distance;
- explanations for active warnings.

Each field uses a left-aligned label line followed by one or more right-aligned value lines. Values wrap only at safe boundaries when possible; selection encloses value lines only. Navigation and taps operate on whole fields and keep the focused field within the round-display safe area.

Internal radians are not exposed in the normal Details view.

## Help content

Contextual Help explains:

- acquiring and editing location;
- Decimal and DMS formats;
- MSL elevation;
- Garmin GPS quality categories;
- atmospheric defaults and Refraction off;
- Generic hour-angle text modulo 12;
- pole distance;
- Earth-data expiry;
- Reticle selection and iOptron/Sifo graphic guidance.

Implementation-level SOFA documentation does not appear in the primary help flow.
