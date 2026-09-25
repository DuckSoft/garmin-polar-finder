/*
 * Frozen official EOP rows for the independent pyerfa astrometry vector.
 *
 * This is intentionally separate from the rolling production table. The
 * vector's expected values were recorded with these rows, so its input must
 * not change when the scheduled IERS snapshot advances.
 */
module IersEopReferenceData {
    var EOP = [0.2031920, 0.3340950, -0.0012829, 0.2024300, 0.3334080, -0.0023990];
    
    function eop(mjd) {
        mjd = mjd.toDouble();
        if (mjd < 61292.0 || mjd > 61293.0) {
            return { :status => -1, :warning => false };
        }
        var w = mjd - 61292.0;
        return {
            :status => 0,
            :dut1 => EOP[2] + w * (EOP[5] - EOP[2]),
            :xp => (EOP[0] + w * (EOP[3] - EOP[0])) * Astrometry.DAS2R,
            :yp => (EOP[1] + w * (EOP[4] - EOP[1])) * Astrometry.DAS2R,
            :first => 61292.0,
            :last => 61659.0,
            :warning => false
        };
    }
}
