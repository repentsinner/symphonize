**Modal verbs, in requirements.** `shall` marks a requirement, `should` a
recommendation, `may` permission (IEEE SA Standards Style Manual). That
manual deprecates `must` and `will` only *for stating requirements*; it
permits `must` for an unavoidable situation and `will` for a statement
of fact. A linter cannot tell those uses apart by their words, so a
requirement takes a form it can recognize: in REQUIREMENTS.md, state
each requirement as a list item. The scaffolded style flags `must` and
`will` in those list items as errors, and narrative, rationale and
problem statements keep IEEE's allowance.

SPEC.md is declarative and carries no modal rules. Describe what the
system does ("the hook searches the plugin cache"), not what it shall
do; obligation belongs in REQUIREMENTS.md. Prefer rephrasing to
substitution everywhere: "the adopter re-maps each header" beats "the
adopter shall re-map each header" where nothing is required.

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

These rules derive from Strunk & White, *The Elements of Style* —
Rule 17, "omit needless words"; the Google Developer Documentation
Style Guide (<https://developers.google.com/style>) — tone, voice and
conciseness; Gernot Heiser, "Notes on Writing"
(<https://gernot-heiser.org/style-guide.html>) — gainful compression
and passive-voice limits; and the IEEE SA Standards Style Manual —
modal verbs.
