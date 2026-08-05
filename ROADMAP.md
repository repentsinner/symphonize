# symphonize — Roadmap

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

## Release-aware clean checks §road:release-aware-clean

### Per-tool release check in /conduct:clean §road:clean-release-check

Detect the release tool from `.flywheel.yml` / `release-please-config.json`
/ neither and run the matching advisory check (flywheel eligibility, next
release-please PR, or manual CHANGELOG/tag reminder) in
`plugins/conduct/commands/clean.md`, mirroring the re-run detection signals
`/notation:init` already reads. §spec:release-automation-options

**Verify:** Run `/conduct:clean` in a flywheel-scaffolded repo with
unreleased commits — confirm it reports the commits are eligible for a
managed-branch release. In a release-please repo — confirm it reports the
next release PR picks up the commits. In a manual repo — confirm it checks
CHANGELOG.md `[Unreleased]` and reminds to tag. The check reads repo state
and does not invoke the release tool. Governance-lint passes.

