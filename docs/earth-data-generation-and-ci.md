# Earth-data generation and CI

## Ownership and runtime contract

The app separates Earth data by maintenance responsibility:

| File | Ownership | Purpose |
| --- | --- | --- |
| `source/GeoidData.mc` | Handwritten and checked in | EGM96 lattice, `geoidOffset(lat, lon)`, and `mslToEllipsoid(lat, lon, msl)` |
| `data/iers/finals2000A-YYYY-MM-DD.txt` | Official fixed-width records, checked in by an explicit update | Sole input to IERS generation |
| `tools/iers.py` | Handwritten generator and updater | Validate the snapshot, render Monkey C, or explicitly fetch replacement data |
| `source/IersEopData.mc` | Generated and checked in | EOP table and `eop(mjd)`, `firstDate()`, `lastDate()` |

There is no `EarthData` facade. Callers use `GeoidData` for height conversion
and `IersEopData` for Earth orientation. The geoid remains the existing NGA
EGM96 (`us_nga_egm96_15.tif`, 2019-12-27) global 15° lattice and interpolation
implementation. It has no generator or raw-data refresh pipeline. Do not
regenerate it as part of an IERS update.

The initial split preserves all 1,104 EOP numeric literals and the existing
coverage: MJD **61292–61659**, **2026-09-09–2027-09-11**. Snapshot values are
`xp` and `yp` in arcseconds and DUT1 in seconds. The runtime interpolates daily
triplets at fractional UTC MJD and converts `xp` and `yp` to radians in the
returned dictionary. Successful lookups return `:status => 0`, `:dut1`, `:xp`,
`:yp`, `:first`, `:last`, and `:warning`. Both endpoints are accepted; the last
endpoint uses the last interpolation pair. Outside that interval, the result
is `{:status => -1, :warning => false}`. The warning is true when at most 30
days remain. `firstDate()` and `lastDate()` return the MJD bounds.

## Snapshot rules

Exactly one file matching `data/iers/finals2000A-*.txt` must exist. Its name
must be `finals2000A-YYYY-MM-DD.txt`, with a valid UTC calendar date recording
the selected coverage start, not the retrieval date. It contains exactly
**368 contiguous daily records**, beginning on that date and ending 367 days
later. The initial file is `finals2000A-2026-09-09.txt`.

The snapshot retains the official fixed-width records rather than converting
them to CSV or synthesizing missing columns. Calendar dates and MJD must
agree; the required Bulletin A polar-motion and UT1 fields, their `I`/`P`
flags, and uncertainties must be valid. Missing, duplicated, out-of-order, or
incomplete daily records fail validation. An update fails if no complete
368-row window satisfies the freshness and coverage rules below; it does not
silently shorten app coverage.

## Reproduce and check generation

Install [uv](https://docs.astral.sh/uv/). `tools/iers.py` uses PEP 723 inline
metadata, requires Python 3.11 or later, and declares no third-party Python
dependencies. Run these commands from the repository root:

```sh
uv run --script tools/iers.py generate
uv run --script tools/iers.py check
```

The Make equivalents are `make generate-iers` and `make check-generated`.
`UV` can be overridden when a different uv executable is needed.

`generate` reads only the checked-in snapshot and replaces the generated
module. `check` renders the expected output in memory and compares its bytes
to `source/IersEopData.mc`. It exits unsuccessfully for malformed input,
missing output, or any difference, and never rewrites files. Decimal formatting
uses seven places; output order and coverage derive from the snapshot, without
a current timestamp or host-specific path. The same snapshot and generator
produce the same bytes.

Neither operation fetches IERS data or consults today's date. uv may provision
a Python interpreter on first use; fully offline operation requires uv and a
compatible Python installation already available. Ordinary builds consume the
checked-in Monkey C module and have no regeneration or refresh dependency.

## Explicit refresh and failure handling

Only the updater fetches IERS data:

```sh
uv run --script tools/iers.py update
# Equivalent:
make update-iers
```

The updater downloads
[`finals2000A.all`](https://datacenter.iers.org/data/9/finals2000A.all) from the
IERS Data Center using `curl`. It selects the newest contiguous window of
exactly 368 fully populated, valid official records. The selected coverage
start must be no later than the invocation UTC date and no more than seven
days earlier, and the coverage end must include that invocation date. The
snapshot filename records the selected coverage start. It validates the
entire selected window and renders the new module before changing installed
files.

Bulletin A is published weekly, so its complete prediction horizon need not
support 368 records starting on the invocation date. Selecting the newest
complete window accommodates that publication cadence while preserving the
fixed 368-row contract. Incomplete trailing records beyond the complete
horizon do not extend coverage. An incomplete selected window, a start more
than seven days old or in the future, or coverage that excludes the invocation
date causes the update to fail.

`curl` inherits the caller's proxy environment, including `ALL_PROXY`,
`HTTPS_PROXY`, and `NO_PROXY` according to curl's normal precedence. Configure
any required proxy in the invoking environment; no proxy endpoint or credentials
belong in repository files. The updater disables user curl configuration,
requires HTTPS for the source and redirects, fails on HTTP errors, and sets
connection and total-transfer timeouts. Generation and checking do not invoke
curl.

A download, parse, validation, rendering, or staging failure leaves the installed
snapshot and module untouched. Installation stages both outputs and rollback
copies beside their destinations before replacing either. The old dated
snapshot is removed only after both new outputs are installed. An installation
failure restores replaced files and removes newly created files. If filesystem
errors also prevent rollback, the updater reports the recovery paths and
retains the relevant backup files. Each replacement is atomic, but the pair
is not a crash-atomic filesystem transaction; do not run concurrent updates or
interrupt installation deliberately.

## Developer update procedure

1. Start with a checkout whose existing Earth-data changes you understand.
   Configure the caller's network/proxy environment and ensure curl is installed.
2. Run `uv run --script tools/iers.py update` or `make update-iers` explicitly.
3. Review the new snapshot's date, 368-day coverage, provenance, and EOP changes,
   together with the generated module. A successful update leaves exactly one
   dated snapshot. Do not hand-edit the generated module to fix a failed check.
4. Run `make check-generated` and `make lint`, then the appropriate local build
   and behavioral checks for the change. If only generator logic changed, use
   `make generate-iers` against the existing snapshot instead of refreshing data.
5. Update README coverage dates and MJD bounds when the data window changes.
   Commit the snapshot replacement and generated module together, along with
   any generator changes needed to reproduce them.

To undo a completed refresh, restore the prior snapshot and generated module
together from version control, then run `make check-generated`. Restoring the
previous generator as well is necessary when its output contract changed.

## CI trust and build contract

`.github/workflows/build.yml` runs on pushes, pull requests, and manual dispatch.
The validation job runs `make check-generated` and `make lint` without a signing
secret. CI never runs the IERS updater: it verifies the committed snapshot and
generated module, so passing a build cannot silently change the data window.
Installing actions, uv, formatting packages, and build tools may use the network;
this is separate from refreshing IERS reference data.

The workflow grants only `contents: read` and disables checkout credential
persistence. It uses `pull_request`, not `pull_request_target`. Fork pull
requests run validation but skip the signed build job entirely. Pushes, manual
dispatches, and same-repository pull requests run signed builds after validation
passes. These are trusted code paths: contributors able to modify code or
workflows on same-repository branches must be trusted with the signing secret.
The fork gate does not make malicious same-repository changes safe.

Configure the repository Actions secret `CIQ_DEVELOPER_KEY` as the base64
encoding of the binary Garmin developer signing key (`developer_key.der`).
The workflow exposes this secret only to the key preparation step as an
environment variable, decodes it with `base64 --decode`, and rejects an empty
result. A missing or invalid secret fails a trusted build rather than producing
an unsigned substitute. The key is not printed or interpolated into the shell
program.

The decoded DER lives in a unique ignored `.ci-developer-key.*.der` file within
the checkout, with mode `600`. The Docker build action needs a workspace-local
file because the workspace is mounted into its container; a host-only temporary
directory is not sufficient. The relative path is passed through `GITHUB_ENV`
to the action's `developerKey` input. An `if: always()` cleanup step removes
the key after compilation, including failed builds. Artifact upload selects
only the expected PRG file.

All external actions are pinned to immutable commit SHAs:

| Action | Commit | Version annotation |
| --- | --- | --- |
| `actions/checkout` | `ea165f8d65b6e75b540449e92b4886f43607fa02` | v4 |
| `astral-sh/setup-uv` | `20cfd1bf945f4377ade1205e4dbc17946fc9a30d` | v10.0.1 |
| `blackshadev/garmin-connectiq-build-action` | `8868fb0edf4ced6686f7468f0574e3cd9d8337b3` | v9.2.0 |
| `actions/upload-artifact` | `11d5960a326750d5838078e36cf38b85af677262` | v4 |

setup-uv installs uv **0.12.12**. The Garmin action's v9.2.0 label identifies the
action release; its embedded tools image is currently **9.1.1**, so the action
label must not be described as SDK 9.2.0. Action commit pins freeze the action
definitions; they do not turn a transitive container image tag into an immutable
image digest. Review the action implementation and its image reference when
updating the pin.

The build matrix contains exactly `fr255`, `fr255s`, `fr255m`, `fr255sm`, and
`fr965`. Each independent job compiles `monkey.jungle` with `typeCheck: '0'`,
matching the project's current type-check setting. `fail-fast: false` allows
the remaining device jobs to finish if one fails. Each successful job uploads
`bin/PolarFinder-<device>.prg` as `PolarFinder-<device>`, fails the upload if that
file is absent, and retains the artifact for **14 days**. This workflow compiles
device PRGs; simulator tests remain a separate local command.
