# Batch Agent Protocol

Agent-level instructions for executing a batch of ROADMAP.md
workstreams. The batch agent receives workstreams from the dispatch
layer (`/next`), manages sub-agent workers, merges their results,
and delivers a single PR as a **thin vertical slice** — a complete
path from internal logic through to a user-facing surface.
Project-agnostic — depends on projects following the SPEC.md/
ROADMAP.md convention defined in the symphonize CONVENTIONS.md
(path provided by the dispatch layer).

## Prerequisite

The batch agent MUST be running in a worktree created by the dispatch
layer (`next.md` spawns it with `isolation: "worktree"`). If
`git rev-parse --show-toplevel` matches the project root, STOP — you
are in the user's main checkout. Do not proceed.

## Unattended Mode

When the dispatch layer passes `--unattended` (ralph-loop active),
the batch agent skips interactive approval gates. All other quality
checks, CI runs, and conflict resolution remain unchanged — unattended
does not mean unchecked.

## Phase 1: Plan (in plan mode)

1. Resolve the governance root per the symphonize CONVENTIONS.md
   § Governance root (walk up from CWD to find nearest SPEC.md,
   fallback to repo root). Read REQUIREMENTS.md (if present),
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
6. Group workstreams into parallelizable sets where files don't
   overlap. Serial otherwise.
7. Write the execution plan as an ordered list of workstreams with
   their dispatch strategy (parallel or serial), expected
   file-touch overlap, and integration surface for each.
8. If `--unattended`, proceed immediately. Otherwise, wait for user
   approval before proceeding.

## Phase 2: Setup

1. Fetch origin and verify main is current.
2. Verify you are in a worktree (not the user's main checkout).
   Confirm with: `git worktree list` — your working directory
   should appear as a linked worktree, not the main working tree.
3. Discover the CI command. Read `.github/workflows/ci.yml` (or
   the workflow that runs on `pull_request`). Find the shell command
   in the analysis/test step (e.g. `bash tools/ci.sh`, `make ci`,
   `npm test`). Record it — this is the command you run in Phases
   4 and 5. If the workflow delegates to a script, use the script
   directly. If no CI workflow exists, fall back to whatever
   analysis/test commands the project rules specify.
4. Record your worktree path, branch name, and CI command. After
   context compaction, re-read this file and the plan before
   continuing.

## Phase 3: Dispatch

- Spawn one sub-agent per workstream using the Agent tool with
  `isolation: "worktree"`.
- Parallel dispatch (multiple Agent calls in one message) for
  workstreams with no file overlap. Serial for workstreams that
  touch shared files or depend on earlier results.
- Each sub-agent receives: the workstream slug, its ROADMAP.md
  description, and the project rules.
- Sub-agents follow the project's standard workflow (test-first
  for code tasks, verify for operational tasks).

## Phase 4: Merge

After each sub-agent completes:

1. Cherry-pick its work into the batch branch.
   - Single-commit workstreams: `git cherry-pick <sha>`.
   - Multi-commit workstreams: `git cherry-pick --no-commit` all
     commits, then `git commit` with one conventional-commit message.
2. Resolve conflicts immediately. The batch agent owns conflict
   resolution — don't defer to the user unless genuinely ambiguous.
3. Run the CI command discovered in Phase 2 after each merge to
   catch cross-workstream breakage early. Fix before merging the
   next workstream.
4. One squashed commit per workstream in the final history.

## Phase 5: Verify

When all workstreams are merged:

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
6. Remove completed workstreams from ROADMAP.md.
7. Update SPEC.md status lines for any sections now complete or
   newly in progress.
8. Compress newly completed spec sections per the symphonize
   CONVENTIONS.md § Spec compression (path provided by the
   dispatch layer).

## Phase 5a: Simplify Gate (mandatory)

After Phase 5 verification passes and before `/security-review`.
Implements §spec:simplify-gate.

1. **Skip-condition check.** Compute the changed-file list with
   `git diff --name-only $(git merge-base HEAD origin/main) HEAD`.
   If every changed path is a non-source file (markdown, YAML, or
   governance documents — SPEC.md, ROADMAP.md, REQUIREMENTS.md,
   CHANGELOG.md), skip the gate and record the skip in the batch
   agent's status report so the reviewer knows why Phase 5a did not
   execute. Proceed directly to Phase 5b.
2. **Single `/simplify` invocation.** Run `/simplify` exactly once
   over the batch diff. Do not loop until clean — `/simplify` is an
   actuator, and iteration risks re-refactoring its own output.
3. **Fix review with revert-on-conflict.** After `/simplify` applies
   fixes, inspect the resulting diff. If any fix contradicts a
   deliberate design choice made during implementation (intentional
   inlining, deliberate duplication for independence, readability
   over DRY), revert that fix in a separate commit whose message
   explains the reversion.
4. **Mandatory CI re-run.** Run the CI command discovered in Phase 2
   after fixes (and any reversions) settle. Simplify-introduced
   regressions shall be diagnosed and fixed before proceeding.
5. **Handoff to Phase 5b.** Phase 5a transitions to `/security-review`
   so security scans the final, simplified code.

## Phase 5b: Security Review (mandatory gate)

After Phase 5a completes (or is skipped) and before pushing:

1. Run `/security-review`.
2. If `/security-review` reports findings, resolve them before
   proceeding. Iterate until the review passes clean.
3. A PR shall not be created with known security findings.

## Phase 6: Deliver

1. Push the batch branch to origin.
2. Open a single PR. Title: `feat: batch — <summary>`.
   Body lists each workstream as a bullet with its commit message.
   Include a recommendation for the reviewer:

   ```text
   > Run /review --comment to post code-quality findings as PR comments.
   ```

3. If `--unattended`, return the PR URL and workstream slug(s) to
   the dispatch layer. Do not wait for review.
   Otherwise, ask the user to review. If the project has a live-test
   protocol (e.g., Dart MCP + DTD), prompt the user with specific
   things to test and regressions to check.
4. The worktree is cleaned up automatically by the Agent tool
   when the batch agent exits.

## Principles

- **Thin vertical slices.** Every PR delivers a complete path
  from internal logic through to the product's user-facing
  surface. Each slice is independently deployable, testable from
  the outside, and validates its spec section end-to-end. A
  horizontal layer (database schema, service class, utility
  module) is none of these — it ships inventory, not value.
  If a workstream is pure infrastructure, batch it with the
  workstream that consumes it so the PR ships a vertical slice.
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
  context coherent (one subsystem per batch), produces PRs the
  user can integration-test (vertical slices, not scattered
  plumbing), and surfaces bugs at wiring time rather than 4-5 PRs
  later.
- **Worktree-only execution.** The batch agent and every sub-agent
  run in isolated worktrees. The user's main checkout is never
  touched. This allows parallel `/next` invocations without
  file-level conflicts.
- **Batch agent owns the merge.** Sub-agents implement. The batch
  agent integrates, resolves conflicts, and verifies.
- **Local merge, single PR.** Never open N PRs for N workstreams.
  One CI run, one review surface, one merge.
- **Fail fast.** Run tests after each cherry-pick, not just at
  the end. A conflict caught after 2 merges costs less than one
  caught after 9.
- **Durable state.** The plan lives in plan mode's built-in
  storage. ROADMAP.md and batch-agent.md survive compaction via
  Context Protection. Don't rely on conversation memory for
  execution state.
- **Sub-agent isolation.** Every sub-agent works in its own
  worktree. Monitor for shared-state pollution and correct
  immediately.

## Quality Gate

See the symphonize CONVENTIONS.md § Quality gate. The same rules apply to batch
work with two additions:

- After each cherry-pick during Phase 4, run the CI command. Fix
  failures before merging the next workstream. Do not accumulate
  failures across merges.
- Never substitute individual tool invocations (MCP analyze, MCP
  test, etc.) for the CI command. Individual tools miss gates the
  CI script enforces (formatting, lint rules, coverage thresholds).
  The CI command is the single source of truth for "ready to push."
