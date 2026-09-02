# symphonize

Plan-to-implementation execution engine for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

Plain-language requirements become auditable specs become shipped PRs.
You describe the problem, make the technical decisions, and review the
results; agents do the branching, coding, testing and PR-opening in
between. The governance files constrain them at each stage, which makes
the output loosely deterministic — predictable enough to review
confidently, flexible enough for a real codebase.

> [REQUIREMENTS.md](REQUIREMENTS.md) — the problem.
> [SPEC.md](SPEC.md) — the design and its rationale.
> [ROADMAP.md](ROADMAP.md) — what is not built yet.

## Governance files

Four files at the repo root, each written by exactly one command:

| File | Role | Written by |
|---|---|---|
| `REQUIREMENTS.md` | Problem space. What users need, and why. | `/compose:discover` |
| `SPEC.md` | Target state. What the system does, and why. | `/compose:plan` |
| `ROADMAP.md` | Work queue. What remains to close the gap. | `/compose:roadmap` |
| `CHANGELOG.md` | Release history, in [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format. | release automation |

Each command reads its upstream deliverables and writes one file, so the
documents drive the work rather than trailing it. Enter the pipeline at
any point — commands apply backpressure, filling small gaps inline and
recommending the upstream command for large ones.

Namespaced slugs (`§req:`, `§spec:`, `§road:`) carry references between
the files, and `governance-lint` fails a dangling one. They live in the
repository rather than in Issues because a file is one tool call where an
issue is an API round trip, and because the spec that was true when a
commit was made stays visible in that commit's checkout — at the cost of
labels, milestones and browser-friendly triage (§spec:governance-in-repo).

## How those files are written

The four files are held to one writing standard, because a governance
document a reader distrusts is one they stop reading. Half of it is
mechanical and half is judgement, and the split is deliberate
(§spec:prose-linting).

The mechanical half is [Vale](https://vale.sh), which `/notation:init`
scaffolds as four rules over SPEC.md and REQUIREMENTS.md:

| Rule | Level | What it catches |
|---|---|---|
| `MustDeprecated` | error | `must` — [IEEE SA](https://standards.ieee.org/) reserves `shall` for a requirement, `should` for a recommendation, `may` for permission |
| `WillDeprecated` | warning | `will`, which predicts where a requirement is meant |
| `FillerPhrases` | warning | `in order to`, `due to the fact that`, and four more that carry no information |
| `OrdinalHeadings` | warning | a heading numbered in prose — address it by its `§` slug instead |

Modal discipline applies to every sentence, not only to acceptance
criteria. Vale matches per sentence and cannot tell a requirement line
from a narrative one, so the rule is document-wide and the guidance
matches its reach rather than fighting it. Only the `must` rule fails a
build. The other three warn, because each has an honest exception: `will`
belongs in rationale that genuinely predicts, a filler phrase is
sometimes the clearest phrasing, and only an author can tell an ordinal
that describes the system from one that numbers the document.

The judgement half — terseness, one term per concept, condition before
command — is stated once in `fragments/prose-style.md` and assembled
into every command that writes governance prose, so the rule a linter
enforces and the rule a command teaches are the same sentence rather
than copies free to disagree. It derives from Strunk & White's *The
Elements of Style* (Rule 17, "omit needless words"), the [Google
Developer Documentation Style Guide](https://developers.google.com/style),
and Gernot Heiser's [Notes on Writing](https://gernot-heiser.org/style-guide.html).

Prose linting is opt-in: a project with no `.vale.ini` skips it in both
the local script and CI. The rules ship as `/notation:init` templates
copied from this repository's own config, so the scaffolder cannot hand
you a rule symphonize no longer runs (§spec:scaffold-freshness).

## Plugins

Four plugins, named for a score-and-performance metaphor: a composer
writes the score in a shared **notation**, a **conductor** performs it,
and **symphonize** is the whole work (§spec:governance-schema,
§req:modular-adoption).

```text
            ┌──► compose ──┐
symphonize ─┤              ├──► notation
            └──► conduct ──┘
```

- **notation** — the schema everything builds on: file formats, slug
  grammar, status-line contract, the lint workflow, the scaffolder.
- **compose** — "are we building the right thing": produces the
  governance documents.
- **conduct** — "are we building it right": performs them into landed
  PRs.
- **symphonize** — the umbrella, and the whole-product entry point.

Installing `symphonize` pulls all four. Adopt one layer for a subset —
`notation` alone gives you the schema, linter and scaffolder.

## Usage

Each command resolves under its plugin namespace.

| Command | Description |
|---|---|
| `/notation:init` | Scaffold governance files and CI into a project (one-time) |
| `/notation:lint [type]` | Validate governance files |
| `/compose:discover` | Structured interview → REQUIREMENTS.md |
| `/compose:plan [task]` | Explore design options → SPEC.md sections |
| `/compose:roadmap [section]` | Break sections into thin vertical slices |
| `/compose:triage [issue]` | Route a GitHub issue to the right file |
| `/compose:review [PR]` | Correctness and taste — does it meet its spec |
| `/conduct:next [target]` | Execute the next unblocked workstreams |
| `/conduct:orchestrate` | Loop `/conduct:next` unattended |
| `/conduct:review [PR]` | Integration — conflicts, local checkout, testing |
| `/conduct:clean [--lite\|--full]` | Clean up after batch execution |
| `/symphonize:feedback` | Report a bug to the symphonize project |

## What it expects of your repo

Symphonize is opinionated and works poorly without these (§req:constraints):

- **[Conventional Commits](https://www.conventionalcommits.org/)**, feeding
  [release-please](https://github.com/googleapis/release-please) (or
  [melos](https://melos.invertase.dev/) for monorepos) for semver releases.
- **[Trunk-based development](https://trunkbaseddevelopment.com/)** with
  branch protection — work never lands on the trunk directly. Short-lived
  feature branches per unit of work, created by `/conduct:next` as
  worktrees and pruned by `/conduct:clean`.
- **An authenticated `gh` CLI**, which is how push and PR creation happen.

Execution follows suit: every batch ends in one reviewable PR or an
explicit failure, never a silent no-op (§spec:batch-delivery).

## API

Target projects call this reusable workflow via `workflow_call`:

| Workflow | Description |
|---|---|
| `governance-lint.yml` | Markdownlint, SPEC status lines, slug cross-refs, [Vale](https://vale.sh) prose linting, CHANGELOG structure, README headings |

```yaml
# .github/workflows/governance-lint.yml
jobs:
  lint:
    uses: repentsinner/symphonize/.github/workflows/governance-lint.yml@notation--v0
    with:
      readme-type: library  # or "application", or "" to skip
```

`/notation:init` scaffolds that caller, plus the release-automation
templates (`release-please.yml`, `auto-merge-release.yml`,
`update-major-tag.yml`), which are copied rather than called cross-repo.

A README carries only what orients a reader — SPEC §spec:readme-profile
records what belongs there and what belongs in the source instead.

## Installation

```shell
/plugin marketplace add repentsinner/symphonize
/plugin install symphonize@repentsinner-symphonize
```

Or from source during development:

```bash
claude --plugin-dir /path/to/symphonize
```

Needs `git`, `gh` (authenticated) and a markdown linter on `PATH` —
`rumdl`, or `uvx`/`npx` to fetch one on demand; `vale` when a
`.vale.ini` exists; and Claude Code 2.1.139 or later with hooks enabled
and workspace trust accepted, which `/conduct:orchestrate` needs for its
unattended [`/goal`](https://code.claude.com/docs/en/goal) loop.

## License

MIT
