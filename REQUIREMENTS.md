# symphonize — Requirements

## Problem statement §req:problem-statement

Symphonize targets technically-aware non-developers — people with
domain expertise and enough coding ability to build small projects,
but who don't naturally follow the lifecycle practices that make
larger projects succeed. Solo developers, product managers who code,
domain experts building tools for their teams.

Neither party in the loop manages the product. The domain expert holds
the knowledge that decides whether a solution is the right one, and has
no reason to have learned requirements practice — they came for their
own problem, not for a lifecycle. The coding agent is a strong developer
and a poor product manager: it accepts the first framing offered, scopes
to the corner of the problem it was handed, and produces working code
for a problem nobody finished describing.

The result is not bad code. It is code that solves a fragment, found to
be a fragment after it ships — horizontal plumbing that passes unit
tests and connects to nothing a user can see or verify.

Symphonize fills the process gap. It encodes software lifecycle best
practices as a command pipeline that agents follow, producing auditable
governance documents (requirements, spec, roadmap, changelog) and
shipping thin vertical slices of integrated, testable code.

Current solutions fall short because:

- AI coding agents don't self-organize into lifecycle stages
- Existing project management tools (Jira, Linear) are designed for
  human teams, not agent-driven execution
- Solo developers don't have the process knowledge to impose structure
  themselves — they need the tool to guide them

## Success criteria §req:success-criteria

- A user with no software lifecycle knowledge can run the pipeline
  from `/discover` through `/orchestrate` and produce PRs that ship
  integrated, testable features — not disconnected plumbing
- Every PR is reviewable: the user can exercise the feature from the
  product's visible surface using verification criteria written before
  implementation
- The governance docs stay current — they reflect the actual state of
  the project, not a snapshot from three weeks ago
- The project appears "active" to outside observers: issues get
  responses, PRs ship, releases land. No issue backlog piling up
  unprocessed
- A new contributor can read REQUIREMENTS.md, SPEC.md, and ROADMAP.md
  and understand what the project does, why, and what's left to build
  — without conversation history
- A problem statement carries an observable stopping condition before
  any workstream references it: the author states what "enough" looks
  like before the work is scoped

## User stories §req:user-stories

**As a solo developer,** I want to describe my problem and have the
system guide me through requirements, architecture, and work planning
so that I can build something larger than I could coordinate myself.

**As a product manager who codes,** I want to outsource development
to agents while retaining control over requirements and design
decisions so that the output reflects my domain expertise, not the
agent's defaults.

**As a project maintainer,** I want incoming issues to flow into my
governance docs so that I have one source of truth for planned work,
not a governance loop and a separate issue backlog that drift apart.

**As a project maintainer,** I want to run `/triage` and process the
issue backlog into actionable governance entries so that the project
stays active and responsive without requiring me to manually translate
every issue into spec sections and roadmap workstreams.

**As an issue submitter,** I want to file feedback through
`/feedback` or GitHub's issue form and receive a visible response
(comment, label, or closure) so that I know my input was received
and processed.

**As a PR reviewer,** I want verification criteria in the roadmap
so that I know exactly what to test when reviewing a PR, without
having to reverse-engineer the feature from the diff.

## Quality attributes §req:quality-attributes

**Velocity:** The pipeline should not buffer work. Issue triage,
planning, and execution should flow at a pace that matches the
project's development velocity. An issue filed this week should
be triaged this week — not next month.

**Approachability:** Users who don't know what "requirements" or
"architecture" are should still be able to use the pipeline. The
commands guide through conversation, not jargon. User-facing
language says "technical decisions" not "architecture."

**Proportionality:** Effort scales with risk. A typo fix doesn't
need a requirements interview. A new persistence layer does.
Commands apply backpressure proportional to the gap, not a fixed
ceremony for every change.

**Auditability:** A reader with no conversation history can
reconstruct the project's design intent from the governance docs.
Every spec section traces to a requirement; every workstream traces
to a spec section; every PR traces to a workstream.

**Safety (future):** When triage becomes automated (GitHub Action),
issue bodies are untrusted input. The system shall not leak secrets,
execute injected instructions, or process malicious payloads. For
now (interactive, human-in-the-loop), this is a noted constraint,
not an active requirement.

## Constraints §req:constraints

- **Claude Code plugin system** — commands are markdown files with
  frontmatter. No server, no database, no persistent state beyond
  files in the repo.
- **`gh` CLI as the GitHub interface** — authenticated `gh` handles
  issue reads, PR creation, and comments. No direct API calls.
- **Human-in-the-loop for now** — triage, planning, and review
  require human approval at each gate. Automation (GitHub Actions,
  scheduled agents) is a future evolution, not a launch requirement.
- **Single source of truth** — governance docs are authoritative.
  Issues are input, not a parallel work queue. Processed issues
  point to governance doc entries; governance docs don't duplicate
  issue content.
- **Issue templates as first filter** — structured forms (bug,
  feature, feedback) guide submitters to provide actionable detail
  at filing time, reducing triage effort. `/feedback` handles the
  Claude Code side; templates handle the GitHub web UI side.
- **Branch protection on the trunk** — work never lands on the trunk
  directly. Every change flows through a short-lived feature branch and a
  PR that CI gates, which is what makes a batch reviewable rather than
  merely finished (§spec:batch-delivery).
- **Trunk-based / GitHub Flow only** — symphonize works on a single
  integration trunk (the repository's default branch,
  §spec:integration-ref): short-lived feature branches fork from it and
  merge back. It is not a GitFlow or GitLab-Flow tool — it does not
  support long-lived `develop`/`staging`/`production` branches or the
  merge-forward promotion cascade. Modern promotion (dev→staging→prod)
  moves one immutable artifact through gated environments rather than
  merging code across long-lived branches, so that cascade is out of
  symphonize's grain. A non-`main` trunk works by setting that branch as
  the repository default. Teams committed to GitFlow/GitLab Flow should
  not adopt symphonize expecting it to honor those branch topologies.
  (§req:modular-adoption)

## Priorities §req:priorities

**Shall** (mandatory — the system does not ship without these):

- Pipeline produces integrated vertical slices, not horizontal
  plumbing (addressed in current release)
- Each command owns one deliverable and guides the user to the
  next step
- `/triage` processes issues into governance docs with human
  approval at each gate
- Verification criteria in ROADMAP.md so PRs are reviewable

**Should** (recommended — expected unless there's a justified reason to omit):

- `/review` for guided PR integration testing
- `/feedback` for structured issue submission from Claude Code
- Issue templates for GitHub web UI submissions
- Forward guidance ("run `/plan` next") at each pipeline boundary

**May** (permitted — included if resources allow):

- Automated triage via GitHub Action on issue creation
- Batch triage for processing multiple issues in one session
- Stale issue bot for auto-closing unresponsive `needs-info` issues
- Pipeline auto-chaining with human review gates between stages

## Modular adoption §req:modular-adoption

Symphonize bundles three separable capabilities in one plugin: curating
governance intent (`/discover`, `/plan`, `/roadmap`), dispatching
execution (`/next`, `/orchestrate`, `/review`, `/clean`), and the
conventions contract beneath both — the governance file formats, the
`§`-slug traceability grammar, the scaffolder that installs them, and the
CI workflow that enforces them.

Adopters need these separately:

- A team may want the conventions and their linting without symphonize's
  agent-swarm execution model, or the planning discipline without the
  dispatch machinery. The monolith forces all-or-nothing adoption.
- The conventions contract should serve as the one source of truth that
  symphonize, future symphonize components, and external adopters all
  consume. Holding it inside symphonize couples every adopter to
  symphonize's release cadence and full opinion.
- A contract and the linter that enforces it drift when they live apart.
  The enforcement workflow once validated numbered sections while the
  grammar had moved to slug-style headings, and nothing caught the
  divergence. The contract and its enforcement should share one version.

The conventions layer separates first, because every other component and
every adopter depends on it.

## Low-friction governance §req:low-friction-governance

The repository is the single source of truth for two kinds of artifact:
the governance documents (REQUIREMENTS, SPEC, ROADMAP) and the codebase.
They differ in nature, and that difference should shape how each lands in
the repository:

- Governance documents are **interpreted** — agents read them live, every
  turn, as instructions and context, re-read on each run like an
  interpreted language. Their correctness is whether they parse (slugs
  present, status lines valid, cross-references resolve) and whether an
  agent reads them coherently. They are verified just-in-time, by being
  read.
- Code is **compiled** — built, tested, and gated by CI ahead of time, so
  errors surface before it runs.

Today both land in the repository through the same heavy ceremony, which
is mis-calibrated for an interpreted artifact. Per-document changes
collide on a moving `main` — a ROADMAP change conflicted on GitHub during
PR #118 because main advanced under it; documents drift stale relative to
the repository's real state; and the tastemaking process (`discover`,
`plan`, `roadmap`) produces changes that fail to merge cleanly. The
maintainer pays twice: in wasted conflict-resolution, and in documents no
reader trusts to be current.

This friction is **frequent** — every governance change meets it — and
**expensive** — the merge churn plus the slow erosion of trust when
documents lag reality. The repository, not an agent's working memory, is
the durable source of truth; documents that go stale stop being
auditable. §req:quality-attributes

Success looks like:

- Governance changes land **correct by construction** — they parse, lint,
  and cross-resolve before they reach GitHub — so they seldom fail to
  merge.
- Governance documents stay **fresh**: the lag between the repository's
  real state and what the documents say stays small.
- A governance change meets far less friction than a code change, and
  rarely produces a PR that conflicts on GitHub.
- The effort required of a change is **proportional to its nature** — an
  interpreted document is judged by whether it parses and reads
  coherently, not held to the checks compiled code requires.
  §req:quality-attributes
- The contract CI enforces is verifiable **before the push**, not only
  after it. A contributor catches a dangling `§`-reference, a missing
  status line, or a malformed slug at edit time, rather than waiting on
  a CI round-trip for checks that are cheap to run locally. Local
  verification and CI enforce one contract — what passes locally
  predicts what passes in CI — so the two never drift. Surfaced by #115.
  §req:quality-attributes

CHANGELOG.md is out of scope: release-please generates it, so it is
neither authored by the tastemaking process nor interpreted as
instructions.

## Large-spec addressing §req:large-spec-addressing

**As a maintainer of a large specification,** I want every meaningful
unit of my governance documents to be individually addressable, and
those addresses to survive reorganization, so that I can adopt the
governance loop on a spec organized as chapters with topical
subsections — not only on a small, flat one.

The governance loop's traceability presumes every referenced unit has
a stable identity (§req:quality-attributes, auditability). In a large
spec organized as chapters with subsections, most cross-references
point at subsections, not whole chapters. When only top-level sections
carry identity, subsection references collapse to their parent and lose
precision: distinct subtopics of one chapter become indistinguishable,
and the traceability chain reads as coarser than the work it tracks.

Positional addressing compounds the problem. An address keyed to a
section's ordinal position breaks the moment a section is inserted,
removed, or reordered — renumbering churn that erodes the traceability
the loop depends on. Tooling keyed to the old positions then matches
nothing and reports success: a silent false green, the failure mode
§spec:notation-contract already guards against.

External adopters arrive with specifications already larger and more
deeply structured than symphonize's own (§req:modular-adoption). An
addressing scheme that implicitly assumes many small flat sections
forces those adopters to either flatten their documents or maintain
project-local tooling that duplicates what the governance contract
should own.

Success looks like:

- An adopter references any meaningful unit of a governance document,
  at any depth, and the reference resolves.
- A reference survives reorganization — promotion, demotion,
  reordering — without manual fix-up. The address means the same unit
  before and after the document is restructured.
- Cross-document validation catches a broken reference rather than
  letting it silently resolve to the wrong unit.

## Domain expertise capture §req:domain-expertise-capture

**As a domain expert without product-management training,** I want to
answer questions about my own field and get a coherent problem
description out of it, so that the eventual solution addresses the
problem I have rather than the corner of it I described first.

The knowledge that decides whether a solution is the right one belongs
to the expert. The practice that turns that knowledge into a reviewable
problem description belongs to product management, and the expert has no
reason to have learned it. Requiring them to learn slugs, modal verbs or
story formats before they can record what they know inverts the
exchange: the tool takes structure and hands back homework.

The interview carries the practice. It asks domain questions —
workflows, vocabulary, edge cases, failure modes, handoffs — and does
the product management around the answers. Its value concentrates in the
question the expert would not have volunteered, because an expert
describing a problem unprompted describes the part already in view.

Prose is the recorded form, and the form is load-bearing. Governance
files hold why a decision was made, what constrained it, and what was
rejected. Source code holds none of that, and a reader reconstructing
intent from code reconstructs a guess. Plain language is what a human
checks for internal coherence, which is what makes a problem description
arguable while argument is still cheap (§req:success-criteria).

**Agent legibility is a consequence, not a goal.** The same files orient
a coding agent cheaply, which is useful and costs nothing to keep. It
does not drive how they are written. Where a paragraph helps a human
understand the problem and costs an agent tokens to carry, the paragraph
stays.

### A problem is not ready without a stopping condition §req:stopping-condition-first

A problem statement admits a workstream only once it records what
"enough" looks like.

Attacking one corner of a problem space is not a failure of effort; it
is what happens when no one has said where the work ends. An unbounded
problem has no wrong answer, so the first plausible solution reads as
correct, and the distance between it and the real problem surfaces after
the code ships. Writing the stopping condition first is the cheapest
moment to find that the problem is larger than the corner in view.

- A problem statement carries an explicit stopping condition before any
  workstream references it.
- The stopping condition is observable: a reader can tell whether it has
  been reached without asking the author.
- A workstream referencing a problem that has no stopping condition is
  rejected, the same way an unresolved slug is rejected today.
