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
*Status: complete*

The plugin provides a `/symphonize:triage` command that processes
GitHub issues into governance doc entries. Unlike pipeline commands
that each own a single file, triage is a lateral entry point — it
classifies issues and routes them to whichever governance file the
classification warrants. §req:success-criteria §req:user-stories

Classifications: bug (→ ROADMAP workstream or SPEC section),
feature request (→ REQUIREMENTS section), feedback/question
(→ comment only), out of scope (→ closing comment). The user
approves every classification before the command acts.
§req:constraints (human-in-the-loop)

Issue bodies are untrusted input — read-only data, never executed
or interpolated into shell commands. §req:quality-attributes

**Why a triage command:** without triage, issues accumulate as a
parallel backlog disconnected from governance docs. `/triage`
closes the loop: issues flow into the same governance documents
that `/plan` and `/roadmap` produce.

**Why not single-file ownership:** pipeline commands flow
linearly (requirements → spec → roadmap), so each naturally owns
one file. Triage is a router — issues arrive at varying maturity
levels and map to different governance files. The classification
step replaces the pipeline ordering as the routing mechanism.

## Clean command supersession safety §spec:clean-supersession-safety
*Status: complete*

The `/symphonize:clean` command (full mode) closes open sub-agent
PRs and deletes remote branches during post-merge cleanup. These
are destructive, hard-to-reverse operations — a closed PR with a
deleted remote branch cannot be reopened.

The clean command shall not close a PR or delete its remote branch
based on title similarity, topic overlap, or heuristic matching.
A PR is superseded only when every file it touches exists in main
with equivalent changes. Verification procedure:

1. For each open sub-agent PR, list unmerged commits
   (`git log --oneline main..<branch>`).
2. For each unmerged commit, inspect the diff and confirm the
   classes, functions, and files introduced exist in main.
3. If any introduced symbol or file does not exist in main, the
   PR is not superseded — leave it open.
4. Only after all changes are confirmed present in main, close
   the PR with a comment citing the merge commit or batch PR
   that landed the work.

Remote branch deletion shall occur only for PRs that are already
merged or confirmed superseded and closed by the procedure above.
Open PRs shall never have their remote branches deleted.

**Why:** an instance of `/clean` closed an unmerged PR solely
because its title overlapped with a preceding PR's title. Related
work often spans multiple PRs — title similarity does not imply
duplication. Closing unverified PRs destroys in-progress work.
The verification cost (diffing a few commits) is trivial compared
to the cost of losing a valid PR.

## Vertical-first batch selection §spec:vertical-first-batch-selection
*Status: complete*

The `/symphonize:next` dispatch layer selects workstreams for a
batch by building dependency chains that reach the user-facing
surface, then selecting the longest chain that fits the batch cap.
The algorithm is implemented in `commands/next.md` step 3.

Batch selection goals, in priority order: vertical slices, walking
skeleton, dependency correctness, batch coherence, forward progress.

**Why chains over independent workstreams:** independent unblocked
workstreams are typically all at the same architectural layer —
selecting them produces a horizontal batch. A chain crosses layers
by definition, connecting foundation to surface. This aligns batch
selection with the vertical slice structure `/roadmap` imposes on
sections.

**Why longest chain:** the bottleneck in an orchestration loop is
review latency, not batch size. Maximizing chain length per batch
minimizes review gates between "nothing built" and "vertical slice
shipped."

Reference: Cockburn, *Crystal Clear* (2004) — walking skeleton;
Wake, "INVEST in Good Stories" (2003); Cockburn, "Elephant
Carpaccio" exercise.

## Clean working tree hygiene §spec:clean-working-tree-hygiene
*Status: complete*

The `/symphonize:clean` full-mode command checks for dirty state
at entry, checks out main before verification, and never stashes.

**Why no stashing:** stashes from branch-switching accumulate
silently — the pop never happens. Lock file drift (the usual
cause) is handled by restoring generated files; real dirty state
aborts with a warning. A stash is a deferred decision disguised
as cleanup.

**Why verify from main:** the previous phase ordering ran
verification from a branch, not from the state that ships.
Checking out main and fast-forwarding before governance doc
updates ensures tests run against the shipped state.

## Pre-PR review gates §spec:pre-pr-review-gates
*Status: complete*

The batch agent protocol (`protocols/batch-agent.md`) includes
review gates between Phase 5 (Verify) and Phase 6 (Deliver):
`/security-review` as a mandatory gate, `/review --comment` as a
recommendation in the PR body.

**Why security is mandatory:** vulnerabilities in merged code are
expensive to remediate and may ship before review. A local
`/security-review` pass costs seconds and catches common issues
mechanically.

**Why code review is recommended, not mandatory:** `/review` runs
parallel agents producing nuanced findings that benefit from human
judgment. Gating on it would block unattended loops on false
positives or require auto-dismissal — defeating the purpose.

## Simplify gate §spec:simplify-gate
*Status: not started*

The batch agent protocol (`protocols/batch-agent.md`) includes a
mandatory `/simplify` gate as Phase 5a, between Phase 5 (Verify)
and Phase 5b (`/security-review`). The gate invokes the bundled
`/simplify` skill, which spawns three parallel review agents for
code reuse, quality, and efficiency, aggregates findings, and
applies fixes to recently changed files. §req:quality-attributes

### Gate ordering

1. Phase 5 verify completes (CI green, vertical integration
   confirmed, Boy Scout cleanup applied).
2. Phase 5a runs `/simplify` once over the batch diff. The skill
   applies fixes directly.
3. The batch agent reviews the fixes. If any fix contradicts a
   deliberate design choice made during implementation (e.g.,
   intentional inlining, duplication for clarity), the agent
   reverts that fix with a commit message explaining the reversion.
4. The batch agent re-runs the CI command from Phase 2. Simplify
   fixes that break CI shall be diagnosed and corrected before
   proceeding.
5. Phase 5b (`/security-review`) runs against the simplified code.
6. Phase 6 (Deliver) pushes.

### Skip condition

The gate is skipped when the batch diff touches no source files
(only markdown, YAML, or governance documents). The batch agent
determines this by inspecting `git diff --name-only` against the
merge base and checking that no files match the project's source
file extensions. Skipping the gate is recorded in the batch agent's
status report so the reviewer knows why Phase 5a did not execute.

### Single invocation

The gate runs `/simplify` exactly once. It does not iterate until
clean. `/simplify` is an actuator — repeated invocations risk
re-refactoring the skill's own output, producing churn without
convergence. CI re-run is the safety net; a single pass plus CI
validation bounds the loop.

**Why mandatory:** reuse, duplication, and inefficiency violations
are objective and mechanically detectable. Gating enforces
brownfield-bias (CLAUDE.md § Brownfield bias) at machine speed
rather than relying on batch-agent discretion. Symmetry with
`/security-review`: both are native skills whose output is
deterministic enough to gate on.

**Why Phase 5a, not Phase 5 step:** `/simplify` mutates code and
requires a CI re-run. Embedding it inside Phase 5's verify steps
would interleave verification with mutation. A dedicated phase
makes the mutate-then-revalidate cycle explicit.

**Why after Phase 5, not before:** Phase 5 verifies the batch's
vertical integration against the spec. `/simplify` optimizes
*how* the code is written, not *what* it does. Running simplify
before integration verification risks the skill refactoring
incomplete work. Verify the slice works, then optimize its shape.

**Why before `/security-review`, not after:** security-review
inspects the code that ships. If `/simplify` ran after, security
would review pre-simplify code and miss vulnerabilities introduced
by the refactor. Running simplify first ensures security sees the
final state. Running security twice (before and after) doubles
cost without commensurate benefit.

**Why batch-agent reviews fixes before CI re-run:** `/simplify`
has no visibility into design intent. A batch agent may have
deliberately inlined a helper for readability or duplicated logic
across two sites for independence. Blindly accepting fixes
overrides intent. Review-then-revert is cheap (the fixes are
already a diff) and preserves the agent's architectural choices.

**Why skip for doc-only batches:** `/simplify` reviews "code reuse,
quality, and efficiency." Markdown and YAML have none of these
concerns. Spending three agent spawns on prose is noise.
§req:quality-attributes (proportionality).

**Rejected alternatives:**

- **Recommended, not mandatory.** Matches `/review --comment`'s
  posture. Rejected: recommended gates are silently skipped in
  unattended mode, which defeats the enforcement goal. Reuse
  violations are objective enough to gate on.
- **Iterate until clean.** Matches `/security-review`'s loop.
  Rejected: `/simplify` applies fixes, so subsequent iterations
  see a modified diff and may reverse prior work. Security-review
  is a reporter — its "iterate until clean" is a fixpoint on
  findings. Simplify is an actuator — its fixpoint is unstable.
- **Replace Phase 5 step 5 (Boy Scout cleanup) with `/simplify`.**
  Rejected: Boy Scout cleanup operates on *files the batch
  already touches*, encouraging incremental improvement as a
  side-effect of implementation work. `/simplify` operates on
  *recently changed files*. Overlap is substantial but not
  identical; manual cleanup remains valuable for code the
  batch agent understands in context.

**Tradeoffs accepted:**

- Three additional parallel agent spawns per batch, charged against
  the batch agent's token budget.
- CI runs twice per batch (end of Phase 4, end of Phase 5a).
- Simplify may propose fixes the batch agent must revert, costing
  review time. Bounded by running simplify once.

## Thin roadmap workstreams §spec:thin-roadmap-workstreams
*Status: complete*

Roadmap workstreams are thin pointers into SPEC.md. A workstream
description is one sentence stating the deliverable and affected
file(s), plus a `§spec:` citation. `**Verify:**` blocks remain at
the section level. The `### §road:slug` heading format is retained.

**Why:** verbose workstream descriptions duplicate the spec and
diverge when the spec is updated. The batch agent reads SPEC.md
in Phase 1 — duplicating design context in the roadmap wastes
tokens and creates a second source of truth.

## Directory-scoped governance §spec:directory-scoped-governance
*Status: complete*

Governance files scope to the directory subtree they live in. A
SPEC.md in `packages/auth/` governs that subtree; a SPEC.md at the
repo root governs the project as a whole. Any directory containing
SPEC.md is a governance root. Commands resolve governance root by
CWD walk-up (nearest SPEC.md ancestor, repo root fallback). The
resolution algorithm and scoping rules live in CONVENTIONS.md
§ Governance root.

**Why pull, not push:** packages pull root governance as upstream
context. Push would require root to enumerate packages and
distribute rules — coupling that the monorepo structure does not
mandate. Symphonize stays ecosystem-agnostic (no pubspec.yaml,
package.json, or Cargo.toml awareness).

**Why CWD, not flags:** no `--package` or `--scope` flag exists.
The user `cd`s into the package directory. This mirrors Claude
Code's own directory scoping and preserves single-repo behavior
with zero configuration.

**Why no manifest:** the filesystem is the configuration. Adding a
package means dropping governance files in a directory; removing
means deleting them. No registry to maintain, no sync to drift.

**Why no symphonize-specific lint inheritance:** markdownlint, Vale,
and similar tools already resolve config by walking up the directory
tree. Symphonize delegates to the linter's native scoping.
