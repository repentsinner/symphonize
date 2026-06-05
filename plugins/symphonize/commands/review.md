---
argument-hint: [PR number or URL]
description: Review a PR — resolve conflicts, check out locally, guide integration testing
---

## Responsibility

`/review` helps the user validate a PR from `/next` or
`/orchestrate`. It resolves conflicts, checks out the branch
locally, summarizes changes, and guides the user through
integration testing based on the verification criteria written
by `/roadmap`.

```
/next → PR → /review → merge → /clean
```

## Steps

1. **Identify the PR.** If `$1` is provided, use it (number or
   URL). Otherwise, list open PRs (`gh pr list --state open
   --author @me`) and ask the user which one to review.

2. **Resolve conflicts.** Check if the PR has merge conflicts
   with main. If so, check out the branch, rebase onto
   `origin/main`, resolve conflicts, and force-push. Warn the
   user before force-pushing.

3. **Check out locally.** Switch to the PR branch so the user
   can run the application and test.
   ```
   gh pr checkout <number>
   ```

4. **Summarize changes.** Read the PR diff and provide a concise
   summary:
   - What spec sections does this PR implement?
   - What files changed and why?
   - What's new vs. what's modified?
   - Any architectural decisions or tradeoffs made?

5. **Extract verification criteria.** Read ROADMAP.md (from the
   PR branch) for `**Verify:**` blocks in the relevant sections.
   If verification criteria exist, present them as a checklist
   for the user. If they don't exist, infer integration test
   paths from the PR changes:
   - What user-facing surfaces were added or changed?
   - What should the user exercise end-to-end?
   - What regressions should the user watch for?

6. **Guide testing.** Present the verification checklist and help
   the user work through it:
   - Build/start the application if needed
   - Point the user to the specific screens, endpoints, or
     commands to test
   - Describe expected behavior for each check
   - Flag anything the PR changes that could affect existing
     functionality

7. **Report results.** After the user completes testing:
   - If everything passes: recommend merge, note any follow-up
     items
   - If issues found: help diagnose, suggest fixes, or flag for
     the implementation agent

## What /review does NOT do

- Does not approve or merge the PR — that's the user's decision
- Does not run automated tests — CI handles that
- Does not modify code — if fixes are needed, the user decides
  whether to fix inline or send back to `/next`

The PR to review is: $1
