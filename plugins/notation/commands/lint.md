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

1. From the governance root, run the bundled contract script:
   `scripts/governance-lint.sh --readme-type <library|application>`
   It lives beside this command in the notation plugin. Omit
   `--readme-type` when the project has not chosen a profile.
2. Report its output.

Do not interpret or reimplement lint rules yourself — run the script
and report what it says.

**Contract ownership:** notation owns the governance contract, and
`scripts/governance-lint.sh` is its one executable form. CI's reusable
`governance-lint.yml` runs the same script, so what passes here is what
passes there (§spec:governance-lint).

**What it checks:** Vale prose rules; markdownlint formatting; SPEC.md
status lines; a `§spec:`/`§road:`/`§req:` slug suffix on every `##`
heading (deeper headings may carry one); a flat, unique slug namespace
(a duplicate definition fails); every `§`-reference resolving to exactly
one defined slug (code spans and fenced blocks exempt; zero or multiple
matches fail); rejection of positional addressing (a heading beginning
with a numeric ordinal, or any `§<number>` reference); the README
heading profile; and README derivability (§spec:readme-derivable).

**Local runs are a subset, and say so.** Vale and markdownlint need
tools a contributor may not have installed. When one is absent the
script skips that check with a notice and runs the rest — it never
reports clean on a check it did not run. CI passes `--require-tools`,
which turns absence into a failure, so CI runs the whole contract
unconditionally.

$1
