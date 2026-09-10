# Astrometry Size Optimization

## Scope and result

This change reduces the production footprint without changing the resumable astrometry API or the EOP coverage window:

- Removed the unused synchronous `calculate` / `atco13` path and its six synchronous-only helpers: `epv00`, `pnm06a`, `s06`, `nut06a`, `s06ev`, and `nut00a`.
- Kept independent fixed SOFA and pyerfa expected-vector coverage against the production `begin` / `step` implementation.
- Moved `AstrometryTests.mc` from the compiler's recursively scanned default root to sibling `tests/`; production `monkey.jungle` now fixes `base.sourcePath` to `source`, while `test.jungle` adds `tests` only to test builds.
- Replaced 368 nested EOP rows `[MJD, xp, yp, dut1]` with one contiguous sequence of 368 `[xp, yp, dut1]` triplets. MJD is inferred as `61292 + triplet index`.

The supported interval remains MJD 61292 through 61659 inclusive. Returned dictionary keys and ordering remain `status`, `dut1`, `xp`, `yp`, `first`, `last`, `warning`; rejected dates still return only `status` and `warning`. The warning threshold remains the final 30 days, inclusive at MJD 61629.

## `:test` annotation experiment

SDK 9.1.0 was tested rather than assumed. In a temporary copy, `(:test)` was added to `calculate`, `atco13`, and all six synchronous-only helpers.

| Build | Data | Code | PRG |
|---|---:|---:|---:|
| Unannotated ordinary `fr965` build | 152,168 B | 47,168 B | 359,772 B |
| `(:test)` chain, ordinary `fr965` build | 152,096 B | 42,433 B | 352,156 B |
| `(:test)` chain, `monkeyc -t` `fr965` build | 154,391 B | 54,421 B | 378,652 B |

The ordinary-build values match removal of the complete synchronous chain, while the `-t` build compiled tests that referenced `calculate`. Therefore `(:test)` alone does exclude those annotated declarations from an ordinary build and includes them under `monkeyc -t`.

This does not make an entire mixed test source file weightless: imports and unannotated helpers remain ordinary declarations. The default source discovery also scans sibling directories recursively, so moving the file alone is insufficient. Production now explicitly sets `base.sourcePath = source`; the test overlay appends `tests`. A fresh ordinary `fr255` build's debug symbols contained no `tests/AstrometryTests.mc`, `withinTolerance`, or `astrometryResumableReferenceVector`, while the corresponding `-t` build discovered and ran the tests. The synchronous implementation itself was deleted after its same-implementation oracle was replaced, so it now consumes no test or production footprint.

## Exhaustive EOP equivalence

A throwaway JavaScript harness parsed all original rows, verified that all 368 MJDs were contiguous, constructed the flat representation from the original tokens, and compared the old and new algorithms at:

- all 368 exact row MJDs;
- five fractions (`0.125`, `0.25`, `0.5`, `0.75`, `0.875`) in every one of the 367 intervals;
- values immediately below and above the supported bounds;
- the final day;
- immediately before, exactly at, and immediately after the MJD 61629 warning boundary.

That is 2,209 complete result comparisons. Every dictionary key set, status, warning flag, and metadata value was checked. Maximum absolute errors were:

| Field | Maximum absolute error |
|---|---:|
| `dut1` | 0 s |
| `xp` | 0 rad |
| `yp` | 0 rad |
| `first` | 0 days |
| `last` | 0 days |

The final-day result remained successful with `dut1 = -0.1044597`, `xp = 1.2611603730806693e-6 rad`, `yp = 1.590746409772554e-6 rad`, `first = 61292`, `last = 61659`, and `warning = true`. Both outside values returned exactly `{status: -1, warning: false}`. The warning results immediately before / at / after MJD 61629 were `false / true / true`.

The applied source was reparsed independently after editing: it contained exactly 1,104 flat values and repeated all 2,209 comparisons with zero maximum error. The durable device test uses a `1e-8 s` final-row tolerance because EOP literals are Monkey C `Float` values (the Float representation error for `-0.1044597` is about `2.97e-9 s`); boundary inputs are explicitly `Double` so sub-Float-ULP offsets remain observable.

## Same-series compiler measurements

Representative `fr255` and `fr965` builds used the same temporary project, temporary manifest, SDK, compiler options, signing key, and source/resource context. The baseline had nested EOP rows, the synchronous chain, and tests under `source/`. The optimized variant had flat EOP data, no synchronous chain, and no production test source.

| Device | Variant | Data | Code | Data + Code | PRG |
|---|---|---:|---:|---:|---:|
| `fr255` | Baseline | 152,168 B | 47,168 B | 199,336 B | 350,908 B |
| `fr255` | Optimized | 143,140 B | 39,104 B | 182,244 B | 330,540 B |
| `fr255` | Delta | **-9,028 B** | **-8,064 B** | **-17,092 B** | **-20,368 B** |
| `fr965` | Baseline | 152,168 B | 47,168 B | 199,336 B | 359,708 B |
| `fr965` | Optimized | 143,140 B | 39,104 B | 182,244 B | 339,340 B |
| `fr965` | Delta | **-9,028 B** | **-8,064 B** | **-17,092 B** | **-20,368 B** |

Both optimized representative production builds completed successfully. The actual `fr255s` test build discovered and ran 26 tests from the sibling test source: `PASSED (passed=26, failed=0, errors=0)`. This includes the fixed SOFA/pyerfa vectors, resumable cancellation and invalid-UTC behavior, and EOP interpolation/final-day/bounds/warning-boundary coverage.
