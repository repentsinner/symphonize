#!/usr/bin/env bash
# Unit tests for governance-lint.sh.
#
# The fixtures run offline. Vale, rumdl, markdownlint-cli2, npx and uvx are
# small stubs,
# so these tests cover tool policy without downloading external programs.
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LINT="$SCRIPT_DIR/governance-lint.sh"

pass=0
fail=0
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

STUB_DIR="$TEST_ROOT/stubs"
mkdir -p "$STUB_DIR"
cat > "$STUB_DIR/vale" <<'EOF'
#!/bin/sh
exit 0
EOF
cat > "$STUB_DIR/markdownlint-cli2" <<'EOF'
#!/bin/sh
exit 0
EOF
chmod +x "$STUB_DIR/vale" "$STUB_DIR/markdownlint-cli2"

LINT_PATH="$STUB_DIR:/usr/bin:/bin"
GITHUB_MODE=""
LINT_OUT=""
LINT_STATUS=0

fixture() {
  local dir="$TEST_ROOT/$1"
  mkdir -p "$dir"
  cat > "$dir/SPEC.md" <<'SPEC'
# Fixture

## Only section §spec:only-section
*Status: complete*

A section that satisfies the contract.
SPEC
  echo "$dir"
}

run_lint() {
  local dir="$1"
  shift
  LINT_OUT="$(PATH="$LINT_PATH" GITHUB_ACTIONS="$GITHUB_MODE" \
    "$LINT" --root "$dir" "$@" 2>&1)"
  LINT_STATUS=$?
}

assert_contains() {
  local label="$1" haystack="$2" needle="$3"
  if printf '%s' "$haystack" | grep -qF -- "$needle"; then
    pass=$((pass + 1))
    echo "ok   - $label"
  else
    fail=$((fail + 1))
    echo "FAIL - $label"
    echo "       expected: $needle"
    printf '%s\n' "$haystack" | sed 's/^/       | /'
  fi
}

assert_not_contains() {
  local label="$1" haystack="$2" needle="$3"
  if printf '%s' "$haystack" | grep -qF -- "$needle"; then
    fail=$((fail + 1))
    echo "FAIL - $label"
    echo "       unexpected: $needle"
    printf '%s\n' "$haystack" | sed 's/^/       | /'
  else
    pass=$((pass + 1))
    echo "ok   - $label"
  fi
}

assert_order() {
  local label="$1" haystack="$2" first="$3" second="$4"
  local first_line second_line
  first_line="$(printf '%s\n' "$haystack" | grep -nF -- "$first" | head -1 | cut -d: -f1)"
  second_line="$(printf '%s\n' "$haystack" | grep -nF -- "$second" | head -1 | cut -d: -f1)"
  if [ -n "$first_line" ] && [ -n "$second_line" ] && [ "$first_line" -lt "$second_line" ]; then
    pass=$((pass + 1))
    echo "ok   - $label"
  else
    fail=$((fail + 1))
    echo "FAIL - $label"
    echo "       expected '$first' before '$second'"
  fi
}

assert_status() {
  local label="$1" expected="$2"
  if [ "$LINT_STATUS" -eq "$expected" ]; then
    pass=$((pass + 1))
    echo "ok   - $label"
  else
    fail=$((fail + 1))
    echo "FAIL - $label (exit $LINT_STATUS, expected $expected)"
    printf '%s\n' "$LINT_OUT" | sed 's/^/       | /'
  fi
}

assert_elapsed_under_five() {
  local label="$1" elapsed="$2"
  if [ "$elapsed" -lt 5 ]; then
    pass=$((pass + 1))
    echo "ok   - $label (${elapsed}s)"
  else
    fail=$((fail + 1))
    echo "FAIL - $label (${elapsed}s)"
  fi
}

echo "== valid roots and input forms =="
d=$(fixture valid-library)
cat > "$d/README.md" <<'README'
# Fixture

## Installation
Install the library.

## Usage
Use the library.

## License
MIT.
README
run_lint "$d" --readme-type library --require-tools
assert_status "library profile passes" 0

d=$(fixture valid-application)
cat > "$d/README.md" <<'README'
# Fixture

## Getting Started
Install the application.

## Usage
Run the application.

## License
MIT.
README
run_lint "$d" --readme-type application --require-tools
assert_status "application profile passes" 0

d=$(fixture nested-files)
mkdir -p "$d/docs/reference"
cat > "$d/docs/reference/REQUIREMENTS.md" <<'REQ'
# Requirements

## Nested requirement §req:nested-requirement
A requirement.
REQ
cat > "$d/docs/reference/ROADMAP.md" <<'ROAD'
# Roadmap

## Nested workstream §road:nested-workstream
A workstream.
See §req:nested-requirement.
ROAD
run_lint "$d"
assert_status "nested governance files pass" 0

d=$(fixture crlf-input)
printf '# Fixture\r\n\r\n## CRLF section §spec:crlf\r\n*Status: complete*\r\n\r\nSee §spec:crlf.\r\n' > "$d/SPEC.md"
run_lint "$d"
assert_status "CRLF input passes" 0

d=$(fixture absent-readme)
run_lint "$d"
assert_status "an absent README is allowed without a profile" 0
run_lint "$d" --readme-type library
assert_status "a selected profile requires README.md" 1
assert_contains "the absent README is reported" "$LINT_OUT" "README.md not found"

echo
echo "== status and heading errors =="
d=$(fixture status-errors)
cat > "$d/SPEC.md" <<'SPEC'
# Fixture

## First section §spec:first

## Second section §spec:second
*Status: invalid*
SPEC
run_lint "$d"
assert_status "status errors fail" 1
assert_contains "missing status is reported" "$LINT_OUT" "Section '## First section §spec:first' has no *Status: line"
assert_contains "invalid status is reported" "$LINT_OUT" "invalid or missing status line: *Status: invalid*"
assert_contains "status summary has exact counts" "$LINT_OUT" "2 error(s), 0 warning(s)"

d=$(fixture missing-slug)
cat > "$d/SPEC.md" <<'SPEC'
# Fixture

## Missing heading
*Status: complete*
SPEC
run_lint "$d"
assert_status "a missing slug fails" 1
assert_contains "the missing slug is reported" "$LINT_OUT" "## heading missing §spec: slug: ## Missing heading"

d=$(fixture duplicate-slug)
cat > "$d/SPEC.md" <<'SPEC'
# Fixture

## Later section §spec:z-section
*Status: complete*

## Earlier section §spec:a-section
*Status: complete*

## Repeated section §spec:z-section
*Status: complete*
SPEC
run_lint "$d"
assert_status "a duplicate slug fails" 1
assert_contains "the duplicate slug is reported" "$LINT_OUT" "Duplicate slug definition: §spec:z-section"
assert_contains "defined slugs are sorted" "$LINT_OUT" "    §spec:a-section"
assert_contains "the second defined slug is shown" "$LINT_OUT" "    §spec:z-section"

d=$(fixture dangling-reference)
cat >> "$d/SPEC.md" <<'SPEC'

This points to §spec:not-defined.
SPEC
run_lint "$d"
assert_status "a dangling reference fails" 1
assert_contains "the dangling reference is reported" "$LINT_OUT" "Dangling reference §spec:not-defined — no matching heading"

d=$(fixture ambiguous-reference)
cat > "$d/SPEC.md" <<'SPEC'
# Fixture

## First §spec:same
*Status: complete*

## Second §spec:same
*Status: complete*

See §spec:same.
SPEC
run_lint "$d"
assert_status "an ambiguous reference fails" 1
assert_order "the duplicate is reported before resolution" "$LINT_OUT" \
  "Duplicate slug definition: §spec:same" \
  "Ambiguous reference §spec:same — resolves to 2 headings"

d=$(fixture numeric-address)
cat > "$d/SPEC.md" <<'SPEC'
# Fixture

## 1. Numeric section §spec:numeric-section
*Status: complete*

## 3D view §spec:three-d-view
*Status: complete*

See §8.9.
See `§9.9`.
SPEC
run_lint "$d"
assert_status "numeric addresses fail" 1
assert_contains "numeric headings are rejected" "$LINT_OUT" "Positional heading rejected (numeric ordinal): ## 1. Numeric section §spec:numeric-section"
assert_contains "numeric references are rejected" "$LINT_OUT" "Positional reference rejected (numeric address): See §8.9."
assert_not_contains "a digit-starting topic is allowed" "$LINT_OUT" "3D view"
assert_not_contains "numeric code spans are exempt" "$LINT_OUT" "§9.9"

echo
echo "== code spans and fenced blocks =="
d=$(fixture code-exemptions)
cat >> "$d/SPEC.md" <<'SPEC'

Inline `§spec:not-defined` and `§9.9` are examples.

```markdown
### Not a real heading
See §spec:not-defined and §9.9.
```
SPEC
cat > "$d/README.md" <<'README'
# Fixture

## Usage
Use the fixture.

```markdown
### Not a real section §spec:not-defined
See §spec:not-defined.
```
README
run_lint "$d"
assert_status "inline code and fenced blocks are exempt" 0
assert_not_contains "code references do not dangle" "$LINT_OUT" "Dangling reference §spec:not-defined"
assert_not_contains "code numeric addresses do not fail" "$LINT_OUT" "Positional reference rejected"
assert_not_contains "fenced README headings do not define slugs" "$LINT_OUT" "README defines §slug"

echo
echo "== README derivability =="
d=$(fixture readme-definition)
cat > "$d/README.md" <<'README'
# Fixture

## Project summary §spec:only-section
This heading attempts to define a slug.
README
run_lint "$d"
assert_status "a README definition fails" 1
assert_contains "the README definition is reported" "$LINT_OUT" "README defines §slug"

d=$(fixture readme-dangling)
cat > "$d/README.md" <<'README'
# Fixture

## Usage
See §spec:not-defined.
README
run_lint "$d"
assert_status "a README dangling reference fails" 1
assert_contains "the README reference is reported" "$LINT_OUT" "README.md:4: error: Dangling reference §spec:not-defined"
assert_not_contains "a README reference is not a definition" "$LINT_OUT" "    §spec:not-defined"

d=$(fixture readme-warning)
cat > "$d/README.md" <<'README'
# Fixture

## Usage
Run the fixture.

## Overview
This section has no governance reference.

## License
MIT.
README
run_lint "$d"
assert_status "a derivability warning does not fail" 0
assert_contains "the non-orientation warning is reported" "$LINT_OUT" "Section 'overview' cites no §reference"
assert_contains "the warning count is exact" "$LINT_OUT" "governance contract satisfied — 1 warning(s)"
assert_not_contains "orientation headings do not warn" "$LINT_OUT" "Section 'usage' cites no §reference"

echo
echo "== diagnostics and tool policy =="
d=$(fixture terminal-diagnostic)
tab_heading=$(printf '## Missing\theading')
{
  printf '# Fixture\n\n%s\n*Status: complete*\n' "$tab_heading"
} > "$d/SPEC.md"
run_lint "$d"
assert_contains "terminal diagnostics include path and line" "$LINT_OUT" "./SPEC.md:3: error: ## heading missing §spec: slug"
tab=$(printf '\t')
assert_contains "tabs in Markdown stay unchanged" "$LINT_OUT" "## Missing${tab}heading"

GITHUB_MODE=1
run_lint "$d"
GITHUB_MODE=""
assert_contains "GitHub diagnostics use annotations" "$LINT_OUT" "::error file=./SPEC.md,line=3::## heading missing §spec: slug"

d=$(fixture tool-policy)
: > "$d/.vale.ini"
LINT_PATH="/usr/bin:/bin"
run_lint "$d"
assert_status "missing optional tools do not fail" 0
assert_contains "missing Vale is reported" "$LINT_OUT" "skip — vale not on PATH"
assert_contains "missing markdownlint is reported" "$LINT_OUT" "skip — rumdl or markdownlint-cli2 not on PATH"
run_lint "$d" --require-tools
assert_status "required tools fail when absent" 1
assert_contains "required tool summary is exact" "$LINT_OUT" "2 error(s), 0 warning(s)"
assert_contains "required tool errors use GitHub form" "$LINT_OUT" "::error::vale is required but not on PATH"

LINT_PATH="$STUB_DIR:/usr/bin:/bin"
run_lint "$d" --require-tools
assert_status "stubbed tools pass when required" 0
assert_contains "Vale runs" "$LINT_OUT" "  ok"

NPX_DIR="$TEST_ROOT/npx"
mkdir -p "$NPX_DIR"
cat > "$NPX_DIR/npx" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" > "$NPX_LOG"
exit 0
EOF
chmod +x "$NPX_DIR/npx"
NPX_LOG="$TEST_ROOT/npx.log"
export NPX_LOG
LINT_PATH="$NPX_DIR:/usr/bin:/bin"
d=$(fixture npx-fallback)
run_lint "$d" --require-tools
assert_status "npx markdownlint fallback passes" 0
assert_contains "the pinned markdownlint version stays unchanged" "$(cat "$NPX_LOG")" "--yes markdownlint-cli2@0.23.2"

# Engine policy: rumdl is preferred over markdownlint-cli2, uvx is preferred
# over npx, and rumdl is handed real paths rather than a glob it cannot expand.
RUMDL_DIR="$TEST_ROOT/rumdl"
mkdir -p "$RUMDL_DIR"
cat > "$RUMDL_DIR/rumdl" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" > "$RUMDL_LOG"
exit 0
EOF
cat > "$RUMDL_DIR/markdownlint-cli2" <<'EOF'
#!/bin/sh
echo "markdownlint-cli2 should not have run" > "$RUMDL_LOG"
exit 0
EOF
chmod +x "$RUMDL_DIR/rumdl" "$RUMDL_DIR/markdownlint-cli2"
RUMDL_LOG="$TEST_ROOT/rumdl.log"
export RUMDL_LOG
LINT_PATH="$RUMDL_DIR:/usr/bin:/bin"
d=$(fixture rumdl-preferred)
run_lint "$d" --require-tools
assert_status "rumdl engine passes" 0
assert_contains "rumdl is chosen over markdownlint-cli2" "$LINT_OUT" "engine: rumdl"
assert_contains "rumdl is invoked as a checker" "$(cat "$RUMDL_LOG")" "check"
assert_contains "rumdl receives a real path, not a glob" "$(cat "$RUMDL_LOG")" "./SPEC.md"

UVX_DIR="$TEST_ROOT/uvx"
mkdir -p "$UVX_DIR"
cat > "$UVX_DIR/uvx" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" > "$UVX_LOG"
exit 0
EOF
cat > "$UVX_DIR/npx" <<'EOF'
#!/bin/sh
echo "npx should not have run" > "$UVX_LOG"
exit 0
EOF
chmod +x "$UVX_DIR/uvx" "$UVX_DIR/npx"
UVX_LOG="$TEST_ROOT/uvx.log"
export UVX_LOG
LINT_PATH="$UVX_DIR:/usr/bin:/bin"
d=$(fixture uvx-fallback)
run_lint "$d" --require-tools
assert_status "uvx rumdl fallback passes" 0
assert_contains "uvx is preferred over npx" "$(cat "$UVX_LOG")" "rumdl@0.2.62"

AWK_DIR="$TEST_ROOT/awk-failure"
mkdir -p "$AWK_DIR"
cat > "$AWK_DIR/awk" <<'EOF'
#!/bin/sh
exit 7
EOF
chmod +x "$AWK_DIR/awk"
LINT_PATH="$AWK_DIR:/usr/bin:/bin"
d=$(fixture awk-failure)
run_lint "$d"
assert_status "an awk failure fails the lint" 1
assert_contains "the awk failure is reported" "$LINT_OUT" "governance parser failed (awk exit 7)"
LINT_PATH="$STUB_DIR:/usr/bin:/bin"

echo
echo "== parser runtime =="
d=$(fixture parser-runtime)
{
  printf '# Fixture\n\n## One section §spec:one-section\n*Status: complete*\n'
  i=1
  while [ "$i" -le 2000 ]; do
    printf 'Filler line %s.\n' "$i"
    i=$((i + 1))
  done
  printf '\nSee §spec:one-section.\n'
} > "$d/SPEC.md"
start_time=$(date +%s)
run_lint "$d" --require-tools
elapsed=$(( $(date +%s) - start_time ))
assert_status "the 2,000-line fixture passes" 0
assert_elapsed_under_five "the 2,000-line fixture stays below five seconds" "$elapsed"

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
