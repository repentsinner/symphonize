---
name: conduct-next
description: Execute roadmap workstreams
---

# conduct:next

Use this workflow for the named Symphonize task. Resolve paths under this installed plugin from this SKILL.md file. Treat the user's text after the skill name as its arguments. Follow the project AGENTS.md instructions. Before changing an existing git project, inspect its branch, working tree, remote state, and open PRs. If the remote is unavailable, report that limit before making a change that depends on it.

## Purpose

Execute the next unblocked ROADMAP workstream and deliver one reviewable PR.
The PR is the completion gate (§spec:batch-delivery). If delivery fails,
report the error and keep the worktree for recovery.

## 1. Resolve context

1. Find the nearest ancestor with SPEC.md. Use it as the governance root.
   If none exists, use the repository root.
2. Read REQUIREMENTS.md, SPEC.md, ROADMAP.md, and the repository's AGENTS.md.
   Read root governance files too when the governance root is a package.
3. Resolve the integration trunk from `refs/remotes/origin/HEAD`. If it is
   absent, use `gh repo view --json defaultBranchRef`.
4. Fetch origin. Check the current branch and working tree. Preserve user
   changes. Do not run this workflow in an unclean checkout unless a linked
   worktree can isolate all work.
5. Inspect `git worktree list` and remove only worktrees known to be complete.
   Do not assume Codex uses a fixed worktree directory or branch name.
6. Compare local work with remote and existing PRs before selecting a
   workstream. Do not redo a completed or in-progress workstream.

## 2. Select work

Read the active ROADMAP section. Select the next unattempted workstream whose
requirements are satisfied. If the user named a target, select it if it is
ready. Use the same vertical-slice and dependency rules in the roadmap.
If no ready work remains, report the blocker and stop.

## 3. Work in an isolated checkout

Create a linked git worktree from `origin/<trunk>` and a conventional branch
`<type>/<scope>-<slug>`. Use a unique path outside the user's main checkout.
If Codex subagents are available, delegate implementation to one subagent in
that worktree. Give it the selected workstream, governance context, and the
installed `resources/conduct/batch-agent.md` protocol. The subagent shall
implement and verify the work, commit, and return the branch; it shall not
open the PR. If subagents are unavailable, do those steps in the worktree
in this session. Never edit the user's main checkout to execute the batch.

The work shall reach a user-visible entry point. Run the existing checks for
changed behavior. Keep the branch's commits as the recovery source if the
agent stops or fails. Do not mark the workstream complete on agent return.

## 4. Review and deliver

Operate in the linked worktree. Confirm the branch is ahead of
`origin/<trunk>` and inspect its diff. For source changes, do one focused
simplification review. Do a security review of the diff and resolve findings.
Use available Codex review skills if present; otherwise perform the reviews
in this session. Run the relevant CI checks again after fixes.

Remove the shipped workstream from ROADMAP.md and commit that change. Push the
conventional branch, then open one PR against the resolved trunk. Include the
shipped workstream and how to verify it. Do not report success without a PR
URL. If push or PR creation fails, report the failure and worktree path.

## 5. Record result

After the PR exists, append `- <workstream-slug>: <PR-URL>` to
`.symphonize-progress.local.md` at the governance root. Report the PR URL,
verification results, and any skipped gate. Keep the worktree until the
branch has been delivered and its state is safe to clean.
