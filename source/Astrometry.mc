/*
 * Derived work based on the International Astronomical Union SOFA (Standards
 * of Fundamental Astronomy) collection, release 2016-05-03.  Algorithms and
 * constants are translated to Monkey C and adapted for value-return arrays and
 * dictionaries. This is not software provided by or endorsed by SOFA.
 * SOFA-derived routine names omit the iau/sofa prefix as required by license.
 */

// Resumable calculation lifecycle: begin, cancel, step, and progress/results.
import Toybox.Math;
module Astrometry {
    // Resumable astrometry contract. Each step performs at most the bounded
    // term budget in the ephemeris, nutation, or S06 series; discard state to cancel.
    function begin(
        rc,
        dc,
        pr,
        pd,
        px,
        rv,
        utc1,
        utc2,
        dut1,
        elong,
        phi,
        hm,
        xp,
        yp,
        phpa,
        tc,
        rh,
        wl
    ) {
        var es = [[e0x, e0y, e0z], [e1x, e1y, e1z], [e2x, e2y, e2z]];
        var ss = [[s0x, s0y, s0z], [s1x, s1y, s1z], [s2x, s2y, s2z]];
        var total = 0;
        var g = 0;
        var c = 0;
        for (g = 0; g < 3; g += 1) {
            for (c = 0; c < 3; c += 1) {
                total += es[g][c].size() / 3;
                total += ss[g][c].size() / 3;
            }
        }
        return {
            :stage => 0,
            :progress => 0.0,
            :args => [
                rc,
                dc,
                pr,
                pd,
                px,
                rv,
                utc1,
                utc2,
                dut1,
                elong,
                phi,
                hm,
                xp,
                yp,
                phpa,
                tc,
                rh,
                wl
            ],
            :es => es,
            :ss => ss,
            :epvTotal => total,
            :epvDone => 0,
            :ei => 0,
            :ek => 0,
            :ej => 0,
            :epvPhase => 0,
            :ph => [0.0, 0.0, 0.0],
            :phd => [0.0, 0.0, 0.0],
            :pb => [0.0, 0.0, 0.0],
            :pbd => [0.0, 0.0, 0.0]
        };
    }
    
    function cancel(state) {
        if (state != null) {
            state[:cancelled] = true;
        }
        return true;
    }
    
    function resumableReply(state, done, result) {
        return { :state => state, :done => done, :progress => state[:progress], :result => result };
    }
    
    function step(state) {
        if (state == null || state[:cancelled]) {
            return { :state => state, :done => true, :progress => 1.0, :result => null };
        }
        var args = state[:args];
        if (state[:stage] == 0) {
            if (args[6] + args[7] < 1721425.5 || args[6] + args[7] > 5373484.5) {
                state[:stage] = -1;
                state[:progress] = 1.0;
                return resumableReply(
                    state,
                    true,
                    {
                        :status => -1,
                        :aob => 0.0,
                        :zob => 0.0,
                        :hob => 0.0,
                        :dob => 0.0,
                        :rob => 0.0,
                        :eo => 0.0,
                        :altitude => 0.0
                    }
                );
            }
            var tai = utctai(args[6], args[7]);
            var tt = tai2tt(tai[1], tai[2]);
            var ut1 = utcut1(args[6], args[7], args[8]);
            state[:tt0] = tt[0];
            state[:tt1] = tt[1];
            state[:ut1] = ut1;
            state[:epvT] = (((tt[0] - DJ00) + tt[1]) / DJY).toFloat();
            state[:epvPhase] = 0;
            state[:stage] = 1;
            state[:progress] = 0.05;
            return resumableReply(state, false, null);
        }
        if (state[:stage] == 1) {
            if (!resumableEpvChunk(state, 32)) {
                return resumableReply(state, false, null);
            }
            state[:nutT] = (((state[:tt0] - DJ00) + state[:tt1]) / DJC).toFloat();
            var t = state[:nutT];
            state[:el] = fal03(t);
            state[:elp] = falp03(t);
            state[:f] = faf03(t);
            state[:d] = fad03(t);
            state[:om] = faom03(t);
            state[:al] = mod(2.35555598 + 8328.6914269554 * t, D2PI);
            state[:af] = mod(1.627905234 + 8433.466158131 * t, D2PI);
            state[:ad] = mod(5.198466741 + 7771.3771468121 * t, D2PI);
            state[:aom] = mod(2.18243920 - 33.757045 * t, D2PI);
            state[:apa] = fapa03(t);
            state[:alme] = fame03(t);
            state[:alve] = fave03(t);
            state[:alea] = fae03(t);
            state[:alma] = fama03(t);
            state[:alju] = faju03(t);
            state[:alsa] = fasa03(t);
            state[:alur] = faur03(t);
            state[:alne] = mod(5.321159000 + 3.8127774000 * t, D2PI);
            state[:dpv] = 0.0;
            state[:dev] = 0.0;
            state[:dpp] = 0.0;
            state[:dep] = 0.0;
            state[:ni] = xls.size() - 11;
            state[:nutPhase] = 0;
            state[:nutDone] = 0;
            state[:nutTotal] = xls.size() / 11 + xpl.size() / 17;
            state[:stage] = 2;
            return resumableReply(state, false, null);
        }
        if (state[:stage] == 2) {
            if (!resumableNutChunk(state, 32)) {
                return resumableReply(state, false, null);
            }
            var pp = pfw06(state[:tt0], state[:tt1]);
            state[:rnpb] = fw2m(pp[0], pp[1], pp[2] + state[:nut][0], pp[3] + state[:nut][1]);
            state[:x] = state[:rnpb][2][0];
            state[:y] = state[:rnpb][2][1];
            var st = (((state[:tt0] - DJ00) + state[:tt1]) / DJC).toFloat();
            state[:fa] = [
                fal03(st),
                falp03(st),
                faf03(st),
                fad03(st),
                faom03(st),
                fave03(st),
                fae03(st),
                fapa03(st)
            ];
            state[:s06T] = st;
            state[:s06Arrays] = [s06_s0, s06_s1, s06_s2, s06_s3, s06_s4];
            state[:s06Sum] = [0.0, 0.0, 0.0, 0.0, 0.0];
            state[:s06Phase] = 0;
            state[:s06Index] = s06_s0.size() - 10;
            state[:s06Done] = 0;
            state[:s06Total] = (
                s06_s0.size() + s06_s1.size() + s06_s2.size() + s06_s3.size() + s06_s4.size()
            )
                / 10;
            state[:stage] = 3;
            return resumableReply(state, false, null);
        }
        if (state[:stage] == 3) {
            if (!resumableS06Chunk(state, 32)) {
                return resumableReply(state, false, null);
            }
            state[:stage] = 4;
            return resumableReply(state, false, null);
        }
        if (state[:stage] == 4) {
            var a = args;
            var ev = state[:ev];
            var ehpv = ev[1][0];
            var ebpv = ev[2];
            var x = state[:x];
            var y = state[:y];
            var ss = state[:ss];
            var theta = era00(state[:ut1][1], state[:ut1][2]);
            var sp = sp00(state[:tt0], state[:tt1]);
            var ref = refco(a[14], a[15], a[16], a[17]);
            var along = a[9] + sp;
            var sl = Math.sin(along);
            var cl = Math.cos(along);
            var pvt = pvtob(a[9], a[10], a[11], a[12], a[13], sp, theta);
            var pv = trxpv(c2ixys(x, y, ss), pvt);
            var pmt = ((state[:tt0] - DJ00) + state[:tt1]) / DJY;
            var dpv = [0.0d, 0.0d, 0.0d];
            var dvv = [0.0d, 0.0d, 0.0d];
            var pb = [0.0d, 0.0d, 0.0d];
            var vb = [0.0d, 0.0d, 0.0d];
            var ph = [0.0d, 0.0d, 0.0d];
            var v2 = 0.0d;
            var i = 0;
            for (i = 0; i < 3; i += 1) {
                dpv[i] = pv[0][i] / DAU;
                dvv[i] = pv[1][i] / AUDMS;
                pb[i] = ebpv[0][i] + dpv[i];
                vb[i] = ebpv[1][i] + dvv[i];
                ph[i] = ehpv[i] + dpv[i];
            }
            var emn = pn(ph);
            var vv = [0.0d, 0.0d, 0.0d];
            var k = 0;
            for (k = 0; k < 3; k += 1) {
                vv[k] = vb[k] * CR;
                v2 += vv[k] * vv[k];
            }
            // diurab is the SOFA "diurnal aberration" term; production always
            // passes 0.0 because observer velocity is already carried in
            // ast[:v] (the barycentric/heliocentric velocity used by
            // aberration() above) via the full Apco-style chain -- it is not
            // a free knob the pole/ray helpers below are allowed to enable a
            // second time.
            var xpl = a[12] * cl - a[13] * sl;
            var ypl = a[12] * sl + a[13] * cl;
            var sphi = Math.sin(a[10]);
            var cphi = Math.cos(a[10]);
            var diurab = 0.0;
            var ast = {
                :pmt => pmt,
                :eb => pb,
                :eh => [emn[1], emn[2], emn[3]],
                :em => emn[0],
                :v => vv,
                :bm1 => Math.sqrt(1.0 - v2),
                :bpn => c2ixys(x, y, ss),
                :eral => theta + along,
                :xpl => xpl,
                :ypl => ypl,
                :sphi => sphi,
                :cphi => cphi,
                :diurab => diurab,
                :refa => ref[0],
                :refb => ref[1]
            };
            var pco = pmpx(a[0], a[1], a[2], a[3], a[4], a[5], ast[:pmt], ast[:eb]);
            var pnat = ldsun(pco, ast[:eh], ast[:em]);
            var ppr = aberration(pnat, ast[:v], ast[:em], ast[:bm1]);
            var pi = rxp(ast[:bpn], ppr);
            var cs = c2s(pi);
            var ri = anp(cs[0]);
            var di = cs[1];
            
            // Polaris' observed incoming-light ray: this is the ONLY vector
            // that atmospheric refraction (ast[:refa]/ast[:refb]) is allowed
            // to touch.
            var ray0 = localHorizonRay(
                ri,
                di,
                ast[:eral],
                xpl,
                ypl,
                sphi,
                cphi,
                diurab,
                ast[:refa],
                ast[:refb]
            );
            var xaeo0 = ray0[3];
            var yaeo0 = ray0[4];
            var zaeo0 = ray0[5];
            var haVec0 = [sphi * xaeo0 + cphi * zaeo0, yaeo0, -cphi * xaeo0 + sphi * zaeo0];
            var hcs0 = c2s(haVec0);
            var raobs0 = ast[:eral] + hcs0[0];
            
            // Geometric pole: the mechanical direction the mount's RA axis
            // should point at. Built from the same polar-motion/latitude
            // geometry, but never refracted, aberrated, or otherwise treated
            // as a light ray (geometricPoleLocalVector takes no diurab/refa/
            // refb argument at all, so there is nothing here to disable).
            var poleVec = geometricPoleLocalVector(xpl, ypl, sphi, cphi);
            var basis = poleTangentBasis(poleVec);
            var uVec = basis[0];
            var vVec = basis[1];
            var sVec0 = normalize3([xaeo0, yaeo0, zaeo0]);
            var xy0 = poleTangentXY(sVec0, poleVec, uVec, vVec);
            var x0 = xy0[0];
            var y0 = xy0[1];
            
            // Frozen anchor context for cheap per-tick reticle reevaluation
            // (see reticleAt()). The expensive ephemeris, nutation, CIO,
            // light-time, deflection, and aberration work is retained while
            // Earth Rotation Angle and local geometry are reevaluated for
            // each display timestamp.
            //
            // The cached-context calculation is exact only with respect to
            // those retained quantities. Their aging error is independently
            // checked against the 0.1 arcsecond propagation budget over the
            // supported ~15 minute anchor interval by the full-recomputation
            // test. The separate frozen-context test checks local-geometry
            // consistency; it is not an end-to-end accuracy claim.
            //
            // UT1-UTC is baked into ut1a/ut1b and is not re-fetched from the
            // daily EOP table. "along", xpl/ypl, refa/refb, and the CIRS
            // direction (ri,di) are likewise retained until the next anchor.
            var anchor = {
                :ri => ri,
                :di => di,
                :ut1a => state[:ut1][1],
                :ut1b => state[:ut1][2],
                :along => along,
                :xpl => xpl,
                :ypl => ypl,
                :sphi => sphi,
                :cphi => cphi,
                :refa => ast[:refa],
                :refb => ast[:refb],
                :polePx => poleVec[0],
                :polePy => poleVec[1],
                :polePz => poleVec[2],
                :uX => uVec[0],
                :uY => uVec[1],
                :uZ => uVec[2],
                :vX => vVec[0],
                :vY => vVec[1],
                :vZ => vVec[2]
            };
            
            var result = {
                :status => 0,
                :aob => anp(ray0[6]),
                :zob => ray0[7],
                :hob => -hcs0[0],
                :dob => hcs0[1],
                :rob => anp(raobs0),
                :eo => eors(state[:rnpb], ss),
                :altitude => D2PI / 4.0 - ray0[7],
                // Raw gnomonic tangent-plane coordinates of Polaris' observed
                // ray relative to the geometric pole (X0,Y0), and the
                // equivalent hour-angle/pole-distance pair, both at anchor
                // time (elapsed=0). Matches the old hob/(pi/2-dob) convention
                // when polar motion and refraction are both negligible.
                // Between-anchor propagation is done by calling reticleAt()
                // with :reticleAnchor and an elapsed-seconds offset -- there
                // is no separate constant-rate model to keep in sync.
                :reticleX => x0,
                :reticleY => y0,
                :reticleHourAngle => Math.atan2(-x0, y0),
                :reticlePoleDistance => Math.atan(Math.sqrt(x0 * x0 + y0 * y0)),
                // Geometric pole local unit vector, exposed so tests can
                // confirm it shifts with polar motion (xp,yp) and is
                // completely unaffected by atmospheric refraction.
                :polePx => poleVec[0],
                :polePy => poleVec[1],
                :polePz => poleVec[2],
                :reticleAnchor => anchor
            };
            state[:stage] = -1;
            state[:progress] = 1.0;
            state[:result] = result;
            return resumableReply(state, true, result);
        }
        return resumableReply(state, true, state[:result]);
    }
}
