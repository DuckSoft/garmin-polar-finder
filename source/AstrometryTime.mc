/*
 * Derived work based on the International Astronomical Union SOFA (Standards
 * of Fundamental Astronomy) collection, release 2016-05-03.  Algorithms and
 * constants are translated to Monkey C and adapted for value-return arrays and
 * dictionaries. This is not software provided by or endorsed by SOFA.
 * SOFA-derived routine names omit the iau/sofa prefix as required by license.
 */

// Leap seconds, calendar conversion, and UTC/TAI/TT/UT1 time scales.
import Toybox.Math;
module Astrometry {
    // SOFA 2016-05-03 table with the official 2017-01 TAI-UTC update appended.
    var LEAPS = [
        [1972, 1, 10],
        [1972, 7, 11],
        [1973, 1, 12],
        [1974, 1, 13],
        [1975, 1, 14],
        [1976, 1, 15],
        [1977, 1, 16],
        [1978, 1, 17],
        [1979, 1, 18],
        [1980, 1, 19],
        [1981, 7, 20],
        [1982, 7, 21],
        [1983, 7, 22],
        [1985, 7, 23],
        [1988, 1, 24],
        [1990, 1, 25],
        [1991, 1, 26],
        [1992, 7, 27],
        [1993, 7, 28],
        [1994, 7, 29],
        [1996, 1, 30],
        [1997, 7, 31],
        [1999, 1, 32],
        [2006, 1, 33],
        [2009, 1, 34],
        [2012, 7, 35],
        [2015, 7, 36],
        [2017, 1, 37]
    ];
    
    function unixSecondsToJulianDate(seconds) {
        return 2440587.5d + seconds.toDouble() / 86400.0d;
    }
    function jd2cal(j1, j2) {
        var jd = j1 + j2, z = Math.floor(jd + 0.5), f = jd + 0.5 - z, a, aa, b, c, d, e;
        if (z < 2299161) {
            a = z;
        } else {
            aa = Math.floor((z - 1867216.25) / 36524.25);
            a = z + 1 + aa - Math.floor(aa / 4);
        }
        b = a + 1524;
        c = Math.floor((b - 122.1) / 365.25);
        d = Math.floor(365.25 * c);
        e = Math.floor((b - d) / 30.6001);
        var day = b - d - Math.floor(30.6001 * e) + f;
        var mo = e < 14 ? e - 1 : e - 13;
        var yr = mo > 2 ? c - 4716 : c - 4715;
        return [yr, mo, Math.floor(day), day - Math.floor(day)];
    }
    function dat(y, m, d, f) {
        var v = 0.0;
        var i = 0;
        for (i = 0; i < LEAPS.size(); i += 1) {
            if (y > LEAPS[i][0] || (y == LEAPS[i][0] && m >= LEAPS[i][1])) {
                v = LEAPS[i][2];
            }
        }
        return y < 1972 ? 0.0 : v;
    }
    function utctai(u1, u2) {
        var c = jd2cal(u1, u2);
        return [0, u1, u2 + dat(c[0], c[1], c[2], c[3]) / DAYSEC];
    }
    function utcut1(u1, u2, dut1) {
        return [0, u1, u2 + dut1 / DAYSEC];
    }
    function tai2tt(t1, t2) {
        return [t1, t2 + 32.184 / DAYSEC];
    }
}
