---
description: Validate governance files (SPEC.md, ROADMAP.md, README.md)
---

Validate governance files locally. Runs the same checks as the
`governance-lint.yml` CI workflow.

## Checks

### 1. Markdownlint

Run `npx markdownlint-cli2 SPEC.md ROADMAP.md README.md`.

Use the project's `.markdownlint.json` if it exists. If not, use
these defaults:

```json
{"MD013": false, "MD024": false, "MD036": false}
```

Report all violations. Do not auto-fix.

### 2. SPEC.md status lines

If SPEC.md exists, verify every numbered section (`## N.`) has a
valid status line immediately after the heading (blank lines between
heading and status are allowed):

```
*Status: not started|in progress|complete*
```

Report each section with a missing or invalid status line.

### 3. README heading validation

Skip this check unless the project's `.claude-plugin/plugin.json`
or `package.json` indicates a project type, or the user passes a
type argument.

For `library` projects, require: Installation, Usage, API, License.
For `application` projects, require: Getting Started, Usage, License.

Accept synonym patterns (case-insensitive):
- License: `license`, `licensing`, `licensing note`
- Installation: `installation`, `install`, `getting started`, `quick start`
- Usage: `usage`
- API: `api`, `api reference`
- Getting Started: `quick start`, `getting started`, `installation`, `install`

## Output

Report all errors, then exit. Print a summary line:
- `✓ All governance checks passed` (zero errors)
- `✗ N governance error(s) found` (one or more errors)

$1
