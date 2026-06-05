# symphonize — Roadmap

## Orchestration loop via /goal

### §road:migrate-orchestrate-to-goal

Replace `/ralph-loop:ralph-loop` with `/goal` in
`plugins/symphonize/commands/orchestrate.md`, and retire residual ralph-loop
coupling in `plugins/symphonize/commands/clean.md` (flag-file mode
auto-detect), `plugins/symphonize/protocols/batch-agent.md`, `README.md`,
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
`grep -r 'ralph' plugins/symphonize/ README.md SPEC.md` shall
return no matches in active code paths (CHANGELOG.md may retain
historical references).

## Scaffolding freshness

### §road:scaffold-consumer-dependabot

Add a `.github/dependabot.yml` (`github-actions`) to the files
`/symphonize:init` scaffolds, and document the scaffold-current-state /
delegate-freshness contract in `plugins/symphonize/commands/init.md`.
§spec:scaffold-freshness

**Verify:** a repo scaffolded by `/symphonize:init` contains a
`.github/dependabot.yml` enabling weekly `github-actions` updates;
`plugins/symphonize/commands/init.md` and §spec:scaffold-freshness agree on
the contract; governance-lint passes. The dependabot scaffolding lives with
the `init` scaffolder — `plugins/symphonize/commands/init.md` today, the
notation plugin once the
decomposition (§spec:governance-schema) builds it out.

## conduct plugin

The execution layer, carved out of `plugins/symphonize/`. Declares
`dependencies: [notation]` (notation is extracted and available). After
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
dependencies — no extraction, no new plugin. compose is already extracted;
this depends on §road:extract-conduct-plugin. `yolo`'s
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
