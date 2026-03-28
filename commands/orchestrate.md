---
description: Start ralph-loop to work through ROADMAP.md
---
Run `/symphonize:clean --lite` to ensure local state is clean before
starting the loop.

Then run `/ralph-loop:ralph-loop` with the following arguments:

```
"Run /symphonize:next --unattended to execute the next unblocked workstreams in the active roadmap section (depth-first). When /symphonize:next reports all unblocked workstreams are attempted, output <promise>BLOCKED ON REVIEW</promise>." --completion-promise "BLOCKED ON REVIEW"
```
