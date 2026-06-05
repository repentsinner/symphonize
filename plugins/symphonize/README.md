# symphonize (umbrella plugin)

The whole-product entry point for the symphonize plugin marketplace.
Installing it pulls all three layers through plugin dependencies and adds the
cross-cutting commands.

## Commands

- `/symphonize:feedback` — report a bug or send feedback to the symphonize
  project.

`/symphonize:yolo` — run the governance pipeline end to end in one shot — is
planned but not yet implemented.

## Layers it composes

- **notation** — the governance schema: file formats, the `§`-slug grammar,
  the reusable `governance-lint.yml` workflow, and the `init` scaffolder.
- **compose** — the tastemaking layer: `/compose:discover`, `plan`, `roadmap`,
  `triage`, and the correctness/taste half of `review`.
- **conduct** — the execution layer: `/conduct:next`, `orchestrate`, `clean`,
  and the integration/merge half of `review`, plus the batch-agent protocol
  and the repo-state reconcile hook.

Install a single layer directly if you only need part of the product
(`/plugin install notation@…`, `compose`, or `conduct`).

See the [repository README](../../README.md) for full usage.
