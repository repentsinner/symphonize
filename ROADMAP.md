# symphonize — Roadmap

## Governance consistency

Fix inconsistencies found in the audit. All workstreams are
independent and unblocked.

### §road:fix-init-numbered-headings
Fix init.md scaffolding template: replace `## 1. <first section>`
with slug-style `## <first section> §spec:<slug>` to match
CONVENTIONS.md format rules. Add `§spec:` suffix and status line
to the SPEC.md skeleton. Add REQUIREMENTS.md skeleton to the
scaffolded files list.

### §road:document-requirements-sections
Document the standard REQUIREMENTS.md sections (problem statement,
success criteria, user stories, constraints, priorities) in
CONVENTIONS.md. Currently only defined in discover.md — should
live in conventions so any tool can produce conformant output.

### §road:lint-scope-docs
Document in lint.md that the plugin command runs markdownlint
only, while governance-lint.yml also validates status lines,
slug formats, cross-references, and (future) prose quality.
Users should know which checks they get locally vs. in CI.

### §road:markdownlint-glob-expansion
Add REQUIREMENTS.md and CHANGELOG.md to markdownlint globs in
governance-lint.yml. Currently only SPEC.md, ROADMAP.md, and
README.md are linted for markdown formatting.

### §road:governance-table-consistency
Ensure the governance files table is consistent across README.md,
SPEC.md, and CONVENTIONS.md — four files, same descriptions.
README.md still shows the three-file model in the governance
section body text.

## Prose linting

Add Vale-based prose quality checks to the governance-lint
workflow. Depends on §road:document-requirements-sections
(modal verb rules reference the conventions).

### §road:vale-integration
Add Vale to governance-lint.yml. Create a `Requirements` style
with rules for IEEE modal verbs (flag deprecated "must"/"will",
require "shall" for mandatory requirements), passive voice in
requirements, and filler phrases. Run against SPEC.md and
REQUIREMENTS.md. Depends on §road:document-requirements-sections.

### §road:init-scaffolds-vale
Update init.md to scaffold `.vale.ini` and
`styles/Requirements/` with the modal verb rules. Projects opt
in to prose linting by having these files. Depends on
§road:vale-integration.

## Requirements frameworks

Interview prompts drawn from established frameworks for
`/symphonize:discover`. Frameworks guide conversation — output
is prose, not structured forms.

### §road:yc-problem-types
Add YC Problem Types (Popular, Frequent, Expensive, Mandatory,
Growing, Urgent, Distant) as interview prompts in the discover
command's Phase 1 (Discovery). Use the taxonomy to prompt wider
thinking about why the problem matters — output is prose, not a
structured table. Document the taxonomy in CONVENTIONS.md as a
reference for interviewers.

### §road:ice-scoring
Add ICE framework (Impact, Confidence, Ease) as interview
prompts in the discover command's Phase 2 (Validation) for
surfacing priority tradeoffs. Use to prompt the user about
competing priorities — output is prose rationale, not numeric
scores. Document the framework in CONVENTIONS.md as a reference.
