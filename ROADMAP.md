# symphonize — Roadmap

## Pre-PR review gates

### §road:security-review-gate

Add `/security-review` as a mandatory gate in
`protocols/batch-agent.md` between Phase 5 (Verify) and Phase 6
(Deliver). Add `/review --comment` as a recommendation in the PR
body template. Per §spec:pre-pr-review-gates.

Changes to `protocols/batch-agent.md`:

- Insert a new step after Phase 5 verification passes: run
  `/security-review`, resolve any findings before proceeding to
  Phase 6.
- In Phase 6 step 2 (PR body), add a line recommending the reviewer
  run `/review --comment` for code-quality findings.

**Verify:** Run `/symphonize:next` against a workstream. Confirm
the batch agent runs `/security-review` before pushing. Confirm the
PR body includes the `/review --comment` recommendation.
