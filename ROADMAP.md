# symphonize — Roadmap

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
