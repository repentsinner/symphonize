# symphonize — Roadmap

## Consume the kernel's enforcement workflow

Blocked — depends on the kernel publishing the opt-in governance checks
(`traceability`, `vale`, `extended-globs`) at a referenceable major tag.
Unblocked when the kernel ships those inputs.

### §road:consume-kernel-lint

Point `.github/workflows/ci.yml` at the kernel's `governance-lint.yml`
with the governance checks enabled, retiring the embedded reusable
workflow once CI is green. §spec:conventions-kernel

**Verify:** `ci.yml` calls the kernel's `governance-lint.yml@<major>`
with `traceability`, `vale`, and `extended-globs` enabled; CI passes on
this repo's governance files; symphonize no longer hosts its own
`governance-lint.yml` as the source of truth.

## Adopt the kernel's materialized conventions

Blocked — depends on the kernel publishing the canonical CONVENTIONS.md
and `contracts-version` marker. Unblocked when §road:consume-kernel-lint
lands, since the lint version anchors the contract version.

### §road:adopt-kernel-conventions

Replace symphonize's canonical `CONVENTIONS.md` with a materialized copy
from the kernel carrying a `contracts-version` marker matching the
referenced kernel version. §spec:conventions-kernel

**Verify:** `CONVENTIONS.md` carries a `contracts-version` marker; the
marker matches the kernel major referenced in `ci.yml`; governance-lint
passes.

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

Blocked — depends on the three adoption workstreams above. Unblocked when
consumption is verified end-to-end; removing originals first would orphan
adopters.

### §road:remove-kernel-originals

Delete symphonize's embedded `governance-lint.yml`, its canonical
`CONVENTIONS.md` ownership, and the duplicated `/init` scaffolding now
served by the kernel. §spec:conventions-kernel

**Verify:** no embedded `governance-lint.yml` remains; `CONVENTIONS.md`
is materialized from the kernel, not canonical; `/symphonize:init`
delegates; CI is green; `grep` finds no duplicated scaffolding templates.
