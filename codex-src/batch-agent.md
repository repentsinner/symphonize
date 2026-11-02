# Codex batch implementation protocol

Work only in the linked worktree assigned by the dispatch workflow. Read
REQUIREMENTS.md, SPEC.md, ROADMAP.md, and AGENTS.md before editing. Select only
the assigned workstream. Implement a thin vertical slice that reaches a
user-visible entry point. Preserve unrelated user changes.

Run the repository's existing checks for changed behavior. Add a focused test
when it protects a real boundary or failure. Review the diff for correctness
and security. Commit only the assigned work with a Conventional Commit. Return
the worktree path, branch, commit, checks, and any blocker. Do not open a PR;
the dispatch workflow owns the final review and PR delivery gate.
