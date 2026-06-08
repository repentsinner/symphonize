# symphonize — Roadmap

## Orchestration loop via /goal §road:orchestration-loop

### Migrate orchestrate to /goal §road:migrate-orchestrate-to-goal

Replace `/ralph-loop:ralph-loop` with `/goal` in
`plugins/conduct/commands/orchestrate.md`, and retire residual ralph-loop
coupling in `plugins/conduct/commands/clean.md` (flag-file mode
auto-detect), `plugins/conduct/protocols/batch-agent.md`, `README.md`,
`§spec:unattended-flag-passthrough`, and the known-issue note in
`§spec:progress-file-location`. §spec:orchestration-loop

**Verify:** From a project with a populated ROADMAP section, run
`/conduct:orchestrate`. Confirm: (1) it first invokes
`/conduct:clean --lite`; (2) it sets an active `/goal`, visible
via `/goal` with no arguments, whose condition targets section
completion; (3) `/conduct:next --unattended` runs and produces
at least one PR; (4) the goal clears automatically once the
section reports all unblocked workstreams attempted. In a second
session in the same project, run `/compose:plan` and confirm
no stop-hook directives fire from ralph-loop. Finally,
`grep -r 'ralph' plugins/conduct/ README.md SPEC.md` shall
return no matches in active code paths (CHANGELOG.md may retain
historical references).

## Scaffolding freshness §road:scaffolding-freshness

### Scaffold consumer dependabot §road:scaffold-consumer-dependabot

Add a `.github/dependabot.yml` (`github-actions`) to the files
`/notation:init` scaffolds, and document the scaffold-current-state /
delegate-freshness contract in `plugins/notation/commands/init.md`.
§spec:scaffold-freshness

**Verify:** a repo scaffolded by `/notation:init` contains a
`.github/dependabot.yml` enabling weekly `github-actions` updates;
`plugins/notation/commands/init.md` and §spec:scaffold-freshness agree on
the contract; governance-lint passes. The dependabot scaffolding lives with
the `init` scaffolder, now in `plugins/notation/commands/init.md`.

## Batch delivery robustness §road:batch-delivery-robustness

### Harden Phase 6 delivery and add dispatch recovery §road:harden-batch-delivery

Harden batch delivery in `plugins/conduct/protocols/batch-agent.md` and
`plugins/conduct/commands/next.md`: keep the quality gates from ending the
agent's turn before Phase 6, make Phase 6 a hard completion gate (no return
without a pushed conventional branch, an opened PR, and the shipped workstream
removed from ROADMAP.md), and add a dispatch-layer recovery path that adopts the
worktree and finishes delivery when an agent returns without a PR; document that
`SendMessage` resume is not assumable. §spec:batch-delivery. Reported in #132.

**Verify:** `plugins/conduct/protocols/batch-agent.md` states Phase 6 as a hard
gate (no return without a PR URL) and notes `SendMessage` resume is not
assumable; `plugins/conduct/commands/next.md` has a "Recovery — incomplete
delivery" path that adopts the worktree, removes the shipped ROADMAP workstream,
re-runs CI, pushes to a `<type>/<scope>-<slug>` branch, and opens the PR.
Exercise it: dispatch a batch; if the agent returns a PR URL, delivery worked
end-to-end; if it returns without one, confirm `/conduct:next` detects the
missing URL and delivers from the worktree (conventional branch, ROADMAP bullet
gone, PR open, CI green) — the manual workaround used for #165 and #171 becomes
the documented path.
