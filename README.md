# symphonize

Plan-to-implementation execution engine for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

Symphonize turns plain-language requirements into auditable specs into
shipped PRs with minimal user interaction. You describe the problem
(`/discover`), make technical decisions (`/plan`), roadmap the work
(`/roadmap`), and execute (`/next` or `/orchestrate`).
Agents handle implementation autonomously — branching, coding,
testing, and opening PRs. You review the results.

The governance files constrain agent behavior at each stage, making
output loosely deterministic: predictable enough to review
confidently, flexible enough to handle real codebases.

## Design principles

The goals that shape every decision in symphonize.

- **Acceptance before exploration** — define "done" before exploring
  "how," at every layer. Success criteria before features, observable
  behavior before design, failing tests before code. TDD applied
  recursively from requirements through implementation.
- **Thin vertical slices** — every PR delivers a complete path from
  internal logic through to a user-facing surface. Horizontal layers
  (plumbing without a user-visible path) ship inventory, not value.
- **Single-responsibility commands** — each command reads upstream
  deliverables but writes exactly one. `/discover` → REQUIREMENTS.md,
  `/plan` → SPEC.md, `/roadmap` → ROADMAP.md. Upstream backpressure
  fills gaps without blocking progress.
- **Depth-first by section** — context coherence, testable PRs, early
  bug detection
- **Boy Scout Rule** — leave the code better than you found it. Agents
  clean up orphaned horizontal layers in files they touch.
- **Worktree isolation** — never touches the user's main checkout
- **Single PR per batch** — one CI run, one review surface
- **Fail fast** — CI after each cherry-pick, not just at the end

## Opinions

How the [design principles](#design-principles) are implemented in
practice. Symphonize expects these conventions and won't work well
without them.

- **[Conventional Commits](https://www.conventionalcommits.org/)** —
  every commit follows `<type>(<scope>): <description>`. Feeds
  release-please and changelog generation.
- **[Release Please](https://github.com/googleapis/release-please)**
  (or [melos](https://melos.invertase.dev/) for monorepos) — turns
  conventional commits into semver releases and CHANGELOG.md entries.
- **Branch protection** — work never lands on main directly. Every
  change flows through a feature branch and a PR with CI.
- **[Keep a Changelog](https://keepachangelog.com/en/1.1.0/)** —
  CHANGELOG.md format. `[Unreleased]` section always present.
- **Feature branches per unit of work** — `/next` creates worktree
  branches, `/clean` prunes them. No long-lived branches.
- **`gh` CLI as the Git-ops interface** — authenticated `gh` handles
  push and PR creation.
- **Governance files as source of truth** — REQUIREMENTS.md drives
  SPEC.md drives ROADMAP.md drives work, not the other way around.
  See [Governance files](#governance-files).

## Governance files

Symphonize assumes — and enforces — a four-file governance loop at the
repo root:

| File | Role |
|------|------|
| `REQUIREMENTS.md` | Problem-space requirements. What users need and why. |
| `SPEC.md` | Declarative target state. What the system does and why. |
| `ROADMAP.md` | Imperative work queue. What remains to close the gap. |
| `CHANGELOG.md` | Release history. What shipped, in [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format. |

The loop: `/symphonize:discover` interviews the user and produces
**REQUIREMENTS.md**. `/symphonize:plan` explores technical decisions
and produces **SPEC.md** sections. `/symphonize:roadmap` breaks spec
sections into **ROADMAP.md** workstreams as thin vertical slices.
Each `/next` batch advances the roadmap, produces conventional
commits, and opens a PR. A downstream
[release-please](https://github.com/googleapis/release-please)
workflow (or [melos](https://melos.invertase.dev/) for monorepos)
consumes those commits to cut versioned releases and update
**CHANGELOG.md** automatically.

Each command reads upstream deliverables but writes exactly one.
When upstream documents are absent or thin, commands apply
backpressure — filling small gaps inline, recommending the upstream
command for large ones. Technical users can enter the pipeline at
any point; the commands will pull them back as far as needed.

### Cross-document traceability

Governance files use namespaced slug prefixes (`§req:`, `§spec:`,
`§road:`) for grep-friendly cross-document references. Every spec
section traces to a requirement; every roadmap workstream traces to a
spec section. See `CONVENTIONS.md` for the full traceability chain.

### Why in-repo?

GitHub Issues and Discussions offer rich triage UI, cross-repo
linking, and notifications — but they live behind an API. Every
query costs a tool call, pagination, and noise filtering, all of
which burn agent context and add failure modes.

Files are first-class to agents. Reading ROADMAP.md is one tool call.
Governance files travel with the branch, so the spec that was true
when a commit was made is visible in the same checkout. Spec changes
and code changes land in the same PR — they can't drift apart.

The tradeoff: you lose labels, milestones, assignees, and
browser-friendly triage. For agent-driven execution, co-location
with the code wins.

### Governance lint

Symphonize validates governance files at two levels:

- **Local** (`/symphonize:lint`): runs `npx markdownlint-cli2` against
  SPEC.md, ROADMAP.md, and README.md. Catches formatting errors before
  pushing.
- **CI** (`governance-lint.yml`): runs markdownlint plus SPEC.md
  status-line checks, slug cross-reference validation, optional README
  heading enforcement, and [Vale](https://vale.sh) prose linting (when
  `.vale.ini` exists). Vale enforces modal verb compliance (IEEE
  shall/should/may), flags passive voice, and catches filler phrases.

The local command is a subset of CI — it covers formatting but not
structural or prose checks.

In CI, add a caller workflow:

```yaml
# .github/workflows/governance-lint.yml
name: Governance Lint
on:
  push:
    branches: [main]
  pull_request:

jobs:
  lint:
    uses: repentsinner/symphonize/.github/workflows/governance-lint.yml@v1
    with:
      readme-type: library  # or "application", or "" to skip
```

## Usage

| Command | Description |
|---|---|
| `/symphonize:init` | Scaffold governance files and CI workflows into a project (one-time setup) |
| `/symphonize:discover` | Domain discovery — structured interview that produces REQUIREMENTS.md |
| `/symphonize:plan [task]` | Technical decisions — explore design options and produce SPEC.md sections |
| `/symphonize:roadmap [section]` | Break spec sections into ROADMAP.md workstreams (thin vertical slices) |
| `/symphonize:next [target]` | Execute next unblocked workstreams (depth-first by section) |
| `/symphonize:orchestrate` | Start ralph-loop to work through ROADMAP.md unattended |
| `/symphonize:review [PR]` | Review a PR — resolve conflicts, check out locally, guide integration testing |
| `/symphonize:clean [--lite\|--full]` | Clean up after batch execution |
| `/symphonize:lint [type]` | Validate governance files (markdownlint) |
| `/symphonize:feedback` | Submit feedback or report a bug to the symphonize project |

The batch agent protocol (`protocols/batch-agent.md`) manages
sub-agent dispatch, merge conflict resolution, and CI verification.

## API

### Reusable workflows

Target projects reference these via `workflow_call`:

| Workflow | Description |
|---|---|
| `governance-lint.yml` | Markdownlint + SPEC.md status lines + slug cross-refs + Vale prose linting + README heading checks |

Template workflows (copied by `/symphonize:init`, not called
cross-repo):

| Workflow | Description |
|---|---|
| `release-please.yml` | Conventional commits → semver releases |
| `auto-merge-release.yml` | Auto-merge release PRs |
| `update-major-tag.yml` | Float `vN` tag on each release |

## Installation

Add the marketplace, then install:

```shell
/plugin marketplace add repentsinner/symphonize
/plugin install symphonize@repentsinner-symphonize
```

Or from source during development:

```bash
claude --plugin-dir /path/to/symphonize
```

### Prerequisites

- `git`, `gh` (authenticated), and `npx` (Node.js) on `PATH`
- `vale` (optional — needed when `.vale.ini` exists for prose linting)
- A project with governance files (run `/symphonize:init` to scaffold
  them — format conventions are in `CONVENTIONS.md`)
- [ralph-loop](https://github.com/anthropics/claude-plugins-public/tree/main/plugins/ralph-loop)
  plugin (for unattended `/orchestrate` mode)

## License

MIT
