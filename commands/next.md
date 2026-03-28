---
argument-hint: [task or workstream]
description: Execute roadmap workstreams
---
You are the dispatch layer, not the orchestrator. Do not perform any
orchestration or git work in the current working tree beyond the
pre-flight steps below.

## 1. Pre-flight

Ensure local state is current before selecting work.

1. `git fetch --prune origin` — get latest refs, remove stale
   remote-tracking branches.
2. Delete local branches whose upstream is gone (tracking pruned
   remotes).
3. Remove any leftover worktrees from `.claude/worktrees/` and their
   backing git worktrees (`git worktree list`, `git worktree remove`
   for any linked worktrees that are no longer needed).
4. Read ROADMAP.md from `origin/main` (use `git show origin/main:ROADMAP.md`)
   — not the local working copy, which may be stale.

## 2. Detect unattended mode

Check if `--unattended` was passed as an argument. If present, set
`unattended = true`. Otherwise `unattended = false`.

If `unattended`, read `.symphonize-progress.local.md` (if it exists)
to get the list of workstreams already attempted this loop. Also run
`gh pr list --state open --author @me --json headRefBranch,title,url`
to cross-check.

## 3. Select workstream target (depth-first)

If `$1` is provided, use it. Otherwise, using the ROADMAP.md content
from step 1.4, select workstreams **depth-first by section**:

1. Identify the **active section** — the first ROADMAP section (in
   document order) that has at least one unblocked, un-attempted
   workstream. "Unblocked" means not marked blocked and not depending
   on a workstream still present in ROADMAP.md.
2. Take **all unblocked, un-attempted workstreams** in that section,
   up to a cap of 4. If the section has more than 4 unblocked
   workstreams, take the first 4 in document order.
3. Do **not** pull workstreams from other sections to fill the batch.
   A smaller batch within one section is better than a larger batch
   spanning unrelated sections — it keeps context coherent, PRs
   reviewable, and results integration-testable.
4. Cross-reference `.symphonize-progress.local.md` to skip
   workstreams already attempted this loop.

**When to advance sections:** only when every workstream in the
active section is either completed (removed from ROADMAP.md),
attempted this loop (in progress file), or blocked on an
un-attempted workstream in another section. In the blocked case,
switch to the section containing the blocker.

If no unblocked, un-attempted workstreams remain, report
"All unblocked workstreams attempted — blocked on review" and stop.
If `unattended`, also output:
```
<promise>BLOCKED ON REVIEW</promise>
```

## 4. Dispatch

Read the batch agent protocol:
`!cat ${CLAUDE_SKILL_DIR}/../BATCH_AGENT.md`

Spawn a single Agent with `isolation: "worktree"` and pass it:
- The full contents of the batch agent protocol above
- The workstream target(s) selected in step 3
- If `unattended`: the flag `--unattended`
- Instruction: "Follow the orchestrator protocol to implement this
  workstream from ROADMAP.md."

Wait for the agent to complete.

## 5. Record progress

If the agent returned a PR URL:
- Append a line to `.symphonize-progress.local.md`:
  `- <workstream-slug>: <PR-URL>`
- Create the file if it doesn't exist.

Relay the agent's result (PR URL, errors, or status) to the user.
