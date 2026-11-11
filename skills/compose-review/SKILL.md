---
name: compose-review
description: Review a PR for correctness and taste — summarize changes and guide verification against the roadmap criteria
---

# compose:review

Find the installed plugin root by walking up from this SKILL.md to the
nearest directory containing `.codex-plugin/plugin.json`. Read
`plugins/compose/skills/review/SKILL.md` there in full and follow its workflow. Treat the user's text
after this skill's name as the command arguments.

For an existing git project, inspect its branch, working tree, remote state,
and open PRs before changing files. If the remote is unavailable, report that
limit before a change that depends on it. Follow the project's AGENTS.md.

Apply these Codex adaptations to the source instructions:

- A reference to `/$compose:review` means this skill. Other
  `/<group>:<command>` references mean `$symphonize:<group>-<command>`.
- `$1` means the user's arguments. Resolve `${CLAUDE_PLUGIN_ROOT}` to the
  installed plugin root's `plugins/compose` directory. Resolve bundled
  scripts, templates, and protocols from that directory.
- Use Codex worktrees and subagents where available. Do not assume a
  `.claude/worktrees/` directory or a Claude-assigned branch name. Use
  `git worktree list` for discovery.
- The package has no automatic hook. Check repo state explicitly before
  changing an existing project. No `/goal` turn loop runs in Codex.
