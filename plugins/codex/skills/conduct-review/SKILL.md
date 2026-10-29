---
name: conduct-review
description: Integrate a PR — resolve conflicts and check out the branch locally for testing
---

# conduct:review

Use this workflow for the named Symphonize task. Resolve paths under this installed plugin from this SKILL.md file. Treat the user's text after the skill name as its arguments. Follow the project AGENTS.md instructions. Before changing an existing git project, inspect its branch, working tree, remote state, and open PRs. If the remote is unavailable, report that limit before making a change that depends on it.


## Responsibility

`/review` is the integration/merge half of PR review: it answers
"are we building it right" at the mechanical level — getting a PR
from `/next` or `/orchestrate` into a state where it can land. It
resolves conflicts with the integration trunk, rebases, and checks
out the branch locally so the user (or the taste half of review) can
exercise it.

The correctness/taste half — summarizing changes against the spec
and guiding verification against the roadmap `**Verify:**` criteria —
lives in `$symphonize:compose-review`. Run this half to land the branch; run
the compose half to judge whether the change is correct.

> This command holds only the integration/merge responsibilities and
> ships in the conduct plugin as `$symphonize:conduct-review`. The
> correctness/taste half ships in compose as `$symphonize:compose-review`.

```
/next → PR → /review (merge) + $symphonize:compose-review (taste) → merge → /clean
```

## Steps

1. **Identify the PR.** If `the user's arguments after the skill invocation` is provided, use it (number or
   URL). Otherwise, list open PRs (`gh pr list --state open
   --author @me`) and ask the user which one to review.

2. **Resolve conflicts.** Resolve the integration trunk from the
   repository's own default branch (do not hardcode `main`):

   ```sh
   trunk="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's@^origin/@@')"
   [ -z "$trunk" ] && trunk="$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null)"
   [ -z "$trunk" ] && trunk=main
   ```

   Check if the PR has merge conflicts with `origin/$trunk`. If so,
   check out the branch, rebase onto `origin/$trunk`, resolve
   conflicts, and force-push. Warn the user before force-pushing.
   For symphonize's own repository the trunk resolves to `main`.

3. **Check out locally.** Switch to the PR branch so the user
   can run the application and test.
   ```
   gh pr checkout <number>
   ```

4. **Hand off to verification.** Once the branch is checked out
   clean and conflict-free, the taste half (`$symphonize:compose-review`)
   summarizes the changes and guides the user through the
   roadmap verification criteria.

## What /review does NOT do

- Does not summarize changes against the spec or extract
  verification criteria — that's `$symphonize:compose-review`'s taste half
- Does not approve or merge the PR — that's the user's decision
- Does not run automated tests — CI handles that
- Does not modify code — if fixes are needed, the user decides
  whether to fix inline or send back to `/next`

The PR to review is: the user's arguments after the skill invocation
