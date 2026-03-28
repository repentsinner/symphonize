# symphonize — Roadmap

## Cross-document traceability

Namespaced slug references across governance files, with lint
validation.

### §road:per-file-lint
Refactor `governance-lint.yml` to apply different rules per
governance file. SPEC.md: status lines on `##`, defines
`§spec:`, references `§req:`. ROADMAP.md: `###` workstream
headings with `§road:`, references `§spec:`. REQUIREMENTS.md:
defines `§req:`. CHANGELOG.md: Keep a Changelog structure only.

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
