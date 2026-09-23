/*
 * Derived work based on the International Astronomical Union SOFA (Standards
 * of Fundamental Astronomy) collection, release 2016-05-03.  Algorithms and
 * constants are translated to Monkey C and adapted for value-return arrays and
 * dictionaries. This is not software provided by or endorsed by SOFA.
 * SOFA-derived routine names omit the iau/sofa prefix as required by license.
 */

// Catalog proper motion, parallax, solar deflection, and aberration.
import Toybox.Math;
module Astrometry {
    function ldsun(p, e, em) {
        var qpe = [p[0] + e[0], p[1] + e[1], p[2] + e[2]], qd = dp(p, qpe), qv = em * em;
        var lim = 1e-6 / (qv > 1.0 ? qv : 1.0),
            w = SRS / em / (qd > lim ? qd : lim),
            eq = [e[1] * p[2] - e[2] * p[1], e[2] * p[0] - e[0] * p[2], e[0] * p[1] - e[1] * p[0]],
            peq = [
                p[1] * eq[2] - p[2] * eq[1],
                p[2] * eq[0] - p[0] * eq[2],
                p[0] * eq[1] - p[1] * eq[0]
            ];
        return [p[0] + w * peq[0], p[1] + w * peq[1], p[2] + w * peq[2]];
    }
    function aberration(p, v, s, bm1) {
        var pdv = dp(p, v), w1 = 1.0 + pdv / (1.0 + bm1), w2 = SRS / s, r = [0.0, 0.0, 0.0];
        var i = 0;
        for (i = 0; i < 3; i += 1) {
            r[i] = p[i] * bm1 + w1 * v[i] + w2 * (v[i] - pdv * p[i]);
        }
        var q = pm(r);
        return [r[0] / q, r[1] / q, r[2] / q];
    }
    function pmpx(rc, dc, pr, pd, px, rv, pmt, pob) {
        var sr = Math.sin(rc),
            cr = Math.cos(rc),
            sd = Math.sin(dc),
            cd = Math.cos(dc),
            x = cr * cd,
            y = sr * cd,
            z = sd,
            p = [x, y, z],
            dt = pmt + dp(p, pob) * (AULT / DAYSEC / DJY),
            pxr = px * DAS2R,
            w = (DAYSEC * DJY / DAU) * rv * pxr,
            pdz = pd * z,
            pmv = [-pr * y - pdz * cr + w * x, pr * x - pdz * sr + w * y, pd * cd + w * z];
        var i = 0;
        for (i = 0; i < 3; i += 1) {
            p[i] += dt * pmv[i] - pxr * pob[i];
        }
        var n = pn(p);
        return [n[1], n[2], n[3]];
    }
    // Star catalogs conventionally tabulate the RA proper motion as
    // mu_alpha* = d(alpha)/dt * cos(dec) ("pmRaStarMasYr", mas/yr), while the
    // SOFA-style pr argument consumed by pmpx()/atciq() wants the raw
    // coordinate rate d(alpha)/dt ("prRadYr", rad/yr). The cos(dec) factor
    // must be divided back out before converting units; this is not a fixed
    // constant because it depends on the star's own declination. For Polaris
    // (dec ~ 89.264 deg = 89 15' 50.8", cos(dec) ~ 0.012843), this is roughly
    // a 78-fold correction to the RA *coordinate rate*, not a claim that
    // Polaris' physical tangential proper motion itself is 78x larger:
    // multiplying prRadYr back by cos(dec) recovers the catalog's
    // pmRaStarMasYr.
    //
    // MAS2RAD_D is a dedicated Double-precision milliarcsec->radian factor
    // for this specific high-precision conversion path. It is deliberately
    // NOT expressed via the shared module-level DAS2R constant used
    // throughout the rest of this SOFA port, because DAS2R (and most other
    // scalar constants in AstrometryMath.mc) are plain Monkey C float literals
    // (32-bit, ~7 significant digits); reusing DAS2R here would silently
    // reintroduce Float-level rounding into an otherwise Double-precision
    // computation. This does not change DAS2R itself or any other table in
    // the port.
    var MAS2RAD_D = 4.84813681109535993589914102358e-9d;
    function properMotionPrRadYr(pmRaStarMasYr, decRad) {
        var pmRaStarRadYr = pmRaStarMasYr * MAS2RAD_D;
        return pmRaStarRadYr / Math.cos(decRad);
    }
}
