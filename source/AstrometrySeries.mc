/*
 * Derived work based on the International Astronomical Union SOFA (Standards
 * of Fundamental Astronomy) collection, release 2016-05-03.  Algorithms and
 * constants are translated to Monkey C and adapted for value-return arrays and
 * dictionaries. This is not software provided by or endorsed by SOFA.
 * SOFA-derived routine names omit the iau/sofa prefix as required by license.
 */

// Budgeted ephemeris, nutation, and CIO series evaluation for step().
import Toybox.Math;
module Astrometry {
    function resumableEpvChunk(state, budget) {
        var left = budget;
        while (left > 0 && state[:epvPhase] < 2) {
            var phase = state[:epvPhase];
            var i = state[:ei];
            var k = state[:ek];
            var j = state[:ej];
            if (i >= 3) {
                if (phase == 0) {
                    var z = 0;
                    for (z = 0; z < 3; z += 1) {
                        state[:pb][z] = state[:ph][z];
                        state[:pbd][z] = state[:phd][z];
                    }
                    state[:epvPhase] = 1;
                    state[:ei] = 0;
                    state[:ek] = 0;
                    state[:ej] = 0;
                } else {
                    state[:epvPhase] = 2;
                }
                continue;
            }
            var groups = phase == 0 ? state[:es] : state[:ss];
            var ca = groups[k][i];
            var n = ca.size() / 3;
            if (j >= n) {
                state[:ej] = 0;
                state[:ek] = k + 1;
                if (state[:ek] >= 3) {
                    state[:ek] = 0;
                    state[:ei] = i + 1;
                }
                continue;
            }
            var ix = 3 * j;
            var a = ca[ix];
            var b = ca[ix + 1];
            var cc = ca[ix + 2];
            var t = state[:epvT];
            var t2 = t * t;
            var ct = cc * t;
            var p = b + ct;
            var cp = Math.cos(p);
            var xyz = phase == 0 ? state[:ph][i] : state[:pb][i];
            var xyzd = phase == 0 ? state[:phd][i] : state[:pbd][i];
            if (k == 0) {
                xyz += a * cp;
                xyzd -= a * cc * Math.sin(p);
            } else if (k == 1) {
                xyz += a * t * cp;
                xyzd += a * (cp - ct * Math.sin(p));
            } else {
                xyz += a * t2 * cp;
                xyzd += a * t * (2.0 * cp - ct * Math.sin(p));
            }
            if (phase == 0) {
                state[:ph][i] = xyz;
                state[:phd][i] = xyzd;
            } else {
                state[:pb][i] = xyz;
                state[:pbd][i] = xyzd;
            }
            state[:ej] = j + 1;
            state[:epvDone] += 1;
            left -= 1;
        }
        if (state[:epvPhase] == 2) {
            var a12 = 0.000000211284;
            var a13 = -0.000000091603;
            var a21 = -0.000000230286;
            var a22 = 0.917482137087;
            var a23 = -0.397776982902;
            var a32 = 0.397776982902;
            var a33 = 0.917482137087;
            var h = [
                [
                    state[:ph][0] + a12 * state[:ph][1] + a13 * state[:ph][2],
                    state[:ph][0] * a21 + state[:ph][1] * a22 + state[:ph][2] * a23,
                    state[:ph][1] * a32 + state[:ph][2] * a33
                ],
                [
                    state[:phd][0] / DJY + a12 * state[:phd][1] / DJY + a13 * state[:phd][2] / DJY,
                    (state[:phd][0] * a21 + state[:phd][1] * a22 + state[:phd][2] * a23) / DJY,
                    (state[:phd][1] * a32 + state[:phd][2] * a33) / DJY
                ]
            ];
            var b = [
                [
                    state[:pb][0] + a12 * state[:pb][1] + a13 * state[:pb][2],
                    state[:pb][0] * a21 + state[:pb][1] * a22 + state[:pb][2] * a23,
                    state[:pb][1] * a32 + state[:pb][2] * a33
                ],
                [
                    (state[:pbd][0] * 1.0 + a12 * state[:pbd][1] + a13 * state[:pbd][2]) / DJY,
                    (state[:pbd][0] * a21 + state[:pbd][1] * a22 + state[:pbd][2] * a23) / DJY,
                    (state[:pbd][1] * a32 + state[:pbd][2] * a33) / DJY
                ]
            ];
            state[:ev] = [0, h, b];
        }
        state[:progress] = 0.05 + 0.35 * state[:epvDone] / state[:epvTotal];
        return state[:epvPhase] == 2;
    }
    
    function resumableNutChunk(state, budget) {
        var left = budget;
        while (left > 0 && state[:nutPhase] < 2) {
            if (state[:nutPhase] == 0) {
                var i = state[:ni];
                if (i < 0) {
                    state[:nutPhase] = 1;
                    state[:ni] = xpl.size() - 17;
                    continue;
                }
                var arg = mod(
                    xls[i] * state[:el] + xls[i + 1] * state[:elp] + xls[i + 2] * state[:f]
                        + xls[i + 3] * state[:d]
                        + xls[i + 4] * state[:om],
                    D2PI
                );
                var sa = Math.sin(arg);
                var ca = Math.cos(arg);
                state[:dpv] += (xls[i + 5] + xls[i + 6] * state[:nutT]) * sa + xls[i + 7] * ca;
                state[:dev] += (xls[i + 8] + xls[i + 9] * state[:nutT]) * ca + xls[i + 10] * sa;
                state[:ni] = i - 11;
            } else {
                var q = state[:ni];
                if (q < 0) {
                    state[:nutPhase] = 2;
                    continue;
                }
                var ar = mod(
                    xpl[q] * state[:al] + xpl[q + 1] * state[:af] + xpl[q + 2] * state[:ad]
                        + xpl[q + 3] * state[:aom]
                        + xpl[q + 4] * state[:alme]
                        + xpl[q + 5] * state[:alve]
                        + xpl[q + 6] * state[:alea]
                        + xpl[q + 7] * state[:alma]
                        + xpl[q + 8] * state[:alju]
                        + xpl[q + 9] * state[:alsa]
                        + xpl[q + 10] * state[:alur]
                        + xpl[q + 11] * state[:alne]
                        + xpl[q + 12] * state[:apa],
                    D2PI
                );
                var sns = Math.sin(ar);
                var ccs = Math.cos(ar);
                state[:dpp] += xpl[q + 13] * sns + xpl[q + 14] * ccs;
                state[:dep] += xpl[q + 15] * sns + xpl[q + 16] * ccs;
                state[:ni] = q - 17;
            }
            state[:nutDone] += 1;
            left -= 1;
        }
        if (state[:nutPhase] == 2) {
            var u2r = DAS2R / 1e7;
            var n0 = (state[:dpv] + state[:dpp]) * u2r;
            var n1 = (state[:dev] + state[:dep]) * u2r;
            var fj2 = -2.7774e-6 * state[:nutT];
            state[:nut] = [n0 + n0 * (0.4697e-6 + fj2), n1 + n1 * fj2];
        }
        state[:progress] = 0.40 + 0.35 * state[:nutDone] / state[:nutTotal];
        return state[:nutPhase] == 2;
    }
    
    function resumableS06Chunk(state, budget) {
        var left = budget;
        while (left > 0 && state[:s06Phase] < 5) {
            var arr = state[:s06Arrays][state[:s06Phase]];
            var i = state[:s06Index];
            if (i < 0) {
                state[:s06Phase] += 1;
                if (state[:s06Phase] < 5) {
                    state[:s06Index] = state[:s06Arrays][state[:s06Phase]].size() - 10;
                }
                continue;
            }
            var z = 0.0;
            var j = 0;
            for (j = 0; j < 8; j += 1) {
                z += arr[i + j] * state[:fa][j];
            }
            state[:s06Sum][state[:s06Phase]] += arr[i + 8] * Math.sin(z) + arr[i + 9] * Math.cos(z);
            state[:s06Index] = i - 10;
            state[:s06Done] += 1;
            left -= 1;
        }
        if (state[:s06Phase] >= 5) {
            var t = state[:s06T];
            var w0 = 94.00e-6 + state[:s06Sum][0];
            var w1 = 3808.65e-6 + state[:s06Sum][1];
            var w2 = -122.68e-6 + state[:s06Sum][2];
            var w3 = -72574.11e-6 + state[:s06Sum][3];
            var w4 = 27.98e-6 + state[:s06Sum][4];
            var w5 = 15.62e-6;
            state[:ss] = (w0 + (w1 + (w2 + (w3 + (w4 + w5 * t) * t) * t) * t) * t) * DAS2R
                - state[:x] * state[:y] / 2.0;
        }
        state[:progress] = 0.75 + 0.20 * state[:s06Done] / state[:s06Total];
        return state[:s06Phase] >= 5;
    }
}
