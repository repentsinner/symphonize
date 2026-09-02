# symphonize — Specification

## Plugin commands §spec:plugin-commands
*Status: in progress*

Symphonize provides Claude Code plugin commands that operate on
the governance file loop (REQUIREMENTS.md → SPEC.md → ROADMAP.md
→ CHANGELOG.md) and produce conventional commits suitable for
downstream release automation (§spec:release-automation-options).

The commands distribute across four plugins (§spec:governance-schema),
grouped here by plugin:

- `/notation:init` — project scaffolding
- `/notation:lint` — governance file validation
- `/compose:discover` — domain discovery, produces REQUIREMENTS.md
- `/compose:plan` — technical decisions, produces SPEC.md
- `/compose:roadmap` — break spec into workstreams, produces ROADMAP.md
- `/compose:triage` — classify issues into governance entries
- `/compose:review` — correctness-and-taste review of a PR
- `/conduct:next` — executes workstreams
- `/conduct:orchestrate` — unattended multi-batch execution
- `/conduct:review` — integration review (conflicts, checkout, testing)
- `/conduct:clean` — post-merge cleanup
- `/symphonize:feedback` — submit feedback to symphonize

`/symphonize:yolo`, the full-pipeline one-shot, is planned — §spec:yolo-mode.

## Governance lint command §spec:governance-lint
*Status: complete*

The governance contract — markdownlint formatting, SPEC `*Status:*` lines,
`§spec:`/`§road:`/`§req:` slug grammar and reference resolution, Vale prose
rules, CHANGELOG structure, and README heading profile — has one executable
form: a single `governance-lint` script bundled with the notation plugin.
Every consumer runs that one script, so what passes locally predicts what
passes in CI and the two cannot drift. §req:quality-attributes

Three consumers share it:

- **CI.** The reusable `governance-lint.yml` (§spec:reusable-ci) runs the
  bundled script against the caller's governance files, replacing the inline
  checks it carried before.
- **`/notation:lint`.** The command runs the full suite via the bundled
  script — not markdownlint alone — so a contributor sees every contract
  violation before pushing, not only formatting errors.
- **The pre-commit hook** (§spec:project-scaffolding). A thin early warning.
  A git hook runs outside Claude Code, where `${CLAUDE_PLUGIN_ROOT}` is unset,
  so it finds the script by searching the installed plugin cache. Absent — the
  plugin is not installed — it skips with a notice rather than blocking, since
  the checks live in the script and there is nothing left to fall back to. It
  never blocks a commit on an absent optional tool; a real contract violation
  does block, which is what the hook is for. CI is the authoritative backstop.

When a check's tool is absent locally — Vale ships as a separate binary a
contributor may not have installed — the script skips that check with a notice
and runs the rest. CI runs every check unconditionally, so local verification
is honest about being a subset: it never reports clean on a check it did not
run.

**Why the CHANGELOG check skips a tool-managed changelog:** Keep a Changelog
stages the next release under `[Unreleased]`, and for a hand-kept changelog its
absence is a real defect — there is nowhere to record a landed change. A
changelog a release tool writes is that tool's output, and the tools do not
agree even on an h1: release-please opens with `# Changelog`,
`@semantic-release/changelog` (which flywheel drives) writes none unless given a
title, and flywheel exposes no way to give it one. Holding generated output to
an author's rules reports the generator's choices as defects. The check
therefore runs only where no release tool is configured
(§spec:release-automation-options) and reports itself skipped otherwise.

**Markdown engine.** The pinned version outranks whatever the machine
carries. A linter on `PATH` is an accident of that host's setup; the pin is
what CI runs, and a host binary that silently shadows it makes parity
decorative. Resolution order:

1. `rumdl` on `PATH` whose version equals the pin — the same program without
   the fetch, and an offline machine holding the pin keeps working.
2. `uvx rumdl@<pin>`.
3. `npx --yes markdownlint-cli2@<pin>`.
4. `rumdl` on `PATH` at any other version, reported as unpinned.
5. `markdownlint-cli2` on `PATH`, reported as unpinned.

The run prints the engine and where it came from, so a local/CI disagreement
is visible in the log rather than reconstructed from two of them.

**Why the pin travels through `uvx` and `npx`** rather than a downloader
written here: `vale` publishes six platform archives named
`vale_<v>_Linux_64-bit.tar.gz` through `vale_<v>_Windows_arm64.zip`, and
`rumdl` publishes seven named by Rust target triple, in two container
formats. A resolver inside this script would reimplement platform and
architecture detection twice, in incompatible naming schemes, and would still
have to pick a cache directory that is neither `~/.cache` on macOS nor on
Windows. `uvx` and `npx` exist so that code is not written again.

`rumdl` is the preferred engine: one static binary, no Node runtime. It reads
`.markdownlint.json` and `.markdownlint-cli2.jsonc` and implements the same
rule identifiers, so an existing configuration needs no change. It is not
bug-for-bug identical: line length and list indentation differ, and it
follows CommonMark ahead of compatibility. A project that pins
`markdownlint-cli2` in its own CI should install `markdownlint-cli2` locally
too, so both sides run the linter that gates the merge.

The script hands `rumdl` a resolved file list rather than a glob. Given
`**/SPEC.md` it reports the file as missing and still exits 0, which reads as
a pass — the one behaviour here that fails unsafely.

**Vale resolves the same way, through `mise`.** No language registry ships
it — the PyPI package is a third-party repackage, and the npm ones are
unofficial or abandoned — but aqua's registry does, fetching errata-ai's own
release archives, and `mise` fronts aqua. `mise x vale@<pin>` therefore gets
the official binary at an exact version on every platform aqua covers, which
is the portability the release-archive naming made expensive to write here.
Resolution mirrors the markdown engine: an exact-version match on `PATH`,
then `mise` at the pin, then any `PATH` copy reported as unpinned, then the
skip.

**The pins live in the script.** `governance-lint.sh` declares
`vale_version`, `rumdl_version` and `markdownlint_version`, and the reusable
workflow reads them out of the script rather than repeating them. A second
copy in the workflow drifts, and a CI job installing a version the script
does not expect is the same local/CI split this contract exists to close,
relocated one level up.

**Why one script, plugin-bundled:** parity holds only when local and CI run the
same contract logic, and a single source guarantees that by construction.
Bundling it with the notation plugin — the same channel that delivers
`/notation:lint` — keeps the contract symphonize-owned and refreshed through
plugin and pinned-workflow updates (the owned distribution channels), not a copy
each consumer holds and maintains.

**Why not commit the script into each consumer repo:** a committed copy is a
project-owned artifact that drifts (§spec:scaffold-freshness). For workflow
templates that divergence is intended; for the contract's own logic it is the
defect — a stale local copy silently disagreeing with CI is exactly the
local/CI split #115 reports.

**Why the logic cannot stay in the workflow file:** releases are cut per
package, and every package is a directory under `plugins/`. A reusable workflow
has to live in `.github/workflows/`, which is inside none of them, so a commit
touching only that file changes no package and cuts no release — and the
floating major tag adopters pin never advances to include it. PR #208 fixed a
real defect in the inline checks and remains unreachable for that reason. Logic
in `plugins/notation/` releases normally; the workflow left behind provisions
tools and calls the script, so it rarely changes and its immobility stops
mattering. The workflow checks the script out at `job.workflow_sha` in the
`job` context — the commit of the reusable workflow file itself — so a caller
pinned to an old tag runs that tag's contract rather than today's, and at
`job.workflow_repository` so a fork resolves to its own copy.

**Why the resolution fails loudly:** an unresolvable ref stops the job rather
than falling back to `github.sha`. Cross-repo, the caller's commit does not
exist in this repository and the checkout dies with `upload-pack: not our ref`
— but a same-repo call resolves it happily, so a fallback keeps symphonize's
own CI green while every adopter breaks. That is not hypothetical: the
`github.job_workflow_sha` this section first named is not a property of the
`github` context at all (actions/runner#2417), the expression naming it always
took the fallback, and v0.2.7 shipped a workflow that could not run outside
this repository. The dogfooded path and the adopter path differ, so a failure
mode only the adopter path reaches has to be loud where they diverge.

**Why the hook stays thin:** commit time is the wrong place to require Node,
Vale, and a shell all be present; a hook that hard-fails on a missing optional
tool trains contributors to bypass it. The full local suite belongs to
`/notation:lint`, which a contributor invokes deliberately; the hook is a cheap
nudge, and CI is the gate. Reported in #115. §req:quality-attributes

## Governance in the repository §spec:governance-in-repo
*Status: complete*

The governance documents live in the repository, beside the code, rather
than in GitHub Issues or Discussions. §req:constraints

A file is one tool call. An issue is an API round trip — paginated,
filtered, and rate-limited — and every such query spends agent context on
retrieval instead of on the work. Governance files also travel with the
branch: the spec that was true when a commit was made stays visible in
that commit's checkout, so a specification change and the code change it
describes land in the same PR and cannot drift apart.

The trade is real. Labels, milestones, assignees and browser-friendly
triage belong to an issue tracker, and none of them survive the move. For
agent-driven execution, co-location with the code is worth more than the
triage interface — which is why issues remain an *input* to governance,
routed by `/compose:triage`, rather than a parallel work queue.

## Project scaffolding command §spec:project-scaffolding
*Status: complete*

Re-homed to the notation plugin under §spec:governance-schema; the behavior
below is current. The notation plugin provides a `/notation:init` command
that scaffolds governance files and CI workflows into a target project.

The command creates:

- `SPEC.md` — skeleton with section 1 and status line
- `ROADMAP.md` — empty with format instructions as comments
- `CHANGELOG.md` — with `## [Unreleased]` section
- `.markdownlint.json` — default config
- `.github/workflows/governance-lint.yml` — caller workflow
  referencing `repentsinner/symphonize/.github/workflows/governance-lint.yml@notation--v0`
- Release-automation files for the adopter's chosen tool — the set
  depends on the choice (§spec:release-automation-options): flywheel
  workflows + `.flywheel.yml`, release-please workflows + config and
  manifest, or no files for manual.
- `.githooks/pre-commit` — runs markdownlint on staged governance
  files

The command activates hooks for the current checkout via
`git config core.hooksPath .githooks`. Hook scripts are tracked;
activation is per-checkout. Consumers opt in by running
`/notation:init` — upstream repos do not push hooks on
contributors. CI is the backstop.

The hook resolves its linter through the common version-manager locations
before giving up, because git hooks inherit no interactive shell and a bare
invocation misses nvm, fnm, and volta shims. When no toolchain is reachable
it reports the skip and exits clean. **Why degrade rather than fail:** a
governance repo need not carry the linter's runtime at all, and CI runs the
same check unconditionally — blocking the commit would trade a real
contribution for a check that was going to run anyway.

The command is idempotent: it skips files that already exist and
warns rather than overwrites.

**Why scaffolding:** new projects need boilerplate to participate
in the governance loop. Scaffolding reduces setup from "read the
docs and copy-paste" to one command.

## Reusable CI workflows §spec:reusable-ci
*Status: complete*

Now the notation plugin's, under §spec:governance-schema; the workflows stay
at the repository root `.github/workflows/` (GitHub Actions resolves reusable
workflows only from there — §spec:plugin-packaging). Symphonize ships
reusable GitHub Actions workflows that target projects reference via
`workflow_call`.

`governance-lint.yml` is tool-agnostic. The release workflows below are
the release-please template set — symphonize's own dogfooded workflows
(§spec:dogfooding), and what `/notation:init` copies when an adopter
selects release-please. Flywheel and manual adopters scaffold a different
file set (§spec:release-automation-options).

Every scaffold template lives under `plugins/notation/templates/<tool>/`,
one directory per release-automation option. Plugin isolation forces the
location: an installed plugin reads only its own directory
(§spec:plugin-packaging), so `init` cannot reach a repository-root
`templates/`.

### governance-lint.yml

Reusable workflow accepting a `readme-type` input (string:
`library`, `application`, or empty). Runs markdownlint,
SPEC.md status-line validation, and optional README heading
checks. Errors surface as GitHub annotations.

### README profile §spec:readme-profile

**A README is an executive summary, not a manual.** It answers what this
is, where it sits among its neighbours, and how to start — for a reader
deciding whether to keep reading. Everything else has a better home, and
the profile is built to keep it there.

Required headings, by type:

| Type | Required |
| --- | --- |
| `library` | Installation (or Getting started / Quick start), Usage, License |
| `application` | Getting started (or Quick start / Installation), Usage, License |

Recommended, in this order: what it is in a sentence or two; pointers to
the governance files; where it sits in its layer stack, as a table when
it has siblings; what it deliberately is *not*, where a reader would
otherwise assume; the constraint that shapes it (a licence, a privacy
requirement); install; one minimal example; pointers to the runnable
ones.

What belongs elsewhere, and where:

| Not in the README | Its home |
| --- | --- |
| The API surface, symbol by symbol | Docstrings — `help(pkg)` is the index |
| A tour of the source tree | The source tree |
| Host prerequisites and their remedies | The diagnostic that checks them |
| Every flag of a script | The script's own `--help` and comments |
| Design rationale | SPEC.md |
| What is not built yet | ROADMAP.md |

*Why API is recommended rather than required*: a heading a linter demands
gets filled whether or not it earns its place, and the filling is either
a stub or a table with a row per symbol — which goes stale on the first
rename and duplicates the docstrings that cannot. Require it and every
library README trends toward a manual. Include it where the surface *is*
the product, as this repository's reusable workflows are.

*Why the layer stack is recommended at all*: a repository that sits
between two others is the one most often misread, and the misreading is
expensive — a consumer wires to the wrong seam, or a maintainer lands
work in the repository whose licence cannot carry it. One table at the
top costs six lines and prevents both.

#### Derivable, not authoritative §spec:readme-derivable

**A README states nothing it is the only home for.** Every substantive
claim it makes shall be derivable from the governance documents, which
are the single source of truth (§req:constraints, §spec:governance-in-repo).
The README selects, orders and compresses what those documents already
say, for a reader who has not opened them.

The failure this prevents is silent: a fact that lives only in a README
is a fact no `*Status:*` line tracks, no `§`-reference resolves against,
and no roadmap workstream retires. It goes stale invisibly, because the
document that would have contradicted it never mentions it. Symphonize's
own README asserted a fail-fast policy built on cherry-picking long after
the batch agent moved to worktree isolation — wrong for releases, and
undetectable by any check, because nothing else in the repository
discussed it.

`governance-lint` enforces the contract at three strengths:

| Rule | Level |
| --- | --- |
| A README heading shall not define a `§` slug — defining is what a source of truth does | error |
| A README's `§` references shall resolve, exactly as a governance file's do | error |
| A section beyond the orientation headings should cite at least one `§` reference | warning |

The warning is the derivability probe: a section that cites nothing is
either orientation, which needs no citation, or an assertion whose home
is missing. It warns rather than fails because the judgement of which one
it is belongs to an author, not a linter.

Orientation is a fixed list — install, usage, examples, API, development,
building, testing, prerequisites, contributing, support, security,
changelog, licence, credits — because these sections tell a reader how to
run the thing rather than what it is. A section named for the system's own
concepts is not orientation, whatever it is called, and cites its source.

*Why not require citations everywhere*: install commands, a usage
snippet and a licence name are not claims about the system's design, and
a reference on each would be noise that trains a reader to skip them.

### release-please.yml

Template workflow for release-please-action@v5. Target projects
copy this (via `/notation:init`) rather than calling it as a
reusable workflow, because each project needs its own manifest
and config.

### auto-merge-release.yml

Template workflow that auto-merges release PRs from
github-actions[bot] with the `autorelease: pending` label.

### update-major-tag.yml

Template workflow that moves a floating major version tag on each
release. In symphonize it is gated to the notation release, moving
`notation--v<major>` (e.g. `notation--v0`) — the adopter-facing ref
for the reusable `governance-lint.yml`.

## Scaffolding freshness §spec:scaffold-freshness
*Status: complete*

`/notation:init` scaffolds the current state of the world; it does not
keep scaffolded files current afterward. This matches every scaffolder
(`flutter create`, `npm init`): generated files are handed to the project
to mutate in project-specific ways, so the scaffolder cannot own their
later evolution. Two freshness concerns follow from that boundary, with
different owners.

Symphonize ships its workflow templates two ways (§spec:reusable-ci):
`governance-lint.yml` is scaffolded as a `@notation--v0` reusable caller
(the notation-scoped floating major; pre-1.0, so `v0`, not `v1`), so a
consumer picks up symphonize's internal action bumps transitively; the
chosen tool's release workflows (§spec:release-automation-options) are
copied verbatim because each needs project-specific config and tokens, so
a consumer holds a point-in-time snapshot that does not self-update.

- **Source freshness — symphonize's concern.** The release-please templates'
  source is symphonize's own `.github/workflows/*`, and
  `tools/assemble-fragments.sh` copies them into the notation plugin, with CI
  failing on drift. If the source rots, every new scaffold ships stale action
  versions — "init-ing the past." Symphonize keeps the source current with
  Dependabot (`github-actions`), so a fresh scaffold ships current pins. Two
  template sets fall outside the copy and so outside Dependabot's reach:
  `update-major-tag.yml`, which symphonize gates to its notation release and
  the adopter form does not, and the flywheel set, which symphonize does not
  run. Both are hand-maintained; their action pins need review by hand.
- **Copy freshness — the consumer's concern.** A consumer's copied
  workflows are theirs to mutate and theirs to keep current. `init`
  scaffolds a `.github/dependabot.yml` (`github-actions`) into the consumer
  so those copies self-heal through native upgrade PRs — the same mechanism
  that surfaces a deprecation to any GitHub repository.

**Why delegate copy freshness rather than check it:** a drift checker
would have to diff a consumer's workflows against the current templates,
but those files are *meant* to diverge — it cannot separate intentional
project mutation from a stale pin without re-asserting symphonize as
authority over files it deliberately handed off. Dependabot already owns
the action-version upgrade graph; reimplementing it would be strictly
worse. A `/doctor`-style command, if built, belongs to governance-document
drift (status-line validity, dangling slugs, docs-versus-repo-state),
where symphonize is the source of truth — not to action versions.

The governance-lint contract script (§spec:governance-lint) is **not** a copied
template subject to this delegation. It is distributed through symphonize's owned
channels — the notation plugin bundle and the pinned reusable workflow — not
scaffolded into the consumer as a mutable copy, so it carries no copy-freshness
concern: there is no project-owned copy to drift. Copied artifacts are the
project's to mutate; the contract's logic is symphonize's to own.

The `init` scaffolder becomes the notation plugin's under the plugin
decomposition (§spec:governance-schema); this freshness contract is
notation's and moves with it. §req:modular-adoption

## Release automation options §spec:release-automation-options
*Status: in progress*

`/notation:init` lets the adopter choose how conventional commits become
versioned releases. The supported options are **flywheel** (default),
**release-please**, and **manual**. The choice determines which
release-automation files §spec:project-scaffolding scaffolds and which
release-aware check §spec:clean-working-tree-hygiene runs.

### Selection

When CWD is the repository root (CI scaffolding runs only there),
`/notation:init` prompts: "How should releases be cut from conventional
commits?" with the three options. The choice selects the
`templates/<tool>/` directory to copy from. Flywheel is the default —
taken when the adopter accepts the prompt default or runs unattended.
Manual scaffolds no release-automation files; CHANGELOG.md still receives
its `[Unreleased]` section.

### Re-run detection

`/notation:init` is idempotent (§spec:project-scaffolding). On re-run it
detects the existing choice from repo state and skips the prompt:

- `.flywheel.yml` present → flywheel.
- `release-please-config.json` present → release-please.
- Neither → manual.

It then scaffolds only missing files. Switching tools requires removing
the old config first; symphonize does not migrate one tool's state to
another.

### The squash subject is the release input

Every supported option reads conventional commits off the trunk, so under
squash merging the PR title becomes the only input a release sees. Two
settings make that safe, and a repository adopting any of the three
should carry both:

- The squash commit message defaults to **the pull request title**, not
  GitHub's generated "Branch name (#123)".
- CI rejects a PR title that is not a conventional commit.

*Why a gate rather than a convention*: the failure is silent in the
direction that hurts. A malformed title does not fail the release — it
produces no release at all, reported as success, and the change never
reaches an adopter pinned to a floating major tag. Symphonize lost
PR #207's release this way, and noticed only when the tag failed to
move.
Flywheel gates the title itself (§spec:release-automation-options);
release-please and manual releases need the check supplied.

### Clean integration

`/conduct:clean` reads the same signals to choose its advisory
release-aware check (§spec:clean-working-tree-hygiene):

- **flywheel:** pushed conventional commits are eligible for a release on
  the managed branch.
- **release-please:** the next release-please PR picks up commits since
  the last release.
- **manual:** CHANGELOG.md `[Unreleased]` reflects merged commits, and the
  adopter is reminded to tag.

The check reads repo state; it does not invoke the release tool.

### Tool comparison

| Aspect | flywheel | release-please | manual |
|---|---|---|---|
| Release trigger | PR merge + push to managed branch | push to main | none |
| Merge gate | per-PR (auto-merge by commit type) | per-release (release PR) | none |
| CHANGELOG.md | semantic-release | release-please | by hand |
| Per-repo config | `.flywheel.yml` | `release-please-config.json` + manifest | none |
| Multi-branch streams | first-class | flat | manual |
| Monorepo linked versions | not native (semantic-release is single-package) | native (`linked-versions`) | manual |

**Why flywheel is the default:** most adopters version a single package,
where flywheel's per-PR gate fits symphonize's tastemaking model — docs
and chores auto-merge, features gate on review (§req:quality-attributes).
Flywheel cuts a release per push to a managed branch, so the review gate
sits on each PR, not on an accumulated release PR. That per-PR gate is the
deliberate tradeoff: faster flow and earlier releases, against the loss of
release-please's batch-a-release-then-review step.

**Why release-please remains:** symphonize's own repo versions four
plugins (notation, compose, conduct, symphonize) in lockstep via
release-please's `linked-versions` plugin and `extra-files` write-back,
which inject each computed version into the plugins' `plugin.json` version
and cross-plugin dependency pins. Flywheel runs semantic-release, which is
single-package; replicating linked lockstep versioning and JSON-path
write-back is custom work that buys nothing. Symphonize therefore dogfoods
release-please (§spec:dogfooding) and ships it as the monorepo option,
while defaulting downstream single-package adopters to flywheel.

**Why manual:** early-stage projects, forks, and repos where another tool
already cuts releases opt out of release automation entirely. Without the
option, every adopter pays GitHub App setup before `/notation:init` is
usable.

**Why detect rather than re-prompt:** matches `/notation:init`'s
idempotent contract — skip files that exist, warn on each skip. An adopter
switching tools removes the old config, making the switch explicit rather
than inferred.

## Dogfooding §spec:dogfooding
*Status: complete*

Symphonize's own CI calls its own `governance-lint.yml` reusable
workflow. The repo's `.github/workflows/ci.yml` uses
`./.github/workflows/governance-lint.yml` with
`readme-type: library`.

## Self-contained conventions §spec:self-contained-conventions
*Status: complete*

Superseded by §spec:governance-schema. The conventions content is no
longer a shared `CONVENTIONS.md`: authoring methodology (spec, roadmap,
and requirements formats; spec compression; interview frameworks) is
inline in the compose commands, process discipline (branching, commit
conventions, quality gate) is inline in the conduct commands and
`plugins/conduct/protocols/batch-agent.md`, and the structural grammar is enforced by
governance-lint. Commands carry their own contract inline rather than
deferring to the user's CLAUDE.md.

**Why self-contained:** conventions are part of the plugin's
contract, not the user's personal configuration. Any user who
installs symphonize and runs `/notation:init` gets a working
governance loop without needing symphonize-specific content in
their CLAUDE.md.

## Requirements discovery command §spec:requirements-discovery
*Status: complete*

REQUIREMENTS.md is the fourth governance file — a problem-space
document in the user's language. `/compose:discover` populates
it through a structured interview.

| Document | Voice | Question |
|----------|-------|----------|
| REQUIREMENTS.md | User's | What do we need? |
| SPEC.md | System's | What does the system do? |
| ROADMAP.md | Work queue | What remains to build? |
| CHANGELOG.md | History | What shipped? |

`/compose:plan` reads REQUIREMENTS.md (if present) as input
when drafting SPEC.md sections. `/compose:roadmap` reads
SPEC.md to produce ROADMAP.md workstreams. Each command applies
backpressure when upstream documents are absent or thin — filling
gaps inline for small issues, recommending the upstream command
for large ones. `/notation:init` scaffolds an empty
REQUIREMENTS.md skeleton.

**Why a separate document:** requirements live in the user's
problem space. Specs live in the system's solution space. Mixing
them produces documents that serve neither audience well. The
translation from requirements to spec is where design decisions
happen — that boundary should be explicit.

## Prose linting §spec:prose-linting
*Status: in progress*

The governance-lint workflow validates structure (markdownlint) and
cross-references (slug resolution), but not prose quality. SPEC.md
and REQUIREMENTS.md use IEEE modal verbs — "shall" for mandatory
requirements, "should" for recommendations, "may" for permission.
`Must` and `will` are deprecated per IEEE SA Standards Style Manual.

Modal-verb discipline applies document-wide, not only to criteria.
The scaffolded `Requirements` Vale style flags `must` (and `will`)
in any sentence of SPEC.md / REQUIREMENTS.md, including narrative
problem statements, context, and rationale. The writing commands
(`/compose:discover`, `/compose:plan`) therefore steer all prose in
these files away from `must`/`will` — not the criteria alone — so
generated documents pass the scaffolded Vale style on the first
push.

**Why document-wide:** Vale matches tokens per sentence; it cannot
reliably tell a requirement line ("the system shall…") from
narrative (`the user must re-map each header`). Scoping the rule to
criteria-only is not mechanically feasible, so the prose guidance
matches the rule's actual reach. Aligning the guidance to the
linter is cheaper and more robust than weakening the linter
(reported in #131).

Vale (<https://vale.sh>) enforces prose rules via custom YAML
styles. A `Requirements` style checks modal verb compliance, flags
passive voice in requirements, and catches ambiguous language. Vale
complements markdownlint — structure vs. prose.

The governance-lint workflow runs Vale against SPEC.md and
REQUIREMENTS.md when a `.vale.ini` config exists. Projects opt in
by adding `.vale.ini` and a `styles/` directory via
`/notation:init`.

**Why prose linting:** agents generate requirements and spec text
that drifts toward vague, passive, non-testable language.
Mechanical enforcement catches `the system will...` (deprecated)
and `it should be noted that...` (filler) before review.

CI evaluates the whole file rather than the diff, and a violation
fails the job wherever it sits — including lines the current change
never touched. A push to the trunk is checked on the same terms as a
pull request. **Why:** a rule added after a document was written
never meets the existing text under diff-scoped reporting, and a
branch cut before the rule existed lands violations that stay
invisible from then on. Document-wide reach in the style earns
nothing unless enforcement has the same reach; local `vale` and CI
otherwise disagree about a file they both claim to check.

## Requirements frameworks §spec:requirements-frameworks
*Status: complete*

`/compose:discover` uses established frameworks as interview
prompts to broaden the user's thinking. Frameworks guide
conversation — they do not impose structured output. Answers
flow into REQUIREMENTS.md as prose.

- **Discovery (Phase 1):** YC Problem Types (Popular, Frequent,
  Expensive, Mandatory, Growing, Urgent, Distant) prompt the user
  to articulate *why* the problem matters.
- **Validation (Phase 2):** ICE framework (Impact, Confidence,
  Ease) surfaces priority tradeoffs beyond a binary essential/nice-to-have split.

**Why frameworks as prompts:** users describe *what* they want
without explaining *why*. Framework-derived questions produce
richer problem statements and priority rationale without imposing
structured output forms. `plugins/symphonize/commands/discover.md` documents both
taxonomies inline as interviewer references.

## Product-type-agnostic discovery §spec:product-type-agnostic-discovery
*Status: complete*

The discover command uses product-neutral language throughout. Phase 1
opens with a product-type classifier (application, library/SDK,
platform/service, CLI tool, hardware device, other) that gates which
subsequent prompts are relevant.

**Why:** symphonize targets any software product, not just consumer
apps. Narrow language biases the interview toward GUI applications
and produces requirements that miss concerns specific to other
product types (API ergonomics, operator workflows, physical
constraints).

## Progress file location §spec:progress-file-location
*Status: complete*

The `/conduct:next` command tracks attempted workstreams in
`.symphonize-progress.local.md` at the project root. The file is
symphonize state — it belongs alongside other project-root dotfiles,
named after the tool that owns it. `/conduct:clean` deletes it when
the loop ends.

**Why:** Claude Code controls `.claude/` and may restrict writes
from plugin commands. Symphonize state belongs to symphonize, not
to the host tool's config directory.

## Unattended flag passthrough §spec:unattended-flag-passthrough
*Status: complete*

When `/conduct:orchestrate` starts an orchestration loop, every
agent in the execution hierarchy runs unattended. The `--unattended`
flag propagates explicitly through each layer — no agent infers
unattended mode from file existence or ambient state.

### Propagation chain

1. `/conduct:orchestrate` passes `--unattended` in the `/goal`
   condition that invokes `/conduct:next`.
2. `/conduct:next` reads `--unattended` from its own arguments.
   Passes `--unattended` to the batch agent it spawns.
3. The batch agent
   (`plugins/conduct/protocols/batch-agent.md`) passes
   `--unattended` to every sub-agent it spawns.
4. Agents operating in `--unattended` mode shall not surface
   interactive prompts, approval gates, or questions to the user.
   On ambiguity an agent would normally ask about, it makes a
   conservative choice and documents the decision in its commit
   message.

Mode selection follows the same rule: `/conduct:clean` reads
`--lite`/`--full` from its own arguments and defaults to `--full`;
`/conduct:orchestrate` passes `--lite` explicitly.

**Why:** a batch agent that receives `--unattended` but does not pass
it down leaves sub-agent workers free to surface interactive prompts,
blocking the loop indefinitely with no user present. Explicit
passthrough at every layer keeps the entire tree non-interactive.
Inference from an ambient flag file fails for a second reason: it
coupled symphonize to a third-party plugin's file layout, and such
files are not git-tracked, so agents in worktrees cannot see them.

## Orchestration loop §spec:orchestration-loop
*Status: complete*

`/conduct:orchestrate` runs an unattended execution loop that
invokes `/conduct:next --unattended` repeatedly until the
active ROADMAP section's unblocked workstreams are attempted. The
loop runs in-session via Claude Code's first-party `/goal` command
(Claude Code 2.1.139+). §req:success-criteria

### Observable behavior

- When `/conduct:orchestrate` runs, it first invokes
  `/conduct:clean --lite` to settle local state, then sets a
  `/goal` whose condition describes the section's completion
  state (all unblocked workstreams attempted, or ROADMAP.md
  empty).
- Each turn, Claude Code invokes `/conduct:next --unattended`.
  After the turn, the small fast model judges the goal condition
  against the conversation transcript — it runs no tools and reads
  no files — and either continues or terminates the loop.
- When the condition is met, the goal clears automatically and
  the user regains control. The active ROADMAP section is left
  blocked on review with one PR per executed batch.
- The user terminates an active loop with `/goal clear` or by
  starting a new conversation with `/clear`.

### Termination contract with /next

The goal is met when `/conduct:next --unattended` reports that
all unblocked workstreams in the active ROADMAP section have been
attempted, or when ROADMAP.md contains no remaining workstreams.
`/next`'s output shall make the terminal state visible to a
reading evaluator — a literal sentinel string is not required and
is not part of the contract. The exact condition wording is an
implementation detail of `plugins/conduct/commands/orchestrate.md`.

### Why /goal, not ralph-loop

Earlier versions invoked the third-party ralph-loop plugin with a
literal completion-promise sentinel (`BLOCKED ON REVIEW`). `/goal`
covers the same in-session, condition-bounded execution use case
natively. The switch removes:

- A third-party plugin dependency, simplifying installation and
  reducing the trust surface.
- A flag-file coupling (`.claude/ralph-loop.local.md`) that fired
  ralph-loop's stop hook on file presence rather than active skill
  context, so an idle loop interrupted `/compose:plan` and
  `/compose:discover` in the same project with orchestration
  directives. `/goal` is session-scoped, so a second session is
  unaffected.
- A bespoke sentinel-string convention; the evaluator judges the
  condition from `/next`'s natural output.

### Rejected alternatives

- **Keep ralph-loop.** Rejected: it remains a viable plugin, but
  `/goal` is first-party in the host tool, resolves a documented
  cross-skill leakage issue, and removes an external dependency.
  Sub-1.0.0 status carries no back-compat obligation.
- **Pure auto mode.** Rejected: auto mode approves tool calls
  within a turn but does not start a new turn. The orchestration
  loop needs per-turn continuation, which `/goal` provides.
- **Time-interval `/loop`.** Rejected: orchestration is
  event-driven (when `/next` finishes, start the next), not
  time-driven. A fixed interval either wastes idle time or
  preempts in-flight work.
- **Custom stop hook.** Rejected: `/goal` is a session-scoped
  wrapper around a prompt-based stop hook. Hand-rolling the
  equivalent reproduces what the host already ships.

### Tradeoffs accepted

- Termination is model-judged (small fast model), not literal
  string match. The condition is short and the evaluator's
  accuracy is sufficient at this gate. §req:quality-attributes
- The loop requires the workspace trust dialog accepted and
  hooks enabled. `/goal` reports the reason when unavailable, so
  the failure mode is visible rather than silent.
- Slight per-turn evaluation cost on the small fast model;
  negligible compared to main-turn spend.

## Governance consistency §spec:governance-consistency
*Status: in progress*

Governance files, commands, and scaffolding templates are
internally consistent. Specifically:

- init.md scaffolding templates match the format rules
  governance-lint enforces (slug-style headings, status lines,
  `§prefix:slug` suffixes)
- `plugins/symphonize/commands/discover.md` documents the standard REQUIREMENTS.md
  sections inline
- The lint command documents which checks it runs vs. which
  checks CI runs (lint is a subset of governance-lint.yml)
- The governance files table is consistent across README.md and
  SPEC.md (four files, same descriptions)
- markdownlint globs include REQUIREMENTS.md and CHANGELOG.md

**Why:** inconsistencies between documents erode trust. An agent
that reads init.md and the authoring commands should not get
conflicting instructions.

## Issue triage command §spec:issue-triage
*Status: complete*

The plugin provides a `/compose:triage` command that processes
GitHub issues into governance doc entries. Unlike pipeline commands
that each own a single file, triage is a lateral entry point — it
classifies issues and routes them to whichever governance file the
classification warrants. §req:success-criteria §req:user-stories

Classifications: bug (→ ROADMAP workstream or SPEC section),
feature request (→ REQUIREMENTS section), feedback/question
(→ comment only), out of scope (→ closing comment). The user
approves every classification before the command acts.
§req:constraints (human-in-the-loop)

Issue bodies are untrusted input — read-only data, never executed
or interpolated into shell commands. §req:quality-attributes

Triage edits governance documents only; it never ships behavior.
Every committing classification therefore uses a `docs(<scope>):`
commit — `docs(roadmap)`, `docs(spec)`, or `docs(requirements)` —
and triggers no release. The release-bearing commit is the later
`/next` implementation that resolves the routed work: it carries
`fix`/`feat` and closes the issue with `Fixes #N`. **Why:** typing a
triage commit `fix`/`feat` cuts a release for a bug still unfixed or
a feature still unbuilt — a phantom release whose changelog entry
contradicts the running system.

**Why a triage command:** without triage, issues accumulate as a
parallel backlog disconnected from governance docs. `/triage`
closes the loop: issues flow into the same governance documents
that `/plan` and `/roadmap` produce.

**Why not single-file ownership:** pipeline commands flow
linearly (requirements → spec → roadmap), so each naturally owns
one file. Triage is a router — issues arrive at varying maturity
levels and map to different governance files. The classification
step replaces the pipeline ordering as the routing mechanism.

## Clean command supersession safety §spec:clean-supersession-safety
*Status: complete*

The `/conduct:clean` command (full mode) closes open sub-agent
PRs and deletes remote branches during post-merge cleanup. These
are destructive, hard-to-reverse operations — a closed PR with a
deleted remote branch cannot be reopened.

The clean command shall not close a PR or delete its remote branch
based on title similarity, topic overlap, or heuristic matching.
A PR is superseded only when every file it touches exists in the
integration trunk (the repository's resolved default branch,
§spec:integration-ref) with equivalent changes. Verification
procedure:

1. For each open sub-agent PR, list unmerged commits
   (`git log --oneline <trunk>..<branch>`).
2. For each unmerged commit, inspect the diff and confirm the
   classes, functions, and files introduced exist in the trunk.
3. If any introduced symbol or file does not exist in the trunk, the
   PR is not superseded — leave it open.
4. Only after all changes are confirmed present in the trunk, close
   the PR with a comment citing the merge commit or batch PR
   that landed the work.

Remote branch deletion shall occur only for PRs that are already
merged or confirmed superseded and closed by the procedure above.
Open PRs shall never have their remote branches deleted.

**Why:** an instance of `/clean` closed an unmerged PR solely
because its title overlapped with a preceding PR's title. Related
work often spans multiple PRs — title similarity does not imply
duplication. Closing unverified PRs destroys in-progress work.
The verification cost (diffing a few commits) is trivial compared
to the cost of losing a valid PR.

## Vertical-first batch selection §spec:vertical-first-batch-selection
*Status: complete*

The `/conduct:next` dispatch layer selects workstreams for a
batch by building dependency chains that reach the user-facing
surface, then selecting the longest chain that fits the batch cap.
The algorithm is implemented in `plugins/conduct/commands/next.md` step 3.

Batch selection goals, in priority order: vertical slices, walking
skeleton, dependency correctness, batch coherence, forward progress.

**Why chains over independent workstreams:** independent unblocked
workstreams are typically all at the same architectural layer —
selecting them produces a horizontal batch. A chain crosses layers
by definition, connecting foundation to surface. This aligns batch
selection with the vertical slice structure `/roadmap` imposes on
sections.

**Why longest chain:** the bottleneck in an orchestration loop is
review latency, not batch size. Maximizing chain length per batch
minimizes review gates between "nothing built" and "vertical slice
shipped."

Reference: Cockburn, *Crystal Clear* (2004) — walking skeleton;
Wake, "INVEST in Good Stories" (2003); Cockburn, "Elephant
Carpaccio" exercise.

## Clean working tree hygiene §spec:clean-working-tree-hygiene
*Status: complete*

The `/conduct:clean` full-mode command checks for dirty state
at entry, checks out main before verification, and never stashes.

**Why no stashing:** stashes from branch-switching accumulate
silently — the pop never happens. Lock file drift (the usual
cause) is handled by restoring generated files; real dirty state
aborts with a warning. A stash is a deferred decision disguised
as cleanup.

**Why verify from main:** the previous phase ordering ran
verification from a branch, not from the state that ships.
Checking out main and fast-forwarding before governance doc
updates ensures tests run against the shipped state.

## Pre-PR review gates §spec:pre-pr-review-gates
*Status: complete*

The dispatch layer (`plugins/conduct/commands/next.md`) runs review gates
against the branch the batch agent returns, after the `/simplify` gate and
before opening the PR: `/security-review` as a mandatory gate,
`/review --comment` as a recommendation in the PR body. The gates run as
Skills in the main session, which has a session loop — not in the batch agent,
where a reporter Skill like `/security-review` can end the turn before delivery
(§spec:batch-agent-leaf). A PR shall not open with known security findings.

**Why security is mandatory:** vulnerabilities in merged code are
expensive to remediate and may ship before review. A local
`/security-review` pass costs seconds and catches common issues
mechanically.

**Why code review is recommended, not mandatory:** `/review` runs
parallel agents producing nuanced findings that benefit from human
judgment. Gating on it would block unattended loops on false
positives or require auto-dismissal — defeating the purpose.

## Simplify gate §spec:simplify-gate
*Status: complete*

The dispatch layer (`plugins/conduct/commands/next.md`) runs a mandatory
`/simplify` gate against the branch the batch agent returns, before
`/security-review` and before opening the PR. `/simplify` spawns parallel
review agents for code reuse, quality, and efficiency and applies fixes.
The gate runs as a Skill in the main session, alongside `/security-review` at the
dispatch layer. `/simplify` is an actuator and would survive in the batch agent,
but co-locating both gates keeps a single review locus where a reporter gate's
turn-end is survivable and the harness-assumption surface is smallest
(§spec:batch-agent-leaf). §req:quality-attributes

The gate runs once (simplify is an actuator; iterating re-refactors its
own output), reverts fixes that contradict a deliberate design choice,
re-runs CI, and skips when every changed path is a non-source file.

**Why mandatory:** reuse, duplication, and inefficiency violations are
objective and mechanically detectable. Gating enforces brownfield-bias at
machine speed rather than relying on agent discretion. Symmetry with
`/security-review`: both are native skills whose output is deterministic
enough to gate on.

**Why before `/security-review`, not after:** security-review inspects the
code that ships. If `/simplify` ran after, security would review
pre-simplify code and miss vulnerabilities introduced by the refactor.
Running simplify first ensures security sees the final state. Running
security twice doubles cost without commensurate benefit.

**Why review fixes before the CI re-run:** `/simplify` has no visibility
into design intent. The batch agent may have deliberately inlined a helper
for readability or duplicated logic across two sites for independence.
Blindly accepting fixes overrides intent; review-then-revert preserves the
architectural choices.

**Why skip for doc-only batches:** `/simplify` reviews "code reuse,
quality, and efficiency." Markdown and YAML have none of these concerns.
Spending the agent spawns on prose is noise. §req:quality-attributes
(proportionality).

**Rejected alternatives:**

- **Recommended, not mandatory.** Matches `/review --comment`'s posture.
  Rejected: recommended gates are silently skipped in unattended mode,
  defeating the enforcement goal. Reuse violations are objective enough to
  gate on.
- **Iterate until clean.** Matches `/security-review`'s loop. Rejected:
  `/simplify` applies fixes, so subsequent iterations see a modified diff
  and may reverse prior work. Security-review is a reporter — its "iterate
  until clean" is a fixpoint on findings. Simplify is an actuator — its
  fixpoint is unstable.
- **Run the gate inside the batch agent.** Rejected: `/security-review` (a
  reporter) can end a sub-agent's turn before delivery, so gates co-locate at the
  dispatch layer where a turn-end is survivable. `/simplify` alone would survive
  in-batch, but splitting the gates buys nothing — the batch hands back for the
  reporter gate regardless (§spec:batch-agent-leaf).

**Tradeoffs accepted:**

- Parallel agent spawns per batch, charged against the dispatch layer's
  token budget.
- CI runs again after the gate mutates the branch.
- Simplify may propose fixes the dispatch layer then reverts, costing review
  time. Bounded by running simplify once.

## Batch agent is a fan-out leaf §spec:batch-agent-leaf
*Status: complete*

The batch agent dispatched by `/conduct:next` returns a pushed branch; the
dispatch layer runs the review gates (`/simplify`, then `/security-review`) in the
main session and opens the PR. Gates do not run inside the batch agent. The
constraint is **turn survival**, not delegation capability: a *reporter* Skill —
one whose deliverable is a findings report (`/security-review`, default
`/code-review`) — intermittently ends the invoking agent's turn at completion, so
any later phase (fix-up, delivery) silently never runs (the #165/#171 stall). An
*actuator* Skill (`/simplify`) mutates and continues, so it does not end the turn.
The main session has a loop that survives a turn-end and drives the next turn; the
dispatch layer is therefore where a reporter gate runs safely, at full fidelity.

The batch agent is a fan-out *leaf* by design, not by incapacity: it executes its
workstreams inline in one warm turn. It *can* spawn sub-agents, but vertical-first
selection (`§spec:vertical-first-batch-selection`) makes each batch a dependency
chain with no available parallelism to exploit.

### The dispatch layer is the orchestrator

Review and delivery run at the `/conduct:next` dispatch layer in the main session,
not in the batch agent — the locus that survives a reporter Skill's turn-end and
keeps the harness-assumption surface smallest (above). The dispatch layer is the
orchestrator of work, review, and delivery, not a thin selector.

### Observable behavior

- **The batch agent executes inline and returns a branch.** It plans, implements,
  and verifies its workstreams sequentially in its own turn, spawning no
  sub-agents. Its completion signal is a pushed branch and a status report, not a
  PR.
- **Review gates run at the dispatch layer as Skills.** After the batch agent
  returns, the dispatch layer runs `/simplify` then `/security-review` as Skills.
  The main session has a session loop, so a Skill returns control rather than
  ending the turn, and the Skills run at full fidelity — `/simplify`'s own
  parallel review agents fan out. The reviewers are cold: they did not write the
  code, the property a gate exists to provide.
- **Review and delivery never touch the user's main checkout.** The dispatch layer
  runs the gates and applies fixes against the batch's branch in an isolated
  worktree, preserving worktree-only execution.
- **Delivery runs at the dispatch layer.** Once the gates pass, the dispatch layer
  re-runs CI, removes the shipped ROADMAP workstream, and opens the PR. Review
  precedes PR creation, so "a PR shall not open with known security findings"
  (`§spec:pre-pr-review-gates`) holds. Every batch ends in a reviewed PR or an
  explicit failure — the `§spec:batch-delivery` guarantee, relocated to the
  dispatch layer.

### Why the dispatch layer, not the batch agent

Two reasons, in force order:

- **Turn survival.** A reporter gate run in the batch agent risks the intermittent
  turn-end above; in the main session a turn-end is harmless — the loop drives the
  next turn.
- **Assumption minimization.** Dispatch-layer gating depends on one stable harness
  property: the main session survives Skills. The batch agent *could* host the
  gates — sub-agents may spawn sub-agents (Claude Code 2.1.172, up to 5 levels
  deep) and invoke fan-out Skills, and a disposable gate worker can absorb a
  reporter's turn-end because its findings return as the tool result. But that path
  bets on a stack of harness behaviors: sub-agent spawn depth (now documented) plus
  non-isolated worktree sharing and reporter-Skill turn-survival (both still
  emergent and undocumented). That these shift is not hypothetical — sub-agent
  spawning was absent until 2.1.172, which is why the gates ever stalled on the
  prior harness (#165/#171). The dispatch layer trades autonomy for the smallest
  undocumented-assumption surface.

### Why warm worker, cold reviewers

The batch agent stays warm: it carries the plan and integration context across
all phases in one window, so inline sequential work is cheap. The reviewers are
cold by design — independence is the purpose of a review gate, and a reviewer
sharing the author's context cannot supply it. The seam between warm and cold is
the branch the batch agent returns; splitting the worker into cold fragments
would harm the worker and add nothing for the reviewers.

### Why dispatch-layer delivery, not batch-agent delivery

`§spec:batch-delivery` already had the dispatch layer adopt a batch agent's
committed worktree and finish delivery when the agent returned without a PR — a
recovery path from a stall. This section promotes it from fallback to primary: the
batch agent always stops at a returned branch, and the dispatch layer always gates
and delivers. One delivery path, exercised every batch, replaces a primary path
that could not run and a recovery path that ran only on failure. The
hard-completion guarantee is unchanged in force; only its locus moves.

### Rejected alternative: full flatten

Dissolve the batch agent; have the dispatch layer spawn workstream workers and
reviewers directly. Rejected: it fragments the warm worker into cold per-step
boundaries (higher token and latency cost), moves integration churn into the
interactive session the batch agent exists to isolate, and distributes the
recovery anchor across many worktrees. Its sole gain is workstream parallelism,
which vertical-chain selection is built not to produce. Revisit only if batch
selection changes to prefer wide independent sets over vertical chains.

### Deferred alternative: disposable self-gating for autonomous loops

Dispatch-layer gating makes the orchestrator a context accumulator: per batch it
absorbs gate findings, applied fixes, and CI output. For interactive
`/conduct:next` — one batch, a human reviewing the PR — this is fine. For sustained
autonomous loops (`/conduct:orchestrate`, a future `/symphonize:yolo`) it is the
bottleneck: the orchestrator's window fills over successive batches and exhausts,
sooner on sub-1M context windows.

Disposable self-gating removes this: the batch agent runs `/simplify` directly and
delegates each reporter gate to a throwaway sub-sub-agent whose turn-end is benign
(its findings return as the tool result), then delivers its own PR. The
orchestrator sees only the delivered PR and stays flat regardless of batch count —
every task becomes context-disposable, the property sustained autonomy requires.
Validated end-to-end, but deferred: adopt it only when an autonomous mode makes
orchestrator-context exhaustion real and the harness-assumption bet (see *Why the
dispatch layer, not the batch agent*) is accepted. Until then, interactive `/next`
keeps the lower-assumption dispatch-layer gates.

Reported by the maintainer during architecture review, corroborated by an
observed inline-review fallback in a batch run.

## Thin roadmap workstreams §spec:thin-roadmap-workstreams
*Status: complete*

Roadmap workstreams are thin pointers into SPEC.md. A workstream
description is one sentence stating the deliverable and affected
file(s), plus a `§spec:` citation. `**Verify:**` blocks remain at
the section level. Workstream headings use suffix placement
(`### <Title> §road:slug`) per §spec:heading-addressing.

**Why:** verbose workstream descriptions duplicate the spec and
diverge when the spec is updated. The batch agent reads SPEC.md
in Phase 1 — duplicating design context in the roadmap wastes
tokens and creates a second source of truth.

## Directory-scoped governance §spec:directory-scoped-governance
*Status: complete*

Governance files scope to the directory subtree they live in. A
SPEC.md in `packages/auth/` governs that subtree; a SPEC.md at the
repo root governs the project as a whole. Any directory containing
SPEC.md is a governance root. Commands resolve governance root by
CWD walk-up (nearest SPEC.md ancestor, repo root fallback). Each
command inlines the resolution algorithm in its governance-root
step; governance-lint enforces the scoping rules.

**Why pull, not push:** packages pull root governance as upstream
context. Push would require root to enumerate packages and
distribute rules — coupling that the monorepo structure does not
mandate. Symphonize stays ecosystem-agnostic (no pubspec.yaml,
package.json, or Cargo.toml awareness).

**Why CWD, not flags:** no `--package` or `--scope` flag exists.
The user `cd`s into the package directory. This mirrors Claude
Code's own directory scoping and preserves single-repo behavior
with zero configuration.

**Why no manifest:** the filesystem is the configuration. Adding a
package means dropping governance files in a directory; removing
means deleting them. No registry to maintain, no sync to drift.

**Why no symphonize-specific lint inheritance:** markdownlint, Vale,
and similar tools already resolve config by walking up the directory
tree. Symphonize delegates to the linter's native scoping.

## Plugin decomposition §spec:governance-schema
*Status: complete*

Symphonize is one repository publishing one plugin marketplace with four
plugins — each independently installable, all sharing one coordinated
version line via the `{plugin}--v{version}` tag convention:

- **notation** — the governance schema the others build on: the structural
  grammar (governance file formats, the `§req:`/`§spec:`/`§road:` slug
  rules, the status-line format, cross-reference rules), the reusable
  `governance-lint.yml` workflow that enforces it, and the `init`
  scaffolder that installs it into adopter repos.
- **compose** — the tastemaking layer ("are we building the right
  thing"): `discover`, `plan`, `roadmap`, `triage`, and the
  correctness/taste half of `review`. It produces the governance
  documents — the *score*.
- **conduct** — the execution layer ("are we building it right"): `next`,
  `orchestrate`, `clean`, and the integration/merge half of `review`. It
  performs the score into landed PRs.
- **symphonize** — the umbrella that composes the layers into the whole
  product: `yolo`, which drives the full pipeline end to end
  (`/compose:plan` → `/compose:roadmap` → `/conduct:next`), and `feedback`,
  the meta command for reporting issues to the symphonize project itself.

notation has no dependencies; compose and conduct each declare a plugin
`dependencies` on notation; symphonize declares `dependencies` on compose
and conduct (and notation transitively). All resolve within the one
marketplace, so installing `symphonize` pulls the whole set — the
recommended default. The names follow the product's own metaphor —
**notation ← compose → conduct**, with **symphonize** the verb over all
three: a composer writes the score in a shared notation, a conductor
performs it, and to symphonize is to do the whole work end to end.
§req:modular-adoption

### Notation lives in this repository, not a separate one

Notation is a plugin in this monorepo, not a standalone repository.
Symphonize keeps the `governance-lint.yml` workflow, the grammar it
enforces, and the `init` scaffolder it ships today — they become the
notation plugin rather than moving out. This supersedes §spec:reusable-ci,
§spec:self-contained-conventions, §spec:project-scaffolding, and
§spec:dogfooding: those capabilities are notation's, in-repo.

**Why in-repo, not a separate schema repository:** an earlier design
extracted notation to its own repository to serve generic adopters. The
schema is symphonize-specific — consumed only by symphonize — so that
justification lapsed. Keeping notation in-repo holds compose and conduct's
dependency on it within one marketplace (no cross-marketplace allowlist),
makes a grammar change and its consumers one atomic PR (no cross-repo
drift), and costs only document relocation while notation is unbuilt. If
symphonize ever needs a different schema, it plugs a different notation in
on its own side; that seam stays unbuilt until a second schema exists.

### Why four plugins, one repository

- **Layered, not monolithic:** a team may adopt compose's shaping
  discipline without conduct's agent-swarm execution, or the reverse.
  Separately-installable plugins serve that; one monolithic plugin would
  not. §req:modular-adoption
- **An umbrella, not feature-stuffed siblings:** `yolo` drives the full
  pipeline, so it depends on both compose (`plan`, `roadmap`) and conduct
  (`next`). Housing it in either sibling would couple compose and conduct to
  each other; they are designed as independent peers over notation. A
  separate `symphonize` plugin that depends on both is the only placement
  that keeps the peers uncoupled. It also gives the default adopter — who
  wants the whole product — one thing to install, and gives `feedback`
  (project meta, belonging to no layer) a home.
- **One repository, not four:** notation, compose, conduct, and symphonize
  co-evolve — moving authoring methodology into compose and process
  discipline into conduct touches several, and a grammar change ripples to
  its consumers. One repository makes those changes atomic and shares one
  CI, while the `{plugin}--v{version}` tag convention preserves independent
  installation. Separate repositories would add cross-repo coordination with
  no adoption benefit.

### Where the former CONVENTIONS.md content went

The former shared `CONVENTIONS.md` bundled three contracts the
decomposition separated (the file is deleted):

- **Structural grammar** → notation enforces it; the linter is its
  executable form, so notation ships no per-repo conventions document.
- **Authoring methodology** (declarative spec writing, vertical slicing,
  interview frameworks, compression) → inline in the compose commands
  (`discover`, `plan`, `roadmap`).
- **Process discipline** (branching, commit conventions, quality gate) →
  inline in the conduct commands (`next`, `clean`) and the batch-agent
  protocol.

**Rejected alternatives:**

- **Notation as a separate repository** (the earlier `bug-free-happiness`
  plan). Rejected: the schema is symphonize-specific, so the separate repo
  solves a generic-adoption problem symphonize does not have while adding
  cross-repo dependency machinery and drift surface.
- **compose and conduct in separate repositories.** Rejected: they
  co-evolve and the split refactor touches both; separate repos add
  coordination with no adoption benefit over separately-installable
  plugins in one marketplace.
- **One plugin with grouped commands.** Rejected: it abandons the
  adopt-one-layer-without-the-other goal. §req:modular-adoption

**Tradeoffs accepted:**

- One coordinated version line covers all four plugins — they co-evolve
  in one repo with hard dependency edges, so a release bumps and tags them
  together. Independent *installation* (adopting compose without conduct)
  needs no independent version numbers. §spec:plugin-packaging
- notation welds to symphonize; opening it as a generic governance-doc
  linter later would mean re-extracting it. Accepted given the
  symphonize-specific decision.
- Adopter projects reference the reusable `governance-lint.yml` cross-repo
  via a notation-scoped major tag (`@notation--v0`) rather than a dedicated
  repository's `@v1`. The tag name carries the version; the cosmetic
  difference is accepted.

## Plugin packaging and distribution §spec:plugin-packaging
*Status: complete*

The decomposition (§spec:governance-schema) ships as one Claude Code plugin
marketplace named `symphonize`, declaring four plugins — `notation`,
`compose`, `conduct`, `symphonize` — each rooted at `plugins/<name>/` and
listed in `.claude-plugin/marketplace.json` with
`source: "./plugins/<name>"`. Each plugin carries its own
`.claude-plugin/plugin.json`; commands resolve by convention from each
plugin's `commands/` directory. The marketplace and its umbrella plugin
share the name `symphonize` — the marketplace-named plugin is the
whole-product entry point.

### Observable behavior

- A user adds the marketplace once
  (`/plugin marketplace add repentsinner/symphonize`) and installs any
  subset. The recommended default is `symphonize`, which declares
  `dependencies` on compose and conduct and so pulls the whole product —
  notation included transitively. Installing `compose` or `conduct` alone
  auto-installs `notation`, which both declare as a `dependencies` entry;
  installing `notation` alone yields just the schema. Tastemaking without
  execution is `compose`; the reverse is `conduct`; everything is
  `symphonize`. §req:modular-adoption
- Commands appear under their plugin namespace: `/notation:init`,
  `/notation:lint`; `/compose:discover|plan|roadmap|triage`;
  `/conduct:next|orchestrate|clean`; `/symphonize:yolo`,
  `/symphonize:feedback`. The former monolithic `/symphonize:*` namespace is
  retired — its commands redistribute across the four plugins, and only
  `yolo` and `feedback` keep the `symphonize` prefix (now scoped to the
  umbrella plugin). Pre-1.0, the rename ships without aliases.
- The four plugins share one coordinated version line. A release bumps all
  four `plugin.json` versions together and publishes one
  `{plugin}--v{version}` git tag per plugin (`notation--v0.2.0`,
  `compose--v0.2.0`, `conduct--v0.2.0`, `symphonize--v0.2.0`). compose and
  conduct pin `notation`, and symphonize pins compose and conduct, at that
  shared version through their `dependencies` ranges.

### Dual packaging of notation

notation reaches adopters through two channels on one version line:

- The **plugin** (`plugins/notation/`) ships the `init` scaffolder and the
  workflow templates it copies into adopter repos.
- The **reusable workflow** `governance-lint.yml` stays at the repository
  root `.github/workflows/` — GitHub Actions resolves reusable workflows
  only from that path, and the repo's own CI calls it there. Adopters
  reference it cross-repo via
  `uses: repentsinner/symphonize/.github/workflows/governance-lint.yml@<major>`.

The git ref a workflow caller pins and the plugin version a `dependencies`
range resolves both originate from the same version line, so the scaffolder
always writes a workflow ref that exists and matches.

### Cross-plugin fragment assembly

Installed plugins are copied into `~/.claude/plugins/cache/` and cannot
read files outside their own directory — `../` into a sibling plugin fails.
So the residual that several commands duplicate verbatim — the
governance-root resolution algorithm — lives once under `fragments/` and is
assembled into each consuming command file by a build step, with CI failing
on any drift from a fresh assembly. Each cached plugin stays self-contained
while the fragment keeps one source of truth. (The `§`-slug grammar is
command-specific guidance, not one verbatim block, so it is not a fragment.)
The marker and build mechanics live in `fragments/README.md`.

**Why a build step, not symlinks:** a symlink into a sibling plugin
resolves at install-time copy and dangles in the cache. Assembly resolves
at commit time, leaving each cached plugin self-contained, and the drift
check prevents the divergence a manual copy would invite.

### Rejected alternatives

- **Symlinked shared files** — fragile at cache-copy time (above).
- **Independent version numbers per plugin** — the plugins co-evolve in one
  repo behind hard dependency edges, so divergent versions inflate one
  plugin's number on another's change with no adoption benefit. Independent
  *installation* needs no version divergence.
- **`yolo` and `feedback` folded into conduct (or compose)** — rejected:
  `yolo` spans compose and conduct, so housing it in either couples the two
  sibling peers; the umbrella plugin depends on both without coupling them.
  §spec:governance-schema

### Tradeoffs accepted

- The `/symphonize:*` → `/{plugin}:*` rename breaks existing invocations.
  Accepted pre-1.0 (no compatibility contract); aliases would entrench the
  monolithic namespace the decomposition exists to retire.
- `feedback` has no functional dependency on compose or conduct, yet lives
  in the umbrella, so installing `notation`/`compose`/`conduct` alone omits
  it. Accepted: the recommended install is `symphonize`, which carries it,
  and a leftover meta command does not justify a fifth plugin. Revisit if
  adopters of a single layer ask for `feedback`.

## Notation contract §spec:notation-contract
*Status: complete*

notation defines what a well-formed governance document *is*: the
governance file formats, the `§req:`/`§spec:`/`§road:` slug rules, the
status-line format and placement, the cross-reference rules, and the
governance-root definition. The contract is content-agnostic — it governs
document *structure*, not authoring methodology (compose's) or development
process (conduct's). §spec:heading-addressing defines the slug coverage and
placement rules this contract enforces.

### Expressed, not distributed

The contract ships no document to adopters. Its executable form is the
reusable `governance-lint.yml` workflow — what the linter checks *is* the
contract — and its human-readable form is notation's own documentation.
compose and conduct are built against the same grammar and carry inline
what they need to produce conforming documents (§spec:plugin-packaging);
neither they nor the linter read a per-adopter conventions file. A
materialized `CONVENTIONS.md` in each adopter repo would be a second source
of truth to keep in sync with the linter — the drift this design exists to
prevent.

### Observable behavior

- governance-lint enforces, on every invocation with no opt-in switches:
  markdownlint over the governance documents; a valid status line on every
  `##` SPEC heading; the slug grammar of §spec:heading-addressing (a
  `§`-slug suffix on every `##` heading, unique within its prefix, every
  `§`-reference resolving to exactly one definition, positional addressing
  rejected); code spans and fenced blocks exempt from reference resolution.
  Vale runs when a `.vale.ini` exists, else is a silent no-op. CHANGELOG.md
  is excluded
  entirely (markdownlint and the structural checks both skip it):
  release-please generates it, so enforcing its shape fights the generator.
- These checks already run in symphonize's `governance-lint.yml`, which
  notation now owns; the decomposition re-homes them rather than rebuilding
  them.

### Version coherence

A consumer pins the contract two ways, both off notation's one version
line: the workflow by git ref (`@<major>`), the plugin by a `dependencies`
range. The floating major tag points at the release it names and does not
lag a renamed or restructured workflow. No separate version marker is
needed — the contract ships no file to carry one; ref plus dependency
already declare which schema version a repo targets.

**Why validate every `##` heading, not numbered sections only:** a
numbered-only status-line check matches zero sections in a slug-style
SPEC.md and reports success — a silent false green. This drift occurred
once (the workflow validated `## N.` sections while the grammar had moved
to slug headings; nothing caught it). Validating every heading removes that
failure mode. §req:modular-adoption

## YOLO mode §spec:yolo-mode
*Status: not started*

`/symphonize:yolo` runs the governance pipeline from a user-named entry
stage (`discover`, `plan`, `roadmap`, or `next`) through to a single pull
request that bundles the governance-document changes and the landed
implementation. It runs non-interactively: the agent makes the judgment
calls a person normally makes at each stage, records them, and surfaces
nothing for approval until the final PR. §req:priorities
§req:quality-attributes

YOLO mode is the `symphonize` umbrella plugin's command — the unattended
execution model of §spec:orchestration-loop extended *up* the pipeline.
`yolo` invokes commands across the layers it depends on (`/compose:plan`,
`/compose:roadmap`, `/conduct:next`), which is why it lives in the umbrella
that declares `dependencies` on both compose and conduct rather than in
either peer; the cross-plugin invocations resolve because installing
`symphonize` installs both. Where `/conduct:orchestrate` loops
`/conduct:next` inside an already-merged roadmap, YOLO also authors the
upstream governance documents the run needs and bundles everything onto one
branch. §spec:governance-schema

### Gates collapse, they do not disappear

The default pipeline has two kinds of gate: **human** gates between stages
(a person reviews REQUIREMENTS before `/plan`, SPEC before `/roadmap`, the
PR before merge) and **mechanical** gates inside `/next` (`/simplify`,
`/security-review`, CI, governance-lint). YOLO removes the human gates and
keeps the mechanical ones. The four human review points collapse into one:
a single review of the complete vertical slice — REQUIREMENTS → SPEC →
ROADMAP → code — in one PR, where the run creates and validates the
`§`-slug traceability chain in a single diff. §spec:pre-pr-review-gates
§spec:simplify-gate

### Observable behavior

- **Entry stage.** A required argument names the stage the run starts at;
  YOLO runs that stage and every downstream stage, and assumes the
  upstream stages already hold. When an entry stage would skip an upstream
  document a downstream one cites — a SPEC section references a `§req:`
  slug that `/plan`-entry would not otherwise create — YOLO backfills the
  minimal upstream entry so cross-references resolve, applying the same
  backpressure the individual commands use for thin upstream documents.
  §spec:requirements-discovery
- **Single branch, single PR.** Every stage commits to one branch; the PR
  opens once, at the end. No stage merges before the next begins, so the
  run carries no inter-stage merge dependency.
- **One commit per layer.** The bundle keeps separate conventional
  commits — `docs(requirements):`, `docs(spec):`, `docs(roadmap):`, and
  the implementation's `feat`/`fix`/etc. — so release-please reads the
  history correctly. The PR is one slice; the commits stay one per change.
- **One slice per run.** A run targets a single batch-sized vertical slice
  per §spec:vertical-first-batch-selection. Inputs larger than one batch
  route to the gated pipeline or `/conduct:orchestrate`.
- **Non-interactive curation.** `discover`, `plan`, and `roadmap` run
  without user input; the agent makes conservative choices and documents
  them in the commit, as sub-agents do under `--unattended`.
  §spec:unattended-flag-passthrough
- **Terminal state, risk-tiered.** Once the mechanical gates pass, the
  bundle's merge eligibility follows its conventional-commit risk class:
  - A breaking change (`!` or a `BREAKING CHANGE` footer) always stops at
    a mergeable PR for human review.
  - Clearly low-risk classes (`docs`, `chore`, `refactor`, `style`,
    `test`, `ci`, `build`) auto-merge.
  - `feat`, `fix`, and any class the run cannot confidently classify stop
    for review. The mapping is configurable; the default is conservative.
  - `--yolo-hard` auto-merges every class once the mechanical gates pass,
    for trusted or scheduled contexts.

  With no flag, a run stops at a mergeable PR — that PR is the one retained
  human gate. §req:constraints
- **Failure is explicit.** A run that cannot reach all-gates-green — CI
  red after its attempts, a blocking `/security-review` finding, or an
  agent unable to proceed — leaves a draft PR with diagnostics and stops.
  It never leaves a broken branch or a partially merged state.

**Why YOLO suits only bounded, low-risk slices:** the gated pipeline's
value is cheap early correction — a person kills a bad requirement or
design before any code exists. YOLO writes code against un-reviewed
design, so a design the reviewer rejects at the final PR wastes the
implementation built against it. YOLO pays off when the agent's design is
likely correct — small, familiar work — and wastes effort when the design
needs human steering. It is an opt-in mode, not the default path; the
gated, human-reviewed pipeline remains the norm. §req:constraints

**Why risk-tiered auto-merge keys on the commit type:** conventional-commit
type already encodes semver impact, which tracks change risk — a breaking
change is the most expensive to land wrong, a docs or chore change the
least. Gating auto-merge on that classification reuses a signal the
project already produces instead of inventing a separate risk model. The
classifier trusts the agent's own commit type, so the conservative default
— review anything not clearly low-risk — keeps a mis-typed change from
merging unattended.

**Rejected alternatives:**

- **Auto-merge every class by default.** Rejected: it overrides the
  never-merge-directly posture for every change, including breaking ones.
  `--yolo-hard` offers this as an explicit opt-in instead. §req:constraints
- **A separate PR per stage, auto-merged in sequence.** Rejected:
  inter-stage merges reintroduce the gating and merge-conflict friction
  YOLO exists to remove, and split one slice's traceability across four
  PRs. One bundled PR reviews the whole slice at once.
- **Skip the mechanical gates for speed.** Rejected: non-interactive
  execution makes the mechanical gates the only in-run safety net.
  Dropping them trades a bounded time saving for unbounded risk.

**Tradeoffs accepted:**

- A rejected design wastes the implementation built against it — bounded
  by scoping YOLO to low-risk slices.
- The risk classifier is only as honest as the commit type it reads; the
  conservative default mitigates but does not remove this.
- Non-interactive end-to-end execution widens the blast radius of a
  prompt-injected input, a destructive action, or a flawed design — no
  person inspects the run until the final PR. The one-shot input is
  untrusted attack surface; the mechanical gates and the execution sandbox
  are the only in-run protection. §req:quality-attributes

## Repo-state reconciliation hook §spec:repo-state-reconciliation
*Status: complete*

An agent works from a snapshot of repo state taken when it last looked,
and assumes it is the only actor. A human merges the open PR, force-pushes
the branch, or advances `origin/main` while the conversation continues —
and the agent keeps asserting the merged PR is open, pushes commits onto a
branch that no longer exists upstream, or builds on a stale base. The
governance loop's premise is that the docs and PRs reflect actual state
(§req:success-criteria); an agent reasoning from stale state corrupts that
premise from inside.

Symphonize ships a Claude Code `UserPromptSubmit` hook in the conduct plugin
(`plugins/conduct/hooks/hooks.json` registering
`plugins/conduct/hooks/reconcile-repo-state.sh` via
`${CLAUDE_PLUGIN_ROOT}`) that reconciles the agent's view of repo state with
the remote before each turn, and surfaces any divergence as conversation
context via `hookSpecificOutput.additionalContext`.

### Observable behavior

- Before each user turn, the hook performs a **read-only** reconcile: a
  rate-limited `git fetch --prune`, then a comparison of the current branch
  against its upstream and the integration trunk (the repository's resolved
  default branch, §spec:integration-ref), and of the branch's pull request
  against its remote state.
- The hook injects context **only when reality diverges** from the naive
  "nothing changed since I last looked" assumption — the current branch's
  PR is merged or closed; the branch is behind the resolved trunk; the
  branch no longer exists on the remote. When nothing diverges, it injects
  nothing.
- The divergence is reported as a specific contradiction at the point of use
  (e.g. "PR #118 for this branch is MERGED"), not a status dump.
- The hook never blocks the prompt and never mutates the working tree or the
  remote (no checkout, pull, rebase, push). It reports; the agent and user
  decide.
- The hook degrades to a silent no-op outside a git repository, in detached
  HEAD, when `gh` is unavailable or unauthenticated, or when the network is
  unreachable. Absence of remote state is never reported as divergence.
- The fetch is rate-limited via a per-repo stamp file: the hook skips the
  network round-trip when one ran within a short window (default 300s), so
  most turns add no latency. PR state is at most one window stale.

### Why a hook, not an instruction

No hook fires on the agent's generated text, so nothing can inspect a
stale assertion after the agent makes it and force a correction. The only
available lever is to put fresh ground truth into context *before* the
turn, where it contradicts the stale assumption at the moment the agent
would act on it. This is a floor raise, not behavior policing: it cannot
guarantee the agent heeds the correction, but it removes the excuse of not
knowing.

The mechanism is chosen over a passive instruction — a CLAUDE.md note or a
remembered preference — because passive reminders compete for attention
against everything else in context and get normalized away within a
session. A reminder the agent is free to skip is the failure mode this
section exists to remove; injected ground truth at the decision point is
not skippable in the same way.

### Why shipped in the plugin

The hook lives in the conduct plugin bundle (`plugins/conduct/hooks/hooks.json`
plus a script referenced via `${CLAUDE_PLUGIN_ROOT}`), not in a user's
`settings.json`. Settings hooks bind to one machine and do not travel;
a plugin-shipped hook installs with the plugin and every adopter inherits
it. Keeping agents honest about external state is dispatch-layer
infrastructure — it belongs with conduct's execution machinery that assumes a
current view of the repo. §req:modular-adoption

### Rejected alternatives

- **`SessionStart` hook.** Rejected: it snapshots once and rots. The
  failure being fixed is mid-session drift — a PR merged while the
  conversation is open — which a start-of-session check never sees.
- **A blocking or auto-correcting hook** (deny the prompt, auto-rebase,
  auto-fetch-and-pull). Rejected: a reconciler that mutates the tree or
  blocks work on stale state can clobber in-progress work and surprises
  the user. Reconciliation reports; it does not act.
- **A passive memory or CLAUDE.md instruction.** Rejected: this is the
  status quo the section replaces. It relies on recall and loses to
  attention competition.
- **A flat repo-status dump every turn.** Rejected: undifferentiated
  status gets skimmed and adds noise on every turn. Reporting only the
  contradiction keeps signal high and output silent when state is clean.

### Tradeoffs accepted

- Bounded staleness: the rate-limited fetch trades a few minutes of
  possible PR-state lag for the elimination of a per-turn network tax.
  §req:quality-attributes
- PR-state detection depends on `gh`; without it the hook still reports
  branch ahead/behind from local refs, but not merge state. Degraded, not
  broken.
- The response remains model-judged. Injecting the contradiction raises
  the floor but does not force the agent to act on it. Acceptable — the
  alternative (no fresh state at all) is strictly worse.

## Heading addressing §spec:heading-addressing
*Status: complete*

A governance document addresses its units by slug. Today only top-level
sections carry slugs — `##` in SPEC/REQUIREMENTS, `###` in ROADMAP — so a
subsection has no address: a reference to a subtopic collapses to its parent
section and loses precision, and a spec organized as chapters with topical
subsections cannot be cross-referenced at the grain its own work happens.
§req:large-spec-addressing

This section defines the addressing grammar. It supersedes the slug-coverage
and placement rules stated in §spec:notation-contract and the `### §road:slug`
heading format retained by §spec:thin-roadmap-workstreams. The cross-reference
resolution, status-line, and CHANGELOG rules of §spec:notation-contract are
unchanged.

### Observable behavior

- **A slug on every section, optional below it.** Every `##` heading in
  SPEC.md, REQUIREMENTS.md, and ROADMAP.md carries a `§<prefix>:slug` — `§spec:`,
  `§req:`, `§road:` respectively. A heading deeper than `##` may carry one; it is
  required only to make that heading referenceable. The `#` document title is
  exempt — the filename addresses it. §req:low-friction-governance
- **Suffix placement, uniform across the three documents.** A slug sits at the
  end of its heading text: `### Tool change workflow §road:tool-change`. ROADMAP
  no longer writes the slug first with no title.
- **Flat, unique namespace.** A slug encodes no hierarchy — `§spec:tool-change`,
  never `§spec:machine-control/tool-change`. Each slug is unique within its
  prefix across the governance root; a duplicate definition fails
  governance-lint. Markdown depth is presentation, the slug is identity, so an
  address survives promotion, demotion, and reordering untouched.
- **Every reference resolves to exactly one heading.** A `§`-reference that
  matches no defined slug, or more than one, fails governance-lint. Code spans
  and fenced blocks are exempt, as today. One resolver subsumes the uniqueness
  and dangling-reference checks.
- **Positional addressing is rejected.** A heading whose text begins with a
  numeric ordinal (`## 8. Machine control`) fails governance-lint; a topic name
  that merely starts with a digit (`## 3D visualization`) passes. A `§`-reference
  to a numeric address (`§8.9`) fails at the same gate, code spans and fenced
  blocks exempt. A heading numbered in prose (`### Stage 1 — envelope check`)
  draws a Vale warning, not a failure: the number may describe the system
  (`Stage 2 bootloader`) rather than the document's structure, so a human
  accepts or renames it.
- **Status lines stay orthogonal.** A valid status line is still required on
  every `##` SPEC heading and nowhere else; slugs and status lines compose
  without interacting. §spec:notation-contract

| Document | Slug prefix | Slug required on | Status line |
|----------|-------------|------------------|-------------|
| REQUIREMENTS.md | `§req:` | every `##`; deeper optional | none |
| SPEC.md | `§spec:` | every `##`; deeper optional | every `##` |
| ROADMAP.md | `§road:` | every `##`; deeper optional | none |

### Why explicit slugs, not slugs inferred from heading text

An inferred slug — `slugify(heading text)` — would drop the slug from the
heading and read it from the title instead. It is rejected because a slug is a
stable identity and a title is presentation this project edits routinely (prose
passes, compression). Deriving identity from the title recouples the two, so a
heading copyedit churns every reference that cited it — the renumbering disease
transposed from numbers to words. Repeated subsection titles ("Observable
behavior", "Rejected alternatives") would also collide, forcing positional
disambiguation, the fragility this grammar exists to remove. An explicit slug is
decoupled from its title: a heading reworded for prose keeps its address.
§req:quality-attributes

### Why optional below the section level

Requiring a slug on every heading at every depth would tax every document
forever — symphonize's own spec would slug dozens of "Observable behavior" and
"Rejected alternatives" subsections that nothing cites, against
§req:low-friction-governance. Optional deeper slugs make precision available and
cheap rather than mandatory: an author slugs a subsection when, and only when,
something references it. A large adopter slugs the subtopics its roadmap cites
and leaves the rest bare; a small project slugs almost nothing below its
sections. The resolver guarantees that whatever is cited is addressable and
resolves. §req:large-spec-addressing

### Why retire positional addressing

A number keyed to a section's position breaks the moment a section is inserted,
removed, or reordered, and tooling keyed to the old positions then matches
nothing and reports success — the silent false green §spec:notation-contract
guards against. Rejecting numbered headings and numeric references at the lint
gate, alongside the slug grammar, closes that failure mode for an adopter
migrating off a numbered scheme. §req:large-spec-addressing §req:modular-adoption

### Adopter migration

Retiring ordinals breaks anything keyed to section numbers outside the
governance files — `@spec §8.9` test annotations, coverage tooling that greps
them against `## N.` headings. Left unconverted, such tooling matches zero
sections and reports success. An adopter's migration converts heading numbers to
slugs and the external annotations and tooling that referenced them in the same
change. notation's adopter documentation and the `init` scaffolder own this
guidance; symphonize's own documents already use slug headings, so its migration
is the placement and coverage change only. §req:modular-adoption

### Rejected alternatives

- **Mandatory slug on every heading at every depth.** Uniform and maximally
  addressable, but it taxes every document with slugs on uncited boilerplate and
  forces unique names on repeated subsection titles. Rejected against
  §req:low-friction-governance — optional deeper slugs give the same
  addressability where it is used.
- **Slugs inferred from heading text** (see above). Rejected: recouples identity
  to presentation and collides on repeated titles.
- **Inferred slugs matching a Git host's anchor algorithm** (e.g. GitHub's).
  Rejected: it would weld a host-agnostic contract to one host's mutable,
  position-deduped rule, and the apparent benefit — references that double as
  clickable anchors — does not exist while references are plain text rather than
  markdown links.
- **Hierarchical slugs** (`§spec:machine-control/tool-change`). Rejected:
  encoding containment in the identifier reimports the renumbering disease —
  promoting a subsection to a section breaks every reference. Flat slugs survive
  restructuring.

### Tradeoffs accepted

- Optional deeper slugs let an author cite a parent section when the precise
  subsection is unslugged, losing precision. This is a discipline matter, not a
  correctness one; the authoring commands encourage slugging the unit cited.
- An explicit slug duplicates words from its heading when the author picks a slug
  that echoes the title. The duplication is benign — the slug is the stable
  identifier, deliberately allowed to differ — and avoidable with a short slug.

## Integration-ref resolution §spec:integration-ref
*Status: complete*

symphonize's commands and the batch-agent protocol hardcode `main` as the
integration branch: `git checkout -b … origin/main`, "verify main is current",
`git log main..<branch>`, reading ROADMAP.md from `origin/main`, rebasing onto
`origin/main`. A project whose trunk is `develop` — or anything other than
`main` — targets the wrong branch in every command (§req:modular-adoption).
Reported by an external adopter whose trunk is not `main`.

### Observable behavior

- **The integration trunk is resolved once, not hardcoded.** Commands and
  protocols reference a single resolved trunk branch rather than the literal
  `main`, defaulting to the repository's own default branch so a non-`main` trunk
  works without per-command edits. The `main`-relative comparisons in
  §spec:clean-supersession-safety and §spec:repo-state-reconciliation use the
  resolved trunk.

### Why resolve rather than hardcode

The contract serves adopters beyond symphonize's own repository
(§req:modular-adoption), and those adopters do not all use `main`. Resolving the
trunk from the repository's default branch — rather than introducing a
configuration file — keeps the "no state beyond governance documents" constraint
intact while removing the wrong-branch failure for every non-`main` project.

The single trunk is a deliberate scope boundary, not just an implementation
choice: symphonize is trunk-based / GitHub Flow only and does not model
GitFlow/GitLab-Flow long-lived branches or the merge-forward cascade
(§req:constraints).

### Scope

The hardcoded trunk spans conduct (`next.md`, `review.md`, `clean.md`,
`protocols/batch-agent.md`) and compose (`triage.md`, `roadmap.md`), plus the
`main`-relative descriptions in §spec:clean-supersession-safety and
§spec:repo-state-reconciliation. The change is cross-plugin and touches the
shared branching convention every agent inherits.

## Batch delivery §spec:batch-delivery
*Status: complete*

Every attempted batch ends in a reviewable PR or an explicit failure, never a
silent no-op. A partial success that reads as completion is the worst failure
mode — the loop advances believing a PR exists, the ROADMAP keeps listing shipped
work, and the gap surfaces only on a later manual check. Delivery is therefore a
hard completion gate, owned by the dispatch layer. §req:success-criteria

The original defect: a batch agent ran its mandatory quality gates as Skills and
stalled, because a Skill ends a sub-agent's turn before delivery — it committed
its work, emitted the review, and stopped (observed twice, #132). The gates now
run at the dispatch layer, where the session loop survives a Skill
(§spec:batch-agent-leaf), so the stall cannot recur. The dispatch layer's
former *recovery* path — adopt the committed worktree and finish delivery — is
now the *primary* delivery path, exercised every batch.

### Observable behavior

- **Delivery is a hard completion gate.** `/conduct:next` does not report success
  until a reviewed PR exists; a return without a PR URL is a failure, not a
  partial success. Removing the shipped workstream from ROADMAP.md is part of the
  same gate.
- **The dispatch layer delivers.** The batch agent returns a pushed branch; the
  dispatch layer runs the review gates against it, re-runs CI, removes the shipped
  ROADMAP workstream, and opens the PR. When the agent instead returns a failure
  (no pushed branch), the dispatch layer adopts the worktree's committed work and
  delivers from it — the commits are the source of truth.
- **Delivered branches use the conventional name.** A delivered branch follows
  `<type>/<scope>-<slug>`, never the `worktree-agent-<id>` name the isolation
  harness assigns to the worktree.

### Why recovery from commits, not resume

In-band resumption of a stalled sub-agent is not assumable. `SendMessage`-based
resume is gated behind Claude Code's `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`,
which is off by default and — because the gate is read at module init — takes
effect only through a shell-level environment export before launch, not through
`settings.json`. It is also version-dependent. So when an agent fails to push, the
dispatch layer finishes delivery from the worktree's commits, which already exist,
without depending on any resume mechanism.

Reported by the maintainer (#132) and corroborated by two stalls observed in
practice.
