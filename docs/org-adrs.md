# Org-wide decisions (frostyard/core ADRs)

These core ADRs bind `omarchy-apps`. This list records the repository rule that each one applies.

## Decisions this repository follows

- [ADR-0018 — Org-wide agent instruction and knowledge surfaces](https://github.com/frostyard/core/blob/main/docs/adr/0018-org-wide-agent-instruction-and-knowledge-surfaces.md): [`AGENTS.md`](../AGENTS.md) is canonical. The four aliases are relative symlinks to it. Blocking corrections add one line to [`.memory/corrections.jsonl`](../.memory/corrections.jsonl).
- [ADR-0019 — Repository governance as machine-readable policy with risk tiers](https://github.com/frostyard/core/blob/main/docs/adr/0019-governance-as-code-and-risk-tiers.md): [`.github/risk-paths.json`](../.github/risk-paths.json) identifies high-risk package and publication paths. [`.github/pull_request_template.md`](../.github/pull_request_template.md) requires a risk tier.
- [ADR-0021 — SHA-pinned actions and least-privilege CI workflows](https://github.com/frostyard/core/blob/main/docs/adr/0021-sha-pinned-actions-and-least-privilege-ci.md): workflows pin actions to commit SHAs, use least privilege and disable checkout credential persistence.
- [ADR-0025 — One docs/ tree per repository, in core's four-category shape](https://github.com/frostyard/core/blob/main/docs/adr/0025-consolidate-repository-docs-into-docs.md): repository documentation lives in the [`docs/`](README.md) tree and starts from category templates.
- [ADR-0029 — ACMM conformance via canonical aliases](https://github.com/frostyard/core/blob/main/docs/adr/0029-acmm-conformance-via-canonical-aliases.md): `CLAUDE.md`, `GEMINI.md`, `.cursorrules` and `.github/copilot-instructions.md` are relative symlinks to `AGENTS.md`.
- [ADR-0043 — Pin repository tools in mise and name the verify gate](https://github.com/frostyard/core/blob/main/docs/adr/0043-pin-repository-tools-in-mise-and-name-the-verify-gate.md): [`mise.toml`](../mise.toml) and [`mise.lock`](../mise.lock) pin the repository tools.
- [ADR-0044 — Expose the make gate triad in every repository](https://github.com/frostyard/core/blob/main/docs/adr/0044-expose-the-make-gate-triad-in-every-repository.md): the [`Makefile`](../Makefile) exposes `verify`, `check` and `ci`.
- [ADR-0055 — Publish Debian packages through the apt-publisher single writer](https://github.com/frostyard/core/blob/main/docs/adr/0055-publish-debian-packages-through-the-apt-publisher.md): this repository sends package publication requests to apt-publisher. It does not hold signing or bucket credentials.
- [ADR-0060 — Publish omarchy-apps through the apt-publisher](https://github.com/frostyard/core/blob/main/docs/adr/0060-publish-omarchy-apps-through-the-apt-publisher.md): omarchy-apps attaches built Debian packages to a release and requests publication.
- [ADR-0066 — Build only the omarchy-apps packages that Snosi uses](https://github.com/frostyard/core/blob/main/docs/adr/0066-build-only-the-omarchy-apps-packages-that-snosi-uses.md): the maintained build set contains only packages used by a snosi image or sysext.
- [ADR-0067 — Publish omarchy-apps packages on change, and keep the newest two](https://github.com/frostyard/core/blob/main/docs/adr/0067-publish-omarchy-apps-on-change-and-keep-the-newest-two.md): publication follows the input digest and apt-publisher keeps the newest two versions of each app.
- [ADR-0068 — Label pull requests that touch high-risk paths](https://github.com/frostyard/core/blob/main/docs/adr/0068-label-pull-requests-that-touch-high-risk-paths.md): [`.github/workflows/risk-paths.yml`](../.github/workflows/risk-paths.yml) applies the level label of the strictest matching entry (`level:L1` to `level:L4`) and `risk:high` at L1 and L2 to matching pull requests (core ADR-0078).
- [ADR-0071 — Hold every code repository to one baseline](https://github.com/frostyard/core/blob/main/docs/adr/0071-hold-every-code-repository-to-one-baseline.md): this repository carries the baseline guard and its negative tests.
- [ADR-0072 — Write every README to one standard](https://github.com/frostyard/core/blob/main/docs/adr/0072-write-every-readme-to-one-standard.md): [the root README](../README.md) is the packaging README for this repository.
- [ADR-0075 — Group Dependabot updates and sync skills once a day](https://github.com/frostyard/core/blob/main/docs/adr/0075-batch-routine-pull-requests.md): each entry of [`.github/dependabot.yml`](../.github/dependabot.yml) has 1 `patterns: ["*"]` group, so Dependabot opens at most 1 version-update PR for each ecosystem and run; security updates stay 1 PR each.

## Not applicable

- ADR-0070 does not apply because this repository has no user-facing documentation site.
- ADR-0012 and ADR-0053 do not apply because this repository has no Go module and publishes packages directly from `main`.
