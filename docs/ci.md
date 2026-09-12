# CI trust and build contract

`.github/workflows/build.yml` runs on pushes to `main`, pull requests, and manual
dispatch. Feature-branch pushes do not trigger a second run alongside their PR;
branches without a PR can be checked through manual dispatch.
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
the checkout, with mode `600`. Its relative path is passed through `GITHUB_ENV`
as `CIQ_KEY_PATH`; Make receives the full path through `DEVELOPER_KEY`.
An `if: always()` cleanup step removes the key after compilation, including
failed builds. Artifact upload selects only the expected PRG file.

External actions use version tags:

| Action | Reference |
| --- | --- |
| `actions/checkout` | `v4` |
| `astral-sh/setup-uv` | `v10.0.1` |
| `actions/setup-java` | `v4` |
| `DuckSoft/setup-connectiq-actions` | `v2` |
| `actions/upload-artifact` | `v7` |

setup-uv installs uv **0.12.12**. The Connect IQ setup action installs SDK
**9.2.0**, and setup-java selects Java **17**.

Both workflows run representative simulator tests on one Ubuntu 22.04 runner
before building. The simulator wrapper runs `make test-profiles` in one
simulator session, testing `fr255s`, `fr255`, then `fr965`. This target forces
serial execution even when Make receives `-j`; a failed profile stops the
remaining tests and blocks the build.

The build job runs `make build-all` for `fr255`, `fr255s`, `fr255m`, `fr255sm`,
and `fr965`. Its parallel job count is half of `nproc`, rounded down, with a
minimum of one. Each compiler writes to `bin/<device>/` to isolate generated
state as well as the PRG. The job uploads
`bin/<device>/PolarFinder-<device>.prg` as `PolarFinder-<device>`, fails the
upload if that file is absent, and retains the artifact for **14 days**.
