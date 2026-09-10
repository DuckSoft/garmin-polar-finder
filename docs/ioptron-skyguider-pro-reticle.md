# iOptron SkyGuider Pro Reticle Display

## Status and scope

Implemented in the Forerunner 965 app. Automated geometry and marker tests and the application build pass; simulator and physical-eyepiece visual verification remain manual release checks.

The variant adds a static reticle and a live Polaris marker to the existing result flow. It does not change the Generic numerical Display, the astronomical calculation model, location entry, atmosphere handling, or the existing Actions and Details destinations. It does not add a brightness setting or attempt to model arbitrary polar-scope reticles.

## Display geometry

The design coordinate system is the Forerunner 965's `454×454` display, with center

```text
(cx, cy) = (227, 227)
R70 = 170 px
```

Screen `x` increases rightward and screen `y` increases downward. For a circle representing angular radius `theta` in arcminutes,

```text
r(theta) = R70 * theta / 70
```

The exact circles and their nominal pixel radii are:

| `theta` (arcmin) | Radius equation | Radius (px, approximate) |
| ---: | --- | ---: |
| 4 | `170 * 4 / 70` | 9.71 |
| 36 | `170 * 36 / 70` | 87.43 |
| 40 | `170 * 40 / 70` | 97.14 |
| 44 | `170 * 44 / 70` | 106.86 |
| 60 | `170 * 60 / 70` | 145.71 |
| 65 | `170 * 65 / 70` | 157.86 |
| 70 | `170 * 70 / 70` | 170.00 |

The crosshair consists only of the complete horizontal and vertical diameters of the `R36` circle. Both strokes are continuous through the center and the `R4` circle.

### Tick construction

There are 36 radial directions at 10-degree intervals. Let `a = 10° * k` for integer `k` in `[0, 35]`, with zero at the top and positive angles proceeding clockwise. A radial endpoint at radius `r` is

```text
x(a, r) = cx + r * sin(a)
y(a, r) = cy - r * cos(a)
```

Ticks occupy one of two annuli and are centered on that annulus's middle circle:

- inner annulus: `R36–R44`, centered on `R40`;
- outer annulus: `R60–R70`, centered on `R65`.

For an annulus with inner radius `ri`, outer radius `ro`, center radius `rm`, and span fraction `f`, each tick's exact endpoints are

```text
r0 = rm - f * (ro - ri) / 2
r1 = rm + f * (ro - ri) / 2
P0 = (x(a, r0), y(a, r0))
P1 = (x(a, r1), y(a, r1))
```

Apply the same direction and span class in both annuli:

| Direction class | Count | Span fraction `f` | Stroke width |
| --- | ---: | ---: | ---: |
| `k` is a multiple of 6 | 6 | `1.0` (full band) | 2 px |
| `k` is an odd multiple of 3 | 6 | `0.6` (centered) | 1 px |
| all remaining `k` | 24 | `0.3` (centered) | 1 px |

The twelve numerals `1–12` are upright, centered at `R52 = 170 * 52 / 70 ≈ 126.29 px`, and arranged in standard clock order. Glyphs use `FONT_XTINY`; they are not rotated along a tangent. Each numeral is first knocked out in black and then drawn in red so rings or other geometry cannot reduce legibility.

Two concise value-only readouts supplement the graphic without changing its geometry: the true polar-scope clock position is centered above the central 4′ ring and the fixed Polaris pole offset is centered below it. Both use `FONT_XTINY` with a black knockout capsule, so the crosshair remains legible. They are positioned inside the inner 36′ circle, clear of the 52′ clock numerals and outer marker track.

## Optical transform and live marker

The eyepiece image is inverted horizontally and vertically, equivalent to a 180-degree rotation. This rotation preserves handedness.

Use the full observed hour angle from the calculation result, not its user-facing formatted text. Let `hob` be that angle in radians at the authoritative calculation timestamp and `elapsedSeconds` be elapsed SI seconds since that timestamp. The marker retains the full 24-hour phase, while its numeric polar-scope clock position is the numeral at that same direction:

```text
H(t) = normalize2pi(hob + elapsedSeconds * 1.0027379 * pi / 43200)
C(t) = normalize12(6 h - H(t) / 2)
rho = R70 * poleDistanceArcmin / 70
x = cx + rho * sin(H)
y = cy + rho * cos(H)
```

The marker updates once per second. The static reticle does not rotate or animate.

The required cardinal checks are:

| Full observed hour angle | True clock position | Expected marker direction |
| ---: | ---: | --- |
| 0 h | 6 | bottom |
| 6 h | 3 | right |
| 12 h | 12 | top |
| 18 h | 9 | left |

These checks are part of release verification against the physical eyepiece, not merely simulator coordinate checks.
The September 2026 comparison reference reports `H = LST − RA` using equinox-based LST and a reported apparent RA. That mixes conventions with SOFA `atco13`'s CIO-based observed `hob`; the marker therefore remains driven by `hob` rather than being offset to reproduce the mixed subtraction. The reference's `H ≈ 19.34 h` still provides an independent clock conversion check: `C ≈ 8.33 h`.


A pole distance outside the inclusive interval `[0, 70]` arcminutes is an explicit calculation error. The app must not clamp the value, draw a marker at the edge, or present the result as usable guidance.

## Visual style and render order

The reticle color is Garmin full red `0xFF0000` on black. Rings and crosshair strokes are 2 px. Major ticks are 2 px; medium and small ticks are 1 px. The live marker uses a high-brightness Garmin green fill. Its shape and halo supplement color so it remains identifiable without color discrimination.

Render in this order:

1. circles and crosshair;
2. tick marks;
3. each numeral's black knockout, then its `0xFF0000` text;
4. both readout knockout capsules and text;
5. black marker halo, radius 8 px;
6. green filled marker, radius 6 px;
7. warning overlay, when needed.

The design intentionally provides no app-specific brightness control. It relies on the watch's normal nighttime display dimming behavior. The black background limits AMOLED emission, while Garmin full red keeps the reticle legible after the watch dims and the marker remains small despite its higher brightness.

## Menu, persistence, and navigation

Locate adds a persisted **Reticle** row between **Coordinate Format** and **Atmosphere**. Its options are:

- Generic;
- iOptron.

Generic is the fresh-install default. A missing stored preference also resolves to Generic, so an upgrade from a version without this setting preserves the current numerical Display. Only a confirmed preference is persisted; an open selection or transient focus state is not.

The selected option determines the Display variant after a successful calculation:

- **Generic** keeps the existing numerical result unchanged.
- **iOptron** shows the graphic reticle and live marker, plus the compact upper clock-position and lower pole-offset readouts.

On the iOptron Display, START/Select opens the existing Actions menu; touch (tap or swipe) is wake-only and triggers no app action. BACK returns directly to Locate, matching the Generic Display. Returning from Actions restores the same Display variant under the existing result-freshness rules.

## State and lifecycle

The reticle selection belongs to confirmed preferences, not to a calculation result. Relaunch returns to Locate with the persisted selection, while a missing selection resolves to Generic.

The iOptron Display follows the existing Display lifecycle contract:

- its marker updates once per second from the authoritative calculation timestamp;
- periodic full recalculation re-anchors the result;
- UTC discontinuity triggers recalculation;
- inactive/resume handling must not briefly show stale guidance;
- leaving Display restores normal power behavior.

When calculation or freshness state does not permit a valid result, the app does not draw a plausible marker.

## Warnings, errors, and Details
On a valid graphical result with an active warning, the app must render exactly one short overlay at the top. It must not cover the marker or become a persistent text panel. Full warning wording, explanation, and diagnostics belong in Details.

The existing Actions menu remains the route to Details. Location visibility, pressure fallback, and Earth-data-expiry warnings retain their existing semantics. Pole distance outside `[0, 70]` arcminutes is a calculation error rather than a warning; no reticle result or marker is shown. This range error uses the existing calculation-error actions—Back to location, Try again where applicable, and Details—rather than introducing another screen.

## Accessibility and localization

Reticle geometry is language-neutral. The combination of marker shape, black halo, contrast, and position prevents color from being the sole indicator. Focus remains in the Actions and Locate controls rather than on decorative reticle elements.

The **Reticle**, **Generic**, and **iOptron** menu strings, short warning overlay, error text, Details explanations, and Help content are synchronized in English, Simplified Chinese, and Traditional Chinese.

## Edge cases

- Exactly `0` or `70` arcminutes is valid and follows the same mapping equation.
- A non-finite hour angle, pole distance, timestamp, or elapsed-time input is a calculation error; no marker is drawn.
- Hour-angle wrap uses `normalize2pi`, preserving a continuous path across 24 h.
- The marker may overlap reticle strokes or numerals; the black halo preserves its boundary.
- A warning and marker may coexist only when the underlying result remains valid.
- If current data becomes stale or invalid while visible, guidance is withheld until recalculation produces a fresh valid result.

## Acceptance criteria

- Locate presents Reticle between Coordinate Format and Atmosphere, with Generic and iOptron options.
- Generic is used for fresh installs and whenever the preference is absent, including upgrades; its numerical Display is unchanged.
- iOptron presents the specified static graphic, live marker, and compact knocked-out upper clock-position/lower pole-offset readouts.
- The display uses the specified center, radii, circles, crosshair, two tick annuli, 36-direction classes, and twelve upright numerals.
- Reticle strokes and text use Garmin full red `0xFF0000`; the marker has an 8 px black halo and 6 px high-brightness Garmin green fill.
- The marker uses full observed hour angle and the stated sidereal update and mapping equations, updating once per second.
- Out-of-range pole distance produces a calculation error without clamping or a marker.
- START/Select opens the existing Actions menu, touch is wake-only with no app action, and BACK returns to Locate.
- A valid result with an active warning renders exactly one short top overlay that does not cover the marker; Details contains the full explanation.
- The result remains readable by shape, position, and contrast without relying on color alone.

## Verification plan

### Simulator

On the `454×454` Forerunner 965 simulator:

1. Verify the Reticle row's order, focus treatment, touch target, button navigation, option selection, and persistence behavior, including an absent preference.
2. Confirm Generic is visually and behaviorally unchanged.
3. Inspect circle radii, crosshair limits, tick counts and spans, upright numeral placement, stroke widths, color, marker halo, and render order.
4. Feed known valid calculations for `0 h`, `6 h`, `12 h`, and `18 h`; verify bottom, right, top, and left marker positions at the expected radius.
5. Observe the marker for multiple one-second updates and across the 24-hour normalization boundary.
6. Exercise warning overlay, Details, Actions, BACK, inactive/resume, UTC discontinuity, and periodic recalculation behavior.
7. Verify values just below `0` and just above `70` arcminutes produce a calculation error and no marker; verify both endpoints remain valid.
8. Review English, Simplified Chinese, and Traditional Chinese menu, warning, error, Details, and Help layouts when localization resources are implemented.

### Physical watch and eyepiece

On a Forerunner 965 and an iOptron SkyGuider Pro:

1. Compare the rendered ring, tick, numeral, and crosshair orientation with the physical reticle.
2. Verify all four cardinal cases against the view through the physical eyepiece: `0 h` at bottom/6, `6 h` at right/3, `12 h` at top/12, and `18 h` at left/9.
3. Confirm the 180-degree optical inversion and preserved handedness through the complete watch-to-eyepiece workflow.
4. Check dark adaptation, OLED dimming, marker visibility, halo separation, warning readability, touch operation, and physical-button operation in realistic nighttime use.
