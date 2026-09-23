/*
 * Derived work based on the International Astronomical Union SOFA (Standards
 * of Fundamental Astronomy) collection, release 2016-05-03.  Algorithms and
 * constants are translated to Monkey C and adapted for value-return arrays and
 * dictionaries. This is not software provided by or endorsed by SOFA.
 * SOFA-derived routine names omit the iau/sofa prefix as required by license.
 */

// Atmospheric refraction, local pole geometry, and between-anchor projection.
import Toybox.Math;
module Astrometry {
    function refco(phpa, tc, rh, wl) {
        var t = clamp(tc, -150.0, 200.0),
            p = clamp(phpa, 0.0, 10000.0),
            r = clamp(rh, 0.0, 1.0),
            w = clamp(wl, 0.1, 1e6),
            ps = 0.0,
            pw = 0.0;
        if (p > 0.0) {
            ps = Math.pow(10.0, (0.7859 + 0.03477 * t) / (1.0 + 0.00412 * t))
                * (1.0 + p * (4.5e-6 + 6e-10 * t * t));
            pw = r * ps / (1.0 - (1.0 - r) * ps / p);
        }
        var tk = t + 273.15,
            wlsq = w * w,
            gamma = ((77.53484e-6 + (4.39108e-7 + 3.666e-9 / wlsq) / wlsq) * p - 11.2684e-6 * pw)
                / tk,
            beta = 4.4474e-6 * tk;
        return [gamma * (1.0 - beta), -gamma * (beta - gamma / 2.0)];
    }
    // Local horizon-frame ray (SOFA "aet"/"aeo" convention: z is the local
    // zenith, azimuth = atan2(y,-x)) for a CIRS direction (ri,di) observed at
    // local Earth rotation angle eral, given polar motion tilted onto the
    // local meridian (xpl,ypl), geodetic latitude (sphi,cphi), diurnal
    // aberration magnitude, and refraction constants refa/refb. Returns
    // [xaet,yaet,zaet, xaeo,yaeo,zaeo, az, zd]: "aet" is the ray before
    // atmospheric refraction, "aeo" is the refraction-bent observed ray.
    function localHorizonRay(ri, di, eral, xpl, ypl, sphi, cphi, diurab, refa, refb) {
        var hv = s2c(ri - eral, di);
        var xx = hv[0];
        var yy = hv[1];
        var zz = hv[2];
        var xhd = xx + xpl * zz;
        var yhd = yy - ypl * zz;
        var zhd = zz - xpl * xx + ypl * yy;
        var ff0 = 1.0 - diurab * yhd;
        var xhdt = ff0 * xhd;
        var yhdt = ff0 * (yhd + diurab);
        var zhdt = ff0 * zhd;
        var xaet = sphi * xhdt - cphi * zhdt;
        var yaet = yhdt;
        var zaet = cphi * xhdt + sphi * zhdt;
        var az = (xaet != 0.0 || yaet != 0.0) ? Math.atan2(yaet, -xaet) : 0.0;
        var rr = Math.sqrt(xaet * xaet + yaet * yaet);
        if (rr <= 1e-6) {
            rr = 1e-6;
        }
        var zsafe = zaet > 0.05 ? zaet : 0.05;
        var tz = rr / zsafe;
        var rw = refb * tz * tz;
        var delta = (refa + rw) * tz / (1.0 + (refa + 3.0 * rw) / (zsafe * zsafe));
        var cdel = 1.0 - delta * delta / 2.0;
        var fobs = cdel - delta * zsafe / rr;
        var xaeo = xaet * fobs;
        var yaeo = yaet * fobs;
        var zaeo = cdel * zaet + delta * rr;
        var zd = Math.atan2(Math.sqrt(xaeo * xaeo + yaeo * yaeo), zaeo);
        return [xaet, yaet, zaet, xaeo, yaeo, zaeo, az, zd];
    }
    
    // The mount's mechanical RA axis targets the geometric Earth rotation
    // axis (the Celestial Intermediate Pole), not an incoming light ray, so
    // it must never be refracted, aberrated, or otherwise treated as an
    // incoming light ray. In the CIRS frame the CIP is trivially [0,0,1]
    // (dec=+90 regardless of RA), so its local horizon direction is obtained
    // by running that trivial vector through the SAME polar-motion geometry
    // used for Polaris above, but purely as a geometric rotation -- there is
    // no refa/refb/diurab argument to accidentally misuse here. The result
    // does not depend on Earth rotation angle or on Polaris's own position,
    // only on polar motion (xp,yp) and geodetic latitude, so it stays valid
    // without recomputation for as long as the anchor is valid.
    function geometricPoleLocalVector(xpl, ypl, sphi, cphi) {
        var xaet = sphi * xpl - cphi;
        var yaet = -ypl;
        var zaet = cphi * xpl + sphi;
        return normalize3([xaet, yaet, zaet]);
    }
    
    // Orthonormal tangent-plane basis centered on the geometric pole p, with
    // "up" (u) chosen toward the local zenith z=(0,0,1) per the reticle
    // convention, and v completing a right-handed frame.
    function poleTangentBasis(p) {
        var zp = p[2];
        var u = normalize3([-zp * p[0], -zp * p[1], 1.0 - zp * zp]);
        var v = cross3(p, u);
        return [u, v];
    }
    
    // Gnomonic (tangent-plane) coordinates of local unit vector s relative
    // to pole p with basis (u,v): X grows toward v, Y grows toward u.
    function poleTangentXY(s, p, u, v) {
        var spDot = dp(s, p);
        if (spDot == 0.0) {
            spDot = 1.0e-12;
        }
        return [dp(s, v) / spDot, dp(s, u) / spDot];
    }
    
    // Cheap between-anchor reevaluation of the reticle solution at
    // anchor-time + elapsedSeconds. Reuses every expensive quantity from the
    // anchor (CIRS direction, polar-motion geometry, refraction coefficients,
    // geometric pole and tangent basis) and only recomputes the Earth
    // Rotation Angle (era00 is an O(1) polynomial, not a series) for the new
    // UT1 timestamp. This preserves the exact (non-linear) relationship
    // between Earth rotation and the refracted ray's position around the
    // geometric pole, instead of assuming either a constant pole distance or
    // a constant angular rate.
    //
    // elapsedSeconds is treated as elapsed UT1 (dut1 is frozen at the anchor
    // value); UT1-UTC drifts by at most a few milliseconds per day, so this
    // is negligible over the ~15 minute anchor lifetime.
    function reticleAt(anchor, elapsedSeconds) {
        var eral = era00(anchor[:ut1a], anchor[:ut1b] + elapsedSeconds / DAYSEC) + anchor[:along];
        var ray = localHorizonRay(
            anchor[:ri],
            anchor[:di],
            eral,
            anchor[:xpl],
            anchor[:ypl],
            anchor[:sphi],
            anchor[:cphi],
            0.0,
            anchor[:refa],
            anchor[:refb]
        );
        var xaeo = ray[3];
        var yaeo = ray[4];
        var zaeo = ray[5];
        var norm = Math.sqrt(xaeo * xaeo + yaeo * yaeo + zaeo * zaeo);
        if (norm == 0.0) {
            norm = 1.0e-12;
        }
        var sx = xaeo / norm;
        var sy = yaeo / norm;
        var sz = zaeo / norm;
        var spDot = sx * anchor[:polePx] + sy * anchor[:polePy] + sz * anchor[:polePz];
        if (spDot == 0.0) {
            spDot = 1.0e-12;
        }
        var xVal = (sx * anchor[:vX] + sy * anchor[:vY] + sz * anchor[:vZ]) / spDot;
        var yVal = (sx * anchor[:uX] + sy * anchor[:uY] + sz * anchor[:uZ]) / spDot;
        return {
            :hourAngle => Math.atan2(-xVal, yVal),
            :poleDistance => Math.atan(Math.sqrt(xVal * xVal + yVal * yVal)),
            :x => xVal,
            :y => yVal,
            :aob => anp(ray[6]),
            :zob => ray[7],
            :altitude => D2PI / 4.0 - ray[7]
        };
    }
}
