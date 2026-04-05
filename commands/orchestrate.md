---
description: Start ralph-loop to work through ROADMAP.md
---
The governance root is determined by the current working directory
when this command is invoked. `/symphonize:next` resolves the
governance root per `${CLAUDE_PLUGIN_ROOT}/CONVENTIONS.md`
§ Governance root.

Run `/symphonize:clean --lite` to ensure local state is clean before
starting the loop.

Then run `/ralph-loop:ralph-loop` with the following arguments:

```
"Run /symphonize:next --unattended to execute the next unblocked workstreams in the active roadmap section (depth-first). When /symphonize:next reports all unblocked workstreams are attempted, output <promise>BLOCKED ON REVIEW</promise>." --completion-promise "BLOCKED ON REVIEW"
```
