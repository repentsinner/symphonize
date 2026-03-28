---
description: Validate governance files (SPEC.md, ROADMAP.md, README.md)
---

Run `npx markdownlint-cli2 SPEC.md ROADMAP.md README.md` and report
the results. Uses the project's `.markdownlint.json` if present.

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
