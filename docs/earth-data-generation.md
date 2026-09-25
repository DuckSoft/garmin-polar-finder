# Earth-data generation

## Ownership and runtime contract

The app separates Earth data by maintenance responsibility:

| File | Ownership | Purpose |
| --- | --- | --- |
| `source/GeoidData.mc` | Handwritten and checked in | EGM96 lattice, `geoidOffset(lat, lon)`, and `mslToEllipsoid(lat, lon, msl)` |
| `data/iers/finals2000A-YYYY-MM-DD.txt` | Official fixed-width records, checked in by an explicit update | Sole input to IERS generation |
| `tools/iers.py` | Handwritten generator and updater | Validate the snapshot, render Monkey C, refresh coverage documentation, or explicitly fetch replacement data |
| `source/IersEopData.mc` | Generated and checked in | EOP table and `eop(mjd)`, `firstDate()`, `lastDate()` |

There is no `EarthData` facade. Callers use `GeoidData` for height conversion
and `IersEopData` for Earth orientation. The geoid remains the existing NGA
EGM96 (`us_nga_egm96_15.tif`, 2019-12-27) global 15° lattice and interpolation
implementation. It has no generator or raw-data refresh pipeline. Do not
regenerate it as part of an IERS update.

The split preserves all 1,104 EOP numeric literals and the current
coverage: MJD **61308–61675**, **2026-09-25–2027-09-27**. Snapshot values are
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
later. The current file is `finals2000A-2026-09-25.txt`.

The snapshot retains the official fixed-width records rather than converting
them to CSV or synthesizing missing columns. Calendar dates and MJD must
agree; the required Bulletin A polar-motion and UT1 fields, their `I`/`P`
flags, and uncertainties must be valid. Missing, duplicated, out-of-order, or
incomplete daily records fail validation. An update fails if no complete
368-row window satisfies the freshness and coverage rules below; it does not
silently shorten app coverage.

## Reproduce and check generation

Install [uv](https://docs.astral.sh/uv/) and `monkeyc-fmt` **0.1.1**:

```sh
cargo install --locked --version 0.1.1 monkeyc-fmt
```

`tools/iers.py` uses PEP 723 inline metadata, requires Python 3.11 or later, and
declares no third-party Python dependencies. Run these commands from the
repository root:

```sh
make generate-iers
make check-generated
make check-freshness
```

The Make targets pass `MONKEYC_FMT` to the generator. `UV` and `MONKEYC_FMT`
can be overridden when different executables are needed. Direct generator
invocation uses `monkeyc-fmt` from `PATH`:

```sh
uv run --script tools/iers.py generate
uv run --script tools/iers.py check
uv run --script tools/iers.py check-freshness
```

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

`check-freshness` is the date-sensitive guard used by CI. It validates the
snapshot without downloading anything: the coverage start must be no more than
seven UTC days old, and the end must be at least 330 UTC days in the future.
The 330-day threshold leaves room for the monthly maintenance schedule while
retaining roughly a full year of predictions in the 368-day table.

## Explicit refresh and failure handling

Only the updater fetches IERS data:

```sh
make update-iers

uv run --script tools/iers.py update
```

The repository also runs this updater automatically on the first day of each
month and on demand through **Update IERS EOP data** in GitHub Actions. A
successful run validates the generated source, freshness, formatting, and all
three simulator test profiles, then opens a pull request containing the dated
snapshot and generated module. If the download or any validation fails, no
branch or pull request is created.

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
snapshot and module untouched. Installation stages all generated outputs and rollback
copies beside their destinations before replacing any. The old dated
snapshot is removed only after all new outputs are installed. An installation
failure restores replaced files and removes newly created files. If filesystem
errors also prevent rollback, the updater reports the recovery paths and
retains the relevant backup files. Each replacement is atomic, but the pair
is not a crash-atomic filesystem transaction; do not run concurrent updates or
interrupt installation deliberately.

## Developer update procedure

1. Start with a checkout whose existing Earth-data changes you understand.
   Configure the caller's network/proxy environment and ensure curl is installed.
2. Run `make update-iers` explicitly, or invoke
   `uv run --script tools/iers.py update` with `monkeyc-fmt` available on
   `PATH`.
3. Review the new snapshot's date, 368-day coverage, provenance, and EOP changes,
   together with the generated module and updated coverage fields in README and
   this document. A successful update leaves exactly one dated snapshot. Do not
   hand-edit the generated module to fix a failed check.
4. Run `make check-generated` and `make lint`, then the appropriate local build
   and behavioral checks for the change. If only generator logic changed, use
   `make generate-iers` against the existing snapshot instead of refreshing data.
5. Commit the snapshot replacement, generated module, and coverage documentation
   together, along with any generator changes needed to reproduce them.

To undo a completed refresh, restore the prior snapshot, generated module, and
coverage documentation together from version control, then run
`make check-generated`. Restoring the previous generator as well is necessary
when its output contract changed.
