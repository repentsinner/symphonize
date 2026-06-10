# Batch Agent Protocol

Agent-level instructions for executing a batch of ROADMAP.md
workstreams. The batch agent receives workstreams from the dispatch
layer (`/next`), implements them inline as a **thin vertical slice** —
a complete path from internal logic through to a user-facing surface —
and returns a pushed branch. The batch agent is a fan-out **leaf**: it
spawns no sub-agents. It plans, implements, integrates, and verifies in
its own turn, then hands a branch back to the dispatch layer, which runs
the review gates and opens the PR (§spec:batch-agent-leaf).
Project-agnostic — depends on projects following the SPEC.md/
ROADMAP.md governance convention.

## Prerequisite

The batch agent runs in a worktree created by the dispatch layer
(`next.md` spawns it with `isolation: "worktree"`). If
`git rev-parse --show-toplevel` matches the project root, STOP — you
are in the user's main checkout. Do not proceed.

## Unattended Mode

When the dispatch layer passes `--unattended`, the batch agent skips
interactive approval gates. All other quality checks, CI runs, and
conflict resolution remain unchanged — unattended does not mean
unchecked.

## Phase 1: Plan (in plan mode)

1. Resolve the governance root: walk up from CWD to the nearest
   ancestor containing SPEC.md; fall back to the repository root.
   Read REQUIREMENTS.md (if present),
   SPEC.md, ROADMAP.md at the governance root, and project rules.
   If operating on a package (governance root is not the repo root),
   also read root SPEC.md as upstream architectural context. All
   upstream documents provide layered context for implementation
   decisions.
2. Identify the target workstream(s). If a specific workstream was
   passed, scope to that. Otherwise, identify unblocked workstreams
   and skip anything marked blocked.
3. **Stay within one ROADMAP section.** The dispatch layer selects
   workstreams depth-first — all workstreams in a batch belong to
   the same section. Do not pull in workstreams from other sections
   to fill capacity. A smaller, cohesive batch is better than a
   larger, scattered one.
4. **Order for vertical integration.** Workstreams that change
   shared interfaces go first; surface-touching workstreams (UI,
   API endpoints, CLI commands) go last. The surface workstream is
   the integration point that consumes the layers beneath it — it
   wires the batch into a testable vertical slice. If the batch
   has no surface workstream, it is a horizontal layer — flag this
   to the dispatch layer and request guidance.
5. **Identify integration surface.** For each workstream, state
   where the new code connects to the product's visible surface
   (UI component, API endpoint, CLI command, configuration option,
   etc.). If a workstream produces only internal plumbing with no
   path to a user-facing surface in *this* batch, either wire it
   into a consuming surface or defer it until the consuming
   workstream is ready. Horizontal layers cannot be
   integration-tested and their fitness against the spec is
   unverifiable.
6. Write the execution plan as an ordered list of workstreams in
   dependency order, with the integration surface for each.
7. If `--unattended`, proceed immediately. Otherwise, wait for user
   approval before proceeding.

## Phase 2: Setup

1. Fetch origin and resolve the integration **trunk** — the branch a
   finished batch lands on. The dispatch layer passes `$trunk`; if it
   did not, resolve it from the repository's own default branch (do
   not hardcode `main`):

   ```sh
   trunk="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's@^origin/@@')"
   [ -z "$trunk" ] && trunk="$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null)"
   [ -z "$trunk" ] && trunk=main
   ```

   Verify `origin/$trunk` is current. Use `$trunk` and `origin/$trunk`
   everywhere a trunk branch is referenced below. For symphonize's own
   repository this resolves to `main`.
2. Verify you are in a worktree (not the user's main checkout).
   Confirm with: `git worktree list` — your working directory
   should appear as a linked worktree, not the main working tree.
3. Discover the CI command. Read `.github/workflows/ci.yml` (or
   the workflow that runs on `pull_request`). Find the shell command
   in the analysis/test step (e.g. `bash tools/ci.sh`, `make ci`,
   `npm test`). Record it — this is the command you run in Phases
   3 and 4. If the workflow delegates to a script, use the script
   directly. If no CI workflow exists, fall back to whatever
   analysis/test commands the project rules specify.
4. Record your worktree path, branch name, and CI command. After
   context compaction, re-read this file and the plan before
   continuing.

## Phase 3: Implement (inline, sequential)

The batch agent implements every workstream itself, in its own turn.
It spawns no sub-agents — a sub-agent cannot fan out (§spec:batch-agent-leaf).
Vertical-first selection (§spec:vertical-first-batch-selection) makes
each batch a dependency chain, sequential by construction, so inline
execution forfeits no available parallelism.

For each workstream, in the dependency order set in Phase 1:

1. Implement it following the project's standard workflow — test-first
   for code tasks, change-then-verify for operational tasks.
2. Commit with one conventional-commit message
   (`<type>(<scope>): <description>`). One logical change per commit;
   if a message needs "and," split it.
3. Run the CI command discovered in Phase 2 before moving to the next
   workstream, so cross-workstream breakage surfaces early. Fix
   failures before continuing — do not accumulate them across
   workstreams.

The batch agent stays warm across all workstreams: it carries the plan
and integration context in one window, so each workstream builds on the
last without re-establishing context.

## Phase 4: Verify

When all workstreams are implemented:

1. Run the CI command discovered in Phase 2. This is the
   definitive check — not individual tool invocations. The CI
   command covers formatting, analysis, tests, and any other
   project-specific gates in one pass. Do not push until it
   passes.
2. Check for DDD/Clean Architecture compliance if the project
   requires it.
3. Review lints and static analysis — tighten where appropriate.
4. **Verify vertical integration.** For each ROADMAP section in
   the batch, check for `**Verify:**` criteria written by
   `/roadmap`. If present, execute or validate each criterion
   — these are the pre-defined acceptance tests for the vertical
   slice. If absent, confirm that new code is reachable from the
   product's visible surface identified in Phase 1 by describing
   a concrete user-level test path (e.g., "invoke CLI command X,
   observe output Y"). Code that passes unit tests but is
   unreachable from any user-facing entry point is a horizontal
   layer, not a vertical slice — do not ship it. If the project
   has an existing integration test suite, add a test exercising
   the new surface.
5. **Boy Scout Rule — clean up orphaned layers.** If, during
   implementation, you encountered dead code, unintegrated plumbing,
   unused imports, or orphaned registrations in files you modified,
   clean them up in a separate commit. Scope cleanup to files the
   batch already touches — do not audit the entire codebase. Leave
   the code better than you found it.
6. Remove completed workstreams from ROADMAP.md and commit.
7. Update SPEC.md status lines for any sections now complete or
   newly in progress.
8. Compress newly completed spec sections. A completed section
   shifts from guiding implementation to documenting the running
   system. **Retain** design rationale (constraints, tradeoffs,
   rejected alternatives), observable behavior, state machines and
   transition tables, and cross-references. **Remove** wire formats
   and protocol tables (point to the protocol's own docs), algorithm
   pseudocode and step-by-step detail (the code owns *how*), edge
   cases obvious from tests, and "shall" language that restates the
   code without rationale. Heuristic: cover a paragraph with your
   thumb — if the design intent survives, cut it; if the *why*
   disappears, keep it.

The review gates (`/simplify`, `/security-review`) do **not** run in
the batch agent. They run at the dispatch layer, against the branch
this agent returns — a leaf cannot spawn the reviewer sub-agents the
gates need, and a gate Skill would end this agent's turn before
delivery. The dispatch layer has a session loop, so the Skills run
there at full fidelity (§spec:batch-agent-leaf, §spec:simplify-gate,
§spec:pre-pr-review-gates).

## Phase 5: Deliver (return a pushed branch)

The batch agent's completion signal is a **pushed branch and a status
report** — not a PR. The dispatch layer runs the review gates and opens
the PR (§spec:batch-agent-leaf).

1. Push the batch branch to origin under its **conventional name**
   (`<type>/<scope>-<slug>`, e.g. `feat/harden-batch-delivery`). Never
   push under the `worktree-agent-<id>` name the isolation harness
   assigned to this worktree — that name is an implementation artifact,
   not a delivery branch. Create the conventional branch from the
   current HEAD before pushing if the checked-out branch is the
   harness-assigned one.
2. **Return the pushed branch name, the workstream slug(s), and a
   status report as your final message.** The report records which
   workstreams shipped, the CI result, and any gate-relevant context
   the dispatch layer needs (for example, "doc-only batch — the simplify
   gate skips"). This is the completion signal; the dispatch
   layer gates and delivers from the branch.
3. **If delivery cannot complete** — the push fails, or any blocker
   prevents returning a pushed branch — say so explicitly in your final
   message and leave the worktree committed. Do not report success. The
   dispatch layer adopts the committed worktree and finishes delivery
   from there (§spec:batch-delivery).
4. The worktree is cleaned up by the dispatch layer after delivery.

### Why a branch, not a PR

The batch agent is a leaf and cannot fan out, so it cannot run the
review gates (`/simplify` spawns parallel reviewers; both gates need an
independent cold reviewer a self-review cannot supply) or survive a gate
Skill (a Skill ends a sub-agent's turn, so any phase after it —
including delivery — is unreachable). The dispatch layer runs in the
main session, which has a session loop: there a Skill returns control,
and `/simplify`'s reviewers fan out. Returning a branch puts the seam
between the warm worker and the cold reviewers exactly where the
capability boundary falls (§spec:batch-agent-leaf).

The branch in origin is the durable handoff. If this agent fails to push,
the dispatch layer recovers from the worktree's committed work; in-band
resume of a stalled sub-agent is not assumable (§spec:batch-delivery).

## Principles

- **Thin vertical slices.** Every batch delivers a complete path
  from internal logic through to the product's user-facing
  surface. Each slice is independently deployable, testable from
  the outside, and validates its spec section end-to-end. A
  horizontal layer (database schema, service class, utility
  module) is none of these — it ships inventory, not value.
  If a workstream is pure infrastructure, batch it with the
  workstream that consumes it so the slice ships value.
  (Cockburn, *Crystal Clear* — walking skeleton; Wake, "INVEST"
  — the "V" is Valuable.)
- **Boy Scout Rule.** Leave the code better than you found it.
  When modifying a file, clean up orphaned horizontal layers
  (dead code, unintegrated plumbing, unused imports) encountered
  in that file. Scope cleanup to files the batch already
  touches — this is continuous improvement, not a codebase audit.
  (Martin, *Clean Code* — Boy Scout Rule.)
- **Depth-first by section.** Each batch completes workstreams
  within one ROADMAP section before moving on. This keeps agent
  context coherent (one subsystem per batch), produces a vertical
  slice the user can integration-test rather than scattered
  plumbing, and surfaces bugs at wiring time rather than 4-5 PRs
  later.
- **Warm worker, cold reviewers.** The batch agent stays warm —
  it carries the plan and integration context across all phases in
  one window, so inline sequential work is cheap. The review gates
  run at the dispatch layer on a cold reviewer that did not write
  the code; independence is the property a gate exists to provide.
- **Worktree-only execution.** The batch agent runs in an isolated
  worktree. The user's main checkout is never touched. This allows
  parallel `/next` invocations without file-level conflicts.
- **Durable state.** ROADMAP.md and batch-agent.md survive
  compaction via Context Protection. Don't rely on conversation
  memory for execution state.

## Branching and commits

The batch agent owns the git work for the slice:

- Work on a feature branch — never commit to the trunk. One logical
  unit of work per branch (the batch). Branch naming
  `<type>/<scope>-<slug>` matches the commit scope (e.g.
  `feat/buffer-aware-execution`), never the `worktree-agent-<id>` name
  the isolation harness assigns. Create from `origin/$trunk` (the
  resolved trunk, Phase 2); deliver under the conventional name
  (Phase 5).
- One logical change per commit. If a commit message needs "and,"
  split it into two commits. Use conventional commits:
  `<type>(<scope>): <description>`, where type is one of
  feat fix docs style refactor perf test build ci chore revert.
  Semver mapping: feat = minor, fix = patch, `BREAKING CHANGE`
  footer or `!` = major.

## Quality Gate

A branch is not ready to hand off until analysis and tests pass with
zero failures and zero warnings from new code. Zero is the only
sustainable baseline — every "known failure" that ships becomes
invisible within a session; within two batches the failure count
drifts and real regressions hide behind the noise floor.

- Never hand off with failing tests. "Pre-existing" is not an excuse —
  fix it or delete it in the same branch.
- Never skip a failing test to unblock the handoff. A flaky, broken, or
  vacuous test is a defect. Fix or remove it with a commit
  explaining why.
- Warnings from new or modified code shall be resolved. Warnings from
  untouched code may be deferred to a lint-hardening workstream, but
  document them.

Two additions for batch work:

- After each workstream during Phase 3, run the CI command. Fix
  failures before starting the next workstream. Do not accumulate
  failures across workstreams.
- Never substitute individual tool invocations (MCP analyze, MCP
  test, etc.) for the CI command. Individual tools miss gates the
  CI script enforces (formatting, lint rules, coverage thresholds).
  The CI command is the single source of truth for "ready to hand off."
