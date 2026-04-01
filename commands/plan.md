---
argument-hint: [task or feature area]
description: Technical decisions — explore design options and produce SPEC.md sections
---
Read CONVENTIONS.md for spec format rules (§ Spec format).

## Responsibility

`/plan` owns **SPEC.md** — the solution-space document that describes
what the system does and why. It takes requirements (from
REQUIREMENTS.md or the user directly) and produces spec sections with
architecture rationale, design decisions, and tradeoffs.

`/plan` does not write ROADMAP.md. Workstream decomposition is
`/decompose`'s job. `/plan` produces the spec that `/decompose`
reads.

```
/discover → REQUIREMENTS.md → /plan → SPEC.md → /decompose → ROADMAP.md → /next
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

## Phase 1: Check upstream

Before doing technical discovery, assess the state of requirements.
Apply backpressure proportional to the gap — fill inline when
possible, recommend `/discover` when the gap is too large.

1. Create a planning worktree. Fetch origin and start from tip of
   main.
2. Read SPEC.md and ROADMAP.md to understand current state.
3. **Check REQUIREMENTS.md.**
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

7. **Draft or update SPEC.md sections.** For each feature or
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
11. Commit updated SPEC.md to a branch, push, and open a PR. Review
    with the user before merging.

The task goals from the user are: $1
