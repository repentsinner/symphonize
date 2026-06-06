# symphonize — Roadmap

## Orchestration loop via /goal

### §road:migrate-orchestrate-to-goal

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

## Scaffolding freshness

### §road:scaffold-consumer-dependabot

Add a `.github/dependabot.yml` (`github-actions`) to the files
`/notation:init` scaffolds, and document the scaffold-current-state /
delegate-freshness contract in `plugins/notation/commands/init.md`.
§spec:scaffold-freshness

**Verify:** a repo scaffolded by `/notation:init` contains a
`.github/dependabot.yml` enabling weekly `github-actions` updates;
`plugins/notation/commands/init.md` and §spec:scaffold-freshness agree on
the contract; governance-lint passes. The dependabot scaffolding lives with
the `init` scaffolder, now in `plugins/notation/commands/init.md`.

## Heading addressing grammar

### §road:ordinal-prose-vale

Add an ordinal-prose heading warning to the Vale `Requirements` style
(`styles/Requirements/`). §spec:heading-addressing

### §road:notation-scaffold-grammar

Update the `/notation:init` skeletons to emit `##`-mandatory, suffix-placed
slugs in all three governance files (`plugins/notation/commands/init.md`).
§spec:heading-addressing

### §road:authoring-grammar-sync

Revise the compose authoring formats and the notation lint scope text to the
suffix-placement, optional-deeper-slug grammar
(`plugins/compose/commands/plan.md`, `plugins/compose/commands/roadmap.md`,
`plugins/notation/commands/lint.md`). §spec:heading-addressing

### §road:heading-addressing-lint

Extend `governance-lint.yml` to enforce the addressing grammar and migrate
`ROADMAP.md` to conform (`.github/workflows/governance-lint.yml`, `ROADMAP.md`).
§spec:heading-addressing. Depends on §road:notation-scaffold-grammar and
§road:authoring-grammar-sync — the scaffolder and authoring docs describe the
grammar before CI enforces it, per §spec:governance-consistency.

**Verify:** on a scratch branch, push governance-doc edits and confirm
governance-lint (CI) behaves as specified: a `## Foo` ROADMAP section with no
`§road:` slug fails; two headings defining the same `§spec:` slug fail the
uniqueness check; a heading `## 9. Numbered thing` fails; a `§9.9` reference
outside a code span fails while the same text inside backticks passes; a
`### Stage 1 — x` heading draws a Vale warning, not a failure; and
symphonize's own `SPEC.md`, `ROADMAP.md`, and `REQUIREMENTS.md` pass clean.
Run `/notation:init` in an empty directory and confirm the scaffolded
`ROADMAP.md` uses `## Title §road:slug` suffix placement.
