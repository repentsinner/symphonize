# Batch Agent Protocol

Agent-level instructions for executing a batch of ROADMAP.md
workstreams. The batch agent receives workstreams from the dispatch
layer (`/next`), manages sub-agent workers, merges their results,
and delivers a single PR. Project-agnostic — depends on projects
following the SPEC.md/ROADMAP.md convention defined in CONVENTIONS.md.

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

1. Read REQUIREMENTS.md (if present), SPEC.md, ROADMAP.md, and
   project rules. All three upstream documents provide layered
   context for implementation decisions.
2. Identify the target workstream(s). If a specific workstream was
   passed, scope to that. Otherwise, identify unblocked workstreams
   and skip anything marked blocked.
3. **Stay within one ROADMAP section.** The dispatch layer selects
   workstreams depth-first — all workstreams in a batch belong to
   the same section. Do not pull in workstreams from other sections
   to fill capacity. A smaller, cohesive batch is better than a
   larger, scattered one.
4. Determine dependency order — workstreams that change shared
   interfaces go first; pure additions and UI last.
5. Group workstreams into parallelizable sets where files don't
   overlap. Serial otherwise.
6. Write the execution plan as an ordered list of workstreams with
   their dispatch strategy (parallel or serial) and expected
   file-touch overlap.
7. If `--unattended`, proceed immediately. Otherwise, wait for user
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
4. Remove completed workstreams from ROADMAP.md.
5. Update SPEC.md status lines for any sections now complete or
   newly in progress.
6. Compress newly completed spec sections per CONVENTIONS.md §
   Spec compression.

## Phase 6: Deliver

1. Push the batch branch to origin.
2. Open a single PR. Title: `feat: batch — <summary>`.
   Body lists each workstream as a bullet with its commit message.
3. If `--unattended`, return the PR URL and workstream slug(s) to
   the dispatch layer. Do not wait for review.
   Otherwise, ask the user to review. If the project has a live-test
   protocol (e.g., Dart MCP + DTD), prompt the user with specific
   things to test and regressions to check.
4. The worktree is cleaned up automatically by the Agent tool
   when the batch agent exits.

## Principles

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
  storage. ROADMAP.md and BATCH_AGENT.md survive compaction via
  Context Protection. Don't rely on conversation memory for
  execution state.
- **Sub-agent isolation.** Every sub-agent works in its own
  worktree. Monitor for shared-state pollution and correct
  immediately.

## Quality Gate

See CONVENTIONS.md § Quality gate. The same rules apply to batch
work with two additions:

- After each cherry-pick during Phase 4, run the CI command. Fix
  failures before merging the next workstream. Do not accumulate
  failures across merges.
- Never substitute individual tool invocations (MCP analyze, MCP
  test, etc.) for the CI command. Individual tools miss gates the
  CI script enforces (formatting, lint rules, coverage thresholds).
  The CI command is the single source of truth for "ready to push."
