# symphonize — Roadmap

## Orchestration loop via /goal

### §road:migrate-orchestrate-to-goal

Replace `/ralph-loop:ralph-loop` with `/goal` in
`plugins/symphonize/commands/orchestrate.md`, and retire residual ralph-loop
coupling in `plugins/symphonize/commands/clean.md` (flag-file mode
auto-detect), `plugins/symphonize/protocols/batch-agent.md`, `README.md`,
`§spec:unattended-flag-passthrough`, and the known-issue note in
`§spec:progress-file-location`. §spec:orchestration-loop

**Verify:** From a project with a populated ROADMAP section, run
`/symphonize:orchestrate`. Confirm: (1) it first invokes
`/symphonize:clean --lite`; (2) it sets an active `/goal`, visible
via `/goal` with no arguments, whose condition targets section
completion; (3) `/symphonize:next --unattended` runs and produces
at least one PR; (4) the goal clears automatically once the
section reports all unblocked workstreams attempted. In a second
session in the same project, run `/symphonize:plan` and confirm
no stop-hook directives fire from ralph-loop. Finally,
`grep -r 'ralph' plugins/symphonize/ README.md SPEC.md` shall
return no matches in active code paths (CHANGELOG.md may retain
historical references).

## Scaffolding freshness

### §road:scaffold-consumer-dependabot

Add a `.github/dependabot.yml` (`github-actions`) to the files
`/symphonize:init` scaffolds, and document the scaffold-current-state /
delegate-freshness contract in `plugins/symphonize/commands/init.md`.
§spec:scaffold-freshness

**Verify:** a repo scaffolded by `/symphonize:init` contains a
`.github/dependabot.yml` enabling weekly `github-actions` updates;
`plugins/symphonize/commands/init.md` and §spec:scaffold-freshness agree on
the contract; governance-lint passes. The dependabot scaffolding lives with
the `init` scaffolder — `plugins/symphonize/commands/init.md` today, the
notation plugin once the
decomposition (§spec:governance-schema) builds it out.

## Coordinated release

One shared version line across the four plugins, tagged together. All four
plugins now exist.

### §road:coordinate-plugin-release

Reconfigure `release-please-config.json` and `.release-please-manifest.json`
for the four `plugins/<name>/plugin.json` packages on one shared version,
emit a `{plugin}--v{version}` git tag per plugin, pin compose's and
conduct's notation `dependencies` range and symphonize's compose/conduct
range to that version, and keep `update-major-tag.yml` moving notation's
floating major for adopters' `governance-lint.yml@<major>` pin.
§spec:plugin-packaging

**Verify:** a release PR bumps all four `plugin.json` versions together;
merging it publishes `notation--vX.Y.Z`, `compose--vX.Y.Z`,
`conduct--vX.Y.Z`, and `symphonize--vX.Y.Z`; compose and conduct
`dependencies` resolve notation, and symphonize resolves compose and
conduct, at the shared version; a fresh scaffold's
`governance-lint.yml@<major>` ref points at the released workflow.

## Fragment assembly coverage

The fragment-assembly mechanism (`tools/assemble-fragments.sh` plus the CI
drift-check, §spec:plugin-packaging) single-sources the governance-root
algorithm, but only for the four command files that carried it as a verbatim
numbered block. Three other command files restate the same
algorithm as command-specific prose and stay hand-maintained — free to drift
from the canonical fragment without the CI drift-check noticing. This section
closes that gap, completing the no-drift intent. It reverses the coverage
narrowing §spec:plugin-packaging recorded when the mechanism landed, so the work
includes reconciling that spec text to describe full coverage.

### §road:normalize-governance-root-restatements

Bring the prose-form governance-root restatements under the canonical
fragment — register `plugins/notation/commands/lint.md` and
`plugins/conduct/commands/clean.md` as `governance-root` consumers (marked,
assembled block), trim `plugins/conduct/commands/orchestrate.md` to defer
resolution to `/conduct:next` rather than restating the walk-up, leave
`plugins/notation/commands/init.md`'s deliberately different CWD-based
algorithm untouched — and reconcile §spec:plugin-packaging's coverage
description. §spec:plugin-packaging

**Verify:** `tools/assemble-fragments.sh`'s consumer registry includes
lint.md and clean.md and the CI fragment-drift job covers them; editing
`fragments/governance-root.md` then rebuilding updates lint.md and clean.md
identically; `orchestrate.md` references `/conduct:next` for governance-root
resolution instead of restating the algorithm; a grep across
`plugins/*/commands/` finds no unmanaged verbatim restatement of the walk-up
algorithm (init.md's distinct CWD-based text excepted); governance-lint and
the fragment-drift job pass.
