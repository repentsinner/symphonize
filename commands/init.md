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

  ## <first section> §spec:<slug>
  *Status: not started*

  <!-- Describe the desired behavior of this section. -->
  ```
- **ROADMAP.md** — skeleton:
  ```markdown
  # <project-name> — Roadmap

  <!-- Sections in build-dependency order. -->
  <!-- Workstreams as `- **slug**: description` bullets. -->
  ```
- **REQUIREMENTS.md** — skeleton:
  ```markdown
  # <project-name> — Requirements

  <!-- Problem-space document. Each ## section carries a §req:slug suffix. -->
  <!-- Run /symphonize:discover to populate through a structured interview. -->
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

### Prose linting (Vale)

- **.vale.ini** — Vale config:
  ```ini
  StylesPath = styles
  MinAlertLevel = warning

  [SPEC.md]
  BasedOnStyles = Requirements

  [REQUIREMENTS.md]
  BasedOnStyles = Requirements
  ```
- **styles/Requirements/MustDeprecated.yml** — flags deprecated `must`:
  ```yaml
  extends: existence
  message: "'%s' is deprecated by IEEE. Use 'shall' for mandatory requirements."
  ignorecase: true
  level: error
  scope: sentence
  tokens:
    - '\bmust\b'
  ```
- **styles/Requirements/WillDeprecated.yml** — flags deprecated `will`:
  ```yaml
  extends: existence
  message: "'%s' is deprecated by IEEE for requirements. Use 'shall' for mandatory, 'should' for recommended."
  ignorecase: true
  level: warning
  scope: sentence
  tokens:
    - '\bwill\b'
  ```
- **styles/Requirements/FillerPhrases.yml** — catches filler:
  ```yaml
  extends: existence
  message: "Filler phrase '%s' — cut it."
  ignorecase: true
  level: warning
  scope: sentence
  tokens:
    - 'it should be noted that'
    - 'in order to'
    - 'due to the fact that'
    - 'it is important to note'
    - 'at this point in time'
    - 'for the purpose of'
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

### Git hooks

Create `.githooks/pre-commit`:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Only lint when governance files are staged
staged=$(git diff --cached --name-only)
if echo "$staged" | grep -qE '^(SPEC|ROADMAP|README)\.md$'; then
  npx markdownlint-cli2 SPEC.md ROADMAP.md README.md
fi
```

Then activate hooks for this checkout:

```bash
git config core.hooksPath .githooks
```

The hook scripts live in `.githooks/` (tracked). Activation is
per-checkout via `core.hooksPath` — git intentionally does not
auto-run hooks on clone. Consumers who fork the repo opt in by
running `/symphonize:init` in their checkout.

CI remains the backstop for contributors who haven't activated
hooks.

## Behavior

1. Read the project name from the repo directory name or manifest.
2. For each file above, check if it exists. If it does, print
   `skip: <path> (already exists)` and move on.
3. Create any missing files with the templates above.
4. Make `.githooks/pre-commit` executable.
5. Run `git config core.hooksPath .githooks` to activate hooks.
6. Run `/symphonize:lint` to validate the result.
7. Print a summary of created and skipped files.

Do NOT commit. Leave the files unstaged so the user can review
and commit when ready.

$1
