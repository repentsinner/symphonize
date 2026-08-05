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

Also create `.github/dependabot.yml`. The scaffolded workflows are the
project's copies to maintain, and their action pins go stale; Dependabot
is what keeps them current:

```yaml
version: 2
updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
```

If the file exists, add the `github-actions` entry only when it is
missing; leave every other entry alone.

### Release automation

Each option's templates live at
`${CLAUDE_PLUGIN_ROOT}/templates/<tool>/`. Copy the files its section
below names, verbatim — nothing else in that directory is a template.

#### Detect before prompting

Read repo state first and skip the prompt when it already answers:

- `.flywheel.yml` present → flywheel.
- `release-please-config.json` present → release-please.
- Neither → prompt.

On a detected choice, print
`detected release automation: <tool>` and scaffold only the missing
files of that tool's set. Switching tools is not a prompt outcome —
tell the adopter to remove the old config first.

#### Prompt

When nothing is detected, ask: "How should releases be cut from
conventional commits?" Offer flywheel (default), release-please, and
manual. Take flywheel when the adopter accepts the default or the run
is unattended.

- **flywheel** — per-PR auto-merge by commit type, release on push to
  a managed branch. Fits single-package projects.
- **release-please** — accumulates commits into a release PR. Fits
  monorepos needing linked versions across packages.
- **manual** — no release automation. Edit CHANGELOG.md and tag by
  hand.

#### flywheel

Copy from `templates/flywheel/`:

- `.flywheel.yml` → the repository root. If the repo's default branch
  is not `main`, rename the branch entry to match.
- `flywheel-pr.yml`, `flywheel-push.yml` → `.github/workflows/`.

Report the remaining setup as manual steps — they need repo admin and
`gh`, so do not run them:

1. Install a GitHub App with Contents, Pull requests, Issues, and
   Checks read/write, then store its id as the repository **variable**
   `FLYWHEEL_GH_APP_ID` and its private key as the **Actions secret**
   `FLYWHEEL_GH_APP_PRIVATE_KEY`. Registering that key in the
   **Dependabot** secret store as well is a separate decision: it is what
   lets Dependabot's `chore(deps)` PRs auto-merge unreviewed, including
   bumps to the flywheel pin itself. Leave it unregistered to keep the
   review gate.
2. Enable "Allow auto-merge" in repository settings.
3. Grant the App a branch-protection bypass on managed branches —
   without it, flywheel cannot push its release commit or tag.

State the trust this buys: flywheel is a third-party action, and steps 1
and 3 hand it a private key plus the standing to write the default branch
unreviewed. The templates pin it by commit SHA so its repository cannot
repoint that credential at new code; review each bump.

<https://github.com/point-source/flywheel> carries a setup script that
automates the three steps. Say it exists, say it provisions the App, and
tell the adopter to read it before running it — do not run it here.

#### release-please

Copy from `templates/release-please/`:

- `release-please.yml`, `auto-merge-release.yml`,
  `update-major-tag.yml` → `.github/workflows/`.

Then generate `release-please-config.json` and
`.release-please-manifest.json` with the project's current version (read
from `package.json`, `pubspec.yaml`, `.claude-plugin/plugin.json`, or
default to `0.1.0`).

The workflows authenticate through a GitHub App. Report as a manual
step: store the App id as `RELEASE_BOT_APP_ID` and its private key as
`RELEASE_BOT_PRIVATE_KEY`, both repository secrets.

#### manual

Scaffold no release-automation files. CHANGELOG.md still gets its
`[Unreleased]` section from the governance-file step above.

### Git hooks

Create `.githooks/pre-commit`:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Only lint when governance files are staged
staged=$(git diff --cached --name-only)
if ! echo "$staged" | grep -qE '^(SPEC|ROADMAP|README)\.md$'; then
  exit 0
fi

# Git hooks run with a minimal PATH and do not inherit an interactive shell,
# so version-manager shims (nvm, fnm, volta) are absent and a bare `npx`
# fails even when node is installed. Look in the usual places.
if ! command -v npx >/dev/null 2>&1; then
  for dir in \
    "$HOME"/.nvm/versions/node/*/bin \
    "$HOME"/.volta/bin \
    "$HOME"/.local/share/fnm/node-versions/*/installation/bin \
    /opt/homebrew/bin \
    /usr/local/bin
  do
    if [ -x "${dir}/npx" ]; then
      PATH="${dir}:${PATH}"
      export PATH
      break
    fi
  done
fi

# No node toolchain reachable: skip rather than block. CI runs the same
# check and is the authority.
if ! command -v npx >/dev/null 2>&1; then
  echo "pre-commit: npx not found, skipping markdownlint (CI still enforces it)" >&2
  exit 0
fi

npx markdownlint-cli2 SPEC.md ROADMAP.md README.md
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
   a. Create `.github/workflows/governance-lint.yml` and
      `.github/dependabot.yml`.
   b. Resolve the release-automation tool per § Release automation and
      copy its templates.
   c. Create `.githooks/pre-commit` and make it executable.
   d. Run `git config core.hooksPath .githooks` to activate hooks.
6. If CWD is not the repo root, skip CI workflows, release automation,
   and hooks with a note.
7. Run `/notation:lint` to validate the result.
8. Print a summary of created and skipped files, the release-automation
   tool used, and any manual setup steps it needs.

Do NOT commit. Leave the files unstaged so the user can review
and commit when ready.

$1
