# symphonize — Roadmap

## Simplify gate in batch-agent protocol

### §road:batch-agent-simplify-phase

Add Phase 5a (simplify gate) to `protocols/batch-agent.md` between
Phase 5 (Verify) and Phase 5b (`/security-review`), implementing
single invocation, doc-only skip detection, fix review, and CI
re-run per §spec:simplify-gate.

**Verify:** Read `protocols/batch-agent.md` at the PR branch. Confirm
Phase 5a sits between Phase 5 and Phase 5b with these elements: (1)
skip-condition check via `git diff --name-only` against merge base,
excluding non-source files; (2) single `/simplify` invocation, not a
loop; (3) batch-agent review of applied fixes with revert-on-conflict
instruction; (4) mandatory CI re-run after fixes settle; (5)
explicit handoff to Phase 5b. Cross-reference §spec:simplify-gate
and confirm every design decision in the spec (mandatory, single
invocation, skip condition, ordering, fix review) is represented in
the protocol text. Run `/symphonize:lint` and confirm no
markdownlint errors.
