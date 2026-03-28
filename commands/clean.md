---
argument-hint: [--lite | --full]
description: Cleans up after executing batch workstreams
---

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

### 1. Git housekeeping

- Fetch origin.
- Delete local branches whose upstream is gone (`git fetch --prune`,
  then delete local branches tracking pruned remotes).
- Delete remote branches for merged PRs that weren't auto-deleted
  (`gh pr list --state merged --author @me`, then
  `git push origin --delete <branch>` for each).
- Delete any remaining `.claude/worktrees/` worktree directories
  and their backing git worktrees (`git worktree list`, `git worktree
  remove`).
- Close any open PRs from sub-agent branches that were superseded
  by the batch PR (check with `gh pr list --author @me`).
- Leave the working tree on `main` at the tip of `origin/main`.
- Verify `git status` is clean. If not, warn — do not discard
  uncommitted work.

### 2. Progress file cleanup

If `.claude/.ralph-progress.local.md` exists, delete it. The loop
is over — progress state is no longer needed.

### 3. Governance docs

Read SPEC.md, ROADMAP.md, CHANGELOG.md, and recent commit history
(`git log --oneline -20`). Check:

- **ROADMAP.md**: no completed workstreams remain. Every bullet
  traces to a SPEC.md gap that is still open. Delete anything
  that shipped.
- **SPEC.md**: status lines match reality. Sections whose last
  workstream just merged should move to `complete` or
  `in progress`. Apply spec compression per CONVENTIONS.md §
  Spec compression for any newly completed sections.
- **CHANGELOG.md**: `[Unreleased]` section reflects what merged
  since the last release. If release-please manages this, verify
  it will pick up the new commits.
- Run `/symphonize:lint` and fix any violations before committing.

Commit governance doc changes to a `docs/post-merge-cleanup` branch
and open a PR (or push directly to main if the project allows).

### 4. Verify

- Run the project's analysis tool — zero warnings.
- Run the project's test suite — zero failures.
- `git log --oneline -5` — confirm HEAD is clean main.

$1
