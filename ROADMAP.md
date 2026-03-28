# symphonize — Roadmap

## Self-contained conventions

Remove dependency on user's CLAUDE.md for governance file formats
and workflow rules. The plugin ships its own conventions.

- **extract-conventions**: Create `CONVENTIONS.md` at repo root
  with spec format, spec compression, roadmap format, changelog
  format, commit conventions, branching rules, and quality gate.
  Extract from the author's CLAUDE.md §§ Spec Format, Roadmap
  Format, Changelog Format, Commits and Versioning, Branching,
  Quality Gate.
- **update-batch-agent**: Replace all `CLAUDE.md §` references in
  `BATCH_AGENT.md` with inline rules or
  `!`cat ${CLAUDE_SKILL_DIR}/../CONVENTIONS.md`` references.
  Depends on extract-conventions.
- **update-commands**: Replace CLAUDE.md references in `plan.md`,
  `clean.md`, and `next.md` with conventions file references.
  Depends on extract-conventions.
- **update-readme-prerequisites**: Remove "following the
  conventions in your CLAUDE.md" prerequisite. Reference
  CONVENTIONS.md instead. Depends on update-commands.

## Requirements discovery

Add REQUIREMENTS.md to the governance file loop as the entry
point for new projects and features.

- **discover-command**: Create `/symphonize:discover` command
  from `product-interview.md`. Revise output format to produce
  REQUIREMENTS.md (problem-space: user stories, constraints,
  success criteria) instead of a PRD-style spec. Remove reference
  to nonexistent `references/spec-template.md`.
- **plan-reads-requirements**: Update `/symphonize:plan` to read
  REQUIREMENTS.md as input when it exists. Fall back to direct
  user clarification if absent. Depends on discover-command.
- **init-scaffolds-requirements**: Update `/symphonize:init` to
  scaffold an empty REQUIREMENTS.md skeleton alongside the other
  governance files. Depends on discover-command.
- **update-governance-docs**: Update README.md governance files
  table and SPEC.md section 1 pipeline to include REQUIREMENTS.md
  as the fourth governance file. Depends on discover-command.
