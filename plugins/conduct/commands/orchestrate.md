---
description: Start ralph-loop to work through ROADMAP.md
---
The governance root is determined by the current working directory
when this command is invoked. `/conduct:next` resolves the
governance root (walk up from CWD to the nearest ancestor containing
SPEC.md; fall back to the repository root).

Run `/conduct:clean --lite` to ensure local state is clean before
starting the loop.

Then run `/ralph-loop:ralph-loop` with the following arguments:

```
"Run /conduct:next --unattended to execute the next unblocked workstreams in the active roadmap section (depth-first). When /conduct:next reports all unblocked workstreams are attempted, output <promise>BLOCKED ON REVIEW</promise>." --completion-promise "BLOCKED ON REVIEW"
```
