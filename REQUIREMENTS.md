# symphonize — Requirements

## Problem statement §req:problem-statement

Symphonize targets technically-aware non-developers — people with
domain expertise and enough coding ability to build small projects,
but who don't naturally follow the lifecycle practices that make
larger projects succeed. Solo developers, product managers who code,
domain experts building tools for their teams.

AI coding agents have strong "solve the next problem" priors. They
produce working code but skip requirements gathering, architecture
decisions, integration testing, and every other development stage
that separates a solo script from a maintainable product. The result:
horizontal plumbing that passes unit tests but doesn't connect to
anything a user can see or verify.

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
- The effort a change must clear is **proportional to its nature** — an
  interpreted document is judged by whether it parses and reads
  coherently, not held to the checks compiled code requires.
  §req:quality-attributes

CHANGELOG.md is out of scope: release-please generates it, so it is
neither authored by the tastemaking process nor interpreted as
instructions.
