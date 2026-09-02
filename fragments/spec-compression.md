**Retain** — design rationale (constraints, tradeoffs, rejected
alternatives), expensive to reconstruct and the thing that prevents
re-litigation; observable behavior a reviewer can check against the
running system; state machines and transition tables; cross-references
to other sections.

**Remove** — wire formats, protocol tables and command byte values
(point to the protocol's own documentation); algorithm pseudocode and
step-by-step detail (the code owns *how*, the spec owns *what* and
*why*); edge cases obvious from the implementation or its tests;
`shall` language that restates what the code does without adding
rationale.

**Heuristic** — cover a paragraph with your thumb. If the section's
design intent survives, cut it. If the *why* disappears, keep it.
