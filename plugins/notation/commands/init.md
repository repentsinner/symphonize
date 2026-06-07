---
description: Scaffold governance files and CI workflows into a project
---

Scaffold the governance file loop and CI workflows into the current
project. Idempotent — skip files that already exist, warn on each
skip.

## Governance root resolution

Resolve the governance root before creating files:

1. The governance root is the current working directory (CWD).
   When run from a subdirectory (e.g., `packages/auth/`), scaffold
   governance files there — not at the repo root.
2. CI workflows and git hooks always go at the repo root (they are
   repo-level, not package-level). If CWD is not the repo root,
   skip CI workflow and git hook scaffolding with a note:
   `skip: CI workflows and hooks (package-level init — configure
   at repo root)`.

## Files to scaffold

### Governance files

Create at the governance root (CWD):

- **SPEC.md** — skeleton:
  ```markdown
  # <project-name> — Specification

  <!-- Each ## section carries a §spec:slug suffix (title then slug). -->
  <!-- Headings deeper than ## may carry a slug — required only to make -->
  <!-- them referenceable. -->

  ## <first section> §spec:<slug>
  *Status: not started*

  <!-- Describe the desired behavior of this section. -->
  ```
- **ROADMAP.md** — skeleton:
  ```markdown
  # <project-name> — Roadmap

  <!-- Sections in build-dependency order. Each ## section carries a -->
  <!-- §road:slug suffix (title then slug). Workstreams are ### headings -->
  <!-- in suffix form: ### <Title> §road:<slug>. -->

  ## <first section> §road:<slug>

  ### <first workstream> §road:<slug>
  ```
- **REQUIREMENTS.md** — skeleton:
  ```markdown
  # <project-name> — Requirements

  <!-- Problem-space document. Each ## section carries a §req:slug suffix -->
  <!-- (title then slug). Run /compose:discover to populate through a -->
  <!-- structured interview. -->

  ## <first section> §req:<slug>
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
- **styles/Requirements/OrdinalHeadings.yml** — warns on ordinal-prose headings:
  ```yaml
  extends: existence
  message: "Heading '%s' is numbered in prose. If the number is document structure, address by §slug instead; if it describes the system, keep it."
  level: warning
  scope: heading
  nonword: true
  tokens:
    - '^(Stage|Phase|Step|Part|Pass|Round|Tier|Level|Iteration)\s+([0-9]+[a-z]?|[IVXivx]+)\b'
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
      uses: repentsinner/symphonize/.github/workflows/governance-lint.yml@notation--v0
      with:
        readme-type: ""
  ```
  Ask the user whether their project is a `library` or `application`
  and set `readme-type` accordingly. Leave empty if they decline.

  Pin the `@notation--v0` floating major tag: `governance-lint.yml`
  belongs to the notation plugin, whose coordinated version line is
  pre-1.0, so the adopter-facing major ref is `notation--v0` (not `v1`).
  `update-major-tag.yml` moves this tag forward on each notation release.

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
running `/notation:init` in their checkout.

CI remains the backstop for contributors who haven't activated
hooks.

## Behavior

1. Resolve the governance root per § Governance root resolution above.
2. Read the project name from the repo directory name or manifest.
3. For each file above, check if it exists at the governance root.
   If it does, print `skip: <path> (already exists)` and move on.
4. Create any missing governance files at the governance root.
5. If CWD is the repo root, also scaffold CI workflows and hooks:
   a. Create CI workflow files under `.github/workflows/`.
   b. Create `.githooks/pre-commit` and make it executable.
   c. Run `git config core.hooksPath .githooks` to activate hooks.
6. If CWD is not the repo root, skip CI workflows and hooks with
   a note.
7. Run `/notation:lint` to validate the result.
8. Print a summary of created and skipped files.

Do NOT commit. Leave the files unstaged so the user can review
and commit when ready.

$1
