---
argument-hint: [app idea or problem area]
description: Interview the user to produce or update REQUIREMENTS.md
---
Read CONVENTIONS.md for governance file formats (§ Cross-document traceability).
If CONVENTIONS.md exists in the target project, read it before producing output.

Conduct a structured interview to understand the user's problem space and
produce, expand, or update REQUIREMENTS.md — a problem-space document in the
user's language. If REQUIREMENTS.md already exists, read it first, then focus
the interview on gaps, changes, or new feature areas.

## Interview Workflow

1. **Discovery** — Understand the problem and who has it
2. **Validation** — Define success criteria and acceptance conditions
3. **Deep Dive** — Explore features, workflows, and constraints
4. **Output** — Create or update REQUIREMENTS.md

Define "done" before exploring "how" — the same TDD discipline
applied at the requirements level.

## Phase 1: Discovery

Open with these questions (adapt based on responses):

- What problem does your app solve?
- Who is your target user and what's their current workflow?
- What's your vision for the final product?
- What similar apps inspire you or compete with your idea?

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

- How would you measure success for this app?
- What would make a user abandon your app?
- How do you envision users discovering and onboarding?
- What must be true for this to be worth building?

**Goal:** Establish observable, measurable acceptance conditions that
scope the deep dive. Features explored in Phase 3 must trace back to
a success criterion defined here.

## Phase 3: Deep Dive

Explore each area systematically, scoped by the success criteria
from Phase 2:

| Area | Key Questions |
|------|---------------|
| **User Experience** | Walk through a typical user journey step-by-step |
| **Core Features** | What are must-have vs. nice-to-have features? |
| **Data & Content** | What information does the app store, display, or process? |
| **Integrations** | External services or APIs needed? |
| **Technical Constraints** | Platform preferences, performance requirements? |
| **Business Logic** | Rules governing app behavior in different scenarios? |

**Pacing:** Ask 2-3 questions at a time. Don't overwhelm non-technical users.

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

Observable, measurable outcomes that define whether the product
succeeds. Defined before features — these scope the solution space.

## User stories §req:user-stories

Concrete workflows and scenarios in the user's language.
Format: "As a [user], I want [goal] so that [benefit]."
Each story traces to a success criterion.

## Constraints §req:constraints

Technical, business, and regulatory constraints that bound the
solution space.

## Priorities §req:priorities

Must-have vs. nice-to-have, ordered by user impact.
```

Adapt slugs and add subsections as the interview warrants. The document
stays in the user's problem space — no solution design, no architecture,
no implementation details. That translation happens in `/symphonize:plan`.

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
