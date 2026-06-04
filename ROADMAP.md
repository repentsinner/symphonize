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

## Relocate CONVENTIONS.md content

Not blocked — proceeds against today's command files, which become the
compose and conduct plugins. Implements the content split in
§spec:governance-schema ("Where today's CONVENTIONS.md content goes"): the
structural grammar needs no replacement file because notation's linter is
its executable form, so only the methodology and process content move.

### §road:relocate-conventions-content

Move `CONVENTIONS.md`'s authoring methodology inline into the compose
commands (`discover`/`plan`/`roadmap`) and its process discipline into the
conduct commands (`next`/`orchestrate`/`clean`) and
`protocols/batch-agent.md`, then delete `CONVENTIONS.md`.
§spec:governance-schema

**Verify:** `discover`/`plan`/`roadmap` carry the authoring methodology
inline; `next`/`orchestrate`/`clean` and `batch-agent.md` carry the process
discipline; `CONVENTIONS.md` is deleted with no command referencing it;
governance-lint passes.

## Scaffolding freshness

### §road:scaffold-consumer-dependabot

Add a `.github/dependabot.yml` (`github-actions`) to the files
`/symphonize:init` scaffolds, and document the scaffold-current-state /
delegate-freshness contract in `commands/init.md`. §spec:scaffold-freshness

**Verify:** a repo scaffolded by `/symphonize:init` contains a
`.github/dependabot.yml` enabling weekly `github-actions` updates;
`commands/init.md` and §spec:scaffold-freshness agree on the contract;
governance-lint passes. The dependabot scaffolding lives with the `init`
scaffolder — `commands/init.md` today, the notation plugin once the
decomposition (§spec:governance-schema) builds it out.
