# symphonize — Roadmap

## Clean command safety

### §road:harden-supersession-check

Replace the heuristic PR-closing logic in `commands/clean.md` (full
mode, git housekeeping) with diff-level supersession verification.
Add remote-branch-deletion guard for open PRs. Per
§spec:clean-supersession-safety.

Changes to `commands/clean.md`:

- Replace the "close superseded PRs" bullet (line 41-42) with the
  four-step verification procedure from the spec (diff each unmerged
  commit, confirm all symbols present in main, cite the landing PR).
- Add a guard to the remote branch deletion bullet (lines 35-37):
  never delete remote branches for open PRs.

**Verify:** Run `/symphonize:clean --full` against a repo with an
open sub-agent PR whose title overlaps a merged PR but whose changes
are not in main. Confirm the PR is left open and its remote branch
is not deleted.

## Pre-PR review gates

### §road:security-review-gate

Add `/security-review` as a mandatory gate in
`protocols/batch-agent.md` between Phase 5 (Verify) and Phase 6
(Deliver). Add `/review --comment` as a recommendation in the PR
body template. Per §spec:pre-pr-review-gates.

Changes to `protocols/batch-agent.md`:

- Insert a new step after Phase 5 verification passes: run
  `/security-review`, resolve any findings before proceeding to
  Phase 6.
- In Phase 6 step 2 (PR body), add a line recommending the reviewer
  run `/review --comment` for code-quality findings.

**Verify:** Run `/symphonize:next` against a workstream. Confirm
the batch agent runs `/security-review` before pushing. Confirm the
PR body includes the `/review --comment` recommendation.
