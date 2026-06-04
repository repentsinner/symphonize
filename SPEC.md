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

## Scaffolding freshness §spec:scaffold-freshness
*Status: in progress*

`/symphonize:init` scaffolds the current state of the world; it does not
keep scaffolded files current afterward. This matches every scaffolder
(`flutter create`, `npm init`): generated files are handed to the project
to mutate in project-specific ways, so the scaffolder cannot own their
later evolution. Two freshness concerns follow from that boundary, with
different owners.

Symphonize ships its workflow templates two ways (§spec:reusable-ci):
`governance-lint.yml` is scaffolded as a `@v1` reusable caller, so a
consumer picks up symphonize's internal action bumps transitively; the
release, auto-merge, and major-tag workflows are copied verbatim because
each needs project-specific manifests and tokens, so a consumer holds a
point-in-time snapshot that does not self-update.

- **Source freshness — symphonize's concern.** The copied templates'
  source is symphonize's own `.github/workflows/*`, and the plugin bundle
  init copies from is built from it. If the source rots, every new scaffold
  ships stale action versions — "init-ing the past." Symphonize keeps the
  source current with Dependabot (`github-actions`), so a fresh scaffold
  ships current pins.
- **Copy freshness — the consumer's concern.** A consumer's copied
  workflows are theirs to mutate and theirs to keep current. `init`
  scaffolds a `.github/dependabot.yml` (`github-actions`) into the consumer
  so those copies self-heal through native upgrade PRs — the same mechanism
  that surfaces a deprecation to any GitHub repository.

**Why delegate copy freshness rather than check it:** a drift checker
would have to diff a consumer's workflows against the current templates,
but those files are *meant* to diverge — it cannot separate intentional
project mutation from a stale pin without re-asserting symphonize as
authority over files it deliberately handed off. Dependabot already owns
the action-version upgrade graph; reimplementing it would be strictly
worse. A `/doctor`-style command, if built, belongs to governance-document
drift (status-line validity, dangling slugs, docs-versus-repo-state),
where symphonize is the source of truth — not to action versions.

When scaffolding ownership migrates to the schema's scaffolder
(§spec:governance-schema, §road:adopt-schema-scaffolder), this freshness
contract migrates with it. §req:modular-adoption

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

## Orchestration loop §spec:orchestration-loop
*Status: not started*

`/symphonize:orchestrate` runs an unattended execution loop that
invokes `/symphonize:next --unattended` repeatedly until the
active ROADMAP section's unblocked workstreams are attempted. The
loop runs in-session via Claude Code's first-party `/goal` command
(Claude Code 2.1.139+). §req:success-criteria

### Observable behavior

- When `/symphonize:orchestrate` runs, it first invokes
  `/symphonize:clean --lite` to settle local state, then sets a
  `/goal` whose condition describes the section's completion
  state (all unblocked workstreams attempted, or ROADMAP.md
  empty).
- Each turn, Claude Code invokes `/symphonize:next --unattended`.
  After the turn, the small fast model (typically Haiku) judges
  the goal condition against the conversation transcript and
  either continues or terminates the loop.
- When the condition is met, the goal clears automatically and
  the user regains control. The active ROADMAP section is left
  blocked on review with one PR per executed batch.
- The user terminates an active loop with `/goal clear` or by
  starting a new conversation with `/clear`.

### Termination contract with /next

The goal is met when `/symphonize:next --unattended` reports that
all unblocked workstreams in the active ROADMAP section have been
attempted, or when ROADMAP.md contains no remaining workstreams.
`/next`'s output shall make the terminal state visible to a
reading evaluator — a literal sentinel string is not required and
is not part of the contract. The exact condition wording is an
implementation detail of `commands/orchestrate.md`.

### Why /goal, not ralph-loop

Earlier versions invoked the third-party ralph-loop plugin with a
literal completion-promise sentinel (`BLOCKED ON REVIEW`). `/goal`
covers the same in-session, condition-bounded execution use case
natively. The switch removes:

- A third-party plugin dependency, simplifying installation and
  reducing the trust surface.
- The `.claude/ralph-loop.local.md` flag-file coupling that bled
  ralph-loop's stop hook into unrelated commands when the user
  ran `/symphonize:plan` or `/symphonize:discover` in a project
  with an active loop (see prior known-issue note in
  §spec:progress-file-location).
- A bespoke sentinel-string convention; the evaluator judges the
  condition from `/next`'s natural output.

### Rejected alternatives

- **Keep ralph-loop.** Rejected: it remains a viable plugin, but
  `/goal` is first-party in the host tool, resolves a documented
  cross-skill leakage issue, and removes an external dependency.
  Sub-1.0.0 status carries no back-compat obligation.
- **Pure auto mode.** Rejected: auto mode approves tool calls
  within a turn but does not start a new turn. The orchestration
  loop needs per-turn continuation, which `/goal` provides.
- **Time-interval `/loop`.** Rejected: orchestration is
  event-driven (when `/next` finishes, start the next), not
  time-driven. A fixed interval either wastes idle time or
  preempts in-flight work.
- **Custom stop hook.** Rejected: `/goal` is a session-scoped
  wrapper around a prompt-based stop hook. Hand-rolling the
  equivalent reproduces what the host already ships.

### Tradeoffs accepted

- Termination is model-judged (small fast model), not literal
  string match. The condition is short and the evaluator's
  accuracy is sufficient at this gate. §req:quality-attributes
- The loop requires the workspace trust dialog accepted and
  hooks enabled. `/goal` reports the reason when unavailable, so
  the failure mode is visible rather than silent.
- Slight per-turn evaluation cost on the small fast model;
  negligible compared to main-turn spend.

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

Triage edits governance documents only; it never ships behavior.
Every committing classification therefore uses a `docs(<scope>):`
commit — `docs(roadmap)`, `docs(spec)`, or `docs(requirements)` —
and triggers no release. The release-bearing commit is the later
`/next` implementation that resolves the routed work: it carries
`fix`/`feat` and closes the issue with `Fixes #N`. **Why:** typing a
triage commit `fix`/`feat` cuts a release for a bug still unfixed or
a feature still unbuilt — a phantom release whose changelog entry
contradicts the running system.

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
*Status: complete*

The batch agent protocol includes a mandatory `/simplify` gate as
Phase 5a, between Phase 5 (Verify) and Phase 5b (`/security-review`).
`/simplify` spawns three parallel review agents for code reuse,
quality, and efficiency and applies fixes to recently changed files.
§req:quality-attributes

The gate flow (skip-condition check, single invocation, fix review
with revert-on-conflict, mandatory CI re-run, handoff) is defined in
`protocols/batch-agent.md` Phase 5a.

**Why mandatory:** reuse, duplication, and inefficiency violations
are objective and mechanically detectable. Gating enforces
brownfield-bias at machine speed rather than relying on batch-agent
discretion. Symmetry with `/security-review`: both are native skills
whose output is deterministic enough to gate on.

**Why Phase 5a, not a Phase 5 step:** `/simplify` mutates code and
requires a CI re-run. Embedding it inside Phase 5's verify steps
would interleave verification with mutation. A dedicated phase
makes the mutate-then-revalidate cycle explicit.

**Why after Phase 5, not before:** Phase 5 verifies the batch's
vertical integration against the spec. `/simplify` optimizes *how*
the code is written, not *what* it does. Running simplify before
integration verification risks the skill refactoring incomplete
work. Verify the slice works, then optimize its shape.

**Why before `/security-review`, not after:** security-review
inspects the code that ships. If `/simplify` ran after, security
would review pre-simplify code and miss vulnerabilities introduced
by the refactor. Running simplify first ensures security sees the
final state. Running security twice doubles cost without
commensurate benefit.

**Why batch-agent reviews fixes before CI re-run:** `/simplify` has
no visibility into design intent. A batch agent may have
deliberately inlined a helper for readability or duplicated logic
across two sites for independence. Blindly accepting fixes overrides
intent. Review-then-revert preserves the agent's architectural
choices.

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
  Rejected: Boy Scout cleanup operates on *files the batch already
  touches*, encouraging incremental improvement as a side-effect of
  implementation work. `/simplify` operates on *recently changed
  files*. Overlap is substantial but not identical; manual cleanup
  remains valuable for code the batch agent understands in context.

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

## Governance-schema extraction §spec:governance-schema
*Status: not started*

Symphonize's governance-schema — the structural definition of its
governance documents (file formats, the `§req:`/`§spec:`/`§road:` slug
grammar, the status-line format, cross-reference rules) plus the workflow
that enforces it and the scaffolder that wires a repo up to it — lives in
a dedicated repository (`bug-free-happiness`), not inside symphonize. The
schema ships no document to adopters: the linter is its executable form,
and symphonize's commands are built against the grammar. Symphonize
consumes the schema; it keeps its authoring methodology and process
discipline, which are symphonize's own opinion and not part of the shared
schema. §req:modular-adoption

In the target state:

- Symphonize's CI references the schema's enforcement workflow instead of
  shipping its own `governance-lint.yml`; the workflow runs the full
  schema with no toggles to set. CHANGELOG.md stays unenforced — it is
  release-please's generated artifact. This supersedes §spec:reusable-ci
  and §spec:dogfooding.
- Symphonize's `CONVENTIONS.md` is deleted, not replaced. Its three kinds
  of content disperse: the structural grammar needs no per-repo file —
  the schema's linter enforces it and the curate/dispatch commands are
  built against it; the authoring methodology (declarative spec writing,
  vertical slicing, interview frameworks, compression) moves inline into
  the curation commands; the process discipline (branching, commit
  conventions, quality gate) moves into the dispatch commands and the
  batch-agent protocol. This supersedes §spec:self-contained-conventions.
- `/symphonize:init` defers to the schema's scaffolder, and symphonize
  declares a plugin dependency on the schema — the dependency pin and the
  CI workflow ref together establish which schema version symphonize
  targets. This supersedes the scaffolding ownership in
  §spec:project-scaffolding.

The schema repository's own SPEC.md specifies its design — single repo,
three faces, and the version-coherence contract. Symphonize references
that spec instead of restating it.

**Why a separate schema:** a linter is the executable form of the schema,
so co-locating the grammar and its enforcement on one version line keeps
them from drifting — they did once, when a numbered-versus-slug mismatch
went uncaught. Holding the schema in its own repo also gives the future
curation and dispatch layers one shared definition to depend on, rather
than each embedding its own copy. §req:modular-adoption

**Why symphonize-specific:** the schema encodes symphonize's conventions
and is consumed only by symphonize — not a general-purpose linter other
projects adopt. If symphonize ever needs a different schema, it would plug
a different one in on its own side; that seam stays unbuilt until a second
schema exists.

**Direction:** the schema extraction is the first step toward decomposing
symphonize into independently-adoptable layers — a curation layer and a
dispatch layer over the shared schema. The three-way split of today's
`CONVENTIONS.md` mirrors that layering: the structural slice anchors the
schema, the authoring methodology becomes curation's, and the process
discipline becomes dispatch's. This section covers only the
governance-schema boundary; the further splits await their own spec
sections.

**Tradeoff accepted:** a cross-repo dependency replaces an in-repo one.
Symphonize's CI and scaffolding depend on a published schema release. The
pinned workflow ref and the plugin dependency range — both machine-checked
— keep symphonize and the schema on one version, with no bespoke marker to
maintain.

## YOLO mode §spec:yolo-mode
*Status: not started*

`/symphonize:yolo` runs the governance pipeline from a user-named entry
stage (`discover`, `plan`, `roadmap`, or `next`) through to a single pull
request that bundles the governance-document changes and the landed
implementation. It runs non-interactively: the agent makes the judgment
calls a person normally makes at each stage, records them, and surfaces
nothing for approval until the final PR. §req:priorities
§req:quality-attributes

YOLO mode is a dispatch-layer capability — the unattended execution model
of §spec:orchestration-loop extended *up* the pipeline. Where
`/symphonize:orchestrate` loops `/symphonize:next` inside an
already-merged roadmap, YOLO also authors the upstream governance
documents the run needs and bundles everything onto one branch.

### Gates collapse, they do not disappear

The default pipeline has two kinds of gate: **human** gates between stages
(a person reviews REQUIREMENTS before `/plan`, SPEC before `/roadmap`, the
PR before merge) and **mechanical** gates inside `/next` (`/simplify`,
`/security-review`, CI, governance-lint). YOLO removes the human gates and
keeps the mechanical ones. The four human review points collapse into one:
a single review of the complete vertical slice — REQUIREMENTS → SPEC →
ROADMAP → code — in one PR, where the run creates and validates the
`§`-slug traceability chain in a single diff. §spec:pre-pr-review-gates
§spec:simplify-gate

### Observable behavior

- **Entry stage.** A required argument names the stage the run starts at;
  YOLO runs that stage and every downstream stage, and assumes the
  upstream stages already hold. When an entry stage would skip an upstream
  document a downstream one cites — a SPEC section references a `§req:`
  slug that `/plan`-entry would not otherwise create — YOLO backfills the
  minimal upstream entry so cross-references resolve, applying the same
  backpressure the individual commands use for thin upstream documents.
  §spec:requirements-discovery
- **Single branch, single PR.** Every stage commits to one branch; the PR
  opens once, at the end. No stage merges before the next begins, so the
  run carries no inter-stage merge dependency.
- **One commit per layer.** The bundle keeps separate conventional
  commits — `docs(requirements):`, `docs(spec):`, `docs(roadmap):`, and
  the implementation's `feat`/`fix`/etc. — so release-please reads the
  history correctly. The PR is one slice; the commits stay one per change.
- **One slice per run.** A run targets a single batch-sized vertical slice
  per §spec:vertical-first-batch-selection. Inputs larger than one batch
  route to the gated pipeline or `/symphonize:orchestrate`.
- **Non-interactive curation.** `discover`, `plan`, and `roadmap` run
  without user input; the agent makes conservative choices and documents
  them in the commit, as sub-agents do under `--unattended`.
  §spec:unattended-flag-passthrough
- **Terminal state, risk-tiered.** Once the mechanical gates pass, the
  bundle's merge eligibility follows its conventional-commit risk class:
  - A breaking change (`!` or a `BREAKING CHANGE` footer) always stops at
    a mergeable PR for human review.
  - Clearly low-risk classes (`docs`, `chore`, `refactor`, `style`,
    `test`, `ci`, `build`) auto-merge.
  - `feat`, `fix`, and any class the run cannot confidently classify stop
    for review. The mapping is configurable; the default is conservative.
  - `--yolo-hard` auto-merges every class once the mechanical gates pass,
    for trusted or scheduled contexts.

  With no flag, a run stops at a mergeable PR — that PR is the one retained
  human gate. §req:constraints
- **Failure is explicit.** A run that cannot reach all-gates-green — CI
  red after its attempts, a blocking `/security-review` finding, or an
  agent unable to proceed — leaves a draft PR with diagnostics and stops.
  It never leaves a broken branch or a partially merged state.

**Why YOLO suits only bounded, low-risk slices:** the gated pipeline's
value is cheap early correction — a person kills a bad requirement or
design before any code exists. YOLO writes code against un-reviewed
design, so a design the reviewer rejects at the final PR wastes the
implementation built against it. YOLO pays off when the agent's design is
likely correct — small, familiar work — and wastes effort when the design
needs human steering. It is an opt-in mode, not the default path; the
gated, human-reviewed pipeline remains the norm. §req:constraints

**Why risk-tiered auto-merge keys on the commit type:** conventional-commit
type already encodes semver impact, which tracks change risk — a breaking
change is the most expensive to land wrong, a docs or chore change the
least. Gating auto-merge on that classification reuses a signal the
project already produces instead of inventing a separate risk model. The
classifier trusts the agent's own commit type, so the conservative default
— review anything not clearly low-risk — keeps a mis-typed change from
merging unattended.

**Rejected alternatives:**

- **Auto-merge every class by default.** Rejected: it overrides the
  never-merge-directly posture for every change, including breaking ones.
  `--yolo-hard` offers this as an explicit opt-in instead. §req:constraints
- **A separate PR per stage, auto-merged in sequence.** Rejected:
  inter-stage merges reintroduce the gating and merge-conflict friction
  YOLO exists to remove, and split one slice's traceability across four
  PRs. One bundled PR reviews the whole slice at once.
- **Skip the mechanical gates for speed.** Rejected: non-interactive
  execution makes the mechanical gates the only in-run safety net.
  Dropping them trades a bounded time saving for unbounded risk.

**Tradeoffs accepted:**

- A rejected design wastes the implementation built against it — bounded
  by scoping YOLO to low-risk slices.
- The risk classifier is only as honest as the commit type it reads; the
  conservative default mitigates but does not remove this.
- Non-interactive end-to-end execution widens the blast radius of a
  prompt-injected input, a destructive action, or a flawed design — no
  person inspects the run until the final PR. The one-shot input is
  untrusted attack surface; the mechanical gates and the execution sandbox
  are the only in-run protection. §req:quality-attributes

## Repo-state reconciliation hook §spec:repo-state-reconciliation
*Status: complete*

An agent works from a snapshot of repo state taken when it last looked,
and assumes it is the only actor. A human merges the open PR, force-pushes
the branch, or advances `origin/main` while the conversation continues —
and the agent keeps asserting the merged PR is open, pushes commits onto a
branch that no longer exists upstream, or builds on a stale base. The
governance loop's premise is that the docs and PRs reflect actual state
(§req:success-criteria); an agent reasoning from stale state corrupts that
premise from inside.

Symphonize ships a Claude Code `UserPromptSubmit` hook in the plugin
(`hooks/hooks.json` registering `hooks/reconcile-repo-state.sh` via
`${CLAUDE_PLUGIN_ROOT}`) that reconciles the agent's view of repo state with
the remote before each turn, and surfaces any divergence as conversation
context via `hookSpecificOutput.additionalContext`.

### Observable behavior

- Before each user turn, the hook performs a **read-only** reconcile: a
  rate-limited `git fetch --prune`, then a comparison of the current branch
  against its upstream and `origin/main`, and of the branch's pull request
  against its remote state.
- The hook injects context **only when reality diverges** from the naive
  "nothing changed since I last looked" assumption — the current branch's
  PR is merged or closed; the branch is behind `origin/main`; the branch no
  longer exists on the remote. When nothing diverges, it injects nothing.
- The divergence is reported as a specific contradiction at the point of use
  (e.g. "PR #118 for this branch is MERGED"), not a status dump.
- The hook never blocks the prompt and never mutates the working tree or the
  remote (no checkout, pull, rebase, push). It reports; the agent and user
  decide.
- The hook degrades to a silent no-op outside a git repository, in detached
  HEAD, when `gh` is unavailable or unauthenticated, or when the network is
  unreachable. Absence of remote state is never reported as divergence.
- The fetch is rate-limited via a per-repo stamp file: the hook skips the
  network round-trip when one ran within a short window (default 300s), so
  most turns add no latency. PR state is at most one window stale.

### Why a hook, not an instruction

No hook fires on the agent's generated text, so nothing can inspect a
stale assertion after the agent makes it and force a correction. The only
available lever is to put fresh ground truth into context *before* the
turn, where it contradicts the stale assumption at the moment the agent
would act on it. This is a floor raise, not behavior policing: it cannot
guarantee the agent heeds the correction, but it removes the excuse of not
knowing.

The mechanism is chosen over a passive instruction — a CLAUDE.md note or a
remembered preference — because passive reminders compete for attention
against everything else in context and get normalized away within a
session. A reminder the agent is free to skip is the failure mode this
section exists to remove; injected ground truth at the decision point is
not skippable in the same way.

### Why shipped in the plugin

The hook lives in symphonize's plugin bundle (`hooks/hooks.json` plus a
script referenced via `${CLAUDE_PLUGIN_ROOT}`), not in a user's
`settings.json`. Settings hooks bind to one machine and do not travel;
a plugin-shipped hook installs with the plugin and every adopter inherits
it. Keeping agents honest about external state is dispatch-layer
infrastructure — it belongs with the execution machinery that assumes a
current view of the repo. §req:modular-adoption

### Rejected alternatives

- **`SessionStart` hook.** Rejected: it snapshots once and rots. The
  failure being fixed is mid-session drift — a PR merged while the
  conversation is open — which a start-of-session check never sees.
- **A blocking or auto-correcting hook** (deny the prompt, auto-rebase,
  auto-fetch-and-pull). Rejected: a reconciler that mutates the tree or
  blocks work on stale state can clobber in-progress work and surprises
  the user. Reconciliation reports; it does not act.
- **A passive memory or CLAUDE.md instruction.** Rejected: this is the
  status quo the section replaces. It relies on recall and loses to
  attention competition.
- **A flat repo-status dump every turn.** Rejected: undifferentiated
  status gets skimmed and adds noise on every turn. Reporting only the
  contradiction keeps signal high and output silent when state is clean.

### Tradeoffs accepted

- Bounded staleness: the rate-limited fetch trades a few minutes of
  possible PR-state lag for the elimination of a per-turn network tax.
  §req:quality-attributes
- PR-state detection depends on `gh`; without it the hook still reports
  branch ahead/behind from local refs, but not merge state. Degraded, not
  broken.
- The response remains model-judged. Injecting the contradiction raises
  the floor but does not force the agent to act on it. Acceptable — the
  alternative (no fresh state at all) is strictly worse.
