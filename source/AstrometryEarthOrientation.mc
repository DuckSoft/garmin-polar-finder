/*
 * Derived work based on the International Astronomical Union SOFA (Standards
 * of Fundamental Astronomy) collection, release 2016-05-03.  Algorithms and
 * constants are translated to Monkey C and adapted for value-return arrays and
 * dictionaries. This is not software provided by or endorsed by SOFA.
 * SOFA-derived routine names omit the iau/sofa prefix as required by license.
 */

// Earth rotation, observer position, precession, and fundamental arguments.
import Toybox.Math;
module Astrometry {
    function era00(dj1, dj2) {
        var d1, d2;
        if (dj1 < dj2) {
            d1 = dj1;
            d2 = dj2;
        } else {
            d1 = dj2;
            d2 = dj1;
        }
        var t = d1 + (d2 - DJ00), f = mod(d1, 1.0) + mod(d2, 1.0);
        return anp(D2PI * (f + 0.7790572732640 + 0.00273781191135448 * t));
    }
    function sp00(d1, d2) {
        return -47e-6 * ((d1 - DJ00) + d2) / DJC * DAS2R;
    }
    function gd2gc(elong, phi, h) {
        var a = 6378137.0,
            f = 1.0 / 298.257223563,
            e2 = f * (2.0 - f),
            s = Math.sin(phi),
            c = Math.cos(phi),
            n = a / Math.sqrt(1.0 - e2 * s * s);
        return [
            (n + h) * c * Math.cos(elong),
            (n + h) * c * Math.sin(elong),
            (n * (1.0 - e2) + h) * s
        ];
    }
    function pom00(xp, yp, sp) {
        var r = ident();
        rz(sp, r);
        ry(-xp, r);
        rx(-yp, r);
        return r;
    }
    function pvtob(elong, phi, hm, xp, yp, sp, theta) {
        var xyz = rxp(pom00(xp, yp, sp), gd2gc(elong, phi, hm)),
            s = Math.sin(theta),
            c = Math.cos(theta),
            om = 1.00273781191135448 * D2PI / DAYSEC;
        return [
            [c * xyz[0] - s * xyz[1], s * xyz[0] + c * xyz[1], xyz[2]],
            [om * (-s * xyz[0] - c * xyz[1]), om * (c * xyz[0] - s * xyz[1]), 0.0]
        ];
    }
    function c2ixys(x, y, s) {
        var r2 = x * x + y * y,
            e = r2 > 0.0 ? Math.atan2(y, x) : 0.0,
            d = Math.atan(Math.sqrt(r2 / (1.0 - r2))),
            r = ident();
        rz(e, r);
        ry(d, r);
        rz(-(e + s), r);
        return r;
    }
    function obl06(d1, d2) {
        var t = ((d1 - DJ00) + d2) / DJC;
        var a = 84381.406
            + t
                * (
                    -46.836769
                        + t
                            * (
                                -0.0001831
                                    + t * (0.00200340 + t * (-0.000000576 + t * (-0.0000000434)))
                            )
                );
        return a * DAS2R;
    }
    function pfw06(d1, d2) {
        var t = ((d1 - DJ00) + d2) / DJC;
        var g = -0.052928
            + t
                * (
                    10.556378
                        + t
                            * (
                                0.4932044
                                    + t * (-0.00031238 + t * (-0.000002788 + t * 0.0000000260))
                            )
                );
        var p = 84381.412819
            + t
                * (
                    -46.811016
                        + t
                            * (
                                0.0511268
                                    + t * (0.00053289 + t * (-0.000000440 + t * (-0.0000000176)))
                            )
                );
        var ps = -0.041775
            + t
                * (
                    5038.481484
                        + t
                            * (
                                1.5584175
                                    + t * (-0.00018522 + t * (-0.000026452 + t * (-0.0000000148)))
                            )
                );
        return [g * DAS2R, p * DAS2R, ps * DAS2R, obl06(d1, d2)];
    }
    function fw2m(gamb, phib, psi, eps) {
        var r = ident();
        rz(gamb, r);
        rx(phib, r);
        rz(-psi, r);
        rx(-eps, r);
        return r;
    }
    
    function fal03(t) {
        return mod(
            (
                485868.249036
                    + t * (1717915923.2178 + t * (31.8792 + t * (0.051635 + t * (-0.00024470))))
            ),
            TURNAS
        )
            * DAS2R;
    }
    function faf03(t) {
        return mod(
            (
                335779.526232
                    + t * (1739527262.8478 + t * (-12.7512 + t * (-0.001037 + t * (0.00000417))))
            ),
            TURNAS
        )
            * DAS2R;
    }
    function faom03(t) {
        return mod(
            (
                450160.398036
                    + t * (-6962890.5431 + t * (7.4722 + t * (0.007702 + t * (-0.00005939))))
            ),
            TURNAS
        )
            * DAS2R;
    }
    function falp03(t) {
        return mod(
            (
                1287104.793048
                    + t * (129596581.0481 + t * (-0.5532 + t * (0.000136 + t * (-0.00001149))))
            ),
            TURNAS
        )
            * DAS2R;
    }
    function fad03(t) {
        return mod(
            (
                1072260.703692
                    + t * (1602961601.2090 + t * (-6.3706 + t * (0.006593 + t * (-0.00003169))))
            ),
            TURNAS
        )
            * DAS2R;
    }
    function fave03(t) {
        return mod(3.176146697 + 1021.3285546211 * t, D2PI);
    }
    function fae03(t) {
        return mod(1.753470314 + 628.3075849991 * t, D2PI);
    }
    function fame03(t) {
        return mod(4.402608842 + 2608.7903141574 * t, D2PI);
    }
    function fama03(t) {
        return mod(6.203480913 + 334.0612426700 * t, D2PI);
    }
    function faju03(t) {
        return mod(0.599546497 + 52.9690962641 * t, D2PI);
    }
    function fasa03(t) {
        return mod(0.874016757 + 21.3299104960 * t, D2PI);
    }
    function faur03(t) {
        return mod(5.481293872 + 7.4781598567 * t, D2PI);
    }
    function fapa03(t) {
        return (0.024381750 + 0.00000538691 * t) * t;
    }
    function eors(r, s) {
        var x = r[2][0],
            ax = x != 0.0 ? x : 1.0,
            xs = 1.0 - ax * x,
            ys = -ax * r[2][1],
            zs = -x,
            p = r[0][0] * xs + r[0][1] * ys + r[0][2] * zs,
            q = r[1][0] * xs + r[1][1] * ys + r[1][2] * zs;
        return (p != 0.0 || q != 0.0) ? s - Math.atan2(q, p) : s;
    }
}
