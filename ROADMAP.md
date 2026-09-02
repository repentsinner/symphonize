# symphonize — Roadmap

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


## Prose style modularization §road:prose-style-modularity

### Extract the shared prose contract into a canonical fragment §road:prose-style-fragment

The writing guidance that shapes generated governance prose is restated
across five files with no drift guard: the spec-compression thumb
heuristic appears in `plugins/compose/commands/plan.md`,
`plugins/conduct/commands/clean.md`, and
`plugins/conduct/protocols/batch-agent.md`, while mood and modal-verb
rules are split across `plan.md`, `roadmap.md`, and `discover.md`. Add
`fragments/prose-style.md` stating the contract once — declarative mood
for SPEC.md, imperative for ROADMAP.md, IEEE modals document-wide,
filler-phrase and compression rules with their sources — and register
each consumer in the `CONSUMERS` array of `tools/assemble-fragments.sh`.
Depends on §road:modal-verb-scope; the fragment is where its broadened
modal rule lands. §spec:prose-linting §spec:governance-consistency

### Ship the Vale styles as notation templates §road:vale-style-templates

`plugins/notation/commands/init.md` inlines all four
`styles/Requirements/*.yml` rule bodies as literal code blocks — the one
duplicated artifact `tools/assemble-fragments.sh` does not guard, so a
rule edited in `styles/` leaves the scaffolder handing adopters a stale
copy. Move the canonical files into `plugins/notation/templates/vale/`,
register them in the script's `COPIES` array alongside the
release-please workflows, and reduce init.md to a directory copy plus
the rationale for each rule. §spec:scaffold-freshness
§spec:plugin-packaging

**Verify:** Run `tools/assemble-fragments.sh` twice — the second run
produces no diff. Confirm the thumb heuristic and the modal-verb rule
appear only inside assembled regions and the fragment itself. Edit a
rule in `styles/Requirements/`, run the script without committing, and
confirm `git diff --exit-code` fails on the notation template. Scaffold
a fresh project with `/notation:init` and confirm `vale` runs against
the copied styles. Governance-lint passes.

## README freshness in the execution loop §road:readme-freshness

### Reconcile README.md when a batch changes governance §road:batch-readme-refresh

The batch agent updates ROADMAP.md and SPEC.md status lines as it
delivers (`plugins/conduct/protocols/batch-agent.md`, delivery phase)
and `plugins/conduct/commands/next.md` removes shipped workstreams, but
nothing revisits README.md — so its compression of the governance files
decays silently. Governance-lint catches only the loud half: a deleted
spec section leaves a dangling `§` reference and hard-fails, while a
section rewritten under the same slug leaves the README's summary of it
wrong and every check green. Add a README-reconciliation step to the
batch agent's delivery phase and to `next.md`: for each governance
section the batch touched, confirm the README's derived claims still
hold and correct them in the governance commit. §spec:readme-derivable

**Verify:** Run `/conduct:next` on a workstream that rewrites a SPEC
section the README summarizes without changing its slug. Confirm the
delivered PR updates README.md alongside SPEC.md and ROADMAP.md, and
that the README's claim matches the rewritten section. Run a batch
touching no README-derived claim and confirm it adds no README churn.
Governance-lint passes.

## Bundled governance-lint adoption §road:bundled-lint-adoption

The contract now has one executable form — `plugins/notation/scripts/`
— which CI and `/notation:lint` both run (§spec:governance-lint). Two
consumers of the old arrangement have yet to move to it.

### Run the bundled script from the pre-commit hook §road:hook-runs-bundled-script

The hook `/notation:init` scaffolds resolves a markdown linter itself
and runs it against a hardcoded file list, so it checks formatting where
the script checks the contract, and it holds a second copy of both the
file list and the engine-resolution order to drift from. Point it at the bundled script instead, keeping the hook's
degradation contract: skip silently when the script is unreachable, and
never block a commit on an absent optional tool. §spec:governance-lint

**Verify:** In a repo scaffolded by `/notation:init`, commit a SPEC.md
section with no `*Status:*` line and confirm the hook reports it — the
old hook could not. Uninstall the plugin, commit again, and confirm the
hook degrades quietly rather than failing. Governance-lint passes.

### CHANGELOG structure check §road:changelog-structure

§spec:governance-lint names CHANGELOG.md structure as part of the
contract, and the script does not implement it: no consumer checks that
`[Unreleased]` is present or that releases read as Keep a Changelog.
Add it to the script, gated on CHANGELOG.md existing, so a repo without
one stays clean. §spec:governance-lint

**Verify:** Run the script against a repo whose CHANGELOG.md has lost
its `[Unreleased]` section and confirm it reports the omission; against
symphonize's own, confirm it passes; against a repo with no
CHANGELOG.md, confirm the check skips rather than failing.
Governance-lint passes.

## Cross-repo contract verification §road:cross-repo-contract

### Exercise the reusable workflow from a second repository §road:cross-repo-smoke

Symphonize calls `governance-lint.yml` through a local `uses: ./…`, which
resolves `job.workflow_repository` and `job.workflow_sha` to this
repository and this commit. An adopter calls it cross-repo, where both
differ and a wrong value is fatal. No test covers that path, which is how
v0.2.7 shipped a workflow that could not run anywhere but here with CI
fully green. Add a job that calls the reusable workflow the way an
adopter does — a fixture repository, or a scheduled call from one — so
the divergence is exercised before a tag moves. §spec:governance-lint

**Verify:** Introduce a deliberately wrong contract ref and confirm the
cross-repo check fails while the local dogfooded call still passes —
that asymmetry is the whole point. Restore it and confirm both pass.
Governance-lint passes.

### Make a workflow-only fix reachable by adopters §road:workflow-release-trigger

`.github/workflows/governance-lint.yml` sits outside every release-please
package path, so a commit touching only it cuts no release and the
floating tag adopters pin never advances to include it. PR #208 was
stranded this way and reached adopters only because #209 happened to
touch `plugins/notation/` in the same release; the fix for #209's own
adopter break hit it again. Give the workflow a package-path presence —
sync it into `plugins/notation/` through the `COPIES` registry, or add a
release trigger that watches it — so a fix to the contract's CI half
reaches adopters on its own. §spec:governance-lint

**Verify:** Land a change touching only `.github/workflows/` and confirm
release-please opens a release PR for notation. Confirm the floating
`notation--v0` tag then resolves to a commit containing that change.
Governance-lint passes.
