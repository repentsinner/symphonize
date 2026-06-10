---
argument-hint: [task or workstream]
description: Execute roadmap workstreams
---
You are the orchestrator. You select the batch, dispatch a batch agent
to implement it, then run the review gates and open the PR yourself
(§spec:batch-agent-leaf). The batch agent is a fan-out leaf — it
implements inline and returns a pushed branch; everything that needs to
fan out or survive a Skill invocation runs here, in the main session,
which has a session loop. Do all gate and delivery git work in an
isolated worktree against the returned branch — never in the user's main
checkout.

## 0. Resolve governance root

Resolve the governance root before selecting work:

<!-- assembled:governance-root -->
1. Walk up from the current working directory to find the nearest
   ancestor directory containing SPEC.md.
2. If no ancestor contains SPEC.md, fall back to the repository root.
<!-- /assembled:governance-root -->
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
4. Resolve the integration **trunk** — the branch a finished batch
   lands on — from the repository's own default branch; do not
   hardcode `main`. Read the remote's recorded default branch, falling
   back to `gh`, then to `main`:

   ```sh
   trunk="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's@^origin/@@')"
   [ -z "$trunk" ] && trunk="$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null)"
   [ -z "$trunk" ] && trunk=main
   ```

   Use `$trunk` and `origin/$trunk` wherever a trunk branch is
   referenced below, and pass `$trunk` to the batch agent. For
   symphonize's own repository this resolves to `main`.
5. Read ROADMAP.md from `origin/$trunk` at the governance root path
   (`git show "origin/$trunk:<governance-root-relative>/ROADMAP.md"`)
   — not the local working copy, which may be stale. For the repo
   root governance, this is `git show "origin/$trunk:ROADMAP.md"`.

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
from step 1.5, select workstreams by building dependency chains that
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
Consider running `/compose:roadmap` to add an integration
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
- The conduct plugin root: `${CLAUDE_PLUGIN_ROOT}` (so the
  batch agent can read `protocols/batch-agent.md`)
- The resolved integration trunk `$trunk` (step 1.4) — the branch
  the batch lands on; the agent cuts its branch from `origin/$trunk`
  and targets the PR there
- The workstream target(s) selected in step 3
- If `unattended`: the flag `--unattended`
- Instruction: "Implement this workstream from ROADMAP.md as a batch
  agent leaf: execute the workstreams inline and sequentially (spawn no
  sub-agents), then push a branch and return its name with a status
  report — do not open a PR. Deliver thin vertical slices — every batch
  must wire its code into the product's visible surface (UI, API, CLI,
  or other user-facing entry point). Code unreachable from any
  user-facing path is a horizontal layer, not a vertical slice — do not
  ship it. If you encounter orphaned horizontal layers from prior work
  (dead code, unintegrated plumbing, unused imports/registrations) in
  files you are already modifying, clean them up — leave the code better
  than you found it."

Wait for the agent to complete. It returns a pushed branch name and a
status report, not a PR.

## 5. Gate and deliver (primary path)

The batch agent returns a pushed branch; the orchestrator runs the
review gates against it and opens the PR. Delivery is a **hard
completion gate**: `/next` does not report success until a reviewed PR
exists. A batch that ends without a PR URL is a failure, not a partial
success. §spec:batch-agent-leaf §spec:batch-delivery

Run every step below in an **isolated worktree** on the returned branch,
never in the user's main checkout — gates may mutate files, and
worktree-only execution lets parallel `/next` invocations coexist.

1. **Locate the work.** Take the branch name from the agent's report and
   check it out in a fresh worktree:
   `git worktree add <path> <branch>`. If the agent reported a failure
   (no pushed branch), find its committed work under `.claude/worktrees/`
   (`git worktree list`); its branch is the harness-assigned
   `worktree-agent-<id>`, and its commits are the source of truth.
2. **Verify there is work to deliver.** Confirm the branch has commits
   ahead of `origin/$trunk`
   (`git -C <worktree> log --oneline "origin/$trunk..HEAD"`). If it has
   none, there is nothing to deliver — report the failure to the user
   and stop; do not open an empty PR.
3. **Run the simplify gate.** Unless every changed path is a non-source
   file (markdown, YAML, or governance documents — SPEC.md, ROADMAP.md,
   REQUIREMENTS.md, CHANGELOG.md), run the `/simplify` Skill against the
   branch's diff and apply its fixes. Run it once — simplify is an
   actuator; iterating risks re-refactoring its own output. If a fix
   contradicts a deliberate design choice the batch agent made
   (intentional inlining, duplication for independence, readability over
   DRY), revert that fix in a separate commit explaining the reversion.
   Record a skip in the result when the diff is doc-only.
   §spec:simplify-gate
4. **Run the security gate.** Run the `/security-review` Skill against
   the branch's diff and resolve every reported finding; re-review until
   clean. For a diff that is entirely non-executable text with no attack
   surface, a brief inline assessment suffices in place of the Skill;
   record that judgement. A PR shall not open with known security
   findings. §spec:pre-pr-review-gates
5. **Re-run CI** (the command from `.github/workflows/ci.yml`) after the
   gates settle. Do not push until it passes; fix or report blockers.
6. **Remove the shipped ROADMAP workstream(s)** for this batch from
   ROADMAP.md, if the agent did not already, and commit that change.
7. **Confirm the conventional branch.** The delivered branch follows
   `<type>/<scope>-<slug>`; never push the `worktree-agent-<id>` name.
   If the checked-out branch is the harness-assigned one, create the
   conventional branch from its HEAD. Push the branch (and any gate or
   ROADMAP commits) to origin.
8. **Open the PR.** Single PR targeting `$trunk`, body listing each
   shipped workstream and including:

   ```text
   > Run /review --comment to post code-quality findings as PR comments.
   ```

   If `unattended`, do not wait for review. Otherwise ask the user to
   review.

## 6. Record progress

Once the PR exists:
- Append a line to `.symphonize-progress.local.md` at the governance
  root: `- <workstream-slug>: <PR-URL>`
- Create the file if it doesn't exist.

Relay the result (PR URL, errors, or status) to the user. If the batch
agent stalled before pushing and the orchestrator recovered from its
worktree, note that.
