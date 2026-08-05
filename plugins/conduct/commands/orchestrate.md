---
description: Loop /conduct:next over ROADMAP.md until the section is attempted
---
The governance root is determined by the current working directory
when this command is invoked. `/conduct:next` resolves the governance
root.

## Preconditions

The loop runs on Claude Code's first-party `/goal` command, which
requires:

- Claude Code 2.1.139 or later.
- An accepted workspace trust dialog — the goal evaluator is part of
  the hooks system.
- Hooks enabled. `/goal` is unavailable when `disableAllHooks` is set
  at any settings level, or when `allowManagedHooksOnly` is set in
  managed settings.

`/goal` starts turns; it does not grant permissions. Pair it with auto
mode for a genuinely unattended run.

If a precondition is unmet, name it to the user and stop — do not run
`/goal`.

## 1. Settle local state

Run `/conduct:clean --lite` before starting the loop.

## 2. Set the goal

Run `/goal` with this condition:

```text
Run /conduct:next --unattended to execute the next unblocked workstreams in the active ROADMAP.md section, depth-first. This goal is met when /conduct:next reports that all unblocked workstreams in the active section have been attempted and the section is blocked on review, or that ROADMAP.md holds no remaining workstreams. Stop after 20 turns if neither has been reported.
```

`/goal <condition>` sets the goal and starts the first turn — no
separate prompt follows it.

The evaluator reads only the conversation transcript; it runs no tools
and reads no files. The condition therefore keys on what
`/conduct:next` reports in its own output, not on repository state.

## Monitoring and early termination

- `/goal` with no arguments reports the condition, elapsed time, turns
  evaluated, token spend, and the evaluator's most recent reason.
- The goal clears itself once the condition is met, leaving the active
  ROADMAP section blocked on review with one PR per executed batch.
- To end the loop early, run `/goal clear`. `/clear` also removes it.

Non-interactive equivalent: `claude -p "/goal <condition>"` runs the
loop to completion in one invocation.
