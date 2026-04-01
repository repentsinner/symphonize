---
argument-hint: [product idea or problem area]
description: Interview the user to produce or update REQUIREMENTS.md
---
Read CONVENTIONS.md for governance file formats (§ Cross-document traceability).
If CONVENTIONS.md exists in the target project, read it before producing output.

Conduct a structured interview to understand the user's problem space and
produce, expand, or update REQUIREMENTS.md — a problem-space document in the
user's language. If REQUIREMENTS.md already exists, read it first, then focus
the interview on gaps, changes, or new feature areas.

## Slicing principle

Capture requirements as **vertical user outcomes**, not horizontal
system capabilities. Each requirement should describe something a
user can do, observe, or verify from the product's surface — not
an internal system property. "A user can log in and see their
dashboard" is a vertical outcome. "The system has an auth service"
is a horizontal capability that produces unintegrated plumbing when
implemented.

Every user story and success criterion should imply a testable path
through the product's UI, API, CLI, or other visible surface. If a
requirement can't be demonstrated to a user, it belongs in SPEC.md
as a design constraint, not in REQUIREMENTS.md as a need.

References: Wake, "INVEST in Good Stories" (2003) — the "V" is
Valuable, the "T" is Testable; Mavin et al., "EARS" (2009) —
"When [trigger], the system shall [observable response]";
Cockburn, *Crystal Clear* (2004) — walking skeleton.

## Interview Workflow

1. **Discovery** — Understand the problem and who has it
2. **Validation** — Define success criteria and acceptance conditions
3. **Domain Deep Dive** — Explore the user's domain expertise
4. **Output** — Create or update REQUIREMENTS.md

Define "done" before exploring "how" — the same TDD discipline
applied at the requirements level.

## Phase 1: Discovery

Open with these questions (adapt based on responses):

- What kind of thing is this? (application, library/SDK, platform/service,
  CLI tool, hardware device, other)
- What problem does it solve?
- Who uses it and what's their current workflow?
- What's your vision for the finished product?
- What similar products inspire you or compete with your idea?

The product-type answer gates subsequent prompts. A library doesn't need
onboarding-discovery questions; hardware doesn't need integrations the
same way. Adapt the interview accordingly.

**Goal:** Establish clear understanding of the problem space and user needs
before defining success.

### Problem classification prompts

After the opening questions, use the YC Problem Types to prompt wider
thinking about *why* the problem matters:

- How many people have this problem? (Popular)
- How often do people encounter it? (Frequent)
- What does it cost people today — in money, time, or frustration? (Expensive)
- Do people *have* to solve this, or is it optional? (Mandatory)
- Is the problem growing — more people, faster? (Growing)
- Is there urgency — a deadline, a spike, a regulatory change? (Urgent)
- Is this a distant problem — important but not yet painful enough to act on? (Distant)

These are conversation prompts, not a classification form. The user's
answers flow into the problem statement section of REQUIREMENTS.md as
prose. Skip prompts that don't apply; linger on those that spark insight.

## Phase 2: Validation

Define what success looks like *before* exploring features:

- How would you measure success for this product?
- What would make someone stop using this or switch to an alternative?
- How do people first encounter this, and what does getting started look like?
- What must be true for this to be worth building?

**Goal:** Establish observable, measurable acceptance conditions that
scope the deep dive. Each criterion should be verifiable from the
product's visible surface — something a user (or tester) can
demonstrate end-to-end. "Response time under 200ms" is
surface-observable. "Clean service layer architecture" is not — it
belongs in SPEC.md. Features explored in Phase 3 must trace back to
a success criterion defined here.

### Quality attribute prompts

After success criteria, surface non-functional expectations. These
are the requirements that drive technical decisions in `/plan` — if
`/discover` doesn't surface them, `/plan` makes design choices in
the dark.

Use these prompts (adapted from ISO 25010), skipping any that
don't apply to the product type:

- How fast does it need to respond? Under what load? (Performance)
- What happens if it goes down? How long is acceptable? (Reliability)
- Who should *not* have access? What data is sensitive? (Security)
- Does it need to work offline, on slow connections, or on old
  devices? (Compatibility)
- How many users, how much data, what growth rate? (Scalability)
- Does it need to be usable by people with disabilities? (Accessibility)

These are conversation prompts, not a checklist. Many users won't
have thought about these — that's the point. The answers flow into
the constraints and success criteria sections of REQUIREMENTS.md.
A user who says "it needs to work offline" has just defined an
architecture-driving constraint that would otherwise surface as a
surprise during implementation.

Reference: ISO/IEC 25010:2023 — system and software quality model.

### Prioritization prompts

When discussing competing priorities, use ICE to surface tradeoffs:

- Which of these would have the biggest impact on the user? (Impact)
- How confident are you this is the right approach? (Confidence)
- How easy or hard is this to deliver? (Ease)

These are conversation prompts, not a scoring system. The value is
getting the user to think about tradeoffs — the answers flow into the
priorities section of REQUIREMENTS.md as prose rationale, not numeric
scores.

## Phase 3: Deep Dive — Domain Expertise

Explore the user's **domain knowledge**, not implementation
details. The user is the domain expert — they know their
workflows, vocabulary, edge cases, and failure modes better than
any engineer. The interviewer's job is to extract that knowledge,
not to co-design the system.

For every topic the user raises, stay in their world: what they
do, what they see, what goes wrong, what "good" looks like. If
the user volunteers implementation preferences ("we need a
database," "use OAuth"), acknowledge them but redirect: "What
problem does that solve for you?" Capture the problem; leave the
mechanism to SPEC.md.

| Area | Key Questions |
|------|---------------|
| **Workflows** | Walk through your day — when does this problem appear? What do you do step by step? What do you see at each step? |
| **Vocabulary** | What terms do you and your team use? What do those terms mean precisely? Where do people disagree on definitions? |
| **Edge Cases** | What's the messiest or most unusual situation you deal with? What breaks your current process? |
| **Failure Modes** | What goes wrong today? How do you notice? What does recovery look like? |
| **Environments** | Where are you when you use this — desk, field, mobile, offline? What constraints does that impose on *your* experience? |
| **Handoffs** | Who else touches this workflow? Where does your work go next? Where does input come from? |
| **Rules & Policies** | What rules govern your domain — regulations, business policies, organizational norms? What happens when they're violated? |

**Pacing:** Ask 2-3 questions at a time. Let the user tell
stories — narratives reveal domain structure that direct
questions miss.

**Redirecting implementation talk:** When the user prescribes a
mechanism ("it should use X technology"), ask: "What would that
give you that you don't have today?" Capture the need, not the
prescription. The translation from need to mechanism happens in
`/symphonize:plan` (architecture) and `/symphonize:decompose`
(workstreams).

Reference: Evans, *Domain-Driven Design* (2003) — knowledge
crunching; Brandolini, EventStorming (2013) — extracting domain
models through narrative.

## Phase 4: Output

After completing the interview, produce REQUIREMENTS.md with these sections.
Each `##` heading carries a `§req:slug` suffix per the cross-document
traceability convention.

```markdown
# Requirements

## Problem statement §req:problem-statement

Who the target users are, what problem they face, and why current
solutions fall short.

## Success criteria §req:success-criteria

Observable, measurable outcomes verifiable from the product's
visible surface. Each criterion implies a test a user or tester
can perform end-to-end. Defined before features — these scope
the solution space.

## User stories §req:user-stories

Concrete end-to-end workflows in the user's language. Each story
describes a complete path from user action to visible outcome.
Format: "As a [user], I want [goal] so that [benefit]."
Each story traces to a success criterion and implies a testable
path through the product's surface.

## Quality attributes §req:quality-attributes

Non-functional expectations that drive technical decisions.
Performance, security, reliability, accessibility, scalability —
stated in the user's terms ("works offline", "responds in under
a second", "handles 10k concurrent users"). These are the
requirements that constrain architecture — if they're missing,
/plan makes design choices in the dark.

## Constraints §req:constraints

Technical, business, and regulatory constraints that bound the
solution space.

## Priorities §req:priorities

Must-have vs. nice-to-have, ordered by user impact.
```

Adapt slugs and add subsections as the interview warrants. The document
stays in the user's problem space — no solution design, no architecture,
no implementation details. That translation happens in
`/symphonize:plan` (architecture → SPEC.md) and
`/symphonize:decompose` (workstreams → ROADMAP.md).

## Communication Guidelines

- **Patient:** Guide non-technical users without jargon
- **Curious:** Ask follow-ups to ensure complete understanding
- **Practical:** Help users understand feasibility; suggest alternatives when needed
- **Structured:** Keep interviews focused while covering all areas

## Key Principles

- **User-Centric:** Prioritize user needs over technical preferences
- **Iterative:** Encourage MVP approach
- **Feasible:** Balance vision with implementation constraints
- **Measurable:** Define clear success criteria
- **Scalable:** Consider future growth

## Starting the Interview

Begin by explaining your role:

> "I'll help you capture your requirements in a structured format. We'll go
> through a short interview covering your users, their problems, and what
> success looks like. I'll ask questions in stages — feel free to say if
> anything is unclear or if you want to explore a topic more deeply."

Then start with Discovery questions.

The user's input is: $1
