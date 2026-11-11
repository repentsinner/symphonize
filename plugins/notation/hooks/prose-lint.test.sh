#!/usr/bin/env bash
# Unit tests for prose-lint.sh.
#
# Vale is a stub, so these cover the hook's own policy — which files it acts
# on, when it stays silent, and what it returns — without a linter install.
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="$SCRIPT_DIR/prose-lint.sh"

pass=0
fail=0
ROOT="$(mktemp -d)"
trap 'rm -rf "$ROOT"' EXIT

# A stub Vale: reports one finding for any file containing "must", else silent.
STUB="$ROOT/vale"
cat > "$STUB" <<'EOF'
#!/bin/sh
for a in "$@"; do
  case "$a" in --*) continue ;; esac
  if [ -f "$a" ] && grep -q 'must' "$a"; then
    echo "$a:3:12:Requirements.MustDeprecated:'must' is deprecated by IEEE."
  fi
done
exit 0
EOF
chmod +x "$STUB"

# run FILE — invoke the hook as PostToolUse would, capturing stderr and status.
run() {
  HOOK_ERR="$(PROSE_LINT_VALE="$STUB" \
    printf '{"tool_input":{"file_path":"%s"}}' "$1" | \
    PROSE_LINT_VALE="$STUB" bash "$HOOK" 2>&1 >/dev/null)"
  HOOK_STATUS=$?
}

assert_status() {
  local label="$1" want="$2"
  if [ "$HOOK_STATUS" -eq "$want" ]; then echo "ok   - $label"; pass=$((pass + 1))
  else echo "FAIL - $label (want exit $want, got $HOOK_STATUS)"; fail=$((fail + 1)); fi
}
assert_contains() {
  local label="$1" hay="$2" needle="$3"
  if printf '%s' "$hay" | grep -qF -- "$needle"; then echo "ok   - $label"; pass=$((pass + 1))
  else echo "FAIL - $label (missing '$needle')"; fail=$((fail + 1)); fi
}
assert_empty() {
  local label="$1" hay="$2"
  if [ -z "$hay" ]; then echo "ok   - $label"; pass=$((pass + 1))
  else echo "FAIL - $label (expected silence, got '$hay')"; fail=$((fail + 1)); fi
}

# governed FIXTURE — a governance root whose prose linting is switched on.
governed() {
  local d="$ROOT/$1"
  mkdir -p "$d"
  : > "$d/.vale.ini"
  printf '%s' "$d"
}

echo "== a governance file with a finding =="
d=$(governed with-finding)
printf '# S\n\nThe kernel must be loaded first.\n' > "$d/SPEC.md"
run "$d/SPEC.md"
assert_status   "a finding exits 2 so the author sees it" 2
assert_contains "the finding is reported" "$HOOK_ERR" "MustDeprecated"
assert_contains "the modal guidance is included" "$HOOK_ERR" "shall = requirement"

echo
echo "== REQUIREMENTS.md is governed too =="
d=$(governed requirements)
printf '# R\n\nThe system must respond.\n' > "$d/REQUIREMENTS.md"
run "$d/REQUIREMENTS.md"
assert_status "REQUIREMENTS.md is linted" 2

echo
echo "== clean prose is silent =="
d=$(governed clean)
printf '# S\n\nThe kernel loads before the module attaches.\n' > "$d/SPEC.md"
run "$d/SPEC.md"
assert_status "clean prose exits 0" 0
assert_empty  "clean prose says nothing" "$HOOK_ERR"

echo
echo "== files the contract does not govern =="
d=$(governed other-file)
printf 'This must be fine.\n' > "$d/README.md"
run "$d/README.md"
assert_status "README.md is not linted" 0
assert_empty  "README.md produces no output" "$HOOK_ERR"

printf 'This must be fine.\n' > "$d/ROADMAP.md"
run "$d/ROADMAP.md"
assert_status "ROADMAP.md is not linted — Vale does not govern it" 0

echo
echo "== prose linting stays opt-in =="
d="$ROOT/no-vale-ini"; mkdir -p "$d"
printf '# S\n\nThe kernel must be loaded first.\n' > "$d/SPEC.md"
run "$d/SPEC.md"
assert_status "no .vale.ini means no linting" 0
assert_empty  "an un-opted project hears nothing" "$HOOK_ERR"

echo
echo "== absent input and absent file =="
HOOK_ERR="$(printf '' | bash "$HOOK" 2>&1 >/dev/null)"; HOOK_STATUS=$?
assert_status "empty payload exits clean" 0
run "$ROOT/does-not-exist/SPEC.md"
assert_status "a missing file exits clean" 0

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
