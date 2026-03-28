# symphonize — Roadmap

## Progress file location

Move symphonize's orchestration state out of `.claude/`.
Implements §spec:progress-file-location.

### §road:relocate-progress-file
Rename `.claude/.ralph-progress.local.md` to
`.symphonize-progress.local.md` (project root) in
`commands/next.md` and `commands/clean.md`. Four path
references total.

