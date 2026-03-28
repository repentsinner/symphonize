# symphonize — Specification

## 1. Plugin commands
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

## 2. Governance lint command
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

## 3. Project scaffolding command
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

## 4. Reusable CI workflows
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

## 5. Dogfooding
*Status: complete*

Symphonize's own CI calls its own `governance-lint.yml` reusable
workflow. The repo's `.github/workflows/ci.yml` uses
`./.github/workflows/governance-lint.yml` with
`readme-type: library`.

## 6. Self-contained conventions
*Status: not started*

The plugin ships its own `CONVENTIONS.md` defining the governance
file formats, commit conventions, and quality gate rules. Commands
and BATCH_AGENT.md reference this file via
`!`cat ${CLAUDE_SKILL_DIR}/../CONVENTIONS.md`` instead of
deferring to the user's CLAUDE.md.

The plugin is self-contained: a user who installs symphonize and
runs `/symphonize:init` gets a working governance loop without
needing any symphonize-specific content in their CLAUDE.md.

CONVENTIONS.md contains:

- **Spec format** — declarative style, numbered sections, status
  lines (`*Status: not started|in progress|complete*`), EARS
  reference, rationale requirements
- **Spec compression** — rules for compressing completed sections
  (retain rationale and observable behavior, remove protocol
  detail and pseudocode)
- **Roadmap format** — imperative work queue, build-dependency
  order, workstream slug format, sizing to ~200k tokens, delete
  completed work
- **Changelog format** — Keep a Changelog, `[Unreleased]` section,
  reverse chronological
- **Commit conventions** — conventional commits, one logical
  change per commit, semver mapping
- **Branching** — feature branches, `<type>/<short-description>`
  naming, create from `origin/main`
- **Quality gate** — zero failures, zero warnings from new code,
  never skip failing tests

**Why self-contained:** the plugin currently depends on the user
having specific sections in their CLAUDE.md. This works for the
author but fails for any other user. The conventions are part of
the plugin's contract, not the user's personal configuration.

## 7. Requirements discovery command
*Status: not started*

The plugin provides a `/symphonize:discover` command that
conducts a structured interview with the user to produce
REQUIREMENTS.md — a problem-space document in the user's
language.

REQUIREMENTS.md captures:

- Problem statement and target users
- User stories and workflows
- Constraints (technical, business, regulatory)
- Success criteria
- Priorities (must-have vs. nice-to-have)

REQUIREMENTS.md is the fourth governance file. The pipeline:

| Document | Voice | Question |
|----------|-------|----------|
| REQUIREMENTS.md | User's | What do we need? |
| SPEC.md | System's | What does the system do? |
| ROADMAP.md | Work queue | What remains to build? |
| CHANGELOG.md | History | What shipped? |

`/symphonize:plan` reads REQUIREMENTS.md (if present) as input
when drafting SPEC.md sections. If REQUIREMENTS.md does not exist,
`/plan` falls back to clarifying requirements directly with the
user (current behavior).

**Why a separate document:** requirements live in the user's
problem space. Specs live in the system's solution space. Mixing
them produces documents that serve neither audience well. The
translation from requirements to spec is where design decisions
happen — that boundary should be explicit.
