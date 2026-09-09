import Toybox.Test;

/* Official SOFA t_atco13 vector (release 2016-05-03). Monkey C Float
 * arithmetic is retained by the target runtime; angular tolerances are the
 * smallest bounds that contain its measured single-precision result. */
function withinTolerance(actual, expected, tolerance) {
    var error = actual - expected;
    if (error < 0.0) { error = -error; }
    return error <= tolerance;
}

(:test)
function astrometryReferenceVector(logger as Test.Logger) {
    var r = Astrometry.calculate(
        2.71, 0.174, 1e-5, 5e-6, 0.1, 55.0,
        2456384.5, 0.969254051, 0.1550675,
        -0.527800806, -1.2345856, 2738.0,
        2.47230737e-7, 1.82640464e-6,
        731.0, 12.8, 0.59, 0.55);
    var ok = r[:status] == 0;
    var names = [:aob, :zob, :hob, :dob, :rob, :eo];
    var expected = [0.09251774485358230653, 1.407661405256767021,
                    -0.09265154431403157925, 0.1716626560075591655,
                    2.710260453503097719, -0.003020548354802412839];
    var tolerance = [2e-6, 1e-7, 2e-6, 1e-7, 5e-7, 3e-8];
    var i = 0;
    for (i = 0; i < names.size(); i += 1) {
        if (!withinTolerance(r[names[i]], expected[i], tolerance[i])) { ok = false; }
    }
    var injectedError = expected[0] + tolerance[0] * 2.0;
    if (withinTolerance(injectedError, expected[0], tolerance[0])) { ok = false; }
    return ok;
}

(:test)
function astrometryResumableReferenceVector(logger as Test.Logger) {
    var state = Astrometry.begin(2.71, 0.174, 1e-5, 5e-6, 0.1, 55.0,
        2456384.5, 0.969254051, 0.1550675,
        -0.527800806, -1.2345856, 2738.0,
        2.47230737e-7, 1.82640464e-6,
        731.0, 12.8, 0.59, 0.55);
    var direct = Astrometry.calculate(2.71, 0.174, 1e-5, 5e-6, 0.1, 55.0,
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
    ok = ok && done && steps > 10 && result[:status] == direct[:status];
    var names = [:aob, :zob, :hob, :dob, :rob, :eo];
    var tolerance = [2e-6, 1e-7, 2e-6, 1e-7, 5e-7, 3e-8];
    var i = 0;
    for (i = 0; i < names.size(); i += 1) {
        if (!withinTolerance(result[names[i]], direct[names[i]], tolerance[i])) { ok = false; }
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

(:test)
function astrometryRejectsOutOfRangeUtc(logger as Test.Logger) {
    var r = Astrometry.calculate(2.71, 0.174, 1e-5, 5e-6, 0.1, 55.0,
        1000000.0, 0.0, 0.0, -0.5278, -1.2346, 2738.0,
        0.0, 0.0, 731.0, 12.8, 0.59, 0.55);
    return r[:status] < 0;
}

(:test)
function earthDataInterpolatesAndRejects(logger as Test.Logger) {
    var a = EarthData.eop(61292.0);
    var b = EarthData.eop(61293.0);
    var m = EarthData.eop(61292.5);
    var ok = a[:status] == 0 && b[:status] == 0 && m[:status] == 0;
    ok = ok && m[:dut1] > b[:dut1] && m[:dut1] < a[:dut1];
    var loXp = a[:xp] < b[:xp] ? a[:xp] : b[:xp];
    var hiXp = a[:xp] > b[:xp] ? a[:xp] : b[:xp];
    ok = ok && m[:xp] > loXp && m[:xp] < hiXp;
    ok = ok && !a[:warning] && EarthData.eop(61659.0)[:warning];
    ok = ok && EarthData.eop(61660.0)[:status] < 0;
    var geo = EarthData.geoidOffset(0.0, 0.0);
    ok = ok && geo > 17.15 && geo < 17.18;
    var ellipsoid = EarthData.mslToEllipsoid(0.0, 0.0, 100.0);
    ok = ok && ellipsoid > 117.15 && ellipsoid < 117.18;
    return ok;
}
(:test)
function menuFocusVisibilityTracksDrawableGeometry(logger as Test.Logger) {
    // The saved Locate layout derives its row top and rectangle height from
    // the fr965 fonts. At the observed geometry, focus 5 must scroll on the
    // first DOWN from focus 4 rather than waiting for a fixed slot count.
    var scroll = focusVisibleScroll(164, 42, 18, 58, 390, 5, 0);
    var center = 164 + (5 - scroll) * 42;
    if (scroll != 1 || center - 18 < 58 || center + 18 > 390) { return false; }

    // Exercise all menu geometries, including Details' 31 rows, in both
    // directions. Every selected row must remain wholly drawable.
    var tops = [68, 82, 104, 116, 244, 250, 276];
    for (var t = 0; t < tops.size(); t += 1) {
        scroll = 0;
        for (var focus = 0; focus < 31; focus += 1) {
            scroll = focusVisibleScroll(tops[t], 42, 14, 58, 390, focus, scroll);
            center = tops[t] + (focus - scroll) * 42;
            if (center - 14 < 58 || center + 14 > 390) { return false; }
        }
        for (var focusBack = 30; focusBack >= 0; focusBack -= 1) {
            scroll = focusVisibleScroll(tops[t], 42, 14, 58, 390, focusBack, scroll);
            center = tops[t] + (focusBack - scroll) * 42;
            if (center - 14 < 58 || center + 14 > 390) { return false; }
        }
    }
    return true;
}
(:test)
function atmosphereConditionalRowsRemainSelectable(logger as Test.Logger) {
    // Physical navigation and taps on either half of the omitted manual
    // pressure slot must resolve to an actual rendered row.
    return atmosphereVisibleFocus(1, 1, false) == 2
        && atmosphereVisibleFocus(1, -1, false) == 0
        && atmosphereVisibleFocus(1, 1, true) == 1;
}
