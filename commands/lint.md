---
description: Validate governance files (SPEC.md, ROADMAP.md, README.md)
---

Glob for governance files across the directory tree and run
markdownlint against all matches. Uses the project's
`.markdownlint.json` if present (markdownlint resolves config by
walking up the directory tree natively).

Read `${CLAUDE_PLUGIN_ROOT}/CONVENTIONS.md` § Governance root for
the resolution algorithm.

## Procedure

1. From the repository root, glob for governance files:
   `**/SPEC.md **/ROADMAP.md **/README.md **/REQUIREMENTS.md **/CHANGELOG.md`
2. Run `npx markdownlint-cli2` against all matched files.
3. Report the results.

Do not interpret or reimplement lint rules yourself — run the tool
and report its output.

**Scope difference:** this command runs markdownlint only — it checks
markdown formatting (heading structure, line length, etc.). The CI
workflow `governance-lint.yml` runs markdownlint plus additional
validations: SPEC.md status lines, `§spec:`/`§road:`/`§req:` slug
formats, cross-document reference resolution, CHANGELOG.md structure,
and README heading checks. To get the full validation suite, push and
let CI run, or inspect `governance-lint.yml` directly.

$1
