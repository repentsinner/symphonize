# symphonize

Depth-first roadmap execution engine for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

Turns `ROADMAP.md` workstreams into batched PRs via worktree-isolated
agents. Completes all unblocked workstreams within one roadmap section
before moving to the next — producing testable vertical slices instead
of scattered plumbing PRs.

## Prerequisites

- A project with `SPEC.md` and `ROADMAP.md` following the conventions
  in your `CLAUDE.md`
- [ralph-loop](https://github.com/anthropics/claude-plugins-public/tree/main/plugins/ralph-loop)
  plugin (for unattended `/orchestrate` mode)
- `gh` CLI authenticated

## Install

```
/plugin install symphonize
```

Or from source during development:

```bash
claude --plugin-dir /path/to/symphonize
```

## Commands

| Command | Description |
|---|---|
| `/symphonize:next [target]` | Execute next unblocked workstreams (depth-first by section) |
| `/symphonize:orchestrate` | Start ralph-loop to work through ROADMAP.md unattended |
| `/symphonize:clean [--lite\|--full]` | Clean up after batch execution |
| `/symphonize:plan [task]` | Plan spec and roadmap entries for a new task |

## How it works

1. **`/plan`** scopes the spec gap and breaks it into sized workstreams
2. **`/next`** selects the active section, dispatches a batch agent in
   a worktree, cherry-picks results, runs CI, opens a single PR
3. **`/orchestrate`** wraps `/next` in ralph-loop for unattended
   multi-batch execution
4. **`/clean`** prunes branches, worktrees, and updates governance docs
   after PRs merge

The batch agent protocol (`BATCH_AGENT.md`) manages sub-agent
dispatch, merge conflict resolution, and CI verification.

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

### Governance lint

[bug-free-happiness](https://github.com/repentsinner/bug-free-happiness)
provides a reusable GitHub Actions workflow that validates governance
files on every push and PR — markdownlint, SPEC.md status-line
checks, and optional README heading enforcement. Add it to your repo:

```yaml
# .github/workflows/spec-lint.yml
name: Spec Lint
on:
  push:
    branches: [main]
  pull_request:

jobs:
  lint:
    uses: repentsinner/bug-free-happiness/.github/workflows/spec-lint.yml@v1
```

## Design principles

- **Depth-first by section** — context coherence, testable PRs, early
  bug detection
- **Worktree isolation** — never touches the user's main checkout
- **Single PR per batch** — one CI run, one review surface
- **Fail fast** — CI after each cherry-pick, not just at the end
