# Canonical fragments

Single-source content assembled into multiple plugin command files.

## Why

Installed plugins are copied into `~/.claude/plugins/cache/` and cannot read
files outside their own directory — `../` into a sibling plugin dangles at
cache-copy time (SPEC §spec:plugin-packaging). Shared content must therefore
physically live inside each plugin. Hand-duplication drifts. Each fragment
here is the one source of truth; `tools/assemble-fragments.sh` writes it into
every consumer, and CI fails when a committed copy drifts.

## Fragments

- **governance-root.md** — the governance-root resolution algorithm (walk up
  from CWD to the nearest ancestor containing SPEC.md; fall back to the repo
  root). Consumed by `compose` (`discover`, `plan`, `roadmap`) and `conduct`
  (`next`).

## Markers

Each consumer delimits the assembled region with HTML comments:

```markdown
<!-- assembled:governance-root -->
... canonical content, overwritten by the build ...
<!-- /assembled:governance-root -->
```

Everything outside the markers is hand-authored and untouched by the build —
including each command's own surrounding context (the section heading, the
intro sentence, the per-command list of files read and written, and the
upstream-context paragraph), which legitimately varies per command.

## Build

```sh
tools/assemble-fragments.sh
```

Idempotent. The consumer registry lives in the script's `CONSUMERS` array;
add a `fragment|path` entry to enroll a new file. CI runs the build then
`git diff --exit-code`, so a drifted committed file fails the job. The fix is
the same command: run `tools/assemble-fragments.sh` and commit.
