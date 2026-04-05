# symphonize — Roadmap

## Clean working tree hygiene

### §road:clean-phase-reorder

Rewrite `commands/clean.md` full-mode phases: dirty-state check
at entry (warn and abort if dirty, restore lock files), checkout
main and fast-forward before governance doc updates, verify after
commit. Ban `git stash`. §spec:clean-working-tree-hygiene

**Verify:** Run `/symphonize:clean --full` with a dirty
pubspec.lock. Confirm lock file is restored and clean proceeds.
Run with a dirty source file. Confirm clean warns and aborts.
Confirm verification runs on main, not a branch.

## Directory-scoped governance

### §road:directory-scoped-pipeline

Update `commands/discover.md`, `commands/plan.md`, and
`commands/roadmap.md` to resolve governance root before reading or
writing governance files. Read root governance as upstream context
when operating on a package. §spec:directory-scoped-governance

**Verify:** Run `/symphonize:init` from a `packages/auth/`
subdirectory. Confirm SPEC.md, ROADMAP.md, CHANGELOG.md are
created in `packages/auth/`, not at repo root. Run
`/symphonize:lint` from repo root. Confirm it validates governance
files in both root and `packages/auth/`. Run `/symphonize:plan`
from `packages/auth/`. Confirm it reads root SPEC.md as upstream
context and writes to `packages/auth/SPEC.md`.
