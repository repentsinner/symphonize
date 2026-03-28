# symphonize — Roadmap

## Fix next command shell injection syntax

### §road:fix-next-shell-expansion

The `/symphonize:next` command fails every invocation because the
dynamic file injection on line 68 uses wrong syntax: `!` outside
backticks instead of inside. Fix: swap to `` `!cat ...` `` per
Claude Code skill file convention.

Implements §spec:plugin-commands.

