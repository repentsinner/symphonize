**Modal verbs, document-wide.** `shall` marks a requirement, `should` a
recommendation, `may` permission (IEEE SA Standards Style Manual).
`Must` and `will` are deprecated, and the scaffolded Vale style flags
them in *any* sentence of SPEC.md or REQUIREMENTS.md — narrative,
rationale and problem statements included, not criteria alone. Vale
matches per sentence and cannot tell a requirement line from a narrative
one, so the guidance matches the rule's reach rather than fighting it.
Prefer rephrasing to substitution: "the adopter re-maps each header"
beats "the adopter shall re-map each header" where nothing is required.

**Omit needless words.** Cut adverbs, qualifiers and hedges — `very`,
`really`, `basically`, `simply`, `just`. One idea per sentence. Prefer
the concrete noun and the active verb: "returns null", not "may
potentially result in an empty value."

**Filler phrases fail the linter.** `it should be noted that`, `in order
to` (use "to"), `due to the fact that` (use "because"), `it is important
to note`, `at this point in time`, `for the purpose of`.

**One term per concept.** Pick one of check / verify / confirm /
validate, one of config / settings, and hold it for the whole document.
Terseness rules cannot catch synonym rotation — every one of those words
is equally short.

**Condition before command.** "If the build fails, read the log" — not
the reverse.

**No self-evident commentary.** Do not assert that something is novel,
important or interesting. If it is, the reader notices.

References: IEEE SA Standards Style Manual — modal verbs; Strunk &
White, *The Elements of Style* — Rule 17, "omit needless words";
Heiser, "Notes on Writing" — gainful compression; Google Developer
Documentation Style Guide — tone and voice.
