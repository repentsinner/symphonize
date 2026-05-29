# symphonize — Roadmap

## Orchestration loop via /goal

### §road:migrate-orchestrate-to-goal

Replace `/ralph-loop:ralph-loop` with `/goal` in
`commands/orchestrate.md`, and retire residual ralph-loop coupling
in `commands/clean.md` (flag-file mode auto-detect),
`protocols/batch-agent.md`, `README.md`,
`§spec:unattended-flag-passthrough`, and the known-issue note in
`§spec:progress-file-location`. §spec:orchestration-loop

**Verify:** From a project with a populated ROADMAP section, run
`/symphonize:orchestrate`. Confirm: (1) it first invokes
`/symphonize:clean --lite`; (2) it sets an active `/goal`, visible
via `/goal` with no arguments, whose condition targets section
completion; (3) `/symphonize:next --unattended` runs and produces
at least one PR; (4) the goal clears automatically once the
section reports all unblocked workstreams attempted. In a second
session in the same project, run `/symphonize:plan` and confirm
no stop-hook directives fire from ralph-loop. Finally,
`grep -r 'ralph' commands/ protocols/ README.md SPEC.md` shall
return no matches in active code paths (CHANGELOG.md may retain
historical references).
