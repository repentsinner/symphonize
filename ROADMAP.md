# symphonize — Roadmap

## Orchestration loop via /goal

### §road:migrate-orchestrate-to-goal

Replace `/ralph-loop:ralph-loop` with `/goal` in
`commands/orchestrate.md`, and retire residual ralph-loop coupling
in `commands/clean.md` (flag-file mode auto-detect),
`protocols/batch-agent.md`, `README.md`,
`§spec:unattended-flag-passthrough`, and the known-issue note in
`§spec:progress-file-location`. §spec:orchestration-loop

**Verify:** From a project with a populated ROADMAP section, run
`/symphonize:orchestrate`. Confirm: (1) it first invokes
`/symphonize:clean --lite`; (2) it sets an active `/goal`, visible
via `/goal` with no arguments, whose condition targets section
completion; (3) `/symphonize:next --unattended` runs and produces
at least one PR; (4) the goal clears automatically once the
section reports all unblocked workstreams attempted. In a second
session in the same project, run `/symphonize:plan` and confirm
no stop-hook directives fire from ralph-loop. Finally,
`grep -r 'ralph' commands/ protocols/ README.md SPEC.md` shall
return no matches in active code paths (CHANGELOG.md may retain
historical references).

## Scaffolding freshness

### §road:scaffold-consumer-dependabot

Add a `.github/dependabot.yml` (`github-actions`) to the files
`/symphonize:init` scaffolds, and document the scaffold-current-state /
delegate-freshness contract in `commands/init.md`. §spec:scaffold-freshness

**Verify:** a repo scaffolded by `/symphonize:init` contains a
`.github/dependabot.yml` enabling weekly `github-actions` updates;
`commands/init.md` and §spec:scaffold-freshness agree on the contract;
governance-lint passes. The dependabot scaffolding lives with the `init`
scaffolder — `commands/init.md` today, the notation plugin once the
decomposition (§spec:governance-schema) builds it out.

## Relocate the monolith

The decomposition begins by relocating today's single root plugin into
`plugins/symphonize/`, so the repo root holds only the marketplace manifest
and the shared `.github/` workflows. This is a structural no-op for users —
every command stays `/symphonize:*` — but it removes the `source: "./"`
whole-repo-copy hazard before any sibling appears under `plugins/`: a
root-sourced plugin in a repo that also nests `plugins/*` is an
undocumented, untested case that would drag sibling trees into the
umbrella's cache. notation, compose, and conduct are then carved out of
`plugins/symphonize/`; what remains is the umbrella — the same plugin,
relocated once and drained, never deleted or recreated. The command files
are already self-contained (CONVENTIONS.md inlined into them) and ready to
move.

### §road:relocate-monolith

Move the repo's plugin into `plugins/symphonize/` — relocate `commands/`,
`protocols/`, `hooks/`, and `.claude-plugin/plugin.json` (preserving its
`name`, version, and history) under `plugins/symphonize/`, and point
`.claude-plugin/marketplace.json` at `source: "./plugins/symphonize"`.
§spec:plugin-packaging §spec:governance-schema

**Verify:** every `/symphonize:*` command resolves exactly as before;
installing the plugin copies only `plugins/symphonize/`'s tree into
`~/.claude/plugins/cache/` (no repo-root siblings, no `.github/`);
governance-lint passes.

## Notation plugin

The dependency root and the first separately-installable sibling — the
walking skeleton. Carved out of `plugins/symphonize/`, it establishes the
multi-plugin `marketplace.json` (a second entry) and the per-sibling
`plugin.json` pattern the later carve-outs reuse. Depends on
§road:relocate-monolith.

### §road:extract-notation-plugin

Create `plugins/notation/` with its `.claude-plugin/plugin.json`, move
`commands/init.md` and `commands/lint.md` out of `plugins/symphonize/` into
it under the `/notation:*` namespace, and add it to
`.claude-plugin/marketplace.json` with `source: "./plugins/notation"`.
§spec:plugin-packaging §spec:governance-schema

### §road:rehome-notation-contract

Confirm the root `.github/workflows/governance-lint.yml` enforces the full
notation contract — status line and `§`-slug on every `##`/`###` heading,
`§`-reference resolution, Vale-when-present, CHANGELOG excluded — and
re-point notation's `lint` command and docs to notation as its owner.
§spec:notation-contract

**Verify:** `/plugin marketplace add repentsinner/symphonize` lists
notation; installing notation alone exposes `/notation:init` and
`/notation:lint` and no other commands; `/notation:init` scaffolds a repo;
`/notation:lint` runs markdownlint; a SPEC heading missing a status line or
a dangling `§`-reference fails governance-lint in CI.

## compose plugin

The tastemaking layer, carved out of `plugins/symphonize/`. Depends on
§road:extract-notation-plugin (declares `dependencies: [notation]`). Its
authoring methodology already lives inline in the compose commands
(CONVENTIONS.md split landed).

### §road:extract-compose-plugin

Create `plugins/compose/` with a `plugin.json` declaring
`dependencies: [notation]`, move `discover`/`plan`/`roadmap`/`triage` and
the correctness/taste half of `review` out of `plugins/symphonize/` into it
under `/compose:*` — splitting `review` so the taste half lands here.
§spec:plugin-packaging §spec:governance-schema

**Verify:** installing compose auto-installs notation; `/compose:discover`,
`/compose:plan`, `/compose:roadmap`, `/compose:triage`, and `/compose:review`
appear and run; the former `/symphonize:plan` and siblings no longer
resolve.

## conduct plugin

The execution layer, carved out of `plugins/symphonize/`. Depends on
§road:extract-notation-plugin (declares `dependencies: [notation]`). After
this carve-out `plugins/symphonize/` holds only `feedback`.

### §road:extract-conduct-plugin

Create `plugins/conduct/` with a `plugin.json` declaring
`dependencies: [notation]`, and move `next`/`orchestrate`/`clean` and the
integration/merge half of `review` plus `protocols/batch-agent.md` and the
`hooks/` reconcile-repo-state hook out of `plugins/symphonize/` into it
under `/conduct:*`. §spec:plugin-packaging §spec:governance-schema

**Verify:** installing conduct auto-installs notation; `/conduct:next`,
`/conduct:orchestrate`, `/conduct:clean`, and `/conduct:review` appear and
run; the repo-state reconcile hook fires on a stale branch; the former
`/symphonize:next` and siblings no longer resolve; `plugins/symphonize/`
retains only `feedback`.

## symphonize umbrella plugin

With notation, compose, and conduct carved out, `plugins/symphonize/` holds
only `feedback` (and later `yolo`). It becomes the umbrella by declaring its
dependencies — no extraction, no new plugin. Depends on
§road:extract-compose-plugin and §road:extract-conduct-plugin. `yolo`'s
implementation is a separate, not-yet-roadmapped section (§spec:yolo-mode);
this workstream only wires the dependencies `yolo` will need — the command
lands later under its own roadmap pass.

### §road:wire-symphonize-umbrella

Add `dependencies: [compose, conduct]` to `plugins/symphonize/`'s
`plugin.json` so installing `symphonize` pulls the whole product, and
confirm the plugin now contains only `feedback`. §spec:plugin-packaging
§spec:governance-schema

**Verify:** installing `symphonize` auto-installs compose, conduct, and
notation — the whole product in one install; `/symphonize:feedback` appears
and runs; `plugins/symphonize/` contains only `feedback` (no carved-out
commands remain); installing all four plugins yields the full former command
set under the new namespaces.

## Cross-plugin fragment assembly

The residual content every plugin needs — the governance-root resolution
algorithm and the `§`-slug grammar — cannot be shared by `../` reference
across cached plugin directories. Until this section lands, the extraction
sections above hand-copy that fragment into each plugin's commands. Depends
on all four plugins existing (§road:wire-symphonize-umbrella).

### §road:assemble-shared-fragment

Add a canonical source fragment for the governance-root algorithm and
`§`-grammar plus a build step that assembles it into each plugin's command
files, and a CI check that fails when a committed command file drifts from a
fresh assembly. §spec:plugin-packaging

**Verify:** editing the canonical fragment and rebuilding updates every
plugin's command files identically; hand-editing one assembled copy out of
sync fails the CI drift-check; each plugin under `~/.claude/plugins/cache/`
is self-contained with no `../` references.

## Coordinated release

One shared version line across the four plugins, tagged together. Depends
on all four plugins existing (§road:wire-symphonize-umbrella).

### §road:coordinate-plugin-release

Reconfigure `release-please-config.json` and `.release-please-manifest.json`
for the four `plugins/<name>/plugin.json` packages on one shared version,
emit a `{plugin}--v{version}` git tag per plugin, pin compose's and
conduct's notation `dependencies` range and symphonize's compose/conduct
range to that version, and keep `update-major-tag.yml` moving notation's
floating major for adopters' `governance-lint.yml@<major>` pin.
§spec:plugin-packaging

**Verify:** a release PR bumps all four `plugin.json` versions together;
merging it publishes `notation--vX.Y.Z`, `compose--vX.Y.Z`,
`conduct--vX.Y.Z`, and `symphonize--vX.Y.Z`; compose and conduct
`dependencies` resolve notation, and symphonize resolves compose and
conduct, at the shared version; a fresh scaffold's
`governance-lint.yml@<major>` ref points at the released workflow.
