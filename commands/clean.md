---
argument-hint: [--lite | --full]
description: Cleans up after executing batch workstreams
---

Read `${CLAUDE_PLUGIN_ROOT}/CONVENTIONS.md` § Governance root for
the resolution algorithm. Resolve the governance root before
operating.

Two modes: `--lite` and `--full`. If no flag is passed, auto-detect:
use `--lite` if `.claude/ralph-loop.local.md` exists, `--full`
otherwise.

## Lite mode (minimal between-iteration cleanup)

`/symphonize:next` pre-flight handles git fetch, branch pruning, and
worktree removal. Lite mode exists for anything `/symphonize:next`
doesn't cover — e.g., manual cleanup between interactive
`/symphonize:next` calls without ralph-loop.

1. Fetch origin, prune remote-tracking branches (`git fetch --prune`).
2. Delete local branches tracking pruned remotes.
3. Remove completed worktrees from `.claude/worktrees/` and their
   backing git worktrees.
4. Report what was cleaned.

Do NOT update governance docs, run verification, or sync chezmoi.

## Full mode (post-merge cleanup)

Run after PRs merge to main — either after a single batch or after
reviewing all ralph-loop PRs.

Never run `git stash` under any circumstance. Stashes created by
branch-switching during cleanup accumulate silently — the pop or
drop never happens.

### 0. Dirty-state guard

Before any other work, check for uncommitted changes:

```sh
git status --porcelain
```

- If the only dirty files are generated lock files (`pubspec.lock`,
  `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`,
  `Podfile.lock`, `Gemfile.lock`, `Cargo.lock`, `poetry.lock`,
  `go.sum`), restore them (`git restore <file>` for each) and
  proceed.
- If other files are dirty, print the `git status` output as a
  warning and abort. Tell the user to resolve uncommitted changes
  before re-running `/symphonize:clean --full`.

Do not stash, force-checkout, or silently discard uncommitted work.

### 1. Git housekeeping

- Fetch origin.
- Delete local branches whose upstream is gone (`git fetch --prune`,
  then delete local branches tracking pruned remotes).
- Delete remote branches for merged PRs that weren't auto-deleted
  (`gh pr list --state merged --author @me`, then
  `git push origin --delete <branch>` for each). Never delete a
  remote branch whose PR is still open.
- Delete any remaining `.claude/worktrees/` worktree directories
  and their backing git worktrees (`git worktree list`, `git worktree
  remove`).
- Close open sub-agent PRs only after diff-level supersession
  verification. Do not close based on title similarity or topic
  overlap. For each open sub-agent PR (`gh pr list --author @me`):
  1. List unmerged commits (`git log --oneline main..<branch>`).
  2. For each unmerged commit, inspect the diff and confirm the
     classes, functions, and files introduced exist in main.
  3. If any introduced symbol or file does not exist in main, the
     PR is not superseded — leave it open.
  4. Only after all changes are confirmed present in main, close
     the PR with a comment citing the merge commit or batch PR
     that landed the work.

### 2. Checkout main and fast-forward

Switch to `main` and pull:

```sh
git checkout main
git pull --ff-only
```

If fast-forward fails, warn and abort — main has diverged and
needs manual resolution.

Re-run the dirty-state guard (step 0 logic) after checkout. Lock
file drift from switching branches is common — restore lock files,
abort on other dirty files.

### 3. Progress file cleanup

Find and delete `.symphonize-progress.local.md` files across all
governance roots (glob `**/.symphonize-progress.local.md`). The loop
is over — progress state is no longer needed.

### 4. Governance docs

Read SPEC.md, ROADMAP.md, CHANGELOG.md at the governance root, and
recent commit history (`git log --oneline -20`). Check:

- **ROADMAP.md**: no completed workstreams remain. Every bullet
  traces to a SPEC.md gap that is still open. Delete anything
  that shipped.
- **SPEC.md**: status lines match reality. Sections whose last
  workstream just merged should move to `complete` or
  `in progress`. Apply spec compression per
  `${CLAUDE_PLUGIN_ROOT}/CONVENTIONS.md` § Spec compression for
  any newly completed sections.
- **CHANGELOG.md**: `[Unreleased]` section reflects what merged
  since the last release. If release-please manages this, verify
  it will pick up the new commits.
- Run `/symphonize:lint` and fix any violations before committing.

Commit governance doc changes to a `docs/post-merge-cleanup` branch
and open a PR (or push directly to main if the project allows).

### 5. Verify

Run verification against main — not a branch.

- Run the project's analysis tool — zero warnings.
- Run the project's test suite — zero failures.
- `git log --oneline -5` — confirm HEAD is clean main.
