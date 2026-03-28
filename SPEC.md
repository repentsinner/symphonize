# symphonize — Specification

## Plugin commands §spec:plugin-commands
*Status: in progress*

Symphonize provides Claude Code plugin commands that operate on
the governance file loop (REQUIREMENTS.md → SPEC.md → ROADMAP.md
→ CHANGELOG.md) and produce conventional commits suitable for
release-please.

The command pipeline:

1. `/symphonize:discover` — interviews the user, produces
   REQUIREMENTS.md
2. `/symphonize:plan` — translates requirements into SPEC.md
   sections and ROADMAP.md workstreams
3. `/symphonize:next` — executes workstreams
4. `/symphonize:orchestrate` — unattended multi-batch execution
5. `/symphonize:clean` — post-merge cleanup
6. `/symphonize:lint` — governance file validation
7. `/symphonize:init` — project scaffolding

## Governance lint command §spec:governance-lint
*Status: complete*

The plugin provides a `/symphonize:lint` command that runs
`npx markdownlint-cli2` against SPEC.md, ROADMAP.md, and
README.md. It uses the project's `.markdownlint.json` if present.

The command delegates entirely to the mechanical linter — it does
not interpret or reimplement lint rules. Status-line validation
and README heading checks run in CI via `governance-lint.yml`,
not in the plugin command.

**Why a plugin command:** agents can catch markdownlint violations
before pushing, avoiding a CI round-trip for formatting errors.

## Project scaffolding command §spec:project-scaffolding
*Status: complete*

The plugin provides a `/symphonize:init` command that scaffolds
governance files and CI workflows into a target project.

The command creates:

- `SPEC.md` — skeleton with section 1 and status line
- `ROADMAP.md` — empty with format instructions as comments
- `CHANGELOG.md` — with `## [Unreleased]` section
- `.markdownlint.json` — default config
- `.github/workflows/governance-lint.yml` — caller workflow
  referencing `repentsinner/symphonize/.github/workflows/governance-lint.yml@v1`
- `.github/workflows/release-please.yml` — release-please action
  with config and manifest files
- `.github/workflows/auto-merge-release.yml` — auto-merge for
  release PRs
- `.githooks/pre-commit` — runs markdownlint on staged governance
  files

The command activates hooks for the current checkout via
`git config core.hooksPath .githooks`. Hook scripts are tracked;
activation is per-checkout. Consumers opt in by running
`/symphonize:init` — upstream repos do not push hooks on
contributors. CI is the backstop.

The command is idempotent: it skips files that already exist and
warns rather than overwrites.

**Why scaffolding:** new projects need boilerplate to participate
in the governance loop. Scaffolding reduces setup from "read the
docs and copy-paste" to one command.

## Reusable CI workflows §spec:reusable-ci
*Status: complete*

Symphonize ships reusable GitHub Actions workflows under
`.github/workflows/` that target projects reference via
`workflow_call`.

### governance-lint.yml

Reusable workflow accepting a `readme-type` input (string:
`library`, `application`, or empty). Runs markdownlint,
SPEC.md status-line validation, and optional README heading
checks. Errors surface as GitHub annotations.

### release-please.yml

Template workflow for release-please-action@v4. Target projects
copy this (via `/symphonize:init`) rather than calling it as a
reusable workflow, because each project needs its own manifest
and config.

### auto-merge-release.yml

Template workflow that auto-merges release PRs from
github-actions[bot] with the `autorelease: pending` label.

### update-major-tag.yml

Template workflow that moves a floating major version tag
(e.g., `v1`) on each release.

## Dogfooding §spec:dogfooding
*Status: complete*

Symphonize's own CI calls its own `governance-lint.yml` reusable
workflow. The repo's `.github/workflows/ci.yml` uses
`./.github/workflows/governance-lint.yml` with
`readme-type: library`.

## Self-contained conventions §spec:self-contained-conventions
*Status: complete*

The plugin ships `CONVENTIONS.md` defining governance file formats,
commit conventions, and quality gate rules. Commands reference this
file instead of deferring to the user's CLAUDE.md.

**Why self-contained:** conventions are part of the plugin's
contract, not the user's personal configuration. Any user who
installs symphonize and runs `/symphonize:init` gets a working
governance loop without needing symphonize-specific content in
their CLAUDE.md.

## Requirements discovery command §spec:requirements-discovery
*Status: complete*

REQUIREMENTS.md is the fourth governance file — a problem-space
document in the user's language. `/symphonize:discover` populates
it through a structured interview.

| Document | Voice | Question |
|----------|-------|----------|
| REQUIREMENTS.md | User's | What do we need? |
| SPEC.md | System's | What does the system do? |
| ROADMAP.md | Work queue | What remains to build? |
| CHANGELOG.md | History | What shipped? |

`/symphonize:plan` reads REQUIREMENTS.md (if present) as input
when drafting SPEC.md sections. Falls back to direct user
clarification when absent. `/symphonize:init` scaffolds an empty
REQUIREMENTS.md skeleton.

**Why a separate document:** requirements live in the user's
problem space. Specs live in the system's solution space. Mixing
them produces documents that serve neither audience well. The
translation from requirements to spec is where design decisions
happen — that boundary should be explicit.

## Prose linting §spec:prose-linting
*Status: in progress*

The governance-lint workflow validates structure (markdownlint) and
cross-references (slug resolution), but not prose quality. SPEC.md
and REQUIREMENTS.md use IEEE modal verbs — "shall" for mandatory
requirements, "should" for recommendations, "may" for permission.
`Must` and `will` are deprecated per IEEE SA Standards Style Manual.

Vale (<https://vale.sh>) enforces prose rules via custom YAML
styles. A `Requirements` style checks modal verb compliance, flags
passive voice in requirements, and catches ambiguous language. Vale
complements markdownlint — structure vs. prose.

The governance-lint workflow runs Vale against SPEC.md and
REQUIREMENTS.md when a `.vale.ini` config exists. Projects opt in
by adding `.vale.ini` and a `styles/` directory via
`/symphonize:init`.

**Why prose linting:** agents generate requirements and spec text
that drifts toward vague, passive, non-testable language.
Mechanical enforcement catches `the system will...` (deprecated)
and `it should be noted that...` (filler) before review.

## Requirements frameworks §spec:requirements-frameworks
*Status: complete*

`/symphonize:discover` uses established frameworks as interview
prompts to broaden the user's thinking. Frameworks guide
conversation — they do not impose structured output. Answers
flow into REQUIREMENTS.md as prose.

- **Discovery (Phase 1):** YC Problem Types (Popular, Frequent,
  Expensive, Mandatory, Growing, Urgent, Distant) prompt the user
  to articulate *why* the problem matters.
- **Validation (Phase 2):** ICE framework (Impact, Confidence,
  Ease) surfaces priority tradeoffs beyond binary must/nice-to-have.

**Why frameworks as prompts:** users describe *what* they want
without explaining *why*. Framework-derived questions produce
richer problem statements and priority rationale without imposing
structured output forms. CONVENTIONS.md documents both taxonomies
as interviewer references.

## Product-type-agnostic discovery §spec:product-type-agnostic-discovery
*Status: complete*

The discover command uses product-neutral language throughout. Phase 1
opens with a product-type classifier (application, library/SDK,
platform/service, CLI tool, hardware device, other) that gates which
subsequent prompts are relevant.

**Why:** symphonize targets any software product, not just consumer
apps. Narrow language biases the interview toward GUI applications
and produces requirements that miss concerns specific to other
product types (API ergonomics, operator workflows, physical
constraints).

## Governance consistency §spec:governance-consistency
*Status: in progress*

Governance files, commands, and scaffolding templates are
internally consistent. Specifically:

- init.md scaffolding templates match CONVENTIONS.md format
  rules (slug-style headings, status lines, `§prefix:slug`
  suffixes)
- CONVENTIONS.md documents the standard REQUIREMENTS.md
  sections (not just the discover command)
- The lint command documents which checks it runs vs. which
  checks CI runs (lint is a subset of governance-lint.yml)
- The governance files table is consistent across README.md,
  SPEC.md, and CONVENTIONS.md (four files, same descriptions)
- markdownlint globs include REQUIREMENTS.md and CHANGELOG.md

**Why:** inconsistencies between documents erode trust. An agent
that reads init.md and CONVENTIONS.md should not get conflicting
instructions.
