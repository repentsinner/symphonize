# symphonize — Roadmap

## Requirements discovery

Add REQUIREMENTS.md to the governance file loop as the entry
point for new projects and features.

### §road:discover-command
Create `/symphonize:discover` command from
`product-interview.md`. Revise output format to produce
REQUIREMENTS.md (problem-space: user stories, constraints,
success criteria) instead of a PRD-style spec. Remove reference
to nonexistent `references/spec-template.md`.

### §road:plan-reads-requirements
Update `/symphonize:plan` to read REQUIREMENTS.md as input
when it exists. Fall back to direct user clarification if
absent. Depends on §road:discover-command.

### §road:init-scaffolds-requirements
Update `/symphonize:init` to scaffold an empty REQUIREMENTS.md
skeleton alongside the other governance files. Depends on
§road:discover-command.

### §road:update-governance-docs
Update README.md governance files table and SPEC.md Plugin commands
pipeline to include REQUIREMENTS.md as the fourth governance
file. Depends on §road:discover-command.
