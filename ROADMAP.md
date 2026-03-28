# symphonize — Roadmap

## Governance consistency

Fix inconsistencies found in the audit. All workstreams are
independent and unblocked.

### §road:governance-table-consistency
Ensure the governance files table is consistent across README.md,
SPEC.md, and CONVENTIONS.md — four files, same descriptions.
README.md still shows the three-file model in the governance
section body text.

## Prose linting

Add Vale-based prose quality checks to the governance-lint
workflow.

### §road:vale-integration
Add Vale to governance-lint.yml. Create a `Requirements` style
with rules for IEEE modal verbs (flag deprecated "must"/"will",
require "shall" for mandatory requirements), passive voice in
requirements, and filler phrases. Run against SPEC.md and
REQUIREMENTS.md.

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
