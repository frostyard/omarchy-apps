# omarchy-apps contributor context

This repository builds two Debian packages, `voxtype` and `moonlight-qt`, from pinned upstream sources. It runs package builds in a `debian:trixie` container and publishes Debian packages only through frostyard/apt-publisher. Each build produces 1 unmarked `.deb`, which is published to Debian 13 `trixie` and to Debian 14 `forky`.

## Invariants

- The input digest of an app (`lib/inputs.sh`) covers `build.sh`, `lib/deb.sh`, `download/verified-download.sh`, `apps/<app>.sh` and that app's own entry in `download/checksums.json`. A change to 1 of these files rebuilds and republishes every app whose digest it changes on the next `main` run. Change them only when a new package build is the intent, and say so in the PR.
- A change to `lib/inputs.sh` changes how the digest is made, so every app gets a new digest and is republished. A change to `plan.sh` changes which apps publish. Test both with `bash tests/run.sh`.
- `build.sh` runs as root in `debian:trixie`; local builds use `podman run --rm -v "$PWD":/src -w /src debian:trixie bash build.sh <app>`. Container steps use `bash`, not `sh` (the build and `smoke-forky` jobs set `defaults.run.shell: bash`).
- A package carries no `~debNN` marker, so the same file goes to both codenames (core ADR-0055). Its `Depends` must be satisfiable in Debian 14 as well: the `smoke-forky` job installs each built package in `debian:forky` and runs the app's `APP_SMOKE` there, and the release job waits for it. omarchy-apps' registration for `forky` in apt-publisher's `config/producers.tsv` is the compatibility record. Never add a codename to the publication request without that install passing, and never mark a version with `~debNN` without an ADR.
- **The smoke test proves that the app starts.** `smoke.sh APP` loads `apps/APP.sh` with errors not ignored, installs `APP_SMOKE_DEPS` when the recipe sets it (`apt-get install --no-install-recommends --yes`), and runs `bash -c "$APP_SMOKE"`. Both the `build` job and the `smoke-forky` job call it after the package is installed, so `APP_SMOKE` must be a command that really runs the program: never `test -x`, never a `||` fallback. `APP_SMOKE_DEPS` names packages the smoke needs but the package must not depend on (`xvfb xauth` for moonlight-qt); a host library that the app links belongs in `APP_EXTRA_DEPENDS` instead. `smoke.sh` is NOT part of an app's input digest: a smoke change re-runs the gate and republishes nothing, so do not add it to `lib/inputs.sh`.
- `plan.sh` reads 1 Packages index for each codename (`--packages` once per index), and publishes an app when `Frostyard-Inputs` differs from the app's current input digest in any index: no published version in an index, no field, or another digest there is changed. An app is skipped only when every index holds its current digest. A forced rebuild in `build.yml` can publish one named app. PRs and dispatches outside `main` build every app but publish nothing.
- `download/checksums.json` pins upstream URL, SHA-256 and version. Keep pins exact and rebuild the package through CI.
- The release job attaches exactly one `amd64` `.deb` per published app to a GitHub release, validates the version and `Frostyard-Inputs`, and creates the main timestamp tag. Publication goes through the `publish-deb` dispatch to `frostyard/apt-publisher`, which names both codenames, `trixie` and `forky`.
- This repository holds no signing key and no APT bucket credentials. Never add signing material or publication credentials. apt-publisher keeps the newest 2 versions of each app (core ADR-0067).
- Request values such as `REBUILD`, `PUBLISH`, `TAG`, `TRIXIE_INDEX` and `FORKY_INDEX` arrive through `env:`. Do not put dynamic request values inside `run:` text. The codename each index belongs to is in its file name, and `plan.sh` names that file in its summary table.
- CI gates run `make ci`: `verify` prerequisite runs `lint` and `test`; `lint` runs shellcheck, actionlint and both baseline checks; `test` runs `bash tests/run.sh` with no network.
- `ci` is the gate check. A `GITHUB_TOKEN` pull request starts no `pull_request` workflow, so `check-dependencies.yml` dispatches `ci.yml` and `build.yml` on the bump branch. Keep the `workflow_dispatch` trigger in `ci.yml`.
- Every workflow action uses a 40-character commit SHA and a version comment. Workflows use top-level read-only or empty permissions, and every checkout sets `persist-credentials: false`.
- The bump PR sets its own level labels. A PR that `GITHUB_TOKEN` opens starts no `pull_request_target` run, so the triage caller never labels it (frostyard/core#233); `check-dependencies.yml` sets them in the `create-pull-request` step instead: `add-paths` limits the commit to `download/checksums.json`, and `labels` names the level of that file plus `risk:high` at L1 and L2. `tests/check-baseline.sh` checks the labels against the level that `.github/risk-paths.json` gives the add-paths, so a list change that moves that level must change them too.
- Files in `.github/risk-paths.json`, `.github/workflows/**`, `build.sh`, `plan.sh`, `lib/**`, `apps/**`, `download/**`, `tests/**`, `Makefile`, `mise.toml`, `mise.lock` are risk paths, each at a level in the list (core ADR-0078). A PR that matches one gets that level's label (`level:L1` read every line, `level:L2` read the diff, `level:L3` skim, `level:L4` title and CI), and `risk:high` at L1 and L2, which needs tier 3 review. A core org floor can raise the computed level above the entry's level, and a stricter level label that the PR already has stays (the ratchet); only the author lowers it, with the reason in the PR. The workflow removes `ready-for-human` when the head moves after the label (core ADR-0077).

## Releases and dependencies

- Tag format: `main-<UTC timestamp YYYYMMDDHHMMSS>-<7-character commit SHA>`,
  for example `main-20261124013331-f1f84f6`. The `Check the packages` step of
  the `Release` job in [`build.yml`](.github/workflows/build.yml) computes it.
- How a release starts: automatically. Every push to `main` runs `Build`;
  `plan.sh` compares each app's input digest with the `Frostyard-Inputs` field
  in the published `trixie` and `forky` indexes, and the `Release` job creates
  the GitHub release and its tag only when 1 or more apps changed. The
  `Request APT publication` job then sends `publish-deb` to
  frostyard/apt-publisher. A dispatch of `Build` on `main` with the `rebuild`
  input forces 1 named app.
- Who tags: the `Build` workflow, never a person by hand. Agents never tag,
  push tags, create a release, or dispatch `Build` on `main`; merging a PR
  that changes an input digest is what publishes (see Invariants).
- Version rule: the repository has no version of its own. A package version
  is the upstream version pinned in
  [`download/checksums.json`](download/checksums.json) plus
  `-frostyard<build timestamp>` ([`lib/deb.sh`](lib/deb.sh)). No release
  check is needed: a change on `main` to an input of an app digest
  (`lib/inputs.sh`) is released by the same run.
- Dependencies:
  - Upstream pins: the URL, SHA-256 and version of each app in
    [`download/checksums.json`](download/checksums.json). The weekly
    [`check-dependencies.yml`](.github/workflows/check-dependencies.yml) opens
    the bump PR.
  - Internal: frostyard/core's reusable workflow
    `.github/workflows/pr-triage.yml`, pinned to a commit in
    [`risk-paths.yml`](.github/workflows/risk-paths.yml) and
    [`pr-triage-dispatch.yml`](.github/workflows/pr-triage-dispatch.yml); and
    frostyard/apt-publisher, which the release reaches by the `publish-deb`
    dispatch (not pinned) and which lists omarchy-apps for `trixie` and
    `forky` in its `config/producers.tsv`.
  - Tools and actions: the tool pins in `mise.toml` and `mise.lock`; the
    action SHAs in `.github/workflows/`, which Dependabot bumps monthly
    ([`dependabot.yml`](.github/dependabot.yml)).
- Who uses this repository: frostyard/snosi installs `voxtype` and
  `moonlight-qt` from the Frostyard APT repository in its `voxtype` and
  `moonlight` sysexts.

## Gates

- `mise install` installs pinned tools.
- `make ci` runs the same verification and tests that CI runs.
- `bash tests/run.sh` tests `plan.sh`, `lib/inputs.sh`, `lib/deb.sh` and `smoke.sh` without network access. The smoke cases use fake recipes and a stub `apt-get`.
- The README checker and `actionlint` must pass before a PR is ready.
