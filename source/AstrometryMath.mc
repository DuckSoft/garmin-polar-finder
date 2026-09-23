/*
 * Derived work based on the International Astronomical Union SOFA (Standards
 * of Fundamental Astronomy) collection, release 2016-05-03.  Algorithms and
 * constants are translated to Monkey C and adapted for value-return arrays and
 * dictionaries. This is not software provided by or endorsed by SOFA.
 * SOFA-derived routine names omit the iau/sofa prefix as required by license.
 */

// Shared constants, angle arithmetic, vectors, and rotation matrices.
import Toybox.Math;
module Astrometry {
    var D2PI = 6.283185307179586476925287;
    var DAS2R = 4.848136811095359935899141e-6;
    var DS2R = 7.272205216643039903848712e-5;
    var TURNAS = 1296000.0;
    var DAYSEC = 86400.0;
    var DJY = 365.25;
    var DJC = 36525.0;
    var DJ00 = 2451545.0;
    var DAU = 149597870000.0;
    var AULT = 499.004782;
    var SRS = 1.97412574336e-8;
    var DC = DAYSEC / AULT;
    var CR = AULT / DAYSEC;
    var AUDMS = DAU / DAYSEC;
    function mod(a, b) {
        return a - Math.floor(a / b) * b;
    }
    function anp(a) {
        var w = mod(a, D2PI);
        return w < 0.0 ? w + D2PI : w;
    }
    function clamp(a, lo, hi) {
        return a < lo ? lo : (a > hi ? hi : a);
    }
    function dp(a, b) {
        return a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
    }
    function pm(a) {
        return Math.sqrt(dp(a, a));
    }
    function pn(a) {
        var r = pm(a);
        return [r, a[0] / r, a[1] / r, a[2] / r];
    }
    function s2c(a, b) {
        var r = Math.cos(b);
        return [Math.cos(a) * r, Math.sin(a) * r, Math.sin(b)];
    }
    function c2s(p) {
        return [Math.atan2(p[1], p[0]), Math.atan2(p[2], Math.sqrt(p[0] * p[0] + p[1] * p[1]))];
    }
    function rx(a, r) {
        var s = Math.sin(a), c = Math.cos(a);
        var j = 0;
        for (j = 0; j < 3; j += 1) {
            var y = r[1][j], z = r[2][j];
            r[1][j] = c * y + s * z;
            r[2][j] = -s * y + c * z;
        }
        return r;
    }
    function ry(a, r) {
        var s = Math.sin(a), c = Math.cos(a);
        var j = 0;
        for (j = 0; j < 3; j += 1) {
            var x = r[0][j], z = r[2][j];
            r[0][j] = c * x - s * z;
            r[2][j] = s * x + c * z;
        }
        return r;
    }
    function rz(a, r) {
        var s = Math.sin(a), c = Math.cos(a);
        var j = 0;
        for (j = 0; j < 3; j += 1) {
            var x = r[0][j], y = r[1][j];
            r[0][j] = c * x + s * y;
            r[1][j] = -s * x + c * y;
        }
        return r;
    }
    function ident() {
        return [[1.0d, 0.0d, 0.0d], [0.0d, 1.0d, 0.0d], [0.0d, 0.0d, 1.0d]];
    }
    function rxp(r, p) {
        return [
            r[0][0] * p[0] + r[0][1] * p[1] + r[0][2] * p[2],
            r[1][0] * p[0] + r[1][1] * p[1] + r[1][2] * p[2],
            r[2][0] * p[0] + r[2][1] * p[1] + r[2][2] * p[2]
        ];
    }
    function trxpv(r, pv) {
        return [
            [
                r[0][0] * pv[0][0] + r[1][0] * pv[0][1] + r[2][0] * pv[0][2],
                r[0][1] * pv[0][0] + r[1][1] * pv[0][1] + r[2][1] * pv[0][2],
                r[0][2] * pv[0][0] + r[1][2] * pv[0][1] + r[2][2] * pv[0][2]
            ],
            [
                r[0][0] * pv[1][0] + r[1][0] * pv[1][1] + r[2][0] * pv[1][2],
                r[0][1] * pv[1][0] + r[1][1] * pv[1][1] + r[2][1] * pv[1][2],
                r[0][2] * pv[1][0] + r[1][2] * pv[1][1] + r[2][2] * pv[1][2]
            ]
        ];
    }
    function normalize3(v) {
        var n = pn(v);
        return [n[1], n[2], n[3]];
    }
    function cross3(a, b) {
        return [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]];
    }
}
