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

## Integration-ref resolution §road:integration-ref-resolution

### Resolve the integration trunk across conduct and compose §road:resolve-trunk

Replace hardcoded `main` with a trunk resolved from the repository default
branch across `plugins/conduct/commands/{next,review,clean}.md`,
`plugins/conduct/protocols/batch-agent.md`, and
`plugins/compose/commands/{triage,roadmap}.md`, and update the `main`-relative
wording in §spec:clean-supersession-safety and §spec:repo-state-reconciliation.
§spec:integration-ref. Reported in #167.

### Base worktree sub-agents on the batch integration HEAD §road:worktree-base-ref

Make the dispatch and batch-agent protocol pass the batch branch commit to each
worktree sub-agent and base its work there rather than the default branch
(`plugins/conduct/commands/next.md`, `plugins/conduct/protocols/batch-agent.md`).
§spec:integration-ref. Depends on §road:resolve-trunk. Reported in #167.

**Verify:** in a scratch repo whose default branch is `develop`, run
`/conduct:next` on a populated ROADMAP and confirm the batch branch is cut from
`develop` and the PR targets `develop` (no reference to a non-existent `main`).
In a batch of two serial workstreams touching the same file, confirm the second
sub-agent's worktree already contains the first workstream's integrated commit
(its work builds on it without a cherry-pick conflict) and CI passes after each
integration. `grep -rn 'origin/main' plugins/` returns no hardcoded trunk in
active command and protocol paths.
