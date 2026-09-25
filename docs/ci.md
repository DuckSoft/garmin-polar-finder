# CI trust and build contract

`.github/workflows/build.yml` runs on pushes to `main`, pull requests, and manual
dispatch. Feature-branch pushes do not trigger a second run alongside their PR;
branches without a PR can be checked through manual dispatch.
`.github/workflows/release.yml` runs on pushes of tags matching `v*`.
`.github/workflows/update-iers.yml` runs twice each week and can also be
dispatched manually. It refreshes IERS data, validates the generated
module and freshness, runs the simulator profiles, and opens a pull request only
after all checks pass.
The build and release workflows first run `make check-generated` and
`make lint` without a signing secret. The build workflow also runs
`make check-freshness`; release validation remains reproducible for historical
tags. The lint stage checks all tracked or untracked, nonignored Monkey C files
with the pinned `monkeyc-fmt` **0.1.1**, as well as project XML. Each validation
or test job installs the formatter once through Cargo.
Build and release jobs do not run the IERS updater: they verify the committed
snapshot and generated module, so passing a build cannot silently change the data
window. Installing actions, uv,
the Rust toolchain, formatting packages, and build tools may use the network;
this is separate from refreshing IERS reference data.

Both workflows default to `contents: read` and disable checkout credential
persistence. Only the release workflow's `publish` job grants `contents: write`.
The build workflow uses `pull_request`, not `pull_request_target`.
After validation, fork pull requests run the build job's simulator tests with a
temporary developer key, skipping the repository signing-key preparation,
production compilation, and artifact upload steps. Pushes to `main`, manual
dispatches, and same-repository pull requests also run those signed build steps.
These are trusted code paths: contributors able to modify code or workflows on
same-repository branches must be trusted with the signing secret. The fork gate
does not make malicious same-repository changes safe. Release tags also run
code with access to the signing secret.

Configure the repository Actions secret `CIQ_DEVELOPER_KEY` as the base64
encoding of the binary Garmin developer signing key (`developer_key.der`).
Both workflows expose this secret only to the production key preparation step as an
environment variable, decode it with `base64 --decode`, and reject an empty
result. A missing or invalid secret fails a trusted build rather than producing
an unsigned substitute. The key is not printed or interpolated into the shell
program.

The decoded DER lives in a unique ignored `.ci-developer-key.*.der` file within
the checkout, with mode `600`. Its relative path is passed through `GITHUB_ENV`
as `CIQ_KEY_PATH`; Make receives the full path through `DEVELOPER_KEY`.
An `if: always()` cleanup step removes the key after compilation, including
failed builds. Artifact uploads select only production PRGs.

External actions use version tags:

| Action                                      | Reference |
| ------------------------------------------- | --------- |
| `actions/checkout`                          | `v4`      |
| `astral-sh/setup-uv`                        | `v10.0.1` |
| `dtolnay/rust-toolchain`                    | `stable`  |
| `actions/setup-java`                        | `v4`      |
| `DuckSoft/setup-connectiq-actions`          | `v2`      |
| `actions/upload-artifact`                   | `v7`      |
| `actions/download-artifact`                 | `v4.1.3`  |

setup-uv installs uv **0.12.12**. rust-toolchain provides stable Rust and
Cargo to validation and test jobs, which install `monkeyc-fmt` **0.1.1**.
Test targets format Monkey C sources before compilation. The Connect IQ setup
action installs SDK **9.2.0**, and setup-java selects Java **17**.

The build workflow uses one Ubuntu 22.04 build job with a **30-minute** timeout.
On trusted runs it compiles all production PRGs and removes the repository
signing key, then creates a temporary test key and runs simulator tests.
Fork pull requests proceed directly to temporary-key creation and testing.
Artifact upload follows successful tests.

The release workflow runs separate jobs in order:
`validate` → `test` → `build` → `publish`.
Its test job uses Ubuntu 22.04 with a **15-minute** timeout; validation,
production compilation, and publishing use `ubuntu-latest`.
A failed test blocks production compilation and publishing.

Both workflows generate a fresh RSA 4096-bit test key in `RUNNER_TEMP` and
convert it to DER. Tests do not use `CIQ_DEVELOPER_KEY`.
The Connect IQ setup action installs simulator dependencies in jobs that run
tests. `tests/run-simulator-tests.sh` runs the simulator and test command in a
shared Xvfb/D-Bus session, waits up to **30 seconds** for the simulator's TCP
port, and limits the session to **540 seconds**, with a **10-second** forced-kill
grace period. On exit it stops the simulator and prints any simulator log.

The wrapper invokes `make test-profiles` with `SHELL=bash`,
`SDK_HOME="$CONNECT_IQ_HOME"`, the temporary `DEVELOPER_KEY`, and `ICONS=` to
skip launcher regeneration. One simulator session tests `fr255s`, `fr255`, then
`fr965`. This target forces serial execution even when Make receives `-j`;
a failed profile stops the remaining tests. The Makefile requires a nonzero
passing-test count with zero failures and errors, and rejects failure, exception,
timeout, or crash output. A nonzero MonkeyDo exit status is accepted only after
that output validation passes, to accommodate the known test-runner status quirk.

Both workflows run `make build-all` for `fr255`, `fr255s`, `fr255m`, `fr255sm`,
and `fr965`. The parallel job count is half of `nproc`, rounded down, with a
minimum of one. Each compiler writes to `bin/<device>/` to isolate generated
state as well as `PolarFinder-<device>.prg`.

The build workflow uploads one `PolarFinder-all-devices` artifact from
`bin/*/PolarFinder-*.prg`. The release workflow uploads five separate artifacts
named `PolarFinder-<device>`, each selecting
`bin/<device>/PolarFinder-<device>.prg`. Uploads fail when their configured path
matches no files and retain artifacts for **14 days**.

The release `publish` job downloads the `PolarFinder-*` artifacts into `dist`
with `merge-multiple: true`. It uses `gh release create` to publish the five PRGs
under the pushed tag, using the tag as the title, verifying that the tag exists,
and generating release notes. Neither workflow exports or uploads a `.iq` package.
