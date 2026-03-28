# symphonize — Roadmap

## Unattended flag passthrough

- **unattended-flag-passthrough**: Pass `--unattended` explicitly
  through the full agent hierarchy instead of relying on
  `.claude/ralph-loop.local.md` file detection. Changes:
  `orchestrate.md` (add `--unattended` to ralph-loop prompt),
  `next.md` (read flag from args, remove file check, pass to
  batch agent), `BATCH_AGENT.md` (pass `--unattended` to
  sub-agents in Phase 3, add sub-agent non-interactive behavior
  rule). Implements §spec:unattended-flag-passthrough.
