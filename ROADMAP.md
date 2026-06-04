# symphonize — Roadmap

## Orchestration loop via /goal

### §road:migrate-orchestrate-to-goal

Replace `/ralph-loop:ralph-loop` with `/goal` in
`commands/orchestrate.md`, and retire residual ralph-loop coupling
in `commands/clean.md` (flag-file mode auto-detect),
`protocols/batch-agent.md`, `README.md`,
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
`grep -r 'ralph' commands/ protocols/ README.md SPEC.md` shall
return no matches in active code paths (CHANGELOG.md may retain
historical references).

## Consume the schema's enforcement workflow

Blocked — depends on the schema's `governance-lint.yml` reaching a
referenceable major tag. Unblocked when it ships.

### §road:consume-schema-lint

Point `.github/workflows/ci.yml` at the schema's `governance-lint.yml`,
retiring the embedded reusable workflow once CI is green.
§spec:governance-schema

**Verify:** `ci.yml` calls the schema's `governance-lint.yml@<major>`; CI
passes on this repo's governance files; symphonize no longer hosts its own
`governance-lint.yml` as the source of truth.

## Relocate CONVENTIONS.md content into commands

Not blocked — symphonize-internal, can proceed before the schema ships.
Prepares `CONVENTIONS.md` for deletion (§road:remove-schema-originals);
the structural grammar needs no replacement file (the schema's linter
enforces it), so only the methodology and process content must move.

### §road:relocate-conventions-content

Move `CONVENTIONS.md`'s authoring methodology inline into the curation
commands and its process discipline into the dispatch commands and
`protocols/batch-agent.md`, repointing each command that reads
`CONVENTIONS.md`. §spec:governance-schema

**Verify:** `discover`/`plan`/`roadmap` carry their methodology inline;
`next`/`orchestrate`/`clean` and `batch-agent.md` carry the process
discipline; no command depends on a `CONVENTIONS.md` section slated for
deletion; governance-lint passes.

## Adopt the schema's scaffolder

Blocked — depends on the schema's scaffolder being installable as a
plugin. Unblocked when it ships.

### §road:adopt-schema-scaffolder

Make `/symphonize:init` defer to the schema's scaffolder and declare a
plugin dependency on the schema in symphonize's plugin manifest.
§spec:governance-schema

**Verify:** symphonize's `.claude-plugin` manifest declares a dependency
on the schema's plugin; `/symphonize:init` no longer carries its own
governance-file and CONVENTIONS scaffolding logic; a scaffolded test repo
references a coherent schema.

## Remove symphonize's superseded originals

Blocked — depends on §road:consume-schema-lint,
§road:adopt-schema-scaffolder, and §road:relocate-conventions-content.
Unblocked when consumption is verified end-to-end and `CONVENTIONS.md`'s
content has moved; removing originals first would orphan adopters or
strand command references.

### §road:remove-schema-originals

Delete symphonize's embedded `governance-lint.yml`, its `CONVENTIONS.md`,
and the duplicated `/init` scaffolding now served by the schema.
§spec:governance-schema

**Verify:** no embedded `governance-lint.yml` remains; `CONVENTIONS.md` is
deleted with no replacement file; `/symphonize:init` delegates to the
schema's scaffolder; CI is green via the schema's workflow; `grep` finds
no command referencing the removed `CONVENTIONS.md`.

## Scaffolding freshness

### §road:scaffold-consumer-dependabot

Add a `.github/dependabot.yml` (`github-actions`) to the files
`/symphonize:init` scaffolds, and document the scaffold-current-state /
delegate-freshness contract in `commands/init.md`. §spec:scaffold-freshness

**Verify:** a repo scaffolded by `/symphonize:init` contains a
`.github/dependabot.yml` enabling weekly `github-actions` updates;
`commands/init.md` and §spec:scaffold-freshness agree on the contract;
governance-lint passes. If §road:adopt-schema-scaffolder has landed first,
the dependabot scaffolding lives in the schema's scaffolder, not
`commands/init.md`.
