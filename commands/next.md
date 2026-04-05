---
argument-hint: [task or workstream]
description: Execute roadmap workstreams
---
You are the dispatch layer, not the orchestrator. Do not perform any
orchestration or git work in the current working tree beyond the
pre-flight steps below.

Read `${CLAUDE_PLUGIN_ROOT}/CONVENTIONS.md` § Governance root for
the resolution algorithm.

## 0. Resolve governance root

Resolve the governance root before selecting work:

1. Walk up from the current working directory to find the nearest
   ancestor directory containing SPEC.md.
2. If no ancestor contains SPEC.md, fall back to the repository root.
3. All governance file reads (ROADMAP.md, SPEC.md, REQUIREMENTS.md)
   and writes (progress file) in subsequent steps are relative to
   the governance root, not the repository root.

## 1. Pre-flight

Ensure local state is current before selecting work.

1. `git fetch --prune origin` — get latest refs, remove stale
   remote-tracking branches.
2. Delete local branches whose upstream is gone (tracking pruned
   remotes).
3. Remove any leftover worktrees from `.claude/worktrees/` and their
   backing git worktrees (`git worktree list`, `git worktree remove`
   for any linked worktrees that are no longer needed).
4. Read ROADMAP.md from `origin/main` at the governance root path
   (use `git show origin/main:<governance-root-relative>/ROADMAP.md`)
   — not the local working copy, which may be stale. For the repo
   root governance, this is `git show origin/main:ROADMAP.md`.

## 2. Detect unattended mode

Check if `--unattended` was passed as an argument. If present, set
`unattended = true`. Otherwise `unattended = false`.

If `unattended`, read `.symphonize-progress.local.md` at the
governance root (if it exists) to get the list of workstreams
already attempted this loop. Also run
`gh pr list --state open --author @me --json headRefBranch,title,url`
to cross-check.

## 3. Select workstream target (chain-preferring)

If `$1` is provided, use it. Otherwise, using the ROADMAP.md content
from step 1.4, select workstreams by building dependency chains that
reach the user-facing surface. §spec:vertical-first-batch-selection

### 3.1 Identify the active section

Find the first ROADMAP `##` section (in document order) that has at
least one un-attempted workstream whose external dependencies are
satisfied. "External dependencies" are dependencies on workstreams
in *other* sections — these must already be completed (absent from
ROADMAP.md). Dependencies on workstreams *within the same section*
are resolved during chain building (step 3.3), not here.

Cross-reference `.symphonize-progress.local.md` to exclude
workstreams already attempted this loop.

### 3.2 Build the within-section dependency graph

For each un-attempted workstream in the active section:

1. Parse its `Depends on §road:slug` annotations.
2. Ignore dependencies on workstreams outside the section (those
   are blocking constraints — if unmet, the workstream is excluded
   from the graph entirely).
3. Ignore dependencies on workstreams already completed (removed
   from ROADMAP.md or recorded in the progress file).
4. The result is a directed acyclic graph (DAG) of within-section
   workstreams, where edges point from dependency to dependent.

### 3.3 Identify surface-reaching chains

A **surface workstream** is the last workstream in a section — per
`/roadmap` Phase 3 step 7, every section ends with a workstream
that wires into the product's visible surface. (If the section has
no recognizable surface workstream, treat the last workstream in
document order as the surface candidate.)

A **chain** is a path through the DAG from a root (no unmet
in-section dependencies) to a surface workstream. Enumerate all
maximal chains — paths that cannot be extended further at either
end within the graph.

### 3.4 Select the longest surface-reaching chain

1. Among the chains from step 3.3, select the longest chain that
   fits within the batch cap (currently 4 workstreams). If multiple
   chains have the same length, prefer the one whose root appears
   first in document order.
2. **Fill remaining capacity.** If the selected chain leaves room
   under the batch cap, add un-attempted workstreams from the same
   section that are independent (no dependency relationship with the
   selected chain) and that form their own complete
   surface-reaching chains. Do not add workstreams that would
   create a partial chain (dependency without its dependent, or
   dependent without its dependency).
3. **Fallback.** If no surface-reaching chain exists (all surface
   workstreams depend on incomplete cross-section work), fall back
   to selecting unblocked workstreams in document order up to the
   batch cap. "Unblocked" here means no unmet dependencies —
   neither within-section nor cross-section.

### 3.5 Order the batch

Sort selected workstreams in dependency order (topological sort):
dependencies before dependents. The batch agent builds the
foundation before the integration layer.

### 3.6 Check for integration surface

Scan the selected batch for at least one workstream that wires
into the product's visible surface (UI, API, CLI, config). Under
chain-preferring selection this should rarely fail — the chain
terminates at the surface workstream. But if it does (fallback
case), warn the user:

"Section '\<name>' has no workstream touching a user-facing
surface. PRs from this section will ship unintegrated code.
Consider running `/symphonize:roadmap` to add an integration
workstream."

If `unattended`, log the warning and continue — do not block
the loop, but include the warning in the agent's result.

### 3.7 Section advancement and termination

Do **not** pull workstreams from other sections to fill the batch.
A smaller batch within one section is better than a larger batch
spanning unrelated sections.

**When to advance sections:** only when every workstream in the
active section is either completed (removed from ROADMAP.md),
attempted this loop (in progress file), or blocked on an
un-attempted workstream in another section. In the blocked case,
switch to the section containing the blocker.

If no un-attempted workstreams with satisfiable dependencies
remain, report "All unblocked workstreams attempted — blocked on
review" and stop. If `unattended`, also output:

```
<promise>BLOCKED ON REVIEW</promise>
```

## 4. Dispatch

Read the batch agent protocol at
`${CLAUDE_PLUGIN_ROOT}/protocols/batch-agent.md`.

Spawn a single Agent with `isolation: "worktree"` and pass it:
- The full contents of the batch agent protocol you just read
- The symphonize plugin root: `${CLAUDE_PLUGIN_ROOT}` (so the
  batch agent can read CONVENTIONS.md at
  `${CLAUDE_PLUGIN_ROOT}/CONVENTIONS.md`)
- The workstream target(s) selected in step 3
- If `unattended`: the flag `--unattended`
- Instruction: "Follow the orchestrator protocol to implement this
  workstream from ROADMAP.md. Deliver thin vertical slices — every
  batch must wire its code into the product's visible surface (UI,
  API, CLI, or other user-facing entry point). Code unreachable
  from any user-facing path is a horizontal layer, not a vertical
  slice — do not ship it. If you encounter orphaned horizontal
  layers from prior work (dead code, unintegrated plumbing,
  unused imports/registrations) in files you are already modifying,
  clean them up — leave the code better than you found it."

Wait for the agent to complete.

## 5. Record progress

If the agent returned a PR URL:
- Append a line to `.symphonize-progress.local.md` at the governance
  root: `- <workstream-slug>: <PR-URL>`
- Create the file if it doesn't exist.

Relay the agent's result (PR URL, errors, or status) to the user.
