#!/usr/bin/env bash
# governance-lint — the executable form of the notation governance contract.
#
# One script, three consumers (SPEC §spec:governance-lint): the reusable CI
# workflow, /notation:lint, and the pre-commit hook. Parity between local and
# CI holds by construction, because there is one implementation to drift from.
#
# Checks, in order:
#   1. Vale prose rules            (needs vale; .vale.ini opt-in)
#   2. markdownlint formatting     (needs markdownlint-cli2 or npx)
#   3. SPEC.md status lines
#   4. README heading profile      (--readme-type)
#   5. Heading addressing grammar, and README derivability
#
# Checks 3-5 need nothing but bash. Checks 1-2 need a tool: absent, they skip
# with a notice, so a local run is honest about being a subset rather than
# reporting clean on a check it never ran. --require-tools turns absence into
# a failure; CI passes it.
#
# Exit: 0 when no error-level finding was made. Warnings never fail a run.

set -uo pipefail

readme_type=""
require_tools=false
root="."
markdownlint_version="0.23.2"

usage() {
  cat <<'USAGE'
Usage: governance-lint.sh [options]

  --readme-type <t>   README heading profile: library | application | ""
                      (empty or omitted skips the README heading check)
  --require-tools     Fail when vale or markdownlint is missing, rather
                      than skipping the check. CI passes this.
  --root <dir>        Governance root to lint. Default: the current directory.
  -h, --help          This text.
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --readme-type) readme_type="${2:-}"; shift 2 ;;
    --readme-type=*) readme_type="${1#*=}"; shift ;;
    --require-tools) require_tools=true; shift ;;
    --root) root="${2:-}"; shift 2 ;;
    --root=*) root="${1#*=}"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "governance-lint: unknown option '$1'" >&2; usage >&2; exit 2 ;;
  esac
done

cd "$root" || { echo "governance-lint: cannot enter '$root'" >&2; exit 2; }

errors=0
warnings=0

# GitHub reads ::error/::warning as annotations; a terminal reads path:line.
annotate() {
  local level="$1" file="$2" line="$3" msg="$4"
  if [ -n "${GITHUB_ACTIONS:-}" ]; then
    if [ -n "$line" ]; then
      echo "::${level} file=${file},line=${line}::${msg}"
    else
      echo "::${level} file=${file}::${msg}"
    fi
  else
    if [ -n "$line" ]; then
      echo "${file}:${line}: ${level}: ${msg}"
    else
      echo "${file}: ${level}: ${msg}"
    fi
  fi
  if [ "$level" = "error" ]; then
    errors=$((errors + 1))
  else
    warnings=$((warnings + 1))
  fi
}

section() { echo; echo "== $1 =="; }

# A tool this run needed but did not have. Fatal under --require-tools,
# because a run that silently skips a check reports a clean it did not earn.
missing_tool() {
  local tool="$1" why="$2"
  if $require_tools; then
    echo "::error::${tool} is required but not on PATH (${why})"
    errors=$((errors + 1))
  else
    echo "  skip — ${tool} not on PATH (${why}); CI still checks this"
  fi
}

govfiles=$(find . \( -name 'SPEC.md' -o -name 'ROADMAP.md' -o -name 'REQUIREMENTS.md' \) \
  -not -path './.git/*' | sort)

# ---------------------------------------------------------------- 1. Vale ---
section "Vale prose rules"
if [ ! -f .vale.ini ]; then
  echo "  skip — no .vale.ini (prose linting is opt-in)"
elif ! command -v vale >/dev/null 2>&1; then
  missing_tool "vale" "prose rules"
else
  # Lint the tree root so every finding in the configured files is reported,
  # matching what the .vale.ini scopes rather than a changed-lines subset.
  if ! vale --output=line .; then
    echo "::error::Vale reported findings"
    errors=$((errors + 1))
  else
    echo "  ok"
  fi
fi

# -------------------------------------------------------- 2. markdownlint ---
section "markdownlint formatting"
mdl=""
if command -v markdownlint-cli2 >/dev/null 2>&1; then
  mdl="markdownlint-cli2"
elif command -v npx >/dev/null 2>&1; then
  mdl="npx --yes markdownlint-cli2@${markdownlint_version}"
fi
if [ -z "$mdl" ]; then
  missing_tool "markdownlint-cli2" "markdown formatting"
else
  if ! $mdl "**/SPEC.md" "**/ROADMAP.md" "**/README.md" "**/REQUIREMENTS.md"; then
    echo "::error::markdownlint reported findings"
    errors=$((errors + 1))
  else
    echo "  ok"
  fi
fi

# ---------------------------------------------------- 3. SPEC status lines ---
section "SPEC.md status lines"
for specfile in $(find . -name 'SPEC.md' -not -path './.git/*' | sort); do
  echo "  checking $specfile"
  spec_section=""
  expect_status=false

  while IFS= read -r line; do
    if [[ "$line" =~ ^##\ [^#] ]]; then
      if $expect_status; then
        annotate error "$specfile" "" "Section '$spec_section' has no *Status: line"
      fi
      spec_section="$line"
      expect_status=true
      continue
    fi

    if $expect_status; then
      if [ -z "$line" ]; then
        continue
      fi
      if [[ "$line" =~ ^\*Status:\ (not\ started|in\ progress|complete)\*$ ]]; then
        expect_status=false
      else
        annotate error "$specfile" "" \
          "Section '$spec_section' has invalid or missing status line: $line"
        expect_status=false
      fi
    fi
  done < <(tr -d '\r' < "$specfile")

  if $expect_status; then
    annotate error "$specfile" "" \
      "Section '$spec_section' has no *Status: line (end of file)"
  fi
done

# ------------------------------------------------- 4. README heading profile ---
section "README heading profile"
if [ -z "$readme_type" ]; then
  echo "  skip — no --readme-type given"
elif [ ! -f README.md ]; then
  annotate error "README.md" "" "README.md not found"
else
  headings=$(grep -E '^## ' README.md | sed 's/^## //' | tr '[:upper:]' '[:lower:]')

  check_heading() {
    local label="$1" pattern="$2"
    if ! echo "$headings" | grep -qxE "$pattern"; then
      annotate error "README.md" "" \
        "missing required heading: $label (expected pattern: $pattern)"
    fi
  }

  check_heading "License" "licen(se|sing)|licensing note"

  case "$readme_type" in
    library)
      check_heading "Installation" "install(ation)?|getting started|quick start"
      check_heading "Usage" "usage"
      # API is deliberately NOT required — see SPEC §spec:readme-profile.
      ;;
    application)
      check_heading "Getting Started" "quick start|getting started|install(ation)?"
      check_heading "Usage" "usage"
      ;;
    *)
      echo "::error::Unknown readme-type: $readme_type (expected 'library' or 'application')"
      exit 2
      ;;
  esac
  echo "  checked profile '$readme_type'"
fi

# --------------------------------------------- 5. Heading addressing grammar ---
#
# A §<prefix>:slug suffix is REQUIRED on every ## heading in SPEC.md (§spec:),
# REQUIREMENTS.md (§req:) and ROADMAP.md (§road:). Deeper headings MAY carry
# one; the h1 title is exempt. The namespace is flat and unique, every
# reference resolves to exactly one definition, and positional addressing is
# rejected. Code spans and fenced blocks are exempt.
section "Heading addressing grammar"
defs_file=$(mktemp)

prefix_for() {
  case "$1" in
    SPEC.md) echo "spec" ;;
    REQUIREMENTS.md) echo "req" ;;
    ROADMAP.md) echo "road" ;;
    *) echo "" ;;
  esac
}

# Pass 1 — required slugs, positional rejection, definition collection.
for govfile in $govfiles; do
  echo "  checking $govfile"
  base=$(basename "$govfile")
  prefix=$(prefix_for "$base")
  [ -z "$prefix" ] && continue

  lineno=0
  in_fenced_block=false
  while IFS= read -r line; do
    lineno=$((lineno + 1))

    if echo "$line" | grep -qE '^```'; then
      if $in_fenced_block; then in_fenced_block=false; else in_fenced_block=true; fi
      continue
    fi
    $in_fenced_block && continue

    echo "$line" | grep -qE '^##+ ' || continue

    if echo "$line" | grep -qE '^#+ [0-9]+(\.[0-9]+)*[. ]'; then
      annotate error "$govfile" "$lineno" \
        "Positional heading rejected (numeric ordinal): $line"
    fi

    heading_slugs=$(echo "$line" | grep -oE '§(spec|req|road):[a-z0-9-]+' || true)

    if echo "$line" | grep -qE '^## '; then
      if ! echo "$line" | grep -qE "§${prefix}:[a-z0-9-]+"; then
        annotate error "$govfile" "$lineno" "## heading missing §${prefix}: slug: $line"
      fi
    fi

    for s in $heading_slugs; do
      echo "${s#§}" >> "$defs_file"
    done
  done < <(tr -d '\r' < "$govfile")
done

dupes=$(sort "$defs_file" | uniq -d)
if [ -n "$dupes" ]; then
  while IFS= read -r d; do
    [ -z "$d" ] && continue
    annotate error "" "" "Duplicate slug definition: §${d} (defined more than once)"
  done <<< "$dupes"
fi

# Pass 2 — references in the governance files resolve.
for govfile in $govfiles; do
  lineno=0
  in_fenced_block=false
  while IFS= read -r line; do
    lineno=$((lineno + 1))

    if echo "$line" | grep -qE '^```'; then
      if $in_fenced_block; then in_fenced_block=false; else in_fenced_block=true; fi
      continue
    fi
    $in_fenced_block && continue

    stripped=$(echo "$line" | sed 's/`[^`]*`//g')

    if echo "$stripped" | grep -qE '§[0-9]'; then
      annotate error "$govfile" "$lineno" \
        "Positional reference rejected (numeric address): $line"
    fi

    scan="$stripped"
    if echo "$stripped" | grep -qE '^##+ '; then
      scan=$(echo "$stripped" | sed -E 's/§(spec|req|road):[a-z0-9-]+//g')
    fi

    refs=$(echo "$scan" | grep -oE '§(spec|req|road):[a-z0-9-]+' || true)
    [ -z "$refs" ] && continue

    for ref in $refs; do
      key="${ref#§}"
      count=$(grep -cxF "$key" "$defs_file" || true)
      if [ "$count" -eq 0 ]; then
        annotate error "$govfile" "$lineno" "Dangling reference ${ref} — no matching heading"
      elif [ "$count" -gt 1 ]; then
        annotate error "$govfile" "$lineno" \
          "Ambiguous reference ${ref} — resolves to ${count} headings"
      fi
    done
  done < <(tr -d '\r' < "$govfile")
done

# Pass 3 — README derivability (SPEC §spec:readme-derivable).
#
# A README is derivable, not authoritative: it compresses what the governance
# files already say. So it may not DEFINE a slug, its references resolve as a
# governance file's do, and a section citing nothing is flagged — it is either
# orientation, which needs none, or an assertion whose home is missing. The
# last warns because only an author can tell those apart.
if [ -f README.md ]; then
  echo "  checking README.md derivability"
  lineno=0
  in_fenced_block=false
  rd_section=""
  section_line=0
  section_refs=0

  orientation='^(#+ )?(install(ation)?|getting started|quick start|usage|examples?|api|api reference|licen(se|sing)|licensing note|prerequisites|requirements|development|developing|building|build|testing|tests|contributing|support|security|changelog|acknowledgements?|credits|authors?)$'

  flush_section() {
    [ -z "$rd_section" ] && return
    [ "$section_refs" -gt 0 ] && return
    local bare
    bare=$(echo "$rd_section" | sed -E 's/^#+ //; s/§(spec|req|road):[a-z0-9-]+//g; s/[[:space:]]+$//' \
      | tr '[:upper:]' '[:lower:]')
    echo "$bare" | grep -qxE "$orientation" && return
    annotate warning "README.md" "$section_line" \
      "Section '${bare}' cites no §reference — orientation needs none, but an assertion belongs in a governance file (§spec:readme-derivable)"
  }

  while IFS= read -r line; do
    lineno=$((lineno + 1))

    if echo "$line" | grep -qE '^```'; then
      if $in_fenced_block; then in_fenced_block=false; else in_fenced_block=true; fi
      continue
    fi
    $in_fenced_block && continue

    stripped=$(echo "$line" | sed 's/`[^`]*`//g')

    if echo "$stripped" | grep -qE '^## '; then
      flush_section
      rd_section="$stripped"
      section_line=$lineno
      section_refs=0
    fi

    if echo "$stripped" | grep -qE '^#+ .*§(spec|req|road):[a-z0-9-]+[[:space:]]*$'; then
      annotate error "README.md" "$lineno" \
        "README defines §slug — a README is derivable, not authoritative (§spec:readme-derivable): $line"
      continue
    fi

    for ref in $(echo "$stripped" | grep -oE '§(spec|req|road):[a-z0-9-]+' || true); do
      section_refs=$((section_refs + 1))
      key="${ref#§}"
      count=$(grep -cxF "$key" "$defs_file" || true)
      if [ "$count" -eq 0 ]; then
        annotate error "README.md" "$lineno" "Dangling reference ${ref} — no matching heading"
      elif [ "$count" -gt 1 ]; then
        annotate error "README.md" "$lineno" \
          "Ambiguous reference ${ref} — resolves to ${count} headings"
      fi
    done
  done < <(tr -d '\r' < README.md)
  flush_section
fi

echo "  defined slugs:"
sort -u "$defs_file" | sed 's/^/    §/'
rm -f "$defs_file"

# ------------------------------------------------------------------ summary ---
section "summary"
if [ "$errors" -gt 0 ]; then
  echo "  ${errors} error(s), ${warnings} warning(s)"
  exit 1
fi
echo "  governance contract satisfied — ${warnings} warning(s)"
