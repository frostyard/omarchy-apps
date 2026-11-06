# omarchy-apps contributor context

This repository builds two Debian packages, `voxtype` and `moonlight-qt`, from pinned upstream sources. It runs package builds in a `debian:trixie` container and publishes Debian packages only through frostyard/apt-publisher.

## Invariants

- The input digest of an app (`lib/inputs.sh`) covers `build.sh`, `lib/deb.sh`, `download/verified-download.sh`, `apps/<app>.sh` and that app's own entry in `download/checksums.json`. A change to 1 of these files rebuilds and republishes every app whose digest it changes on the next `main` run. Change them only when a new package build is the intent, and say so in the PR.
- A change to `lib/inputs.sh` changes how the digest is made, so every app gets a new digest and is republished. A change to `plan.sh` changes which apps publish. Test both with `bash tests/run.sh`.
- `build.sh` runs as root in `debian:trixie`; local builds use `podman run --rm -v "$PWD":/src -w /src debian:trixie bash build.sh <app>`. Container steps use `bash`, not `sh` (the build job sets `defaults.run.shell: bash`).
- `plan.sh` publishes an app only when `Frostyard-Inputs` differs from the app's current input digest. A forced rebuild in `build.yml` can publish one named app. PRs and dispatches outside `main` build every app but publish nothing.
- `download/checksums.json` pins upstream URL, SHA-256 and version. Keep pins exact and rebuild the package through CI.
- The release job attaches exactly one `amd64` `.deb` per published app to a GitHub release, validates the version and `Frostyard-Inputs`, and creates the main timestamp tag. Publication goes through the `publish-deb` dispatch to `frostyard/apt-publisher`.
- This repository holds no signing key and no APT bucket credentials. Never add signing material or publication credentials. apt-publisher keeps the newest 2 versions of each app (core ADR-0067).
- Request values such as `REBUILD`, `PUBLISH`, `TAG` and `INDEX` arrive through `env:`. Do not put dynamic request values inside `run:` text.
- CI gates run `make ci`: `verify` prerequisite runs `lint` and `test`; `lint` runs shellcheck, actionlint and both baseline checks; `test` runs `bash tests/run.sh` with no network.
- Every workflow action uses a 40-character commit SHA and a version comment. Workflows use top-level read-only or empty permissions, and every checkout sets `persist-credentials: false`.
- Files in `.github/risk-paths.json`, `.github/workflows/**`, `build.sh`, `plan.sh`, `lib/**`, `apps/**`, `download/**`, `tests/**`, `Makefile`, `mise.toml`, `mise.lock` are high-risk paths. A PR that matches them needs tier 3 review and the `risk:high` label.

## Gates

- `mise install` installs pinned tools.
- `make ci` runs the same verification and tests that CI runs.
- `bash tests/run.sh` tests `plan.sh`, `lib/inputs.sh` and `lib/deb.sh` without network access.
- The README checker and `actionlint` must pass before a PR is ready.
