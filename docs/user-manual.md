# Polar Finder User Manual

Polar Finder is a Garmin watch app that helps you polar-align an equatorial
mount in the Northern Hemisphere. It calculates the observer-corrected position
of Polaris for your current time and location, then presents either numerical
guidance or a graphical polar-scope reticle.

## Contents

- [Before you begin](#before-you-begin)
- [Watch controls](#watch-controls)
- [Quick start](#quick-start)
- [Set the observing location](#set-the-observing-location)
- [Choose a coordinate format](#choose-a-coordinate-format)
- [Choose a result display](#choose-a-result-display)
- [Configure the atmosphere](#configure-the-atmosphere)
- [Run a calculation](#run-a-calculation)
- [Use the result](#use-the-result)
- [Actions and details](#actions-and-details)
- [Warnings and troubleshooting](#warnings-and-troubleshooting)
- [Saved data and privacy](#saved-data-and-privacy)

## Before you begin

You need:

- a supported Garmin watch: Forerunner 255, 255S, 255 Music, 255S Music, or
  Forerunner 965;
- a view of Polaris and a polar-alignment mechanism on your mount;
- the watch's date and time set correctly;
- your observing latitude, longitude, and elevation above mean sea level (MSL),
  or permission for the app to acquire them with GPS.

Polar Finder relies on time-limited bundled Earth-orientation data. Open
**Details** in the app to see the supported interval and expiry date. Install an
updated app version when newer Earth data is required.

The app is an alignment aid. Follow the mount manufacturer's instructions for
leveling the tripod, setting the mount's latitude, orienting it toward north,
and safely adjusting its altitude and azimuth.

## Watch controls

All features can be operated with buttons.

| Button | Normal use |
| --- | --- |
| **UP / DOWN** | Move between rows or change a value |
| **START / SELECT** | Open or confirm the focused item |
| **BACK** | Cancel the current edit or return to the previous screen |

On the Forerunner 965, tap a row to select it, swipe up or down to move through
rows, and swipe right to go back. Touch on a result display only wakes the
screen; it does not change the result or open a menu. Use **START** to open
Actions from a result display.

## Quick start

1. Open **Polar Finder**.
2. On **Locate**, select **Acquire GPS** and wait for a suitable fix. Select
   **Use Location**. Alternatively, enter latitude, longitude, and MSL elevation
   manually.
3. Review the location. If **Confirm Location** is shown, select it. It changes
   to **Calculate**.
4. Optionally choose **Reticle** and **Atmosphere** settings.
5. Select **Calculate** and wait for the result.
6. Use the numerical result or place Polaris at the green marker shown on the
   selected graphical reticle.

On later launches, the last saved location is restored, but you must confirm
that it is still the correct observing location before calculating.

## Set the observing location

### Acquire GPS

1. On **Locate**, focus **Acquire GPS** and press **START**.
2. Wait while the app searches. The latest coordinates, MSL elevation, elapsed
   time, and Garmin GPS quality appear when available.
3. Select **Use Location** when satisfied with the fix.

Acquisition continues after the first fix so that the quality can improve. A
search lasting more than 60 seconds reports **No fix yet; search continues**; it
does not stop automatically.

GPS quality is reported as **Good GPS**, **Usable GPS**, **Poor GPS**, or
**Last known**. Poor and last-known positions require an extra confirmation
before use. A last-known position also shows its age when that information is
available. For accurate alignment, prefer a current Good or Usable fix.

If GPS is unavailable, select **Enter manually** from the GPS screen.

### Enter or correct a location manually

Select the **Latitude**, **Longitude**, or **Elevation (MSL)** row on **Locate**.
Each component is edited separately:

1. Move to a hemisphere, sign, or digit with **UP / DOWN**.
2. Press **START** to begin changing it.
3. Use **UP / DOWN** to change it.
4. Press **START** again to accept that component and advance.
5. Select **Done** to validate and apply the complete value.

Pressing **BACK** while in an editor discards that field's provisional changes.
Latitude accepts 0–90° N/S, longitude accepts 0–180° E/W, and elevation is in
whole meters above mean sea level. At exactly 90° latitude or 180° longitude,
minutes, seconds, and decimal fractions must be zero.

Editing a GPS position labels its source **GPS, adjusted**. A fully manual
position is labeled **Manual**. After any edit, return to **Locate** and select
**Confirm Location** before calculating.

### Confirm or discard changes

Confirmation saves the location and enables **Calculate**. If you try to leave
Locate after changing a previously saved location, the app asks whether to
discard the changes or keep editing.

## Choose a coordinate format

The **Coordinate format** row toggles between:

- **Decimal** — five digits after the decimal point;
- **DMS** — degrees, minutes, and whole seconds.

Changing the display format does not change the stored position. The preference
is retained for the next launch.

## Choose a result display

Open **Reticle** on the Locate screen and choose:

- **Generic** — numerical hour angle and pole distance;
- **iOptron** — a complete clock-style graphical reticle with a live green
  Polaris marker;
- **Sifo** — an enlarged inner-only graphical reticle without the outer scale
  or clock numerals.

Use a graphical option only when its artwork matches the polar-scope reticle you
intend to use. The selected option is saved.

## Configure the atmosphere

Atmospheric refraction slightly changes Polaris's observed position. Open
**Atmosphere** from Locate to review these settings.

### Pressure

- **Automatic** samples the watch barometer, treats its reading as sea-level
  pressure, and derives pressure at your reviewed elevation.
- **Manual local hPa** uses the local pressure you enter directly.
- **Refraction off** performs the calculation without atmospheric refraction.

In Automatic mode, the app tries fresh barometer samples first, then a sample
less than five minutes old. If neither is available, it uses a previously
entered manual value or a standard-atmosphere estimate.

### Temperature and humidity

Set the actual outdoor air temperature and relative humidity when known. The
defaults are 10°C and 50%. The watch's wrist temperature is not used as ambient
temperature. Wavelength is fixed at 0.55 µm for visible Polaris.

To edit a value, press **START**, change it with **UP / DOWN**, and press
**START** again. Select **Done** or press **BACK** to save the settings.

**Calculation alert** enables a short vibration when calculation succeeds and a
different brief vibration when it fails. The watch's system haptic setting still
applies.

## Run a calculation

A location must contain latitude, longitude, and elevation and must be confirmed.
Select **Calculate** on Locate. The progress screen reports these stages:

1. Reading pressure;
2. Loading Earth data;
3. Converting time;
4. Calculating Polaris;
5. Applying observer corrections;
6. Preparing display.

Press **BACK** to request cancellation. The app finishes its current safe step,
discards the partial result, and returns to Locate.

If the app is interrupted during a calculation, it starts the calculation again
when it becomes active. It never restores a stale partial result.

## Use the result

### Generic numerical display

The Generic display shows:

- **Hour angle** as `HH:MM:SS` on a 12-hour scale;
- **Pole distance**, the observed angular distance between Polaris and the
  celestial pole, in arcminutes and arcseconds;
- the watch's local date and time;
- a warning or the location source.

Use these values according to the instructions for your mount, polar scope, or
alignment software.

### iOptron and Sifo displays

The red artwork represents the polar-scope reticle. The green dot is the live
target position for Polaris. Look through the mount's polar scope and use the
mount's altitude and azimuth adjusters to place Polaris at the corresponding
position on the physical reticle.

The upper readout is the target clock position and the lower readout is the pole
distance. The marker and readouts update once per second.

For fine placement:

1. Press physical **UP** to enter a 6× view centered on the target.
2. In this view, all text is hidden and the green dot becomes a full-screen
   green crosshair marking the watch screen's physical center.
3. Press physical **DOWN** to restore the normal reticle.

Magnification is available only on iOptron and Sifo displays. Touch does not
activate it. It resets whenever the display is reopened or recalculated.

### Keeping the result current

The display updates continuously and performs a fresh full calculation at least
every 15 minutes. A clock discontinuity, app interruption, or return to an
inactive result also causes recalculation rather than showing stale guidance.

Press **BACK** from any result to return directly to Locate.

## Actions and details

Press **START** on a result display to open **Actions**:

- **Recalculate** — calculate immediately with the confirmed inputs;
- **Location** — return to Locate;
- **Atmosphere** — change refraction inputs;
- **Details** — inspect the complete calculation inputs, data sources, Earth
  data, catalog information, and precise result.

Pressing **BACK** from Actions recalculates before returning to the result.
Atmosphere changes made from Actions are applied when the result is recalculated.

The **Help** item on Locate provides a short on-watch reminder. This manual is
the more complete reference.

## Warnings and troubleshooting

### Confirm Location is shown instead of Calculate

The location is new, edited, or restored from a previous launch. Review all
three fields and select **Confirm Location**.

### Permission required

The app cannot use positioning. Enable the location permission for Polar Finder
in the watch or Garmin app settings, then try **Acquire GPS** again.

### GPS has no fix

Move outdoors with an unobstructed view of the sky and continue waiting. The
search remains active after 60 seconds. You can also enter the location manually.

### Polaris is not visible from this location

Polaris is at or below the calculated horizon. Check the latitude and longitude.
Polar Finder is intended for Northern Hemisphere polar alignment.

### Polaris is very low

Polaris is less than 5° above the calculated horizon. Refraction and horizon
obstructions can make alignment unreliable. Check the location and atmospheric
settings before relying on the result.

### Date outside Earth-data range

Check the watch date. In **Details**, compare the calculation time with the
displayed supported interval and expiry date. If the watch date is correct but
outside that interval, install an app update containing newer Earth-orientation
data.

Within the final 30 days of the bundled data, the app displays a **Data expires**
warning. The result remains available, but the app should be updated soon.

### Polaris is outside the reticle range

The calculated marker is beyond the selected graphical reticle's supported
range: 70 arcminutes for iOptron or 44 arcminutes for Sifo. Select **Generic**
to inspect the numerical result, or choose the artwork that matches your scope.

### Calculation error

The error screen offers **Try again**, **Back to location**, and **Details**.
First check the watch date, confirmed location, elevation, and atmosphere
settings. Details shows the exact inputs and data sources used.

## Saved data and privacy

The watch stores the last confirmed location and these preferences locally:

- coordinate format and reticle;
- pressure mode and manual pressure;
- temperature and humidity;
- calculation-alert setting.

GPS acquisition, partial edits, calculation progress, and calculated results are
not retained across launches. The app requests positioning and sensor
permissions for GPS and the built-in barometer; it has no communications
permission and does not upload your location.
