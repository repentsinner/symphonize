# symphonize — Roadmap

## Requirements discovery

Add REQUIREMENTS.md to the governance file loop as the entry
point for new projects and features.

### §road:plan-reads-requirements
Update `/symphonize:plan` to read REQUIREMENTS.md as input
when it exists. Fall back to direct user clarification if
absent.

### §road:init-scaffolds-requirements
Update `/symphonize:init` to scaffold an empty REQUIREMENTS.md
skeleton alongside the other governance files.

### §road:update-governance-docs
Update README.md governance files table and SPEC.md Plugin commands
pipeline to include REQUIREMENTS.md as the fourth governance
file.
