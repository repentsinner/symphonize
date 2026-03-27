# symphonize — Roadmap

## Reusable CI workflows

Migrate workflow logic from bug-free-happiness into this repo.

- **governance-lint-workflow**: Port `governance-lint.yml` reusable
  workflow with markdownlint, SPEC.md status validation, and
  README heading checks. Include `.markdownlint.json` defaults.
- **template-workflows**: Add `release-please.yml`,
  `auto-merge-release.yml`, and `update-major-tag.yml` as
  template workflows under `.github/workflows/`.

## Lint command

- **lint-command**: Create `/symphonize:lint` command that runs
  the same three checks as `governance-lint.yml` locally via
  CLI tools. Falls back to default `.markdownlint.json` if the
  project doesn't have one.
- **clean-calls-lint**: Update `/symphonize:clean --full` to call
  `/symphonize:lint` instead of inline markdownlint invocation.

## Init command

Depends on governance-lint-workflow, template-workflows.

- **init-command**: Create `/symphonize:init` command that
  scaffolds governance files, `.markdownlint.json`, and
  `.github/workflows/` into the target project. Idempotent —
  skip existing files, warn on conflicts.

## Dogfooding

Depends on governance-lint-workflow.

- **self-ci**: Add `.github/workflows/ci.yml` that calls
  `./.github/workflows/governance-lint.yml` with
  `readme-type: library`.
- **readme-headings**: Ensure README.md has required library
  headings (Installation, Usage, API, License) to pass the
  lint workflow.
