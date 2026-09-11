import Toybox.Math;
import Toybox.Test;
import Toybox.WatchUi;

/* Fixed expected values below come from the official SOFA t_atco13 vector
 * and an independently frozen pyerfa vector. Production precision is checked
 * through the resumable begin/step API without a same-implementation oracle. */
function withinTolerance(actual, expected, tolerance) {
    var error = actual - expected;
    if (error < 0.0) { error = -error; }
    return error <= tolerance;
}
(:test)
function unixTimestampRetainsSubdayPrecision(logger as Test.Logger) {
    var jd = Astrometry.unixSecondsToJulianDate(1788967221);
    return withinTolerance(jd, 2461293.1391319446d, 1.0e-9d)
        && !withinTolerance(jd, 2461293.25d, 1.0e-3d);
}
(:test)
function beijingPressureOffVectorMatchesPyerfa(logger as Test.Logger) {
    var unixSeconds = 1788967221;
    var jd = Astrometry.unixSecondsToJulianDate(unixSeconds);
    var eop = IersEopData.eop(jd - 2400000.5d);
    var pi = Math.PI.toDouble();
    var rc = (2.0d + 31.0d / 60.0d + 49.09d / 3600.0d) * 15.0d * pi / 180.0d;
    var dc = (89.0d + 15.0d / 60.0d + 50.8d / 3600.0d) * pi / 180.0d;
    var height = GeoidData.mslToEllipsoid(40.06890d, 116.30780d, 125.0d);
    var state = Astrometry.begin(
        rc, dc, 44.22e-3d * pi / (180.0d * 3600.0d),
        -11.74e-3d * pi / (180.0d * 3600.0d), 7.54e-3d, -16.0d,
        jd, 0.0d, eop[:dut1], 116.30780d * pi / 180.0d,
        40.06890d * pi / 180.0d, height, eop[:xp], eop[:yp],
        0.0d, 10.0d, 0.5d, 0.55d);
    var reply = null;
    var done = false;
    var steps = 0;
    while (!done && steps < 500) {
        reply = Astrometry.step(state);
        state = reply[:state];
        done = reply[:done];
        steps += 1;
    }
    if (!done || reply[:result] == null) { return false; }
    var result = reply[:result];
    var hourAngleHours = Astrometry.anp(result[:hob]) * 12.0d / pi;
    var observedRaHours = result[:rob] * 12.0d / pi;
    var poleDistanceArcmin = (pi / 2.0d - result[:dob]) * 180.0d / pi * 60.0d;
    // pyerfa atco13 with these identical inputs and phpa=0 hPa.
    return withinTolerance(hourAngleHours, 19.21246884397d, 0.000019d)
        && withinTolerance(observedRaHours, 3.10363945797d, 0.000004d)
        && withinTolerance(poleDistanceArcmin, 37.6776406015d, 0.02d);
}


(:test)
function astrometryResumableReferenceVector(logger as Test.Logger) {
    var state = Astrometry.begin(2.71, 0.174, 1e-5, 5e-6, 0.1, 55.0,
        2456384.5, 0.969254051, 0.1550675,
        -0.527800806, -1.2345856, 2738.0,
        2.47230737e-7, 1.82640464e-6,
        731.0, 12.8, 0.59, 0.55);
    var lastProgress = -1.0;
    var reply = null;
    var result = null;
    var done = false;
    var ok = true;
    var steps = 0;
    while (!done && steps < 500) {
        reply = Astrometry.step(state);
        state = reply[:state];
        if (reply[:progress] < lastProgress || reply[:progress] > 1.0) { ok = false; }
        lastProgress = reply[:progress];
        done = reply[:done];
        result = reply[:result];
        steps += 1;
    }
    ok = ok && done && steps > 10 && result[:status] == 0;
    var names = [:aob, :zob, :hob, :dob, :rob, :eo];
    var expected = [0.09251774485358230653, 1.407661405256767021,
                    -0.09265154431403157925, 0.1716626560075591655,
                    2.710260453503097719, -0.003020548354802412839];
    var tolerance = [2e-6, 1e-7, 2e-6, 1e-7, 5e-7, 3e-8];
    var i = 0;
    for (i = 0; i < names.size(); i += 1) {
        if (!withinTolerance(result[names[i]], expected[i], tolerance[i])) { ok = false; }
    }
    var cancelled = Astrometry.begin(2.71, 0.174, 1e-5, 5e-6, 0.1, 55.0,
        2456384.5, 0.969254051, 0.1550675,
        -0.527800806, -1.2345856, 2738.0,
        2.47230737e-7, 1.82640464e-6,
        731.0, 12.8, 0.59, 0.55);
    Astrometry.cancel(cancelled);
    var cancelledReply = Astrometry.step(cancelled);
    ok = ok && cancelledReply[:done] && cancelledReply[:result] == null;
    return ok;
}

function runAstrometryFull(rc, dc, pr, pd, px, rv, utc1, utc2, dut1, elong, phi, hm, xp, yp, phpa, tc, rh, wl) {
    var state = Astrometry.begin(rc, dc, pr, pd, px, rv, utc1, utc2, dut1, elong, phi, hm, xp, yp, phpa, tc, rh, wl);
    var reply = null;
    var done = false;
    var steps = 0;
    while (!done && steps < 500) {
        reply = Astrometry.step(state);
        state = reply[:state];
        done = reply[:done];
        steps += 1;
    }
    if (!done) { return null; }
    return reply[:result];
}

(:test)
function astrometryRejectsOutOfRangeUtc(logger as Test.Logger) {
    var state = Astrometry.begin(2.71, 0.174, 1e-5, 5e-6, 0.1, 55.0,
        1000000.0, 0.0, 0.0, -0.5278, -1.2346, 2738.0,
        0.0, 0.0, 731.0, 12.8, 0.59, 0.55);
    var reply = Astrometry.step(state);
    return reply[:done] && reply[:result][:status] < 0;
}

// Item 1: catalogs tabulate mu_alpha* = d(alpha)/dt * cos(dec) (mas/yr), but
// SOFA's pr wants the raw d(alpha)/dt (rad/yr); verify the conversion divides
// out cos(dec) rather than silently reusing mu_alpha* as-is.
(:test)
function properMotionConversionDividesOutCosDec(logger as Test.Logger) {
    var pmRaStarMasYr = 44.22d;
    var decRad = (89.0d + 15.0d / 60.0d + 50.8d / 3600.0d) * Math.PI.toDouble() / 180.0d;
    var expected = (pmRaStarMasYr * Astrometry.MAS2RAD_D) / Math.cos(decRad);
    var actual = Astrometry.properMotionPrRadYr(pmRaStarMasYr, decRad);
    // At Polaris' declination cos(dec) ~ 0.012843 (1/cos(dec) ~ 77.86), so
    // naively skipping the division would understate |pr| by a factor of
    // roughly 78, not merely five -- and that correction lands on the RA
    // *coordinate rate*, not on Polaris' physical tangential proper motion
    // (multiplying prRadYr back by cos(dec) recovers the catalog value).
    var naive = pmRaStarMasYr * Astrometry.MAS2RAD_D;
    // Independent check with a round, non-Polaris declination and a
    // hand-computed expected value, so this isn't just re-deriving the same
    // expression the helper itself uses. Uses a genuine Double pi literal:
    // Math.PI is Float-precision, and .toDouble() cannot recover digits it
    // never had, which would otherwise inject a ~2.16e-14 rad/yr error into
    // this specific high-precision comparison (tolerance 1e-18).
    var piD = 3.1415926535897932384626433832795d;
    var independentDec = piD / 3.0d;
    var independentExpected = 4.2876921957327345e-7d;
    var independentActual = Astrometry.properMotionPrRadYr(pmRaStarMasYr, independentDec);
    return withinTolerance(actual, expected, 1.0e-18d)
        && !withinTolerance(actual, naive, 1.0e-9d)
        && withinTolerance(independentActual, independentExpected, 1.0e-18d);
}

// Item 2/3/4: with no polar motion and no refraction, the new tangent-plane
// reticle coordinates must reduce to the legacy hob/(pi/2-dob) convention
// (verified symbolically: X=-tan(rho)*sin(hob), Y=tan(rho)*cos(hob) exactly).
(:test)
function zeroRefractionZeroPolarMotionMatchesLegacyHourAngleAndPoleDistance(logger as Test.Logger) {
    // A genuine Double pi is required here: Math.PI is a 32-bit Float, and
    // .toDouble() cannot recover the digits it never had. Using it on only
    // one side of this identity would inject a spurious ~4.4e-8 rad error
    // that has nothing to do with the astrometry being tested.
    var pi = 3.1415926535897932384626433832795d;
    var rc = (2.0d + 31.0d / 60.0d + 49.09d / 3600.0d) * 15.0d * pi / 180.0d;
    var dc = (89.0d + 15.0d / 60.0d + 50.8d / 3600.0d) * pi / 180.0d;
    var pr = Astrometry.properMotionPrRadYr(44.22d, dc);
    var result = runAstrometryFull(rc, dc, pr, -11.74e-3d * pi / (180.0d * 3600.0d),
        7.54e-3d, -16.0d, 2461293.1391319446d, 0.0d, 0.0d,
        116.30780d * pi / 180.0d, 40.06890d * pi / 180.0d, 125.0d,
        0.0d, 0.0d, 0.0d, 10.0d, 0.5d, 0.55d);
    if (result == null || result[:status] != 0) { return false; }
    return withinTolerance(result[:reticleHourAngle], result[:hob], 1.0e-9d)
        && withinTolerance(result[:reticlePoleDistance], pi / 2.0d - result[:dob], 1.0e-9d);
}


// Item 3: nonzero polar motion (xp,yp) must shift the geometric pole's local
// direction by (to leading order) sqrt(xp^2+yp^2) radians, independent of
// Polaris' own position -- this is the effect the old hob/(pi/2-dob)
// shortcut could never represent, since it never modeled a separate pole.
(:test)
function nonzeroPolarMotionShiftsGeometricPole(logger as Test.Logger) {
    var xp = 2.47230737e-7d;
    var yp = 1.82640464e-6d;
    var withPm = runAstrometryFull(2.71, 0.174, 1e-5, 5e-6, 0.1, 55.0,
        2456384.5, 0.969254051, 0.1550675, -0.527800806, -1.2345856, 2738.0,
        xp, yp, 731.0, 12.8, 0.59, 0.55);
    var withoutPm = runAstrometryFull(2.71, 0.174, 1e-5, 5e-6, 0.1, 55.0,
        2456384.5, 0.969254051, 0.1550675, -0.527800806, -1.2345856, 2738.0,
        0.0, 0.0, 731.0, 12.8, 0.59, 0.55);
    if (withPm == null || withoutPm == null) { return false; }
    var dx = withPm[:polePx] - withoutPm[:polePx];
    var dy = withPm[:polePy] - withoutPm[:polePy];
    var dz = withPm[:polePz] - withoutPm[:polePz];
    var shift = Math.sqrt(dx * dx + dy * dy + dz * dz);
    var expectedShift = Math.sqrt(xp * xp + yp * yp);
    if (!withinTolerance(shift, expectedShift, 1.0e-9d)) {
        logger.debug("geometric-pole shift mismatch: shift=" + shift
            + " expected=" + expectedShift + " errorNrad=" + ((shift - expectedShift) * 1.0e9d)
            + " xp=" + xp + " yp=" + yp);
        return false;
    }
    return true;
}

// Item 5: toggling atmospheric refraction must move Polaris' observed ray
// (aob/zob/hob/dob) without moving the geometric pole at all -- the pole is
// the mechanical mount target and must never see refa/refb.
(:test)
function refractionOnlyMovesPolarisRayNotGeometricPole(logger as Test.Logger) {
    var noRefr = runAstrometryFull(2.71, 0.174, 1e-5, 5e-6, 0.1, 55.0,
        2456384.5, 0.969254051, 0.1550675, -0.527800806, -1.2345856, 2738.0,
        2.47230737e-7, 1.82640464e-6, 0.0, 12.8, 0.59, 0.55);
    var withRefr = runAstrometryFull(2.71, 0.174, 1e-5, 5e-6, 0.1, 55.0,
        2456384.5, 0.969254051, 0.1550675, -0.527800806, -1.2345856, 2738.0,
        2.47230737e-7, 1.82640464e-6, 731.0, 12.8, 0.59, 0.55);
    if (noRefr == null || withRefr == null) { return false; }
    var poleUnchanged = withinTolerance(noRefr[:polePx], withRefr[:polePx], 1.0e-12d)
        && withinTolerance(noRefr[:polePy], withRefr[:polePy], 1.0e-12d)
        && withinTolerance(noRefr[:polePz], withRefr[:polePz], 1.0e-12d);
    var rayMoved = !withinTolerance(noRefr[:zob], withRefr[:zob], 1.0e-6d);
    return poleUnchanged && rayMoved;
}

// Item 6: helpers for full-3D-direction propagation tests. angularSeparationArcsec
// measures the true angular distance between two local unit vectors (not a
// raw hour-angle or pole-distance difference), matching how a mount would
// actually be mis-pointed if the predicted and reference rays diverge.
function angularSeparationArcsec(a, b) {
    var cr = Astrometry.cross3(a, b);
    var crossNorm = Math.sqrt(cr[0] * cr[0] + cr[1] * cr[1] + cr[2] * cr[2]);
    var dotP = a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
    var rad = Math.atan2(crossNorm, dotP);
    return rad * 180.0d * 3600.0d / Math.PI.toDouble();
}
// Reconstructs the local unit vector s = normalize(p + X*v + Y*u) that a
// tangent-plane (X,Y) pair actually represents, given the pole p and basis
// (u,v) it was measured against -- this is the same reconstruction formula
// used for cross-checking Astrometry.reticleAt()'s output below.
function localFrameToVector(pole, u, v, x, y) {
    return Astrometry.normalize3([
        pole[0] + x * v[0] + y * u[0],
        pole[1] + x * v[1] + y * u[1],
        pole[2] + x * v[2] + y * u[2]
    ]);
}
function reticlePredictedVector(anchor, elapsedSeconds) {
    var r = Astrometry.reticleAt(anchor, elapsedSeconds);
    var pole = [anchor[:polePx], anchor[:polePy], anchor[:polePz]];
    var u = [anchor[:uX], anchor[:uY], anchor[:uZ]];
    var v = [anchor[:vX], anchor[:vY], anchor[:vZ]];
    return localFrameToVector(pole, u, v, r[:x], r[:y]);
}
// Independent reference: recomputes the observed ray at anchor-time +
// elapsedSeconds using ERA's own defining linear-growth formula (conventional
// rate 2*pi*1.00273781191135448 rad/UT1-day) called directly, rather than
// through Astrometry.era00()/reticleAt(); this cross-checks that the
// production predictor's incremental Earth-rotation-angle recompute has no
// sign, scale, or wrap-around bug, without relying on the same code path
// twice.
function independentSiderealRateVector(anchor, elapsedSeconds) {
    var omega = 2.0d * Math.PI.toDouble() * 1.00273781191135448d / 86400.0d;
    var theta0 = Astrometry.era00(anchor[:ut1a], anchor[:ut1b]);
    var eral = theta0 + omega * elapsedSeconds + anchor[:along];
    var ray = Astrometry.localHorizonRay(anchor[:ri], anchor[:di], eral,
        anchor[:xpl], anchor[:ypl], anchor[:sphi], anchor[:cphi], 0.0d,
        anchor[:refa], anchor[:refb]);
    return Astrometry.normalize3([ray[3], ray[4], ray[5]]);
}
// Builds a synthetic anchor directly from CIRS-frame inputs (bypassing the
// full ICRS->CIRS ephemeris/nutation/aberration chain), for isolated
// local-geometry propagation tests. vacuumPoleDistanceRad is the CIRS
// north-pole distance (e.g. ~37.7 arcmin, close to Polaris'); hourAngle0Rad
// is the desired hour-angle-like offset (ri-eral) at elapsedSeconds=0.
function buildSyntheticAnchor(vacuumPoleDistanceRad, phiRad, xp, yp, phpa, tc, rh, wl, hourAngle0Rad) {
    var di = Math.PI.toDouble() / 2.0d - vacuumPoleDistanceRad;
    var sphi = Math.sin(phiRad); var cphi = Math.cos(phiRad);
    var along = 0.0d;
    var cl = Math.cos(along); var sl = Math.sin(along);
    var xpl = xp * cl - yp * sl; var ypl = xp * sl + yp * cl;
    var ref = Astrometry.refco(phpa, tc, rh, wl);
    var ut1a = 2456384.5d; var ut1b = 0.0d;
    var theta0 = Astrometry.era00(ut1a, ut1b);
    var ri = hourAngle0Rad + theta0 + along;
    var pole = Astrometry.geometricPoleLocalVector(xpl, ypl, sphi, cphi);
    var basis = Astrometry.poleTangentBasis(pole);
    return {
        :ri => ri, :di => di, :ut1a => ut1a, :ut1b => ut1b, :along => along,
        :xpl => xpl, :ypl => ypl, :sphi => sphi, :cphi => cphi,
        :refa => ref[0], :refb => ref[1],
        :polePx => pole[0], :polePy => pole[1], :polePz => pole[2],
        :uX => basis[0][0], :uY => basis[0][1], :uZ => basis[0][2],
        :vX => basis[1][0], :vY => basis[1][1], :vZ => basis[1][2]
    };
}

// Item 6 (isolated local-geometry coverage): across a grid of initial hour
// angles, elapsed times, latitudes, refraction on/off, and polar motion
// on/off, Astrometry.reticleAt()'s cheap per-tick recompute must reproduce
// the exact sidereal rotation to well within the requested 0.1 arcsec
// engineering budget -- unlike the superseded fixed-radius/derivative-rate
// models, which the accompanying review measured at up to ~4.5 arcsec of
// error at 900s (phase-dependent, worst near H=90 degrees).
(:test)
function shortTimePropagationMatchesExactRotationGrid(logger as Test.Logger) {
    var deg = Math.PI.toDouble() / 180.0d;
    var arcsec = Math.PI.toDouble() / (180.0d * 3600.0d);
    var budgetArcsec = 0.1d;
    var vacuumPoleDistance = 37.7d / 60.0d * deg;
    var latitudesDeg = [20.0d, 40.0d, 60.0d];
    var hourAnglesDeg = [0.0d, 45.0d, 90.0d, 135.0d, 180.0d, 225.0d, 270.0d, 315.0d];
    var times = [0.0d, 60.0d, 300.0d, 600.0d, 899.0d, 900.0d];
    var polarMotions = [[0.0d, 0.0d], [0.2d * arcsec, -0.3d * arcsec]];
    var weatherOptions = [[0.0d, 10.0d, 0.5d], [1013.25d, 10.0d, 0.5d]];
    var worst = 0.0d;
    var worstFixture = "";
    var li = 0;
    for (li = 0; li < latitudesDeg.size(); li += 1) {
        var phiRad = latitudesDeg[li] * deg;
        var pmi = 0;
        for (pmi = 0; pmi < polarMotions.size(); pmi += 1) {
            var xp = polarMotions[pmi][0]; var yp = polarMotions[pmi][1];
            var wi = 0;
            for (wi = 0; wi < weatherOptions.size(); wi += 1) {
                var phpa = weatherOptions[wi][0]; var tc = weatherOptions[wi][1]; var rh = weatherOptions[wi][2];
                var hi = 0;
                for (hi = 0; hi < hourAnglesDeg.size(); hi += 1) {
                    var h0 = hourAnglesDeg[hi] * deg;
                    var anchor = buildSyntheticAnchor(vacuumPoleDistance, phiRad, xp, yp, phpa, tc, rh, 0.55d, h0);
                    var ti = 0;
                    for (ti = 0; ti < times.size(); ti += 1) {
                        var t = times[ti];
                        var sPred = reticlePredictedVector(anchor, t);
                        var sRef = independentSiderealRateVector(anchor, t);
                        var errArcsec = angularSeparationArcsec(sPred, sRef);
                        // Per-case validity/budget guard: a plain running-max
                        // comparison (errArcsec > worst) silently lets a NaN
                        // or infinite case slip through unnoticed (NaN
                        // comparisons are always false), which could still
                        // leave "worst" looking fine. Every case must itself
                        // be a finite, non-negative value under budget.
                        if (!(errArcsec >= 0.0d && errArcsec < budgetArcsec)) {
                            logger.debug("propagation grid case failed: case="
                                + li + "/" + pmi + "/" + wi + "/" + hi + "/" + ti
                                + " lat=" + latitudesDeg[li] + " xp=" + xp + " yp=" + yp
                                + " phpa=" + phpa + " tc=" + tc + " rh=" + rh + " wl=0.55"
                                + " h0deg=" + hourAnglesDeg[hi] + " t=" + t
                                + " errArcsec=" + errArcsec);
                            return false;
                        }
                        if (worstFixture == "" || errArcsec > worst) {
                            worst = errArcsec;
                            worstFixture = "case=" + li + "/" + pmi + "/" + wi + "/" + hi + "/" + ti
                                + " lat=" + latitudesDeg[li] + " xp=" + xp + " yp=" + yp
                                + " phpa=" + phpa + " tc=" + tc + " rh=" + rh + " wl=0.55"
                                + " h0deg=" + hourAnglesDeg[hi] + " t=" + t;
                        }
                    }
                }
            }
        }
    }
    logger.debug("propagation grid worst case errArcsec=" + worst + " " + worstFixture);
    return worst < budgetArcsec;
}

// Item 6 (end-to-end coverage): using the application's actual Polaris
// catalogue input and a representative EOP fixture, the production
// predictor (reticleAt() called on the anchor stored at t=0) must still
// track an independent, full recomputation at each later timestamp (which
// re-runs the entire ephemeris/nutation/aberration chain and re-derives its
// own geometric pole) within the same 0.1 arcsec budget, up through the
// ~900s (15 minute) re-anchor interval.
(:test)
function endToEndPolarisPropagationMatchesFullRecompute(logger as Test.Logger) {
    var pi = 3.1415926535897932384626433832795d;
    var budgetArcsec = 0.1d;
    var rc = (2.0d + 31.0d / 60.0d + 49.09d / 3600.0d) * 15.0d * pi / 180.0d;
    var dc = (89.0d + 15.0d / 60.0d + 50.8d / 3600.0d) * pi / 180.0d;
    var pr = Astrometry.properMotionPrRadYr(44.22d, dc);
    var pd = -11.74e-3d * pi / (180.0d * 3600.0d);
    var px = 7.54e-3d; var rv = -16.0d;
    var utc1 = 2461293.1391319446d; var utc2 = 0.0d; var dut1 = 0.0d;
    var elong = 116.30780d * pi / 180.0d; var phi = 40.06890d * pi / 180.0d; var hm = 125.0d;
    var xp = 2.47230737e-7d; var yp = 1.82640464e-6d;
    var phpa = 731.0d; var tc = 10.0d; var rh = 0.5d; var wl = 0.55d;
    var anchorResult = runAstrometryFull(rc, dc, pr, pd, px, rv, utc1, utc2, dut1, elong, phi, hm, xp, yp, phpa, tc, rh, wl);
    if (anchorResult == null || anchorResult[:status] != 0) { return false; }
    var anchor = anchorResult[:reticleAnchor];
    var anchorPole = [anchorResult[:polePx], anchorResult[:polePy], anchorResult[:polePz]];
    var anchorBasis = Astrometry.poleTangentBasis(anchorPole);
    var times = [60.0d, 300.0d, 600.0d, 899.0d, 900.0d];
    var worst = 0.0d;
    var worstFixture = "";
    var ti = 0;
    for (ti = 0; ti < times.size(); ti += 1) {
        var t = times[ti];
        var predicted = Astrometry.reticleAt(anchor, t);
        var sPred = localFrameToVector(anchorPole, anchorBasis[0], anchorBasis[1], predicted[:x], predicted[:y]);
        var laterResult = runAstrometryFull(rc, dc, pr, pd, px, rv, utc1, utc2 + t / 86400.0d, dut1, elong, phi, hm, xp, yp, phpa, tc, rh, wl);
        if (laterResult == null || laterResult[:status] != 0) { return false; }
        var laterPole = [laterResult[:polePx], laterResult[:polePy], laterResult[:polePz]];
        var laterBasis = Astrometry.poleTangentBasis(laterPole);
        var sRef = localFrameToVector(laterPole, laterBasis[0], laterBasis[1], laterResult[:reticleX], laterResult[:reticleY]);
        var errArcsec = angularSeparationArcsec(sPred, sRef);
        // Same per-case validity/budget guard as the grid test above: reject
        // NaN/negative/over-budget cases individually instead of relying on
        // a running maximum that a NaN comparison could silently bypass.
        if (!(errArcsec >= 0.0d && errArcsec < budgetArcsec)) {
            logger.debug("end-to-end propagation case failed: t=" + t
                + " xp=" + xp + " yp=" + yp + " phpa=" + phpa + " tc=" + tc
                + " rh=" + rh + " wl=" + wl + " errArcsec=" + errArcsec);
            return false;
        }
        if (worstFixture == "" || errArcsec > worst) {
            worst = errArcsec;
            worstFixture = "t=" + t + " xp=" + xp + " yp=" + yp
                + " phpa=" + phpa + " tc=" + tc + " rh=" + rh + " wl=" + wl;
        }
    }
    logger.debug("end-to-end propagation worst case errArcsec=" + worst + " " + worstFixture);
    return worst < budgetArcsec;
}

(:test)
function iersEopInterpolatesAndChecksBoundsAndWarnings(logger as Test.Logger) {
    var a = IersEopData.eop(61292.0);
    var b = IersEopData.eop(61293.0);
    var m = IersEopData.eop(61292.5);
    var finalDay = IersEopData.eop(61659.0);
    var ok = a[:status] == 0 && b[:status] == 0 && m[:status] == 0;
    ok = ok && m[:dut1] > b[:dut1] && m[:dut1] < a[:dut1];
    var loXp = a[:xp] < b[:xp] ? a[:xp] : b[:xp];
    var hiXp = a[:xp] > b[:xp] ? a[:xp] : b[:xp];
    ok = ok && m[:xp] > loXp && m[:xp] < hiXp;
    ok = ok && a[:first] == 61292.0 && a[:last] == 61659.0;
    ok = ok && finalDay[:status] == 0
        && withinTolerance(finalDay[:dut1], -0.1044597d, 1.0e-8d);
    ok = ok && !IersEopData.eop(61628.999999d)[:warning]
        && IersEopData.eop(61629.0d)[:warning];
    ok = ok && IersEopData.eop(61291.999999d)[:status] < 0
        && IersEopData.eop(61659.000001d)[:status] < 0;
    return ok;
}

(:test)
function geoidOffsetConvertsMslToEllipsoid(logger as Test.Logger) {
    var geo = GeoidData.geoidOffset(0.0, 0.0);
    var ok = geo > 17.15 && geo < 17.18;
    var ellipsoid = GeoidData.mslToEllipsoid(0.0, 0.0, 100.0);
    ok = ok && ellipsoid > 117.15 && ellipsoid < 117.18;
    return ok;
}
(:test)
function menuFocusVisibilityTracksDrawableGeometry(logger as Test.Logger) {
    var profiles = [
        new DisplayProfile(218, 218, 19),
        new DisplayProfile(260, 260, 19),
        new DisplayProfile(454, 454, 37)
    ];
    var referenceTops = [68, 82, 104, 116, 244, 250, 276];
    for (var p = 0; p < profiles.size(); p += 1) {
        var profile = profiles[p];
        if (profile.centerX * 2 != profile.width
                || profile.reticleRadius >= profile.reticleSafeRadius) {
            return false;
        }
        for (var t = 0; t < referenceTops.size(); t += 1) {
            var top = profile.rowTop(referenceTops[t], 14);
            var scroll = 0;
            for (var focus = 0; focus < 31; focus += 1) {
                scroll = focusVisibleScroll(top, profile.rowPitch, 14,
                    profile.drawableTop, profile.drawableBottom, focus, scroll);
                var center = top + (focus - scroll) * profile.rowPitch;
                if (center - 14 < profile.drawableTop
                        || center + 14 > profile.drawableBottom) { return false; }
            }
            for (var focusBack = 30; focusBack >= 0; focusBack -= 1) {
                scroll = focusVisibleScroll(top, profile.rowPitch, 14,
                    profile.drawableTop, profile.drawableBottom, focusBack, scroll);
                var backCenter = top + (focusBack - scroll) * profile.rowPitch;
                if (backCenter - 14 < profile.drawableTop
                        || backCenter + 14 > profile.drawableBottom) { return false; }
            }
        }
    }
    return true;
}

(:test)
function variableHeightDetailsKeepFocusedBlockVisible(logger as Test.Logger) {
    var heights = [48, 72, 48, 96, 48, 72];
    var available = 192;
    var start = 0;
    for (var focus = 0; focus < heights.size(); focus += 1) {
        start = variableHeightVisibleStart(heights, focus, start, available);
        var used = 0;
        for (var i = start; i <= focus; i += 1) { used += heights[i]; }
        if (start > focus || used > available) { return false; }
    }
    for (var focusBack = heights.size() - 1; focusBack >= 0; focusBack -= 1) {
        start = variableHeightVisibleStart(heights, focusBack, start, available);
        if (start > focusBack) { return false; }
    }
    return start == 0;
}
(:test)
function atmosphereConditionalRowsRemainSelectable(logger as Test.Logger) {
    // Physical navigation and taps on either half of the omitted manual
    // pressure slot must resolve to an actual rendered row.
    return atmosphereVisibleFocus(1, 1, false) == 2
        && atmosphereVisibleFocus(1, -1, false) == 0
        && atmosphereVisibleFocus(1, 1, true) == 1;
}

(:test)
function emptyLocateNavigationWrapResetsScrollAndSkipsDisabledConfirm(logger as Test.Logger) {
    var wrappedUp = wrapMenuFocus(-1, 8, 0);
    if (wrappedUp[0] != 8 || wrappedUp[1] != 0) { return false; }
    var profiles = [
        new DisplayProfile(218, 218, 19),
        new DisplayProfile(260, 260, 19),
        new DisplayProfile(454, 454, 37)
    ];
    for (var i = 0; i < profiles.size(); i += 1) {
        var profile = profiles[i];
        var top = profile.rowTop(116, 14);
        var locateScroll = focusVisibleScroll(top, profile.rowPitch, 14,
            profile.drawableTop, profile.drawableBottom, wrappedUp[0], wrappedUp[1]);
        var center = top + (wrappedUp[0] - locateScroll) * profile.rowPitch;
        if (center - 14 < profile.drawableTop
                || center + 14 > profile.drawableBottom) { return false; }
    }
    var wrappedDown = wrapMenuFocus(wrappedUp[0] + 1, 8, 4);
    if (wrappedDown[0] != 0 || wrappedDown[1] != 0) { return false; }
    return locateVisibleFocus(7, 1, false) == 8
        && locateVisibleFocus(7, -1, false) == 6
        && locateVisibleFocus(7, 1, true) == 7;
}

(:test)
function reticlePersistenceAndVisualProfilesRemainStable(logger as Test.Logger) {
    return RETICLE_GENERIC == 0
        && RETICLE_IOPTRON == 1
        && RETICLE_SIFO == 2
        && normalizeReticleType(RETICLE_GENERIC) == RETICLE_GENERIC
        && normalizeReticleType(RETICLE_IOPTRON) == RETICLE_IOPTRON
        && normalizeReticleType(RETICLE_SIFO) == RETICLE_SIFO
        && normalizeReticleType(3) == RETICLE_GENERIC
        && normalizeReticleType(null) == RETICLE_GENERIC
        && reticleShowsOuterScale(RETICLE_IOPTRON)
        && !reticleShowsOuterScale(RETICLE_SIFO)
        && !reticleShowsOuterScale(RETICLE_GENERIC);
}

(:test)
function ioptronReticleClockPositionMatchesMarkerGeometry(logger as Test.Logger) {
    return ioptronReticleClockSeconds(0.0) == 21600
        && ioptronReticleClockSeconds(Math.PI / 2.0) == 10800
        && ioptronReticleClockSeconds(Math.PI) == 0
        && ioptronReticleClockSeconds(3.0 * Math.PI / 2.0) == 32400
        && ioptronReticleClockSeconds(2.0 * Math.PI + Math.PI / 6.0) == 18000;
}

(:test)
function ioptronReticleClockMatchesReferenceVector(logger as Test.Logger) {
    var hourAngle = 19.34 * Math.PI / 12.0;
    return ioptronReticleClockSeconds(hourAngle) == 29988;
}
(:test)
function ioptronRingRadiusVector(logger as Test.Logger) {
    var theta = [4.0, 36.0, 40.0, 44.0, 60.0, 65.0, 70.0];
    var expected = [9.7142857143, 87.4285714286, 97.1428571429,
                    106.8571428571, 145.7142857143, 157.8571428571,
                    170.0];
    var ok = true;
    for (var i = 0; i < theta.size(); i += 1) {
        if (!withinTolerance(ioptronRingRadius(theta[i], 170.0),
                             expected[i], 0.0002)) { ok = false; }
    }
    return ok;
}

(:test)
function ioptronTickClassesAndFractions(logger as Test.Logger) {
    var counts = [0, 0, 0];
    var ok = true;
    for (var k = 0; k < 36; k += 1) {
        var expectedClass = (k % 6 == 0) ? 0 : ((k % 3 == 0) ? 1 : 2);
        var expectedFraction = expectedClass == 0 ? 1.0
            : (expectedClass == 1 ? 0.6 : 0.3);
        var tickClass = ioptronTickClass(k);
        if (tickClass != expectedClass) { ok = false; }
        if (tickClass < 0 || tickClass > 2) { return false; }
        counts[tickClass] += 1;
        if (!withinTolerance(ioptronTickSpanFraction(k),
                             expectedFraction, 0.00001)) { ok = false; }
    }
    return ok && counts[0] == 6 && counts[1] == 6 && counts[2] == 24
        && ioptronTickClass(-3) == 1 && ioptronTickClass(36) == 0;
}


(:test)
function ioptronTickEndpointsMatchBothAnnuli(logger as Test.Logger) {
    var directions = [0, 3, 1];
    var expectedInner0 = [87.4285714, 91.3142857, 94.2285714];
    var expectedInner1 = [106.8571429, 102.9714286, 100.0571429];
    var expectedOuter0 = [145.7142857, 150.5714286, 154.2142857];
    var expectedOuter1 = [170.0, 165.1428571, 161.5];
    var ok = true;
    for (var i = 0; i < directions.size(); i += 1) {
        var inner0 = ioptronTickStartRadius(36.0, 44.0, directions[i], 170.0);
        var inner1 = ioptronTickEndRadius(36.0, 44.0, directions[i], 170.0);
        var outer0 = ioptronTickStartRadius(60.0, 70.0, directions[i], 170.0);
        var outer1 = ioptronTickEndRadius(60.0, 70.0, directions[i], 170.0);
        if (!withinTolerance(inner0, expectedInner0[i], 0.0002)
            || !withinTolerance(inner1, expectedInner1[i], 0.0002)
            || !withinTolerance(outer0, expectedOuter0[i], 0.0002)
            || !withinTolerance(outer1, expectedOuter1[i], 0.0002)) {
            ok = false;
        }
    }
    return ok;
}

(:test)
function ioptronNormalize2PiBoundaries(logger as Test.Logger) {
    var twoPi = 2.0 * Math.PI;
    var epsilon = 0.0001;
    var inputs = [0.0, twoPi - epsilon, twoPi, twoPi + epsilon,
                  -epsilon, -twoPi, 2.0 * twoPi + epsilon];
    var expected = [0.0, twoPi - epsilon, 0.0, epsilon,
                    twoPi - epsilon, 0.0, epsilon];
    var ok = ioptronNormalize2Pi(null) == null;
    for (var i = 0; i < inputs.size(); i += 1) {
        var normalized = ioptronNormalize2Pi(inputs[i]);
        if (normalized == null || normalized < 0.0 || normalized >= twoPi
            || !withinTolerance(normalized, expected[i], 0.0002)) {
            ok = false;
        }
    }
    return ok;
}

(:test)
function ioptronMarkerCardinalPositions(logger as Test.Logger) {
    var point = [0.0, 0.0];
    if (!ioptronMarkerPosition(point, 0.0, 0.0, 35.0, 227.0, 227.0, 170.0, 70.0)
            || !withinTolerance(point[0], 227.0, 0.002)
            || !withinTolerance(point[1], 312.0, 0.002)) { return false; }
    var compact = new DisplayProfile(218, 218, 19);
    return ioptronMarkerPosition(point, 0.0, 0.0, 35.0,
            compact.centerX.toFloat(), compact.centerY.toFloat(), compact.reticleRadius, 70.0)
        && withinTolerance(point[0], 109.0, 0.002)
        && withinTolerance(point[1], 109.0 + compact.reticleRadius / 2.0, 0.002);
}

(:test)
function ioptronMarkerAtSixHours(logger as Test.Logger) {
    var point = [0.0, 0.0];
    return ioptronMarkerPosition(point, Math.PI / 2.0, 0.0, 35.0, 227.0, 227.0, 170.0, 70.0)
        && withinTolerance(point[0], 312.0, 0.002)
        && withinTolerance(point[1], 227.0, 0.002);
}

(:test)
function ioptronMarkerAtTwelveHours(logger as Test.Logger) {
    var point = [0.0, 0.0];
    return ioptronMarkerPosition(point, Math.PI, 0.0, 35.0, 227.0, 227.0, 170.0, 70.0)
        && withinTolerance(point[0], 227.0, 0.002)
        && withinTolerance(point[1], 142.0, 0.002);
}

(:test)
function ioptronMarkerAtEighteenHours(logger as Test.Logger) {
    var point = [0.0, 0.0];
    return ioptronMarkerPosition(point, 3.0 * Math.PI / 2.0, 0.0, 35.0, 227.0, 227.0, 170.0, 70.0)
        && withinTolerance(point[0], 142.0, 0.002)
        && withinTolerance(point[1], 227.0, 0.002);
}

(:test)
function reticlePoleDistanceBoundariesAndSifoScale(logger as Test.Logger) {
    if (!reticleValidPoleDistance(RETICLE_IOPTRON, 0.0)
            || !reticleValidPoleDistance(RETICLE_IOPTRON, 70.0)
            || reticleValidPoleDistance(RETICLE_IOPTRON, 70.001)
            || !reticleValidPoleDistance(RETICLE_SIFO, 44.0)
            || reticleValidPoleDistance(RETICLE_SIFO, 44.001)
            || reticleValidPoleDistance(RETICLE_SIFO, -0.001)
            || reticleValidPoleDistance(RETICLE_SIFO, null)) { return false; }
    var profiles = [
        new DisplayProfile(218, 218, 19),
        new DisplayProfile(260, 260, 19),
        new DisplayProfile(454, 454, 37)
    ];
    for (var i = 0; i < profiles.size(); i += 1) {
        var profile = profiles[i];
        var sifoRadius = reticleAngularRadius(RETICLE_SIFO, profile.reticleRadius);
        var point = [0.0, 0.0];
        if (!withinTolerance(reticleAngularRadius(RETICLE_IOPTRON, profile.reticleRadius),
                             profile.reticleRadius, 0.0002)
                || !withinTolerance(ioptronRingRadius(44.0, sifoRadius),
                                    profile.reticleRadius, 0.0002)
                || !ioptronMarkerPosition(point, 0.0, 0.0, 44.0,
                    profile.centerX.toFloat(), profile.centerY.toFloat(),
                    sifoRadius, 44.0)
                || !withinTolerance(point[0], profile.centerX.toFloat(), 0.002)
                || !withinTolerance(point[1],
                                    profile.centerY + profile.reticleRadius, 0.002)
                || ioptronMarkerPosition(point, 0.0, 0.0, 44.001,
                    profile.centerX.toFloat(), profile.centerY.toFloat(),
                    sifoRadius, 44.0)) { return false; }
    }
    return true;
}

(:test)
function ioptronMarkerRejectsNegativePoleDistance(logger as Test.Logger) {
    var point = [0.0, 0.0];
    return !ioptronMarkerPosition(point, 0.0, 0.0, -0.01, 227.0, 227.0, 170.0, 70.0);
}

(:test)
function ioptronMarkerRejectsPoleDistanceAboveSeventy(logger as Test.Logger) {
    var point = [0.0, 0.0];
    return !ioptronMarkerPosition(point, 0.0, 0.0, 70.01, 227.0, 227.0, 170.0, 70.0)
        && !ioptronMarkerPosition(point, 0.0, 0.0, 35.0, 227.0, 227.0, 0.0, 70.0);
}

(:test)
function ioptronRejectsNaNWhenSupported(logger as Test.Logger) {
    var nan = 0.0;
    try {
        nan = Math.sqrt(-1.0);
    } catch (e) {
        return true;
    }
    if (nan == nan) { return true; }
    return !reticleValidPoleDistance(RETICLE_IOPTRON, nan)
        && ioptronNormalize2Pi(nan) == null;
}

(:test)
function ioptronMarkerRejectsNaNWhenSupported(logger as Test.Logger) {
    var nan = 0.0;
    try {
        nan = Math.sqrt(-1.0);
    } catch (e) {
        return true;
    }
    if (nan == nan) { return true; }
    var point = [0.0, 0.0];
    return !ioptronMarkerPosition(point, nan, 0.0, 35.0, 227.0, 227.0, 170.0, 70.0);
}

(:test)
function ioptronMarkerAdvancesAcrossWrap(logger as Test.Logger) {
    var twoPi = 2.0 * Math.PI;
    var startAngle = twoPi - 0.2;
    var elapsedSeconds = 3600.0;
    var poleDistance = 35.0;
    // For elapsed=3600 s, H=2π−0.2+elapsed*(1.0027379π/43200)
    // wraps to 0.0625162 rad and rho=170*35/70=85 px.
    var point = [0.0, 0.0];
    var ok = ioptronMarkerPosition(point, startAngle, elapsedSeconds, poleDistance, 227.0, 227.0, 170.0, 70.0)
        && withinTolerance(point[0], 232.3104, 0.01)
        && withinTolerance(point[1], 311.8340, 0.01);
    var invalidElapsed = ioptronMarkerPosition(point, startAngle, null, poleDistance, 227.0, 227.0, 170.0, 70.0);
    return ok && !invalidElapsed;
}

class DisplayInputTestView {
    var screen = PolarFinderView.DISPLAY;
    var taps = 0;
    var navigation = 0;
    var backs = 0;

    function touchWakeOnly() { return screen == PolarFinderView.DISPLAY; }
    function tap(y) { taps += 1; }
    function navigate(delta) { navigation += delta; }
    function select() {
        if (screen == PolarFinderView.DISPLAY) { screen = PolarFinderView.ACTIONS; }
    }
    function back() {
        backs += 1;
        if (screen == PolarFinderView.DISPLAY) { screen = PolarFinderView.LOCATE; }
    }
}

(:test)
function displayDelegateSeparatesTouchFromPhysicalButtons(logger as Test.Logger) {
    var view = new DisplayInputTestView();
    var delegate = new PolarFinderDelegate(view);

    // The ambiguous behavior layer must not mutate state. Its false result
    // allows the framework to forward the original event to a raw callback.
    if (delegate.onSelect() || delegate.onNextPage()
            || delegate.onPreviousPage() || delegate.onBack()
            || view.screen != PolarFinderView.DISPLAY) { return false; }

    // Raw touch is consumed on Display without invoking any app action.
    if (!delegate.consumeTouch() || view.screen != PolarFinderView.DISPLAY
            || view.taps != 0 || view.navigation != 0 || view.backs != 0) {
        return false;
    }

    // A physical START/Select still opens Actions.
    if (!delegate.handleKey(WatchUi.KEY_ENTER)
            || view.screen != PolarFinderView.ACTIONS) { return false; }

    // Other screens retain tap, vertical swipe, and right-swipe Back actions.
    if (!delegate.handleTap(227)
            || !delegate.handleSwipe(WatchUi.SWIPE_UP)
            || !delegate.handleSwipe(WatchUi.SWIPE_RIGHT)
            || view.taps != 1 || view.navigation != 1 || view.backs != 1) {
        return false;
    }

    // Physical BACK from Display still returns to Locate.
    view.screen = PolarFinderView.DISPLAY;
    return delegate.handleKey(WatchUi.KEY_ESC)
        && view.screen == PolarFinderView.LOCATE;
}
