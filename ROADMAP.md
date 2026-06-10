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

## Prose-linting scope alignment §road:prose-linting-scope

### Align modal-verb guidance with document-wide Vale rule §road:modal-verb-scope

The writing guidance in `plugins/compose/commands/plan.md` and
`plugins/compose/commands/discover.md` scopes `shall` to *criteria*
only, while the `/notation:init`-scaffolded Vale rule
(`styles/Requirements/MustDeprecated.yml`) flags `must` document-wide
at error level. `/discover` and `/plan` write idiomatic narrative
`must`, which is green locally (the governance-lint script skips
Vale) but fails CI. Broaden the modal-verb guidance in both commands
to steer *all* SPEC.md / REQUIREMENTS.md prose — narrative included —
away from `must`/`will`, and reconcile the README claim
(README.md:126) with the document-wide scope. Reported in #131.
§spec:prose-linting

**Verify:** In a project scaffolded by `/notation:init`, run
`/compose:discover` and `/compose:plan` to produce REQUIREMENTS.md /
SPEC.md containing narrative that would idiomatically use `must`.
Confirm the generated prose uses `shall`/`should` (or rephrases) and
that `vale SPEC.md REQUIREMENTS.md` reports zero
`Requirements.MustDeprecated` errors. Confirm `plan.md`,
`discover.md`, and §spec:prose-linting agree that modal discipline
is document-wide. Governance-lint passes.

## Batch delivery branch-type inference §road:batch-branch-type

### Infer delivered branch and PR title type from batch commits §road:batch-delivery-type-inference

`plugins/conduct/protocols/batch-agent.md` Phase 6 hardcodes the
delivery type to `feat` — the branch example is `feat/<slug>` (step 1)
and the PR title is `feat: batch — <summary>` (step 2) — even when the
batch contains only `fix` commits. Under conventional-commit
semantics the umbrella type should match the batch's highest-severity
commit type, so release-please versions the squashed merge correctly
(a fix-only batch cuts a patch, not a minor). Derive `<type>` for both
the delivered branch name and the PR title from the batch's actual
commit types. Surfaced while triaging #128, whose primary defect — the
`worktree-agent-<id>` branch leak — is already fixed by
§spec:batch-delivery (PR #174). §spec:batch-delivery

**Verify:** Run a batch whose workstreams produce only `fix` commits;
confirm the delivered branch is `fix/<scope>-<slug>` and the PR title
is `fix: batch — <summary>`. Run a batch containing at least one
`feat`; confirm the umbrella type is `feat`. `batch-agent.md` Phase 6
and §spec:batch-delivery agree the delivered type is derived, not
hardcoded. Governance-lint passes.

