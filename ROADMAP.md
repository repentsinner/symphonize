# symphonize — Roadmap

## Consume the kernel's enforcement workflow

Blocked — depends on the kernel publishing the full-schema
`governance-lint.yml` at a referenceable major tag. Unblocked when the
kernel ships it.

### §road:consume-kernel-lint

Point `.github/workflows/ci.yml` at the kernel's `governance-lint.yml`,
retiring the embedded reusable workflow once CI is green.
§spec:conventions-kernel

**Verify:** `ci.yml` calls the kernel's `governance-lint.yml@<major>`; CI
passes on this repo's governance files; symphonize no longer hosts its own
`governance-lint.yml` as the source of truth.

## Relocate CONVENTIONS.md content into commands

Not blocked — symphonize-internal, can proceed before the kernel ships.
Prepares `CONVENTIONS.md` for deletion (§road:remove-kernel-originals);
the structural grammar needs no replacement file (the kernel's linter
enforces it), so only the methodology and process content must move.

### §road:relocate-conventions-content

Move `CONVENTIONS.md`'s authoring methodology inline into the curation
commands and its process discipline into the dispatch commands and
`protocols/batch-agent.md`, repointing each command that reads
`CONVENTIONS.md`. §spec:conventions-kernel

**Verify:** `discover`/`plan`/`roadmap` carry their methodology inline;
`next`/`orchestrate`/`clean` and `batch-agent.md` carry the process
discipline; no command depends on a `CONVENTIONS.md` section slated for
deletion; governance-lint passes.

## Adopt the kernel's scaffolder

Blocked — depends on the kernel publishing the scaffolder plugin.
Unblocked when the kernel's scaffolder is installable as a plugin.

### §road:adopt-kernel-scaffolder

Make `/symphonize:init` defer to the kernel's scaffolder and declare a
plugin dependency on the kernel in symphonize's plugin manifest.
§spec:conventions-kernel

**Verify:** symphonize's `.claude-plugin` manifest declares a dependency
on the kernel plugin; `/symphonize:init` no longer carries its own
governance-file and CONVENTIONS scaffolding logic; a scaffolded test repo
references a coherent kernel.

## Remove symphonize's superseded kernel originals

Blocked — depends on §road:consume-kernel-lint,
§road:adopt-kernel-scaffolder, and §road:relocate-conventions-content.
Unblocked when consumption is verified end-to-end and `CONVENTIONS.md`'s
content has moved; removing originals first would orphan adopters or
strand command references.

### §road:remove-kernel-originals

Delete symphonize's embedded `governance-lint.yml`, its `CONVENTIONS.md`,
and the duplicated `/init` scaffolding now served by the kernel.
§spec:conventions-kernel

**Verify:** no embedded `governance-lint.yml` remains; `CONVENTIONS.md` is
deleted with no replacement file; `/symphonize:init` delegates to the
kernel scaffolder; CI is green via the kernel workflow; `grep` finds no
command referencing the removed `CONVENTIONS.md`.
