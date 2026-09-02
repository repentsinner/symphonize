**Modal verbs, document-wide.** `shall` marks a requirement, `should` a
recommendation, `may` permission (IEEE SA Standards Style Manual). That
manual deprecates `must` and `will` *for stating mandatory
requirements*; it permits `must` for an unavoidable situation and `will`
for a statement of fact. Vale cannot tell a requirement line from a
narrative one, so the scaffolded style flags both in *any* sentence of
SPEC.md or REQUIREMENTS.md — narrative, rationale and problem statements
included, not criteria alone — as an error in REQUIREMENTS.md and a
warning in SPEC.md, where the rationale IEEE still permits them in
lives.
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

These rules derive from Strunk & White, *The Elements of Style* —
Rule 17, "omit needless words"; the Google Developer Documentation
Style Guide (<https://developers.google.com/style>) — tone, voice and
conciseness; Gernot Heiser, "Notes on Writing"
(<https://gernot-heiser.org/style-guide.html>) — gainful compression
and passive-voice limits; and the IEEE SA Standards Style Manual —
modal verbs.
