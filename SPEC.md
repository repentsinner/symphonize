# symphonize — Specification

## Plugin commands §spec:plugin-commands
*Status: in progress*

Symphonize provides Claude Code plugin commands that operate on
the governance file loop (REQUIREMENTS.md → SPEC.md → ROADMAP.md
→ CHANGELOG.md) and produce conventional commits suitable for
release-please.

The command pipeline:

1. `/symphonize:discover` — domain discovery, produces
   REQUIREMENTS.md
2. `/symphonize:plan` — technical decisions, produces SPEC.md
3. `/symphonize:roadmap` — break spec into workstreams, produces
   ROADMAP.md
4. `/symphonize:next` — executes workstreams
5. `/symphonize:orchestrate` — unattended multi-batch execution
6. `/symphonize:triage` — classify issues into governance entries
7. `/symphonize:review` — PR review and integration test guidance
8. `/symphonize:clean` — post-merge cleanup
9. `/symphonize:lint` — governance file validation
10. `/symphonize:init` — project scaffolding
11. `/symphonize:feedback` — submit feedback to symphonize

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
when drafting SPEC.md sections. `/symphonize:roadmap` reads
SPEC.md to produce ROADMAP.md workstreams. Each command applies
backpressure when upstream documents are absent or thin — filling
gaps inline for small issues, recommending the upstream command
for large ones. `/symphonize:init` scaffolds an empty
REQUIREMENTS.md skeleton.

**Why a separate document:** requirements live in the user's
problem space. Specs live in the system's solution space. Mixing
them produces documents that serve neither audience well. The
translation from requirements to spec is where design decisions
happen — that boundary should be explicit.

## Prose linting §spec:prose-linting
*Status: complete*

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

## Progress file location §spec:progress-file-location
*Status: complete*

The `/symphonize:next` command tracks attempted workstreams in
`.symphonize-progress.local.md` at the project root. The file was
previously at `.claude/.ralph-progress.local.md`, which has two
problems: it lives inside Claude Code's managed `.claude/` directory
(permissions conflicts), and its name implies ralph-loop ownership
when symphonize's own commands write and delete it.

The file is symphonize state — it belongs alongside other
project-root dotfiles, named after the tool that owns it.
`/symphonize:clean` deletes it when the loop ends.

**Why:** Claude Code controls `.claude/` and may restrict writes
from plugin commands. Symphonize state belongs to symphonize, not
to the host tool's config directory.

**Known issue:** the ralph-loop stop hook fires based on the
presence of `.claude/ralph-loop.local.md`, not on which skill is
active. If an orchestrate loop is blocked on review and the user
runs `/symphonize:plan` or `/symphonize:discover` in the same
project, the stop hook interrupts planning with orchestration
directives. Workaround: `/clear` and manually remove the flag
file before planning. A proper fix requires the stop hook (in
ralph-loop, not symphonize) to check active skill context.

## Unattended flag passthrough §spec:unattended-flag-passthrough
*Status: complete*

When `/symphonize:orchestrate` starts a ralph-loop, every agent in
the execution hierarchy runs unattended. The `--unattended` flag
propagates explicitly through each layer — no agent infers
unattended mode from file existence or ambient state.

### Propagation chain

1. `/symphonize:orchestrate` passes `--unattended` in the
   ralph-loop prompt that invokes `/symphonize:next`.
2. `/symphonize:next` reads `--unattended` from its arguments
   (not from `.claude/ralph-loop.local.md`). Passes
   `--unattended` to the batch agent it spawns.
3. The batch agent (BATCH_AGENT.md) passes `--unattended` to
   every sub-agent it spawns in Phase 3.
4. Sub-agents operating in `--unattended` mode shall not surface
   interactive prompts, approval gates, or questions to the user.
   When a sub-agent encounters ambiguity it would normally ask
   about, it makes a conservative choice and documents the
   decision in its commit message.

### Detection in `/next`

When `--unattended` is present in `/next`'s arguments, the command
sets `unattended = true`. When absent, `unattended = false`. The
`.claude/ralph-loop.local.md` file check is removed from `/next`.

### `/clean` unchanged

`/symphonize:clean` checks `.claude/ralph-loop.local.md` to
auto-detect cleanup mode. That check remains — `clean` runs in the
main working tree where the file is visible, and mode auto-detect
is a convenience, not a correctness concern.

**Why:** the file-based detection couples symphonize to
ralph-loop's internal file layout. The file is not git-tracked, so
agents in worktrees cannot see it. More critically, even when the
batch agent correctly receives `--unattended`, it does not
propagate the flag to sub-agent workers. Those workers can surface
interactive prompts that block the orchestration loop indefinitely
with no user present. Explicit passthrough at every layer ensures
the entire tree runs non-interactively.

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

## Issue triage command §spec:issue-triage
*Status: not started*

The plugin provides a `/symphonize:triage` command that processes
GitHub issues into governance doc entries. Unlike pipeline commands
that each own a single file, triage is a lateral entry point — it
classifies issues and writes to whichever governance file the
classification warrants. §req:success-criteria §req:user-stories

### Classification

The command reads an issue via `gh issue view` and classifies it:

- **Bug** — observed behavior contradicts spec or user
  expectations. Produces a ROADMAP.md workstream. If the bug
  reveals a design gap, produces a SPEC.md section instead (or
  both).
- **Feature request** — new capability not covered by current
  requirements. Produces a REQUIREMENTS.md section. Recommends
  `/plan` as the next step.
- **Feedback / question** — no governance change needed. The
  command adds a comment acknowledging receipt and closes the
  issue, or labels it for discussion if the user chooses.
- **Out of scope** — the command adds a comment explaining why
  and closes the issue.

The user approves the classification before the command acts on
it. §req:constraints (human-in-the-loop)

### Governance updates

For each classification, the command drafts the governance entry
and presents it for review before committing:

- **Bug → ROADMAP workstream:** a `### §road:slug` entry under
  the appropriate section, with `Depends on:` and `**Verify:**`
  lines. Cites the issue number.
- **Bug → SPEC section:** a new `## N. Title §spec:slug` section
  with status `not started`, describing the corrected behavior.
- **Feature → REQUIREMENTS section:** a new section under the
  appropriate heading (user stories, quality attributes, or
  constraints) with `§req:slug` suffix. Written in the user's
  problem-space language.
- **Feedback → comment only:** no governance file change.

The command writes to a feature branch, commits with conventional
commit format, pushes, and opens a PR. The PR body cites the
source issue.

### Issue lifecycle

After triage, the command updates the source issue:

- Adds a label matching the classification (`bug`,
  `enhancement`, or project-specific labels if they exist).
- Adds a comment linking to the governance entry and/or PR
  (e.g., "Added to roadmap: §road:fix-parser-null-check.
  PR: #42").
- Leaves the issue open. The issue closes when the PR that
  implements the fix/feature merges and includes `Fixes #N`.

No custom status labels. The governance doc link *is* the status
signal — if an issue produced a ROADMAP workstream, the
workstream's presence means it's queued or in progress.

### Scope

v1 processes a single issue per invocation, specified by number
(`/triage 42`) or selected from a list of open issues. Batch
processing (multiple issues per session) is a future enhancement.

### Proportionality

Triage effort scales with issue complexity. A clear bug report
with reproduction steps goes straight to a ROADMAP workstream.
A vague feature request gets follow-up questions before the
command drafts a REQUIREMENTS section. §req:quality-attributes

### Security

Issue bodies are untrusted input. The command shall not execute
code from issue content, interpolate issue text into shell
commands, or treat issue markdown as instructions. Issue content
is read-only data that informs governance entries written by the
agent. §req:quality-attributes (safety)

**Why a triage command:** without triage, issues accumulate as a
parallel backlog disconnected from governance docs. Maintainers
have to manually translate each issue into spec sections and roadmap
workstreams — or ignore them. `/triage` closes the loop: issues
filed via `/feedback` or GitHub's web UI flow into the same
governance documents that `/plan` and `/roadmap` produce,
keeping the project responsive without manual translation.

**Why not single-file ownership:** pipeline commands flow
linearly (requirements → spec → roadmap), so each naturally owns
one file. Triage is a router — issues arrive at varying maturity
levels and map to different governance files. Forcing triage
through the full pipeline for a clear bug report adds ceremony
without value. The classification step replaces the pipeline
ordering as the routing mechanism.
