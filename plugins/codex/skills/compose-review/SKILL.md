---
name: compose-review
description: Review a PR for correctness and taste — summarize changes and guide verification against the roadmap criteria
---

# compose:review

Use this workflow for the named Symphonize task. Resolve paths under this installed plugin from this SKILL.md file. Treat the user's text after the skill name as its arguments. Follow the project AGENTS.md instructions. Before changing an existing git project, inspect its branch, working tree, remote state, and open PRs. If the remote is unavailable, report that limit before making a change that depends on it.


## Responsibility

`$symphonize:compose-review` is the taste half of PR review: it answers "are
we building the right thing." It summarizes a PR from `$symphonize:conduct-next`
or repeated manual batches, maps it back to the spec sections it
implements, and guides the user through verifying the change against
the `**Verify:**` criteria `$symphonize:compose-roadmap` wrote.

The integration/merge half — conflict resolution, rebasing, checking
out the branch for testing — lives in `$symphonize:conduct-review`. Run the
conduct half to land the branch; run this half to judge whether the
change is correct and worth landing.

```
$symphonize:conduct-next → PR → $symphonize:compose-review (taste) + $symphonize:conduct-review (merge) → merge → $symphonize:conduct-clean
```

## Steps

1. **Identify the PR.** If `the user's arguments after the skill invocation` is provided, use it (number or
   URL). Otherwise, list open PRs (`gh pr list --state open
   --author @me`) and ask the user which one to review.

2. **Summarize changes.** Read the PR diff and provide a concise
   summary:
   - What spec sections does this PR implement?
   - What files changed and why?
   - What's new vs. what's modified?
   - Any architectural decisions or tradeoffs made?

3. **Extract verification criteria.** Read ROADMAP.md (from the
   PR branch) for `**Verify:**` blocks in the relevant sections.
   If verification criteria exist, present them as a checklist
   for the user. If they don't exist, infer integration test
   paths from the PR changes:
   - What user-facing surfaces were added or changed?
   - What should the user exercise end-to-end?
   - What regressions should the user watch for?

4. **Guide testing.** Present the verification checklist and help
   the user work through it:
   - Build/start the application if needed
   - Point the user to the specific screens, endpoints, or
     commands to test
   - Describe expected behavior for each check
   - Flag anything the PR changes that could affect existing
     functionality

5. **Report results.** After the user completes testing:
   - If everything passes: recommend merge, note any follow-up
     items
   - If issues found: help diagnose, suggest fixes, or flag for
     the implementation agent

## What $symphonize:compose-review does NOT do

- Does not resolve conflicts, rebase, or check out the branch —
  that's `$symphonize:conduct-review`'s integration/merge half
- Does not approve or merge the PR — that's the user's decision
- Does not run automated tests — CI handles that
- Does not modify code — if fixes are needed, the user decides
  whether to fix inline or send back to `$symphonize:conduct-next`

The PR to review is: the user's arguments after the skill invocation
