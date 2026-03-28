---
argument-hint: [task or workstream]
description: Plan spec and roadmap entries for a new task
---
Read CONVENTIONS.md for roadmap format rules (§ Roadmap format).

1. Create a planning worktree. Fetch origin and start from tip of main.
2. Read SPEC.md and ROADMAP.md to understand current state.
3. If the task lacks a supporting spec section, clarify with the user
   and draft one in SPEC.md before proceeding.
4. Explore the codebase to understand where the work lands — affected
   files, existing patterns, integration points. Use agents to
   parallelize exploration where useful.
5. Write workstream entries in ROADMAP.md under the appropriate section
   (or create a new section). Follow build-dependency order — new work
   enters at the tail unless it unblocks existing work. Each workstream
   gets a slug, brief description, and explicit dependency annotations.
   Size to one agent session (~200k tokens). Don't write sample code —
   the implementation team does their own due diligence.
6. Prioritize by: safety/alarm implications first, then user-visible
   features, then internal quality.
7. Commit updated SPEC.md and ROADMAP.md to a branch, push, and open
   a PR. Review with the user before merging.

The task goals from the user are: $1
