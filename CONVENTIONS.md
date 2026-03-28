# Conventions

Rules that symphonize enforces on projects using its governance loop.

## Governance file loop

Four documents form a directed chain from problem to shipped code:

| Document | Voice | Question | Layer |
|----------|-------|----------|-------|
| REQUIREMENTS.md | User's | What do we need? | Problem space |
| SPEC.md | System's | What does the system do? | Solution space |
| ROADMAP.md | Work queue | What remains to build? | Work planning |
| CHANGELOG.md | History | What shipped? | Release record |

Each layer provides context to the next. Implementation agents read
all three upstream documents — requirements, spec, and roadmap — not
just the workstream description. Requirements supply the "why behind
the why": when the spec says "do X because Y," the requirement says
"Y matters because user Z needs it for W." That context helps agents
make judgment calls at the edges of a workstream's scope.

Requirements and specification co-evolve. You need enough design to
validate requirements feasibility, and enough requirements to
constrain design. The boundary between them is where design decisions
happen — keep it explicit.

References:

- Nuseibeh, "Weaving Together Requirements and Architectures" (2001)
  — the Twin Peaks model: requirements and architecture co-evolve
- Mavin et al., "EARS" (2009) — structured natural-language
  requirements templates
- Singer, *Shape Up* (2019) — shaping and scoping before building
- ISO/IEC/IEEE 29148:2018 — separates stakeholder requirements
  (user language) from system requirements (system language)

## Spec format

SPEC.md is declarative: it describes the desired end state of the system,
not the steps to reach it. Read a spec as "the system is X" — not "do X."
After implementation, every statement in the spec should still read as a
true description of the running system.

Rules:

- State the problem first: what fails or is missing for the end user.
- Write declaratively. Describe what the system does, not what to change.
  "The API returns 404 for unknown IDs" — not "Add a 404 response for
  unknown IDs."
- Each section shall answer "why" — what decision was made and what
  constraint drove it. If the rationale is missing, the section is
  incomplete.
- When wrapping or integrating an external system, reference it — don't
  re-spec it. Document only deviations, scope boundaries, and decisions
  specific to this project.
- Write each criterion as observable behavior: "the system shall…" or
  "when X, the system shall Y." Model after EARS for structure, but
  don't force every line into rigid templates.
- Criteria must remain valid after implementation. If a criterion becomes
  nonsensical once the work is complete, it belongs in a commit message,
  not a spec.
- No implementation details. The spec survives if you swap the underlying
  mechanism.
- The spec shall be sufficient to reconstruct the project's design intent.
  A reader with no conversation history should understand what was built
  and why.
- Each `##` section shall carry a bare status line immediately after the
  heading (before body content):
  `*Status: not started | in progress | complete*`
  No additional detail (PR numbers, dates, descriptions) on the status
  line. Update status when work begins and when it merges. CI validates
  placement and values via governance-lint.
- Headings use slug-style `##` (unnumbered). `## Plugin commands` not
  `## 1. Plugin commands`.

Reference: Alistair Mavin et al., "EARS (Easy Approach to Requirements
Syntax)" (2009).

### Spec compression

A spec section serves two audiences at different times. Before
implementation, it guides the developer — the more detail, the fewer
ambiguities. After implementation, it serves as a verifiable description
of the running system and a record of design rationale.

When a spec section reaches `complete`, compress it. The section shifts
from guiding implementation to documenting the running system.

**Retain**:

- Design rationale ("Why X"): constraints, tradeoffs, rejected
  alternatives. Expensive to reconstruct; prevents re-litigation.
- Observable behavior: verifiable statements a reviewer can check
  against the running system.
- State machines and transition tables: compact, high-signal.
- Cross-references to other spec sections.

**Remove**:

- Protocol byte values, command tables, wire formats: reference material
  for the underlying protocol, not spec. Replace with a pointer to the
  protocol's own documentation.
- Algorithm pseudocode and step-by-step implementation detail: the code
  is the source of truth for *how*. The spec owns *what* and *why*.
- Enumerated edge cases obvious from the implementation or tests.
- "Shall" language that restates what the code does without adding
  rationale.

**Heuristic**: cover a paragraph with your thumb. If the section's
design intent survives, cut it. If the *why* disappears, keep it.

## Roadmap format

ROADMAP.md is imperative: it describes the work remaining to close
the gap between current state and the spec's target state.
Read a roadmap as "we need to do X" — not "the system is X."
The roadmap is a work queue, not a history log. It should stay small.

Rules:

- Derive from SPEC.md. Every roadmap item traces to a spec gap.
- Un-numbered `##` sections in build-dependency order. Earlier sections
  validate assumptions that later sections depend on.
- New work enters at the tail. Completed work leaves from the head.
- When a section or workstream completes, delete it from the roadmap.
  Conventional commit messages feed release-please, which records the
  history in CHANGELOG.md. The roadmap does not duplicate that record.
  Presence in the roadmap means the work is not done.
- Workstreams are `### §road:slug` headings under each section.
  Slugs are lowercase, hyphenated, grep-friendly
  (e.g. `§road:delete-noise-tests`, `§road:extract-protocol`).
- Size each workstream to fit one agent session (~200k tokens).
  If a workstream is too large, split it.
- Blocked workstreams stay under the section they belong to, annotated
  inline ("Blocked — reason. Unblocked when condition.").
- Dependencies between workstreams are stated inline
  (e.g., `Depends on §road:extract-core`).
- Update the roadmap when work starts and when it finishes. Stale
  entries erode trust in the document.
- Lives at repo root alongside SPEC.md.

Reference: CNCF open source roadmap best practices;
Mozilla Open Science "Intro to Roadmapping."

## Changelog format

CHANGELOG.md records what shipped. Follows Keep a Changelog
(<https://keepachangelog.com/en/1.1.0/>).

Rules:

- Lives at repo root.
- Always has an `## [Unreleased]` section at the top.
- Groups: Added, Changed, Deprecated, Removed, Fixed, Security.
- Dates in YYYY-MM-DD. Versions in reverse chronological order.
- Automation via release-please is preferred where available. Manual
  maintenance is acceptable until automation is configured.

## Commit conventions

- One logical change per commit. If a commit message needs "and," split
  it into two commits.
- Use conventional commits: `<type>(<scope>): <description>`
- Types: feat fix docs style refactor perf test build ci chore revert
- Semver mapping: feat = minor, fix = patch, BREAKING CHANGE footer
  or `!` = major.

## Branching

- Always work on a feature branch. Never commit directly to main.
- One logical unit of work per branch. A workstream, a bug fix, a
  feature — not a quarter's worth of refactoring.
- Branch naming: `<type>/<short-description>` matching the commit scope.
  Examples: `refactor/decouple-domain-logging`, `fix/parser-null-check`,
  `feat/buffer-aware-execution`.
- Create from `origin/main`. Merge or abandon within the session when
  possible. Long-lived branches accumulate merge pain.

## Cross-document traceability

Governance files use namespaced slug prefixes for grep-friendly
cross-document references.

| Prefix | File | Heading level |
|--------|------|---------------|
| `§req:` | REQUIREMENTS.md | `##` |
| `§spec:` | SPEC.md | `##` |
| `§road:` | ROADMAP.md | `###` |

Slugs are lowercase, hyphenated, and appended as a suffix on the
heading line:

```markdown
## Plugin commands §spec:plugin-commands
*Status: in progress*

### §road:slug-prefixes
Define namespaced slug convention…
```

SPEC.md and REQUIREMENTS.md carry `§prefix:slug` as a suffix on
each `##` heading. ROADMAP.md carries `§road:slug` on each `###`
workstream heading (existing convention).

Every document both defines its own slugs and references other
documents' slugs inline. References use the same `§prefix:slug`
syntax in body text:

```markdown
Depends on §road:extract-core.
Implements §req:batch-execution.
```

**Why namespaced prefixes:** plain slugs are ambiguous across files.
The `§prefix:` namespace makes references unambiguous and
machine-validatable — a linter can resolve each reference to
exactly one file and heading.

### Traceability chain

The governance files form a directed traceability chain:

```text
REQUIREMENTS.md → SPEC.md → ROADMAP.md → CHANGELOG.md
  (problem)       (design)    (work)       (history)
```

Each document links forward to its successor:

- **SPEC.md sections cite `§req:` sources.** Every spec section
  traces back to the requirement that motivated it. This answers
  "why does this spec section exist?" and ensures no spec section
  is invented without a stated need.
- **ROADMAP.md workstreams cite `§spec:` targets.** Every
  workstream traces to the spec section it implements. This
  answers "what does this work deliver?" and ensures no work is
  planned without a design.

Backward tracing works by searching references. To find all spec
sections that implement a requirement, search for `§req:slug` in
SPEC.md. To find all workstreams that implement a spec section,
search for `§spec:slug` in ROADMAP.md.

**Why a chain:** traceability creates a bidirectional audit trail
from user need to shipped code and back. When a requirement
changes, the chain identifies which spec sections and workstreams
are affected. When code ships, the chain traces it back to the
requirement it satisfies. CI validates the chain by checking that
every reference resolves — dangling references indicate gaps in
the trail.

## Quality gate

A branch is not ready to merge until analysis and tests pass with
zero failures and zero warnings from new code.

Rules:

- Never merge with failing tests. "Pre-existing" is not an excuse —
  fix it or delete it in the same branch.
- Never skip a failing test to unblock a merge. A flaky, broken, or
  vacuous test is a defect. Fix or remove it with a commit explaining
  why.
- Warnings from new or modified code must be resolved. Warnings from
  untouched code may be deferred to a lint-hardening workstream, but
  document them.
- Every "known failure" that ships becomes invisible within a session.
  Agents normalize it and stop investigating. Within two batches the
  failure count drifts and real regressions hide behind the noise floor.
  Zero is the only sustainable baseline.
