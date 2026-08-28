---
argument-hint: [task or feature area]
description: Technical decisions — explore design options and produce SPEC.md sections
---
## 0. Resolve governance root

Resolve the governance root before reading or writing governance files:

<!-- assembled:governance-root -->
1. Walk up from the current working directory to find the nearest
   ancestor directory containing SPEC.md.
2. If no ancestor contains SPEC.md, fall back to the repository root.
<!-- /assembled:governance-root -->
3. All governance file reads and writes in subsequent steps are
   relative to the governance root, not the repository root.

When the governance root is not the repository root (package-level
governance), read root SPEC.md and root REQUIREMENTS.md as upstream
context. Root spec provides system-level architectural decisions and
cross-cutting constraints that package-level specs refine. Do not
modify root files — they are read-only context.

## Responsibility

`/plan` owns **SPEC.md** — the solution-space document that describes
what the system does and why. It takes requirements (from
REQUIREMENTS.md or the user directly) and produces spec sections with
architecture rationale, design decisions, and tradeoffs.

`/plan` does not write ROADMAP.md. Workstream decomposition is
`/roadmap`'s job. `/plan` produces the spec that `/roadmap`
reads.

```
/discover → REQUIREMENTS.md → /plan → SPEC.md → /roadmap → ROADMAP.md → /next
```

Each command reads upstream deliverables but writes exactly one.

## Slicing principle

Design for **thin vertical slices**, not horizontal layers. Every
spec section should describe a capability that is observable from
the product's user-facing surface (UI, API, CLI, config). A spec
section that describes only internal plumbing ("the system has a
caching layer") without connecting it to a user-observable behavior
will produce horizontal workstreams that ship dead code.

References: Cockburn, *Crystal Clear* (2004) — walking skeleton;
Wake, "INVEST in Good Stories" (2003) — the "V" is Valuable;
Cockburn, "Elephant Carpaccio" exercise — thin vertical slicing.

## Prose style

Every governance document this command writes is held to one standard.
The scaffolded Vale style enforces the mechanical half; the rest is
judgement.

<!-- assembled:prose-style -->
**Modal verbs, document-wide.** `shall` marks a requirement, `should` a
recommendation, `may` permission (IEEE SA Standards Style Manual).
`Must` and `will` are deprecated, and the scaffolded Vale style flags
them in *any* sentence of SPEC.md or REQUIREMENTS.md — narrative,
rationale and problem statements included, not criteria alone. Vale
matches per sentence and cannot tell a requirement line from a narrative
one, so the guidance matches the rule's reach rather than fighting it.
Prefer rephrasing to substitution: "the adopter re-maps each header"
beats "the adopter shall re-map each header" where nothing is required.

**Omit needless words.** Cut adverbs, qualifiers and hedges — `very`,
`really`, `basically`, `simply`, `just`. One idea per sentence. Prefer
the concrete noun and the active verb: "returns null", not "may
potentially result in an empty value."

**Filler phrases fail the linter.** `it should be noted that`, `in order
to` (use "to"), `due to the fact that` (use "because"), `it is important
to note`, `at this point in time`, `for the purpose of`.

**One term per concept.** Pick one of check / verify / confirm /
validate, one of config / settings, and hold it for the whole document.
Terseness rules cannot catch synonym rotation — every one of those words
is equally short.

**Condition before command.** "If the build fails, read the log" — not
the reverse.

**No self-evident commentary.** Do not assert that something is novel,
important or interesting. If it is, the reader notices.

These rules derive from Strunk & White, *The Elements of Style* —
Rule 17, "omit needless words"; the Google Developer Documentation
Style Guide (<https://developers.google.com/style>) — tone, voice and
conciseness; Gernot Heiser, "Notes on Writing"
(<https://gernot-heiser.org/style-guide.html>) — gainful compression
and passive-voice limits; and the IEEE SA Standards Style Manual —
modal verbs.
<!-- /assembled:prose-style -->

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
- Criteria stay valid after implementation. If a criterion becomes
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
  `## 1. Plugin commands`. Each `##` heading carries a `§spec:slug`
  suffix (title then slug), and cites `§req:` sources inline. A heading
  deeper than `##` may carry a `§spec:slug` suffix; it is required only
  to make that heading referenceable.

Reference: Alistair Mavin et al., "EARS (Easy Approach to Requirements
Syntax)" (2009).

### Spec compression

A spec section serves two audiences at different times. Before
implementation, it guides the developer — the more detail, the fewer
ambiguities. After implementation, it serves as a verifiable description
of the running system and a record of design rationale.

When a spec section reaches `complete`, compress it. The section shifts
from guiding implementation to documenting the running system.

<!-- assembled:spec-compression -->
**Retain** — design rationale (constraints, tradeoffs, rejected
alternatives), expensive to reconstruct and the thing that prevents
re-litigation; observable behavior a reviewer can check against the
running system; state machines and transition tables; cross-references
to other sections.

**Remove** — wire formats, protocol tables and command byte values
(point to the protocol's own documentation); algorithm pseudocode and
step-by-step detail (the code owns *how*, the spec owns *what* and
*why*); edge cases obvious from the implementation or its tests;
`shall` language that restates what the code does without adding
rationale.

**Heuristic** — cover a paragraph with your thumb. If the section's
design intent survives, cut it. If the *why* disappears, keep it.
<!-- /assembled:spec-compression -->

## Phase 1: Check upstream

Before doing technical discovery, assess the state of requirements.
Apply backpressure proportional to the gap — fill inline when
possible, recommend `/discover` when the gap is too large.

1. Create a planning worktree. Fetch origin and start from tip of
   main.
2. Read SPEC.md and ROADMAP.md at the governance root to understand
   current state. If operating on a package, also read root SPEC.md
   as upstream architectural context.
3. **Check REQUIREMENTS.md** (at the governance root).
   - **Absent:** assess the scope of the task. For a focused feature
     addition, capture the highlights inline — ask 3-4 key questions
     (who uses this, what problem does it solve, what does success
     look like) and proceed. For a greenfield product or a large
     feature set, recommend `/discover` — the gap is too large to
     patch inline. If the user declines, clarify requirements
     directly and proceed.
   - **Thin:** flag specific gaps (missing success criteria, vague
     user stories, no constraints). Fill them with targeted questions
     during this conversation. Don't bounce the user to `/discover`
     for a few missing paragraphs.
   - **Adequate:** proceed.

## Phase 2: Technical discovery

Explore the solution space with the user. `/discover` captured
*what* users need (domain discovery). This phase determines *how*
the system should satisfy those needs (technical discovery). The
two co-evolve — feasibility insights may reshape requirements, and
constraints from requirements narrow the architecture.

Invest design effort proportional to risk. A new button on an
existing screen needs no architecture discussion. A new persistence
layer, a protocol change, or a non-functional requirement (latency,
offline support, multi-tenancy) does.

4. Explore the codebase to understand where the work lands —
   affected files, existing patterns, existing architecture,
   integration points. Use agents to parallelize exploration where
   useful.

### For brownfield projects (existing codebase)

5. **Assess existing architecture.** Identify the patterns already
   in use — layering strategy, state management, API shape, data
   flow. New work should extend the existing architecture unless
   there's a specific reason to diverge. If divergence is needed,
   state why and get user agreement.
6. **Identify constraints and risks.** What quality attributes
   does this feature stress (performance, security, reliability,
   accessibility)? What existing assumptions does it challenge?
   Where could it break what already works?

### For greenfield projects (new codebase)

5. **Propose architectural approach.** Based on requirements and
   constraints, propose one or more approaches. For each, state:
   - The pattern (e.g., layered, hexagonal, event-driven, pipes
     and filters)
   - Why it fits the requirements and constraints
   - What it trades off (complexity, flexibility, performance)
   - Rejected alternatives and why
6. **Discuss technology choices.** Database, framework, API style,
   auth strategy, hosting model — whatever the feature requires.
   Propose options grounded in the requirements. Push back on
   choices that conflict with stated constraints or quality
   attributes. The user decides; the agent informs.

### Security awareness

When a spec section touches authentication, authorization, PII,
payment, file uploads, external input, or cross-system
communication, do a lightweight threat check:

- What could an attacker do here? (Abuse cases)
- What data is exposed if this component is compromised? (Blast radius)
- What input does this accept from untrusted sources? (Attack surface)

This is not a full threat model — it's proportional awareness.
A new admin dashboard needs more scrutiny than a color picker.
Record security-relevant decisions in the spec section's rationale
("rate-limited because the endpoint accepts unauthenticated
requests"). `/discover` may have surfaced security constraints —
check REQUIREMENTS.md § constraints.

Reference: Shostack, *Threat Modeling* (2014) — abuse cases;
OWASP ASVS — verification levels proportional to risk.

### Correcting XY problems

When the user prescribes a mechanism ("add a Redis cache," "use
microservices"), ask: "What problem does this solve for you?"
Capture the need, evaluate whether the prescribed mechanism is the
best fit, and propose alternatives if it isn't. The user may be
right — but the rationale should be explicit in the spec, not
implicit in an unexamined assumption.

Reference: Nuseibeh, "Weaving Together Requirements and
Architectures" (2001) — Twin Peaks model; Cervantes & Kazman,
*Designing Software Architectures* (2016) — ADD 3.0; Fairbanks,
*Just Enough Software Architecture* (2010) — risk-driven design.

## Phase 3: Write spec sections

7. **Draft or update SPEC.md sections** (at the governance root). For each feature or
   capability, write a spec section with:
   - Observable behavior (what the system does, verifiable from the
     surface)
   - Design rationale (why this approach, what constraints drove it)
   - Alternatives considered and why they were rejected
   - Tradeoffs accepted
   - `§req:` citations when requirements informed the decision
   - Status line: `*Status: not started*`

   The spec owns the *what* and *why*. Implementation detail (the
   *how*) lives in the code. A spec section should survive if you
   swap the underlying mechanism.

8. **Identify integration surface per section.** Each spec section
   should describe behavior observable from the product's visible
   surface. If a section describes only internal plumbing, either
   connect it to a user-observable behavior or merge it into the
   section that consumes it.

   If `--unattended`, make reasonable architectural choices aligned
   with existing patterns and stated constraints. Document the
   rationale in the spec so the user can review it in the PR.

## Phase 4: Review and deliver

9. **Review architecture rationale.** Does every spec section answer
   "why"? Are tradeoffs stated? Would a new contributor understand
   the design intent without conversation history?
10. **Check vertical coverage.** For each spec section, can you
    describe a user-level test path? If not, the section is a
    horizontal concern — refactor it.
11. Commit updated SPEC.md (at the governance root) to a branch,
    push, and open a PR. Review with the user before merging.

The task goals from the user are: $1
