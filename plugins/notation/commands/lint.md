---
description: Validate governance files (SPEC.md, ROADMAP.md, README.md)
---

Glob for governance files across the directory tree and run
markdownlint against all matches. Uses the project's
`.markdownlint.json` if present (markdownlint resolves config by
walking up the directory tree natively).

Resolve the governance root before globbing for governance files:

<!-- assembled:governance-root -->
1. Walk up from the current working directory to find the nearest
   ancestor directory containing SPEC.md.
2. If no ancestor contains SPEC.md, fall back to the repository root.
<!-- /assembled:governance-root -->

## Procedure

1. From the repository root, glob for governance files:
   `**/SPEC.md **/ROADMAP.md **/README.md **/REQUIREMENTS.md **/CHANGELOG.md`
2. Run `npx markdownlint-cli2` against all matched files.
3. Report the results.

Do not interpret or reimplement lint rules yourself — run the tool
and report its output.

**Contract ownership:** notation owns the governance contract. Its
executable form is the reusable `governance-lint.yml` workflow
(`.github/workflows/`) — what the linter checks *is* the contract.

**Scope difference:** this command runs markdownlint only — it checks
markdown formatting (heading structure, line length, etc.). The CI
workflow `governance-lint.yml` runs markdownlint plus the rest of the
notation contract: SPEC.md status lines; a `§spec:`/`§road:`/`§req:`
slug suffix on every `##` heading (deeper headings may carry one); a
flat, unique slug namespace (a duplicate slug definition fails); every
`§`-reference resolving to exactly one defined slug (code spans and
fenced blocks exempt; zero or multiple matches fail); rejection of
positional addressing (a heading beginning with a numeric ordinal, or
any `§<number>` reference, hard-fails); CHANGELOG.md structure; and
README heading checks. To get the full validation suite, push and let
CI run, or inspect `governance-lint.yml` directly.

$1
