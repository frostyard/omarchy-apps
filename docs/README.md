# Documentation

Docs are split by the question they answer:

| Directory | Question | Contents |
| --- | --- | --- |
| [adr/](adr/) | **Why** did we choose this? | Architecture Decision Records |
| [design/](design/) | **How** does it fit together? | Living architecture documents |
| [specs/](specs/) | **What exactly** is the contract? | Precise, testable contracts |
| [plans/](plans/) | **When/in what order** do we build? | Roadmaps and phase plans |
| [runbooks/](runbooks/) | **What do I type now?** | Development and operation procedures |

## Index

### Org-wide decisions

- [org-adrs.md](org-adrs.md): the frostyard/core ADRs that bind this repository.

### Decisions (ADRs)

- [TEMPLATE.md](adr/TEMPLATE.md): the template for local architecture decisions.

### Design

- [TEMPLATE.md](design/TEMPLATE.md): the template for design documents.
- [overview.md](design/overview.md): packages, input digests, publication flow, rebuild rules and upstream bumps.

### Specs

- [TEMPLATE.md](specs/TEMPLATE.md): the template for precise contracts.

### Plans

- [TEMPLATE.md](plans/TEMPLATE.md): the template for roadmap plans.

### Runbooks

- [development.md](runbooks/development.md): build locally, plan a publication and run the gates.

## Conventions

- New docs start from their category's `TEMPLATE.md`.
- New docs are indexed here.
- Design documents describe the current system. Core ADRs hold the rationale.
- Cross-links go in both directions.
- The root [README.md](../README.md) follows core's [README spec](https://github.com/frostyard/core/blob/main/docs/specs/readme.md).
