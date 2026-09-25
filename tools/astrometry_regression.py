#!/usr/bin/env -S uv run --script
# /// script
# dependencies = ["pyerfa==2.0.1.5"]
# ///
"""Generate and verify independent astrometry regression fixtures.

The Garmin implementation is translated from SOFA and therefore needs an
oracle that does not share its Monkey C code path.  This script uses ERFA (the
actively maintained, separately compiled SOFA implementation) to evaluate the
same ICRS-to-observed transformation and the reticle projection.  The generated
Monkey C module is consumed by simulator tests; ``check`` makes sure that the
checked-in oracle has not drifted from the scenario definitions or bundled EOP
data.
"""

from __future__ import annotations

import difflib
import math
import re
import sys
import tempfile
from pathlib import Path

import erfa


FIRST_MJD = 61292.0
LAST_MJD = 61659.0
PI = math.pi
STAR_RA = (2.0 + 31.0 / 60.0 + 49.09 / 3600.0) * 15.0 * PI / 180.0
STAR_DEC = (89.0 + 15.0 / 60.0 + 50.8 / 3600.0) * PI / 180.0
STAR_PM_RA_STAR_MAS_YR = 44.22
STAR_PM_DEC_MAS_YR = -11.74e-3
STAR_PARALLAX_ARCSEC = 7.54e-3
STAR_RADIAL_VELOCITY_KM_S = -16.0
STAR_PR = (STAR_PM_RA_STAR_MAS_YR * 1e-3 * erfa.DAS2R) / math.cos(STAR_DEC)
STAR_PD = STAR_PM_DEC_MAS_YR * erfa.DAS2R
STAR_PX = STAR_PARALLAX_ARCSEC
STAR_RV = STAR_RADIAL_VELOCITY_KM_S

# Dates and observing conditions deliberately exercise different numerical
# regimes: pressure off/on, high elevation, southern and near-equatorial
# sites, a near-horizon Polaris ray, and the end of the bundled EOP window.
SCENARIOS = (
    {
        "name": "beijing-day",
        "mjd": 61292.6391319446,
        "longitude": 116.30780,
        "latitude": 40.06890,
        "height": 125.0,
        "pressure": 0.0,
        "temperature": 10.0,
        "humidity": 0.5,
        "wavelength": 0.55,
    },
    {
        "name": "beijing-pressure",
        "mjd": 61352.4,
        "longitude": 116.30780,
        "latitude": 40.06890,
        "height": 125.0,
        "pressure": 1013.25,
        "temperature": 10.0,
        "humidity": 0.5,
        "wavelength": 0.55,
    },
    {
        "name": "sydney",
        "mjd": 61412.75,
        "longitude": 151.20930,
        "latitude": -33.86880,
        "height": 58.0,
        "pressure": 1008.0,
        "temperature": 22.0,
        "humidity": 0.65,
        "wavelength": 0.55,
    },
    {
        "name": "quito-low",
        "mjd": 61472.1,
        "longitude": -78.50000,
        "latitude": 0.50000,
        "height": 2850.0,
        "pressure": 720.0,
        "temperature": 12.0,
        "humidity": 0.8,
        "wavelength": 0.55,
    },
    {
        "name": "ladakh",
        "mjd": 61532.25,
        "longitude": 77.58000,
        "latitude": 34.15000,
        "height": 3500.0,
        "pressure": 650.0,
        "temperature": -5.0,
        "humidity": 0.25,
        "wavelength": 0.55,
    },
    {
        "name": "north-high",
        "mjd": 61592.5,
        "longitude": -42.00000,
        "latitude": 75.00000,
        "height": 20.0,
        "pressure": 980.0,
        "temperature": -20.0,
        "humidity": 0.4,
        "wavelength": 0.55,
    },
    {
        "name": "boundary-last",
        "mjd": 61658.9,
        "longitude": -0.10000,
        "latitude": 51.50000,
        "height": 50.0,
        "pressure": 1013.25,
        "temperature": 15.0,
        "humidity": 0.7,
        "wavelength": 0.55,
    },
    {
        "name": "equator-no-refraction",
        "mjd": 61600.25,
        "longitude": 0.0,
        "latitude": 0.0,
        "height": 0.0,
        "pressure": 0.0,
        "temperature": 20.0,
        "humidity": 0.5,
        "wavelength": 0.55,
    },
)

STEP_SECONDS = (0.0, 300.0, 899.0)


def _parse_eop(source: Path) -> list[float]:
    text = source.read_text(encoding="utf-8")
    array = text.split("var EOP = [", 1)[1].split("];", 1)[0]
    return [float(value) for value in re.findall(r"[-+]?\d+\.\d+", array)]


def _eop(eop_values: list[float], mjd: float) -> tuple[float, float, float]:
    offset = mjd - FIRST_MJD
    if offset < 0.0 or offset > LAST_MJD - FIRST_MJD:
        raise ValueError(f"MJD {mjd} is outside the bundled EOP window")
    index = min(int(math.floor(offset)), int(LAST_MJD - FIRST_MJD) - 1)
    weight = offset - index
    a = index * 3
    return (
        eop_values[a + 2] + weight * (eop_values[a + 5] - eop_values[a + 2]),
        (eop_values[a] + weight * (eop_values[a + 3] - eop_values[a])) * erfa.DAS2R,
        (eop_values[a + 1] + weight * (eop_values[a + 4] - eop_values[a + 1])) * erfa.DAS2R,
    )


def _normalize(vector: tuple[float, float, float]) -> tuple[float, float, float]:
    norm = math.sqrt(sum(component * component for component in vector))
    return tuple(component / norm for component in vector)


def _dot(a: tuple[float, float, float], b: tuple[float, float, float]) -> float:
    return sum(x * y for x, y in zip(a, b))


def _cross(a: tuple[float, float, float], b: tuple[float, float, float]) -> tuple[float, float, float]:
    return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])


def _reticle(aob: float, zob: float, astrom) -> tuple[float, float, float, float]:
    """Project ERFA's observed ray onto the geometric pole tangent plane."""
    ray = (
        -math.sin(zob) * math.cos(aob),
        math.sin(zob) * math.sin(aob),
        math.cos(zob),
    )
    sphi = float(astrom["sphi"])
    cphi = float(astrom["cphi"])
    xpl = float(astrom["xpl"])
    ypl = float(astrom["ypl"])
    pole = _normalize((sphi * xpl - cphi, -ypl, cphi * xpl + sphi))
    u = _normalize((-pole[2] * pole[0], -pole[2] * pole[1], 1.0 - pole[2] * pole[2]))
    v = _cross(pole, u)
    denominator = _dot(ray, pole)
    x = _dot(ray, v) / denominator
    y = _dot(ray, u) / denominator
    return x, y, math.atan2(-x, y), math.atan(math.sqrt(x * x + y * y))


def _observed(case: dict, eop_values: list[float], mjd: float) -> tuple[list[float], object]:
    dut1, xp, yp = _eop(eop_values, mjd)
    elong = case["longitude"] * PI / 180.0
    phi = case["latitude"] * PI / 180.0
    utc1 = 2400000.5 + mjd
    values = erfa.atco13(
        STAR_RA,
        STAR_DEC,
        STAR_PR,
        STAR_PD,
        STAR_PX,
        STAR_RV,
        utc1,
        0.0,
        dut1,
        elong,
        phi,
        case["height"],
        xp,
        yp,
        case["pressure"],
        case["temperature"],
        case["humidity"],
        case["wavelength"],
    )
    astrom, _ = erfa.apco13(
        utc1,
        0.0,
        dut1,
        elong,
        phi,
        case["height"],
        xp,
        yp,
        case["pressure"],
        case["temperature"],
        case["humidity"],
        case["wavelength"],
    )
    aob, zob, hob, dob, rob, eo = (float(value) for value in values)
    x, y, hour_angle, pole_distance = _reticle(aob, zob, astrom)
    return [aob, zob, hob, dob, rob, eo, x, y, hour_angle, pole_distance], astrom


def _mc_number(value: float) -> str:
    if value == 0.0:
        return "0.0d"
    return f"{value:.15g}d"


def _mc_array(values: list[float], indent: int) -> str:
    """Render arrays in the same stable layout as monkeyc-fmt."""
    prefix = " " * indent
    item_prefix = " " * (indent + 4)
    items = "\n".join(f"{item_prefix}{_mc_number(value)}," for value in values)
    return f"[\n{items}\n{prefix}]"


def _generate(root: Path) -> str:
    eop_values = _parse_eop(root / "source" / "IersEopData.mc")
    lines = [
        "/* Generated by tools/astrometry_regression.py; do not edit. */",
        "/* Independent oracle: ERFA/pyerfa 2.0.1.5, not the Monkey C implementation. */",
        "module AstrometryRegressionReference {",
        "    // Approximately 0.41 arcsec in ordinary angular fields; intentionally",
        "    // the multi-arcsecond errors that motivated this regression suite.",
        "    var ANGULAR_TOLERANCE = 2.0e-6d;",
        "    // The translated SOFA hour-angle path differs from ERFA by about",
        "    // 1 arcsec on the frozen Polaris vector; keep this tolerance local",
        "    // instead of weakening the other angular comparisons.",
        "    var HOUR_ANGLE_TOLERANCE = 6.0e-6d;",
        "    // reticleAt derives hour angle from a near-pole tangent pair;",
        "    // propagation magnifies sub-arcsecond X/Y drift in that coordinate.",
        "    var PROPAGATION_HOUR_ANGLE_TOLERANCE = 2.0e-5d;",
        "    var TANGENT_TOLERANCE = 2.0e-6d;",
        "    var CASES = [",
    ]
    for case_index, case in enumerate(SCENARIOS):
        anchor, _ = _observed(case, eop_values, case["mjd"])
        steps = []
        for elapsed in STEP_SECONDS:
            expected, _ = _observed(case, eop_values, case["mjd"] + elapsed / 86400.0)
            steps.append([elapsed, expected[0], expected[1], expected[6], expected[7], expected[8], expected[9]])
        dut1, xp, yp = _eop(eop_values, case["mjd"])
        inputs = [
            STAR_RA,
            STAR_DEC,
            STAR_PR,
            STAR_PD,
            STAR_PX,
            STAR_RV,
            2400000.5 + case["mjd"],
            0.0,
            dut1,
            case["longitude"] * PI / 180.0,
            case["latitude"] * PI / 180.0,
            case["height"],
            xp,
            yp,
            case["pressure"],
            case["temperature"],
            case["humidity"],
            case["wavelength"],
        ]
        lines += [
            "        {",
            f'            :name => "{case["name"]}",',
            f"            :inputs => {_mc_array(inputs, 12)},",
            f"            :anchor => {_mc_array(anchor, 12)},",
            "            :steps => [",
        ]
        for step in steps:
            lines.append(f"                {_mc_array(step, 16)},")
        lines += ["            ]", "        }" + ("," if case_index + 1 < len(SCENARIOS) else "")]
    lines += ["    ];", "}", ""]
    return "\n".join(lines)


def main(argv: list[str]) -> int:
    if len(argv) != 2 or argv[1] not in {"generate", "check"}:
        print(f"usage: {argv[0]} generate|check", file=sys.stderr)
        return 2
    root = Path(__file__).resolve().parents[1]
    target = root / "tests" / "AstrometryRegressionReference.mc"
    generated = _generate(root)
    if argv[1] == "generate":
        target.write_text(generated, encoding="utf-8")
        print(f"generated {target}")
        return 0
    checked_in = target.read_text(encoding="utf-8") if target.exists() else ""
    if checked_in == generated:
        print("astrometry regression oracle is up to date")
        return 0
    diff = difflib.unified_diff(
        checked_in.splitlines(keepends=True),
        generated.splitlines(keepends=True),
        fromfile=str(target),
        tofile="generated oracle",
    )
    sys.stderr.writelines(diff)
    return 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
