---
argument-hint: [task or workstream]
description: Plan spec and roadmap entries for a new task
---
Read CONVENTIONS.md for roadmap format rules (§ Roadmap format).

## Slicing principle

Plan **thin vertical slices**, not horizontal layers. Each ROADMAP
section should deliver a complete path from internal logic through
to the product's user-facing surface (UI, API, CLI, config). A
vertical slice is independently deployable, testable from the
outside, and validates its spec section end-to-end. A horizontal
layer (database schema, service class, utility module) is none of
these — it ships inventory, not value.

References: Cockburn, *Crystal Clear* (2004) — walking skeleton;
Wake, "INVEST in Good Stories" (2003) — the "V" is Valuable;
Cockburn, "Elephant Carpaccio" exercise — thin vertical slicing.

## Steps

1. Create a planning worktree. Fetch origin and start from tip of main.
2. Read SPEC.md and ROADMAP.md to understand current state.
3. If REQUIREMENTS.md exists, read it and use it as input for
   understanding the user's intent, constraints, and priorities. If it
   does not exist, recommend running `/symphonize:discover` first to
   capture requirements. If the user declines, clarify requirements
   directly and proceed — but note that problem-space rationale will
   live only in the spec's "why" sections, not in a dedicated
   requirements document.
4. If the task lacks a supporting spec section, clarify with the user
   (informed by REQUIREMENTS.md when available) and draft one in
   SPEC.md before proceeding. Cite `§req:` sources in the spec
   section when requirements exist.
5. Explore the codebase to understand where the work lands — affected
   files, existing patterns, integration points. Use agents to
   parallelize exploration where useful.
6. **Identify integration surface per feature.** For each feature or
   capability being planned, identify where it becomes visible to the
   user — UI component, API endpoint, CLI command, configuration
   surface, observable behavior change. If the user hasn't defined
   how a feature surfaces, ask. A feature without a user-facing path
   is a horizontal layer, not a vertical slice — it will produce PRs
   of disconnected plumbing that can't be integration-tested or
   validated against requirements.
7. **Slice vertically.** Write workstream entries in ROADMAP.md under
   the appropriate section (or create a new section). Each section
   represents one vertical slice through the architecture — from
   internal logic up to the user-facing surface identified in step 6.
   Follow build-dependency order within each section: infrastructure
   workstreams first, surface workstream last. The surface workstream
   is the integration point that wires everything beneath it into a
   testable feature.
   - Each workstream gets a slug, brief description, and explicit
     dependency annotations.
   - Size to one agent session (~200k tokens).
   - Don't write sample code — the implementation team does its own
     due diligence.
8. **Every section must end with a surface workstream.** The last
   workstream in each section wires the section's plumbing into the
   product's visible surface. A section containing only internal
   layers is a horizontal slice — the orchestration system will
   build it, but the result will be dead code with no way to verify
   it meets the spec. If a section is pure infrastructure consumed
   by a later section, annotate the dependency explicitly and ensure
   the consuming section exists.
9. Prioritize by: safety/alarm implications first, then user-visible
   features, then internal quality.
10. **Review for vertical completeness.** Before committing, apply
    the walking skeleton test to each section: can a reviewer merge
    this section's PR and exercise the feature end-to-end from the
    product's UI/API/CLI? If not, the section is a horizontal slice
    missing its integration point. Fix it now — the orchestration
    system will not compensate for an incomplete plan.
11. Commit updated SPEC.md and ROADMAP.md to a branch, push, and open
    a PR. Review with the user before merging.

The task goals from the user are: $1
