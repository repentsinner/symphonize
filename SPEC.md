# symphonize — Specification

## 1. Plugin commands
*Status: complete*

Symphonize provides four Claude Code plugin commands: `/plan`,
`/next`, `/orchestrate`, and `/clean`. Each command operates on
the governance file loop (SPEC.md → ROADMAP.md → CHANGELOG.md)
and produces conventional commits suitable for release-please.

## 2. Governance lint command
*Status: not started*

The plugin provides a `/symphonize:lint` command that validates
governance files locally without requiring CI.

The command runs three checks:

1. **Markdownlint** on SPEC.md, ROADMAP.md, and README.md using
   the project's `.markdownlint.json` (falls back to sensible
   defaults: MD013 off, MD024 off, MD036 off).
2. **SPEC.md status-line validation** — every numbered section
   (`## N.`) has a `*Status: not started|in progress|complete*`
   line immediately after the heading.
3. **README heading validation** (opt-in) — required H2 headings
   per project type (`library` or `application`).

`/symphonize:clean --full` calls `/symphonize:lint` before
committing governance doc changes. The command is also usable
standalone for pre-push validation.

**Why a plugin command, not just CI:** agents can validate
governance files before pushing, catching errors in seconds
instead of waiting for a CI round-trip.

## 3. Project scaffolding command
*Status: not started*

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

The command is idempotent: it skips files that already exist and
warns rather than overwrites.

**Why scaffolding:** new projects need boilerplate to participate
in the governance loop. Scaffolding reduces setup from "read the
docs and copy-paste" to one command.

## 4. Reusable CI workflows
*Status: not started*

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
*Status: not started*

Symphonize's own CI calls its own `governance-lint.yml` reusable
workflow. The repo's `.github/workflows/ci.yml` uses
`./.github/workflows/governance-lint.yml` with
`readme-type: library`.
