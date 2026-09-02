#!/usr/bin/env bash
#
# Symphonize prose lint hook (PostToolUse).
#
# Vale already gates governance prose in CI and at commit. Neither is the
# cheapest moment to learn about it: by then the author has moved on, and a
# modal verb costs a round trip through review or a CI run to correct. This
# hook closes that gap by linting the one file that was just written, in the
# turn that wrote it (SPEC §spec:prose-lint-hook).
#
# Contract:
#   - Read-only. Runs Vale against a single file and reports; changes nothing.
#   - Silent no-op unless the written file is SPEC.md or REQUIREMENTS.md.
#   - Silent no-op when the governance root has no .vale.ini — prose linting is
#     opt-in (§spec:prose-linting) and a hook may not opt a project in.
#   - Silent no-op when Vale cannot be resolved. A missing linter is a gap in
#     the environment, not a defect in the prose, and nagging about it every
#     write would train the reader to ignore the hook.
#   - On findings, prints them on stderr and exits 2, which is how PostToolUse
#     returns feedback. The write already happened; the point is that the
#     author sees the finding before moving on.
#   - Reports warnings as well as errors. CI fails only on errors, so the
#     warning tier stays honest precisely because this hook surfaces it while
#     the fix is free.
#
# The Vale pin is read from governance-lint.sh rather than repeated here. One
# source of truth for the version means the hook and the gate cannot disagree.
#
# Env overrides (testing):
#   PROSE_LINT_VALE   absolute path to a vale binary, bypassing resolution

set -u

# Any unexpected failure exits clean: a broken hook must not obstruct writing.
bail() { exit 0; }

command -v jq >/dev/null 2>&1 || bail

payload="$(cat)"
[ -n "$payload" ] || bail

file="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // empty' 2>/dev/null)"
[ -n "$file" ] || bail
[ -f "$file" ] || bail

case "$(basename "$file")" in
  SPEC.md | REQUIREMENTS.md) ;;
  *) bail ;;
esac

# The governance root is the nearest ancestor holding .vale.ini. Vale resolves
# its own config by walking up, but it needs to run from that directory for the
# section patterns ([SPEC.md]) to match the path it is given.
dir="$(cd "$(dirname "$file")" && pwd)" || bail
root=""
while [ "$dir" != "/" ]; do
  if [ -f "$dir/.vale.ini" ]; then root="$dir"; break; fi
  dir="$(dirname "$dir")"
done
[ -n "$root" ] || bail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
pin="$(sed -n 's/^vale_version="\(.*\)"/\1/p' "${script_dir}/../scripts/governance-lint.sh" 2>/dev/null)"

# Same precedence as the contract script: an exact-version match on PATH, then
# the pinned resolver. A different version on PATH is not used, because a hook
# that reports findings CI will not raise teaches the author to distrust it.
vale_cmd=""
if [ -n "${PROSE_LINT_VALE:-}" ]; then
  vale_cmd="$PROSE_LINT_VALE"
elif command -v vale >/dev/null 2>&1 &&
  [ "$(vale --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)" = "$pin" ]; then
  vale_cmd="vale"
elif [ -n "$pin" ] && command -v mise >/dev/null 2>&1; then
  vale_cmd="mise x vale@${pin} -- vale"
fi
[ -n "$vale_cmd" ] || bail

rel="${file#"$root"/}"
findings="$(cd "$root" && $vale_cmd --output=line "$rel" 2>/dev/null)"
[ -n "$findings" ] || exit 0

{
  echo "Vale findings in ${rel} — fix them now rather than in CI:"
  echo "$findings"
  echo
  echo "shall = requirement, should = recommendation, may = permission."
  echo "Prefer rephrasing to substitution: drop the modal where nothing is required."
} >&2
exit 2
