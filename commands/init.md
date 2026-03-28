---
description: Scaffold governance files and CI workflows into a project
---

Scaffold the governance file loop and CI workflows into the current
project. Idempotent — skip files that already exist, warn on each
skip.

## Files to scaffold

### Governance files

Create at the repo root:

- **SPEC.md** — skeleton:
  ```markdown
  # <project-name> — Specification

  ## 1. <first section>
  *Status: not started*

  <!-- Describe the desired behavior of this section. -->
  ```
- **ROADMAP.md** — skeleton:
  ```markdown
  # <project-name> — Roadmap

  <!-- Sections in build-dependency order. -->
  <!-- Workstreams as `- **slug**: description` bullets. -->
  ```
- **CHANGELOG.md** — skeleton:
  ```markdown
  # Changelog

  All notable changes to this project will be documented in this file.

  The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
  and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

  ## [Unreleased]
  ```

### Lint config

- **.markdownlint.json** — default config:
  ```json
  {"MD013": false, "MD024": false, "MD036": false}
  ```

### CI workflows

Create under `.github/workflows/`:

- **governance-lint.yml** — caller workflow:
  ```yaml
  name: Governance Lint
  on:
    push:
      branches: [main]
    pull_request:

  jobs:
    lint:
      uses: repentsinner/symphonize/.github/workflows/governance-lint.yml@v1
      with:
        readme-type: ""
  ```
  Ask the user whether their project is a `library` or `application`
  and set `readme-type` accordingly. Leave empty if they decline.

- **release-please.yml** — copy from symphonize's template. Also
  create `release-please-config.json` and
  `.release-please-manifest.json` with the project's current version
  (read from `package.json`, `pubspec.yaml`, `.claude-plugin/plugin.json`,
  or default to `0.1.0`).

- **auto-merge-release.yml** — copy from symphonize's template.

- **update-major-tag.yml** — copy from symphonize's template.

## Behavior

1. Read the project name from the repo directory name or manifest.
2. For each file above, check if it exists. If it does, print
   `skip: <path> (already exists)` and move on.
3. Create any missing files with the templates above.
4. Run `/symphonize:lint` to validate the result.
5. Print a summary of created and skipped files.

Do NOT commit. Leave the files unstaged so the user can review
and commit when ready.

$1
