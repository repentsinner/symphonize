---
argument-hint: [spec section or feature area]
description: Break spec sections into ROADMAP.md workstreams
---
Read `${CLAUDE_PLUGIN_ROOT}/CONVENTIONS.md` for roadmap format rules
(§ Roadmap format, § Governance root).

## 0. Resolve governance root

Resolve the governance root before reading or writing governance files:

1. Walk up from the current working directory to find the nearest
   ancestor directory containing SPEC.md.
2. If no ancestor contains SPEC.md, fall back to the repository root.
3. All governance file reads and writes in subsequent steps are
   relative to the governance root, not the repository root.

When the governance root is not the repository root (package-level
governance), read root SPEC.md and root ROADMAP.md as upstream
context. Root spec provides system-level architectural decisions
that inform workstream decomposition. Root roadmap provides
cross-cutting coordination context. Do not modify root files —
they are read-only context.

## Responsibility

`/roadmap` owns **ROADMAP.md** — the work queue that describes
what remains to build. It takes spec sections (from SPEC.md) and
breaks them into vertical workstream slices sized for agent
execution.

`/roadmap` does not write SPEC.md. Architecture and design
decisions are `/plan`'s job. `/roadmap` reads the spec and
translates design into actionable work.

```
/discover → REQUIREMENTS.md → /plan → SPEC.md → /roadmap → ROADMAP.md → /next
```

Each command reads upstream deliverables but writes exactly one.

## Slicing principle

Decompose into **thin vertical slices**, not horizontal layers.
Each ROADMAP section should deliver a complete path from internal
logic through to the product's user-facing surface (UI, API, CLI,
config). A vertical slice is independently deployable, testable
from the outside, and validates its spec section end-to-end. A
horizontal layer (database schema, service class, utility module)
is none of these — it ships inventory, not value.

References: Cockburn, *Crystal Clear* (2004) — walking skeleton;
Wake, "INVEST in Good Stories" (2003) — the "V" is Valuable;
Cockburn, "Elephant Carpaccio" exercise — thin vertical slicing.

## Phase 1: Check upstream

Before decomposing, assess the state of the spec. Apply
backpressure proportional to the gap.

1. Create a planning worktree. Fetch origin and start from tip of
   main.
2. Read REQUIREMENTS.md (if present), SPEC.md, and ROADMAP.md at
   the governance root. If operating on a package, also read root
   SPEC.md as upstream architectural context.
3. **Check SPEC.md quality.**
   - **Absent:** cannot roadmap without a spec. Recommend
     `/plan` to produce spec sections. If the user insists on
     proceeding, do a lightweight inline technical discovery —
     ask about architecture, constraints, and integration surface
     — and draft minimal spec sections before writing workstreams.
   - **Thin:** flag specific gaps. Common signs:
     - Spec sections with no "why" (missing rationale)
     - Sections describing only internal plumbing (no user-facing
       behavior)
     - Missing quality attribute discussion (performance, security)
     - No alternatives considered
     Fill small gaps with targeted questions. For large gaps
     (entire features with no architecture rationale), recommend
     `/plan` for that section.
   - **Adequate:** proceed.
4. Explore the codebase to understand where workstreams land —
   affected files, existing patterns, integration points. Use
   agents to parallelize exploration where useful.

## Phase 2: Identify integration surfaces

5. **Map each spec section to a user-facing surface.** For each
   feature or capability being roadmapped, identify where it
   becomes visible to the user — UI component, API endpoint, CLI
   command, configuration surface, observable behavior change.
   If a spec section has no user-facing path, flag it: either the
   section is a horizontal concern that should be merged into a
   consuming section, or the spec is missing its surface
   description (recommend `/plan` to fix).

## Phase 3: Slice into workstreams

6. **Slice vertically.** Write workstream entries in ROADMAP.md
   under the appropriate section (or create a new section). Each
   section represents one vertical slice through the architecture
   — from internal logic up to the user-facing surface identified
   in step 5. Follow build-dependency order within each section:
   infrastructure workstreams first, surface workstream last. The
   surface workstream is the integration point that wires
   everything beneath it into a testable feature.
   - Each workstream gets a `### §road:slug` heading, one sentence
     stating the deliverable and the affected file(s), a `§spec:`
     citation, and explicit dependency annotations. Rationale,
     procedures, and implementation detail live in the cited spec
     section — not in the roadmap.
   - Size to one agent session (~200k tokens).
   - Don't write sample code — the implementation team does its
     own due diligence.
7. **Every section must end with a surface workstream.** The last
   workstream in each section wires the section's plumbing into
   the product's visible surface. A section containing only
   internal layers is a horizontal slice — the orchestration
   system will build it, but the result will be dead code with no
   way to verify it meets the spec. If a section is pure
   infrastructure consumed by a later section, annotate the
   dependency explicitly and ensure the consuming section exists.
8. **Write integration test criteria per section.** After the
   surface workstream, add a `**Verify:**` block that describes
   how a reviewer exercises the feature end-to-end from the
   product's visible surface. Be concrete — name the screen, the
   endpoint, the command, and the expected outcome. Example:

   ```markdown
   **Verify:** Navigate to Settings → Notifications. Toggle
   email notifications off. Trigger an event. Confirm no email
   is sent and the in-app badge still appears.
   ```

   These criteria serve three audiences:
   - The **batch agent** uses them during Phase 5 (verify
     integration) to confirm the slice works before opening a PR.
   - The **reviewer** uses them during `/review` to know exactly
     what to validate in the UI/API/CLI.
   - The **implementation agent** uses them as acceptance tests —
     the definition of "done" for the surface workstream.

   This is acceptance-before-exploration applied at the workstream
   level: define what "working" looks like before building it.
9. Prioritize by: safety/alarm implications first, then
   user-visible features, then internal quality.

## Phase 4: Review and deliver

9. **Review for vertical completeness.** Apply the walking
   skeleton test to each section: can a reviewer merge this
   section's PR and exercise the feature end-to-end from the
   product's UI/API/CLI? If not, the section is a horizontal
   slice missing its integration point. Fix it now — the
   orchestration system will not compensate for an incomplete
   decomposition.
10. **Cross-check traceability.** Every workstream should cite a
    `§spec:` target. Every spec section with status `not started`
    or `in progress` should have at least one workstream. Flag
    orphans in either direction.
11. Commit updated ROADMAP.md (at the governance root) to a branch,
    push, and open a PR. Review with the user before merging.

The task goals from the user are: $1
