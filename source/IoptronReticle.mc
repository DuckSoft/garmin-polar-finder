import Toybox.Math;
import Toybox.Lang;

const RETICLE_GENERIC = 0;
const RETICLE_IOPTRON = 1;
const RETICLE_SIFO = 2;

const IOPTRON_SIDEREAL_RATE = 1.0027379 * Math.PI / 43200.0;
function normalizeReticleType(value) {
    if (!(value instanceof Lang.Number)) { return RETICLE_GENERIC; }
    return (value == RETICLE_GENERIC || value == RETICLE_IOPTRON || value == RETICLE_SIFO)
        ? value : RETICLE_GENERIC;
}

function reticleShowsOuterScale(value) {
    return value == RETICLE_IOPTRON;
}

function reticleMaximumPoleDistance(value) {
    return value == RETICLE_SIFO ? 44.0 : 70.0;
}

function reticleAngularRadius(value, screenReticleRadius) {
    return value == RETICLE_SIFO
        ? screenReticleRadius * 70.0 / 44.0
        : screenReticleRadius;
}

function reticleValidPoleDistance(value, distanceArcmin) {
    return ioptronFinite(distanceArcmin)
        && distanceArcmin >= 0.0
        && distanceArcmin <= reticleMaximumPoleDistance(value);
}


function ioptronFinite(value) {
    return value != null && value == value && value < 1.0e30 && value > -1.0e30;
}

function ioptronRingRadius(thetaArcmin, r70) {
    return r70 * thetaArcmin / 70.0;
}

function ioptronTickClass(k) {
    var direction = k % 36;
    if (direction < 0) { direction += 36; }
    if (direction % 6 == 0) { return 0; }
    if (direction % 3 == 0) { return 1; }
    return 2;
}

function ioptronTickSpanFraction(k) {
    var tickClass = ioptronTickClass(k);
    return tickClass == 0 ? 1.0 : (tickClass == 1 ? 0.6 : 0.3);
}

function ioptronTickStartRadius(innerArcmin, outerArcmin, k, r70) {
    var middle = (innerArcmin + outerArcmin) / 2.0;
    var halfSpan = ioptronTickSpanFraction(k) * (outerArcmin - innerArcmin) / 2.0;
    return ioptronRingRadius(middle - halfSpan, r70);
}

function ioptronTickEndRadius(innerArcmin, outerArcmin, k, r70) {
    var middle = (innerArcmin + outerArcmin) / 2.0;
    var halfSpan = ioptronTickSpanFraction(k) * (outerArcmin - innerArcmin) / 2.0;
    return ioptronRingRadius(middle + halfSpan, r70);
}

function ioptronNormalize2Pi(angle) {
    if (!ioptronFinite(angle)) { return null; }
    var twoPi = 2.0 * Math.PI;
    var normalized = angle - Math.floor(angle / twoPi) * twoPi;
    if (normalized < 0.0) { normalized += twoPi; }
    return normalized;
}

function ioptronReticleClockSeconds(fullHourAngle) {
    var angle = ioptronNormalize2Pi(fullHourAngle);
    if (angle == null) { return null; }
    var seconds = Math.round(21600.0 - angle * 21600.0 / Math.PI).toNumber();
    seconds %= 43200;
    if (seconds < 0) { seconds += 43200; }
    return seconds;
}


function ioptronMarkerPosition(output, fullHourAngle, elapsedSeconds, poleDistanceArcmin,
                               centerX, centerY, r70, maximumPoleDistance) {
    if (output == null || output.size() < 2 || !ioptronFinite(elapsedSeconds)
        || !ioptronFinite(centerX) || !ioptronFinite(centerY)
        || !ioptronFinite(r70) || r70 <= 0.0
        || !ioptronFinite(maximumPoleDistance) || maximumPoleDistance < 0.0
        || !ioptronFinite(poleDistanceArcmin) || poleDistanceArcmin < 0.0
        || poleDistanceArcmin > maximumPoleDistance) { return false; }
    var angle = ioptronNormalize2Pi(fullHourAngle + elapsedSeconds * IOPTRON_SIDEREAL_RATE);
    if (angle == null) { return false; }
    var rho = ioptronRingRadius(poleDistanceArcmin, r70);
    output[0] = centerX + rho * Math.sin(angle);
    output[1] = centerY + rho * Math.cos(angle);
    return true;
}
