# symphonize — Roadmap

## Thin roadmap workstreams

### §road:thin-roadmap-command

Update `commands/roadmap.md` Phase 3 output format to produce thin
workstreams — one sentence plus `§spec:` citation, no design
context. Per §spec:thin-roadmap-workstreams.

**Verify:** Run `/symphonize:roadmap` against a spec section with
detailed rationale. Confirm the generated workstream is one sentence
plus a `§spec:` citation — no duplicated rationale, no "Changes to"
blocks.
