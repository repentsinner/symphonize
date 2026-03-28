# symphonize

Plan-to-implementation execution engine for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

Symphonize turns plain-language specifications into shipped PRs with
minimal user interaction. You define what to build (SPEC.md) and
how to sequence it (ROADMAP.md). Agents handle implementation
autonomously — branching, coding, testing, and opening PRs. You
review the results.

The governance files constrain agent behavior at each stage, making
output loosely deterministic: predictable enough to review
confidently, flexible enough to handle real codebases.

## Design principles

The goals that shape every decision in symphonize.

- **Depth-first by section** — context coherence, testable PRs, early
  bug detection
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
- **Governance files as source of truth** — SPEC.md drives ROADMAP.md
  drives work, not the other way around. See
  [Governance files](#governance-files).

## Governance files

Symphonize assumes — and enforces — a three-file state loop at the
repo root:

| File | Role |
|------|------|
| `SPEC.md` | Declarative target state. What the system does and why. |
| `ROADMAP.md` | Imperative work queue. What remains to close the gap. |
| `CHANGELOG.md` | Release history. What shipped, in [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format. |

The loop works like this: **SPEC.md** defines the destination,
**ROADMAP.md** tracks the remaining work, and **CHANGELOG.md** records
what landed. Each `/next` batch advances the roadmap, produces
conventional commits, and opens a PR. A downstream
[release-please](https://github.com/googleapis/release-please)
workflow (or [melos](https://melos.invertase.dev/) for monorepos)
consumes those conventional commits to cut versioned releases and
update the changelog automatically.

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

Symphonize ships a reusable GitHub Actions workflow that validates
governance files on every push and PR — markdownlint, SPEC.md
status-line checks, and optional README heading enforcement.

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

Locally, run `/symphonize:lint` for the same checks without
waiting for CI.

## Usage

1. **`/symphonize:plan`** scopes the spec gap and breaks it into
   sized workstreams
2. **`/symphonize:next`** selects the active section, dispatches a
   batch agent in a worktree, cherry-picks results, runs CI, opens
   a single PR
3. **`/symphonize:orchestrate`** wraps `/next` in ralph-loop for
   unattended multi-batch execution
4. **`/symphonize:clean`** prunes branches, worktrees, and updates
   governance docs after PRs merge
5. **`/symphonize:lint`** validates governance files locally
6. **`/symphonize:init`** scaffolds governance files and CI workflows
   into a new project

The batch agent protocol (`BATCH_AGENT.md`) manages sub-agent
dispatch, merge conflict resolution, and CI verification.

## API

| Command | Description |
|---|---|
| `/symphonize:plan [task]` | Plan spec and roadmap entries for a new task |
| `/symphonize:next [target]` | Execute next unblocked workstreams (depth-first by section) |
| `/symphonize:orchestrate` | Start ralph-loop to work through ROADMAP.md unattended |
| `/symphonize:clean [--lite\|--full]` | Clean up after batch execution |
| `/symphonize:lint [type]` | Validate governance files (markdownlint, status lines, headings) |
| `/symphonize:init` | Scaffold governance files and CI workflows into a project |

### Reusable workflows

Target projects reference these via `workflow_call`:

| Workflow | Description |
|---|---|
| `governance-lint.yml` | Markdownlint + SPEC.md status lines + README heading checks |

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
- A project with `SPEC.md` and `ROADMAP.md` following the conventions
  in your `CLAUDE.md` (or run `/symphonize:init` to scaffold them)
- [ralph-loop](https://github.com/anthropics/claude-plugins-public/tree/main/plugins/ralph-loop)
  plugin (for unattended `/orchestrate` mode)

## License

MIT
