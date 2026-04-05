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

### §road:governance-root-convention

Add governance root resolution algorithm to CONVENTIONS.md: walk
up from CWD to find nearest SPEC.md, fallback to repo root.
Generalize "lives at repo root" rules to "lives at the governance
root." §spec:directory-scoped-governance

### §road:directory-scoped-init

Update `commands/init.md` to scaffold governance files at the
governance root (CWD) instead of always at repo root. When run
from a subdirectory, create package-level governance files there.
Depends on §road:governance-root-convention.
§spec:directory-scoped-governance

### §road:directory-scoped-lint

Update `commands/lint.md` and `.github/workflows/governance-lint.yml`
to glob for `**/SPEC.md`, `**/ROADMAP.md`, etc. instead of
hardcoded root paths. Depends on §road:governance-root-convention.
§spec:directory-scoped-governance

### §road:directory-scoped-pipeline

Update `commands/discover.md`, `commands/plan.md`, and
`commands/roadmap.md` to resolve governance root before reading or
writing governance files. Read root governance as upstream context
when operating on a package. Depends on
§road:governance-root-convention. §spec:directory-scoped-governance

### §road:directory-scoped-execution

Update `commands/next.md`, `commands/orchestrate.md`,
`commands/clean.md`, and `protocols/batch-agent.md` to resolve
governance root for target roadmap and scope progress file to
governance root. Depends on §road:governance-root-convention.
§spec:directory-scoped-governance

**Verify:** Run `/symphonize:init` from a `packages/auth/`
subdirectory. Confirm SPEC.md, ROADMAP.md, CHANGELOG.md are
created in `packages/auth/`, not at repo root. Run
`/symphonize:lint` from repo root. Confirm it validates governance
files in both root and `packages/auth/`. Run `/symphonize:plan`
from `packages/auth/`. Confirm it reads root SPEC.md as upstream
context and writes to `packages/auth/SPEC.md`.
