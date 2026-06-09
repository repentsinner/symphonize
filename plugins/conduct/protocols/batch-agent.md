# Batch Agent Protocol

Agent-level instructions for executing a batch of ROADMAP.md
workstreams. The batch agent receives workstreams from the dispatch
layer (`/next`), manages sub-agent workers, merges their results,
and delivers a single PR as a **thin vertical slice** — a complete
path from internal logic through to a user-facing surface.
Project-agnostic — depends on projects following the SPEC.md/
ROADMAP.md governance convention.

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
6. Group workstreams into parallelizable sets where files don't
   overlap. Serial otherwise.
7. Write the execution plan as an ordered list of workstreams with
   their dispatch strategy (parallel or serial), expected
   file-touch overlap, and integration surface for each.
8. If `--unattended`, proceed immediately. Otherwise, wait for user
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
- **Base each sub-agent on the batch integration HEAD, not the
  trunk.** The worktree-isolation harness cuts a new worktree from
  the repository's default branch, and the batch branch is already
  checked out in this (parent) worktree, so a child cannot check it
  out by name. Immediately before spawning a sub-agent, capture the
  batch branch's current commit (`base_sha="$(git rev-parse HEAD)"`)
  and pass that SHA to the sub-agent. Instruct it to position its
  worktree there as its **first action**, before any work:
  `git reset --hard <base_sha>`. Linked worktrees share one object
  store, so the SHA is reachable even though the branch name is not.
  This makes the child inherit the planning foundation and every
  earlier-integrated workstream. For **serial** workstreams,
  re-capture `base_sha` after each cherry-pick (Phase 4) so the next
  child descends from the just-integrated commit — never from the
  bare trunk.
- Each sub-agent receives: the workstream slug, its ROADMAP.md
  description, the base commit SHA (above), and the project rules.
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

## Quality gates run as sub-agents, never as Skills

Phases 5a and 5b are mandatory quality gates, but the batch agent
**must not invoke `/simplify` or `/security-review` as Skills.** A Skill
invoked inside a sub-agent injects a self-contained task prompt; the
agent answers it and **ends its turn**. The main session has a session
loop that drives the next turn, so control returns after a Skill — but a
batch agent is itself a sub-agent with no such driver, so it stops, and
every protocol phase sequenced after the Skill (including Phase 6
delivery) becomes unreachable. This stall was observed twice in practice
(#165, #171): each agent committed its work, ran the gate as a Skill,
emitted the result, and ended its turn — Phase 6 never ran.
§spec:batch-delivery (skill-ends-sub-agent-turn).

Therefore each gate runs as an **`Agent` sub-agent** (`isolation:
"worktree"`), not as a Skill. A sub-agent's result returns to the batch
agent as a tool result, so control comes back and the protocol
continues. Instruct the reviewer sub-agent to perform the corresponding
review over the batch diff and **report findings as its final message**;
the batch agent then acts on those findings in its own turn. The
batch agent does not invoke the `/simplify` or `/security-review` Skills
directly under any circumstance.

## Phase 5a: Simplify Gate (mandatory)

After Phase 5 verification passes and before Phase 5b.
Implements §spec:simplify-gate.

1. **Skip-condition check.** Compute the changed-file list with
   `git diff --name-only "$(git merge-base HEAD "origin/$trunk")" HEAD`.
   If every changed path is a non-source file (markdown, YAML, or
   governance documents — SPEC.md, ROADMAP.md, REQUIREMENTS.md,
   CHANGELOG.md), skip the gate and record the skip in the batch
   agent's status report so the reviewer knows why Phase 5a did not
   execute. Proceed directly to Phase 5b.
2. **Single simplify sub-agent.** Spawn one `Agent` sub-agent to run a
   simplify pass over the batch diff and report its suggested fixes as
   its final message. Run it exactly once — simplify is an actuator, and
   iteration risks re-refactoring its own output. Do **not** invoke the
   `/simplify` Skill (it would end this agent's turn before Phase 6).
3. **Fix review with revert-on-conflict.** The batch agent applies the
   reviewer's fixes in its own turn, then inspects the diff. If any fix
   contradicts a deliberate design choice made during implementation
   (intentional inlining, deliberate duplication for independence,
   readability over DRY), revert that fix in a separate commit whose
   message explains the reversion.
4. **Mandatory CI re-run.** Run the CI command discovered in Phase 2
   after fixes (and any reversions) settle. Simplify-introduced
   regressions shall be diagnosed and fixed before proceeding.
5. **Handoff to Phase 5b.** Phase 5a transitions to the security gate so
   security scans the final, simplified code.

## Phase 5b: Security Review (mandatory gate)

After Phase 5a completes (or is skipped) and before pushing:

1. Spawn one `Agent` sub-agent to perform a security review of the batch
   diff and report findings as its final message. Do **not** invoke the
   `/security-review` Skill (it would end this agent's turn before
   Phase 6). For a diff that is entirely non-executable text (markdown,
   governance docs) with no attack surface, a brief inline assessment by
   the batch agent suffices in place of spawning the reviewer; record
   that judgement in the status report.
2. If the review reports findings, the batch agent resolves them in its
   own turn before proceeding. Re-review until clean.
3. A PR shall not be created with known security findings.

## Phase 6: Deliver (HARD COMPLETION GATE)

Delivery is a hard gate, not a best-effort final step. **The batch agent
does not report success until it has pushed a branch and opened a PR.**
A return without a PR URL is a failure, not a partial success — even if
every prior phase passed and the work is committed. Removing the shipped
workstream from ROADMAP.md (Phase 5 step 6) is part of this gate: the PR
that ships the work must also remove its ROADMAP bullet. §spec:batch-delivery

1. Push the batch branch to origin under its **conventional name**
   (`<type>/<scope>-<slug>`, e.g. `feat/harden-batch-delivery`). Never
   push under the `worktree-agent-<id>` name the isolation harness
   assigned to this worktree — that name is an implementation artifact,
   not a delivery branch. Create the conventional branch from the
   current HEAD before pushing if the checked-out branch is the
   harness-assigned one.
2. Open a single PR. Title: `feat: batch — <summary>`.
   Body lists each workstream as a bullet with its commit message.
   Include a recommendation for the reviewer:

   ```text
   > Run /review --comment to post code-quality findings as PR comments.
   ```

3. **Return the PR URL and workstream slug(s) as your final message.**
   This is the gate's success signal. Do not end your turn before the PR
   exists. If `--unattended`, do not wait for review; otherwise ask the
   user to review (and, if the project has a live-test protocol such as
   Dart MCP + DTD, prompt for specific things to test).
4. **If delivery cannot complete** — push fails, `gh pr create` fails, or
   any blocker prevents opening the PR — say so explicitly in your final
   message and leave the worktree committed. Do not report success. The
   dispatch layer's recovery path (see `commands/next.md`) adopts the
   committed worktree and finishes delivery from there.
5. The worktree is cleaned up automatically by the Agent tool when the
   batch agent exits.

### Why recovery, not resume

Delivery cannot depend on the dispatch layer resuming a stalled batch
agent in-band. `SendMessage`-based resume is gated behind Claude Code's
`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`, which is off by default and —
because the gate is read at module init — takes effect only through a
shell-level environment export before launch, not through
`settings.json`. It is also version-dependent. So in the common
configuration there is no way to drive a stalled batch agent to
completion. The batch agent's commits in the worktree are the durable
source of truth; if this agent fails to deliver, recovery happens from
those commits, not by resuming this turn. §spec:batch-delivery

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

## Branching and commits

The batch agent owns the git work for the slice:

- Work on a feature branch — never commit to the trunk. One logical
  unit of work per branch (the batch). Branch naming
  `<type>/<scope>-<slug>` matches the commit scope (e.g.
  `feat/buffer-aware-execution`), never the `worktree-agent-<id>` name
  the isolation harness assigns. Create from `origin/$trunk` (the
  resolved trunk, Phase 2); deliver under the conventional name
  (Phase 6).
- One logical change per commit. If a commit message needs "and,"
  split it into two commits. Use conventional commits:
  `<type>(<scope>): <description>`, where type is one of
  feat fix docs style refactor perf test build ci chore revert.
  Semver mapping: feat = minor, fix = patch, `BREAKING CHANGE`
  footer or `!` = major.
- Final history: one squashed commit per workstream (Phase 4).

## Quality Gate

A branch is not ready to merge until analysis and tests pass with
zero failures and zero warnings from new code. Zero is the only
sustainable baseline — every "known failure" that ships becomes
invisible within a session; within two batches the failure count
drifts and real regressions hide behind the noise floor.

- Never merge with failing tests. "Pre-existing" is not an excuse —
  fix it or delete it in the same branch.
- Never skip a failing test to unblock a merge. A flaky, broken, or
  vacuous test is a defect. Fix or remove it with a commit
  explaining why.
- Warnings from new or modified code must be resolved. Warnings from
  untouched code may be deferred to a lint-hardening workstream, but
  document them.

Two additions for batch work:

- After each cherry-pick during Phase 4, run the CI command. Fix
  failures before merging the next workstream. Do not accumulate
  failures across merges.
- Never substitute individual tool invocations (MCP analyze, MCP
  test, etc.) for the CI command. Individual tools miss gates the
  CI script enforces (formatting, lint rules, coverage thresholds).
  The CI command is the single source of truth for "ready to push."
