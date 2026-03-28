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
