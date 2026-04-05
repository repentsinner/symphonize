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
