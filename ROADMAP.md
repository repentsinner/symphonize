# symphonize — Roadmap

## Fix next command shell injection syntax

### §road:fix-next-shell-expansion

The `/symphonize:next` command fails every invocation because the
dynamic file injection on line 68 uses wrong syntax: `!` outside
backticks instead of inside. Fix: swap to `` `!cat ...` `` per
Claude Code skill file convention.

Implements §spec:plugin-commands.

## Update README to reflect current feature set

### §road:readme-refresh

README lags behind the codebase in several areas:

- **Tagline:** says "plain-language specifications into shipped PRs."
  Should reflect the full governance loop starting from requirements
  discovery. Something like "plain-language requirements into auditable
  specs into shipped PRs."
- **Missing `/symphonize:discover`:** absent from Usage narrative and
  API table. It is the entry point to the governance loop.
- **REQUIREMENTS.md underplayed:** governance loop narrative (lines
  65-67) skips requirements — jumps from SPEC.md to ROADMAP.md.
  Rewrite to include the requirements → spec translation step.
- **Vale prose linting invisible:** no mention of Vale, modal verb
  enforcement, or filler phrase detection. Add a brief section or
  bullet under Governance Lint. Add `vale` to prerequisites.
- **Lint scope mismatch:** README conflates the plugin command
  (`/symphonize:lint`, markdownlint only) with the CI workflow
  (markdownlint + status lines + slugs + cross-refs). Clarify
  that the local command is a subset.
- **Cross-document traceability absent:** the `§spec:`, `§road:`,
  `§req:` slug system is core to governance but unmentioned. A brief
  explanation or pointer to CONVENTIONS.md is sufficient.
- **Interview frameworks unmentioned:** YC Problem Types and ICE
  are used by `/symphonize:discover`. A one-liner acknowledging
  structured interview prompts is enough — detail lives in
  CONVENTIONS.md.

Do not over-document. README is an orientation doc, not a reference
manual. Point readers to CONVENTIONS.md for format rules and
BATCH_AGENT.md for the execution protocol.

Implements §spec:plugin-commands, §spec:governance-consistency.

