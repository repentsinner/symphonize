# symphonize — Roadmap

## Thin roadmap workstreams

### §road:thin-roadmap-conventions

Add "one sentence + `§spec:` citation" rule to CONVENTIONS.md
§ Roadmap format. Prohibit duplicating spec rationale in workstream
descriptions. Per §spec:thin-roadmap-workstreams.

### §road:thin-roadmap-command

Update `commands/roadmap.md` Phase 3 output format to produce thin
workstreams — one sentence plus `§spec:` citation, no design
context. Per §spec:thin-roadmap-workstreams.
Depends on §road:thin-roadmap-conventions.

**Verify:** Run `/symphonize:roadmap` against a spec section with
detailed rationale. Confirm the generated workstream is one sentence
plus a `§spec:` citation — no duplicated rationale, no "Changes to"
blocks.
