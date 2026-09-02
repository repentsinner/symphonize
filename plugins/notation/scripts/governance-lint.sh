#!/usr/bin/env bash
# governance-lint — the executable form of the notation governance contract.
#
# One script, three consumers (SPEC §spec:governance-lint): the reusable CI
# workflow, /notation:lint, and the pre-commit hook. Parity between local and
# CI holds by construction, because there is one implementation to drift from.
#
# Checks, in order:
#   1. Vale prose rules            (needs vale, which mise resolves at the
#                                   pin; .vale.ini opt-in)
#   2. markdownlint formatting     (needs rumdl or markdownlint-cli2;
#                                   uvx or npx reach either)
#   3. SPEC.md status lines
#   4. README heading profile      (--readme-type)
#   5. Heading addressing grammar, and README derivability
#   6. CHANGELOG structure         (gated on CHANGELOG.md existing)
#
# Checks 3-6 need nothing but bash. Checks 1-2 need a tool: absent, they skip
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
rumdl_version="0.2.62"
vale_version="3.19.0"

usage() {
  cat <<'USAGE'
Usage: governance-lint.sh [options]

  --readme-type <t>   README heading profile: library | application | ""
                      (empty or omitted skips the README heading check)
  --require-tools     Fail when vale or a markdown linter is missing,
                      rather than skipping the check. CI passes this.
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
# Version triple of a linter, empty when the probe fails. Used to decide
# whether a binary on PATH is the pinned one.
tool_version() {
  "$1" --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1
}

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
# Same precedence as the markdown engine: the pin outranks the host's copy.
# mise resolves vale through aqua, which fetches errata-ai's own release
# archives and already encodes the platform matrix, so the pin is portable
# without a downloader written here.
section "Vale prose rules"
vale_cmd=""
vale_label=""
vale_unpinned=""
vale_on_path="$(command -v vale >/dev/null 2>&1 && tool_version vale)"
if [ -n "$vale_on_path" ] && [ "$vale_on_path" = "$vale_version" ]; then
  vale_cmd="vale"
  vale_label="vale ${vale_version} (PATH)"
elif command -v mise >/dev/null 2>&1; then
  vale_cmd="mise x vale@${vale_version} -- vale"
  vale_label="vale ${vale_version} (mise)"
elif command -v vale >/dev/null 2>&1; then
  vale_cmd="vale"
  vale_label="vale ${vale_on_path:-unknown} (PATH)"
  vale_unpinned="vale ${vale_version}"
fi
if [ ! -f .vale.ini ]; then
  echo "  skip — no .vale.ini (prose linting is opt-in)"
elif [ -z "$vale_cmd" ]; then
  missing_tool "vale" "prose rules"
else
  echo "  engine: ${vale_label}"
  [ -n "$vale_unpinned" ] && echo "  note — not the pinned ${vale_unpinned}; CI runs the pin"
  # Lint the tree root so every finding in the configured files is reported,
  # matching what the .vale.ini scopes rather than a changed-lines subset.
  # shellcheck disable=SC2086
  if ! $vale_cmd --output=line .; then
    echo "::error::Vale reported findings"
    errors=$((errors + 1))
  else
    echo "  ok"
  fi
fi

# -------------------------------------------------------- 2. markdownlint ---
# The pinned version wins over whatever the machine happens to carry. A
# linter on PATH is an accident of that host's setup; the pin is what CI
# runs, and parity is this script's whole purpose. `uvx` and `npx` resolve a
# pinned version on every platform they support, which is why the pin is
# expressed through them rather than through a downloader written here: the
# release archives use two naming schemes and two container formats across
# six platform variants each, and the cache location differs on macOS and
# Windows besides.
#
# An exact-version match on PATH is preferred ahead of the resolver — it is
# the same program without the fetch, and it keeps an offline machine that
# pre-installed the pin working.
#
# rumdl is the preferred engine: one static binary and no Node runtime. It
# reads .markdownlint.json and .markdownlint-cli2.jsonc and implements the
# same MD### rule identifiers, but it is not bug-for-bug identical to
# markdownlint — line length and list indentation differ, and it follows
# CommonMark over compatibility. A project that pins markdownlint-cli2 in its
# own CI should install markdownlint-cli2 locally too, so both sides agree.
section "markdownlint formatting"
mdl=""
mdl_engine=""
mdl_label=""
mdl_unpinned=""
rumdl_on_path="$(command -v rumdl >/dev/null 2>&1 && tool_version rumdl)"
if [ -n "$rumdl_on_path" ] && [ "$rumdl_on_path" = "$rumdl_version" ]; then
  mdl="rumdl check"
  mdl_engine="rumdl"
  mdl_label="rumdl ${rumdl_version} (PATH)"
elif command -v uvx >/dev/null 2>&1; then
  mdl="uvx rumdl@${rumdl_version} check"
  mdl_engine="rumdl"
  mdl_label="rumdl ${rumdl_version} (uvx)"
elif command -v npx >/dev/null 2>&1; then
  mdl="npx --yes markdownlint-cli2@${markdownlint_version}"
  mdl_engine="markdownlint-cli2"
  mdl_label="markdownlint-cli2 ${markdownlint_version} (npx)"
elif command -v rumdl >/dev/null 2>&1; then
  mdl="rumdl check"
  mdl_engine="rumdl"
  mdl_label="rumdl ${rumdl_on_path:-unknown} (PATH)"
  mdl_unpinned="rumdl ${rumdl_version}"
elif command -v markdownlint-cli2 >/dev/null 2>&1; then
  mdl="markdownlint-cli2"
  mdl_engine="markdownlint-cli2"
  mdl_label="markdownlint-cli2 (PATH)"
  mdl_unpinned="markdownlint-cli2 ${markdownlint_version}"
fi
if [ -z "$mdl" ]; then
  missing_tool "rumdl or markdownlint-cli2" "markdown formatting"
elif [ "$mdl_engine" = "rumdl" ]; then
  # rumdl does not expand `**` globs of its own accord. Handed one it prints
  # "File not found" and still exits 0, which reads as a pass, so the file
  # list is resolved here instead.
  mdfiles=$(find . \( -name 'SPEC.md' -o -name 'ROADMAP.md' \
    -o -name 'REQUIREMENTS.md' -o -name 'README.md' \) \
    -not -path './.git/*' | sort)
  if [ -z "$mdfiles" ]; then
    echo "  skip — no governance markdown found"
  else
    echo "  engine: ${mdl_label}"
    [ -n "$mdl_unpinned" ] && echo "  note — not the pinned ${mdl_unpinned}; CI runs the pin"
    # Both expansions are deliberate: $mdl carries arguments, $mdfiles a list.
    # shellcheck disable=SC2086
    if ! $mdl $mdfiles; then
      echo "::error::markdownlint reported findings"
      errors=$((errors + 1))
    else
      echo "  ok"
    fi
  fi
else
  echo "  engine: ${mdl_label}"
  [ -n "$mdl_unpinned" ] && echo "  note — not the pinned ${mdl_unpinned}; CI runs the pin"
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
parser_files=()
while IFS= read -r govfile; do
  [ -n "$govfile" ] && parser_files+=("$govfile")
done <<< "$govfiles"
[ -f README.md ] && parser_files+=("README.md")

# The unit separator keeps tabs in Markdown lines inside one parser record.
unit_separator=$(printf '\034')
parser_output=""
parser_status=0
if [ "${#parser_files[@]}" -gt 0 ]; then
  parser_output="$(
    awk '
      BEGIN {
        us = sprintf("%c", 28)
        for (i = 1; i < ARGC; i++) {
          if (ARGV[i] != "") files[++file_total] = ARGV[i]
        }
      }

      function emit_check(file) {
        printf "C%c%s\n", us, file
      }

      function emit_finding(level, file, line, message) {
        printf "F%c%s%c%s%c%s%c%s\n", us, level, us, file, us, line, us, message
      }

      function emit_slug(slug) {
        printf "S%c%s\n", us, slug
      }

      function basename(file, name) {
        name = file
        sub(/^.*\//, "", name)
        return name
      }

      function prefix_for(file, name) {
        name = basename(file)
        if (name == "SPEC.md") return "spec"
        if (name == "REQUIREMENTS.md") return "req"
        if (name == "ROADMAP.md") return "road"
        return ""
      }

      function collect_definitions(text, rest, token) {
        rest = text
        while (match(rest, /§(spec|req|road):[a-z0-9-]+/)) {
          token = substr(rest, RSTART, RLENGTH)
          sub(/^§/, "", token)
          definitions[token]++
          rest = substr(rest, RSTART + RLENGTH)
        }
      }

      function strip_code_spans(text) {
        gsub(/`[^`]*`/, "", text)
        return text
      }

      function remove_slugs(text) {
        gsub(/§(spec|req|road):[a-z0-9-]+/, "", text)
        return text
      }

      function check_references(text, file, line, rest, ref, key, count) {
        rest = text
        while (match(rest, /§(spec|req|road):[a-z0-9-]+/)) {
          ref = substr(rest, RSTART, RLENGTH)
          key = ref
          sub(/^§/, "", key)
          if (key in definitions) count = definitions[key]
          else count = 0
          if (count == 0) {
            emit_finding("error", file, line, "Dangling reference " ref " — no matching heading")
          } else if (count > 1) {
            emit_finding("error", file, line, "Ambiguous reference " ref " — resolves to " count " headings")
          }
          rest = substr(rest, RSTART + RLENGTH)
        }
      }

      function pass_one(file, prefix,    i, text, in_fence) {
        emit_check(file)
        in_fence = 0
        for (i = 1; i <= document_line_count[file]; i++) {
          text = document_lines[file, i]
          if (text ~ /^```/) {
            in_fence = !in_fence
            continue
          }
          if (in_fence || text !~ /^##+ /) continue

          if (text ~ /^#+ [0-9]+(\.[0-9]+)*[. ]/) {
            emit_finding("error", file, i, "Positional heading rejected (numeric ordinal): " text)
          }

          if (text ~ /^## / && text !~ ("§" prefix ":[a-z0-9-]+")) {
            emit_finding("error", file, i, "## heading missing §" prefix ": slug: " text)
          }
          collect_definitions(text)
        }
      }

      function pass_two(file,    i, text, stripped, scan, in_fence) {
        in_fence = 0
        for (i = 1; i <= document_line_count[file]; i++) {
          text = document_lines[file, i]
          if (text ~ /^```/) {
            in_fence = !in_fence
            continue
          }
          if (in_fence) continue

          stripped = strip_code_spans(text)
          if (stripped ~ /§[0-9]/) {
            emit_finding("error", file, i, "Positional reference rejected (numeric address): " text)
          }

          scan = stripped
          if (stripped ~ /^##+ /) scan = remove_slugs(scan)
          check_references(scan, file, i)
        }
      }

      function section_name(text) {
        sub(/^#+ /, "", text)
        gsub(/§(spec|req|road):[a-z0-9-]+/, "", text)
        sub(/[[:space:]]+$/, "", text)
        return tolower(text)
      }

      function flush_readme_section(    bare) {
        if (readme_section == "" || readme_section_refs > 0) return
        bare = section_name(readme_section)
        if (bare ~ orientation) return
        emit_finding("warning", readme_file, readme_section_line,
          "Section \047" bare "\047 cites no §reference — orientation needs none, but an assertion belongs in a governance file (§spec:readme-derivable)")
      }

      function pass_three(file,    i, text, stripped, in_fence, rest, ref, key, count) {
        emit_check(file " derivability")
        readme_file = file
        readme_section = ""
        readme_section_line = 0
        readme_section_refs = 0
        in_fence = 0
        for (i = 1; i <= document_line_count[file]; i++) {
          text = document_lines[file, i]
          if (text ~ /^```/) {
            in_fence = !in_fence
            continue
          }
          if (in_fence) continue

          stripped = strip_code_spans(text)
          if (stripped ~ /^## /) {
            flush_readme_section()
            readme_section = stripped
            readme_section_line = i
            readme_section_refs = 0
          }

          if (stripped ~ /^#+ .*§(spec|req|road):[a-z0-9-]+[[:space:]]*$/) {
            emit_finding("error", file, i,
              "README defines §slug — a README is derivable, not authoritative (§spec:readme-derivable): " text)
            continue
          }

          rest = stripped
          while (match(rest, /§(spec|req|road):[a-z0-9-]+/)) {
            readme_section_refs++
            ref = substr(rest, RSTART, RLENGTH)
            key = ref
            sub(/^§/, "", key)
            if (key in definitions) count = definitions[key]
            else count = 0
            if (count == 0) {
              emit_finding("error", file, i, "Dangling reference " ref " — no matching heading")
            } else if (count > 1) {
              emit_finding("error", file, i, "Ambiguous reference " ref " — resolves to " count " headings")
            }
            rest = substr(rest, RSTART + RLENGTH)
          }
        }
        flush_readme_section()
      }

      function sort_definitions(    i, j, key, tmp) {
        sorted_definition_count = 0
        for (key in definitions) sorted_definition_keys[++sorted_definition_count] = key
        for (i = 2; i <= sorted_definition_count; i++) {
          tmp = sorted_definition_keys[i]
          j = i - 1
          while (j >= 1 && sorted_definition_keys[j] > tmp) {
            sorted_definition_keys[j + 1] = sorted_definition_keys[j]
            j--
          }
          sorted_definition_keys[j + 1] = tmp
        }
      }

      function emit_duplicates(    i, key) {
        for (i = 1; i <= sorted_definition_count; i++) {
          key = sorted_definition_keys[i]
          if (definitions[key] > 1) {
            emit_finding("error", "", "", "Duplicate slug definition: §" key " (defined more than once)")
          }
        }
      }

      function emit_slugs(    i) {
        for (i = 1; i <= sorted_definition_count; i++) {
          emit_slug(sorted_definition_keys[i])
        }
      }

      {
        text = $0
        gsub(/\r/, "", text)
        document_lines[FILENAME, FNR] = text
        document_line_count[FILENAME] = FNR
      }

      END {
        orientation = "^(#+ )?(install(ation)?|getting started|quick start|usage|examples?|api|api reference|licen(se|sing)|licensing note|prerequisites|requirements|development|developing|building|build|testing|tests|contributing|support|security|changelog|acknowledgements?|credits|authors?)$"

        for (i = 1; i <= file_total; i++) {
          file = files[i]
          prefix = prefix_for(file)
          if (prefix != "") pass_one(file, prefix)
        }

        sort_definitions()
        emit_duplicates()

        for (i = 1; i <= file_total; i++) {
          file = files[i]
          if (prefix_for(file) != "") pass_two(file)
        }

        for (i = 1; i <= file_total; i++) {
          file = files[i]
          if (file == "README.md") pass_three(file)
        }

        emit_slugs()
      }
    ' "${parser_files[@]}"
  )"
  parser_status=$?
fi

defined_slugs_started=false
if [ "$parser_status" -ne 0 ]; then
  echo "::error::governance parser failed (awk exit ${parser_status})"
  errors=$((errors + 1))
else
  while IFS="$unit_separator" read -r record_type field1 field2 field3 field4; do
    case "$record_type" in
      C) echo "  checking $field1" ;;
      F) annotate "$field1" "$field2" "$field3" "$field4" ;;
      S)
        if [ "$defined_slugs_started" = false ]; then
          echo "  defined slugs:"
          defined_slugs_started=true
        fi
        echo "    §$field1"
        ;;
    esac
  done <<< "$parser_output"
fi

if [ "$defined_slugs_started" = false ]; then
  echo "  defined slugs:"
fi

# ------------------------------------------------- 6. CHANGELOG structure ---
# Keep a Changelog only as far as every release tool agrees on it: an h1, and
# sections that each name a version. Past that the tools diverge —
# release-please writes "## [1.2.3](compare-url) (date)" under "### Features",
# the hand-kept form is "## [1.2.3] - date" under "### Added" — so demanding
# one shape would fail every repository that automates its releases.
section "CHANGELOG structure"
if [ ! -f CHANGELOG.md ]; then
  echo "  skip — no CHANGELOG.md (the check is gated on the file existing)"
else
  # [Unreleased] is where a hand-kept changelog stages the next release.
  # release-please and flywheel cut a version section per release and never
  # write one, so requiring it of them reports a defect for doing the right
  # thing (§spec:release-automation-options).
  changelog_managed=false
  if [ -f release-please-config.json ] || [ -f .flywheel.yml ]; then
    changelog_managed=true
  fi

  if ! grep -qE '^# +[Cc]hangelog *$' CHANGELOG.md; then
    annotate error "CHANGELOG.md" "1" \
      "no '# Changelog' heading — Keep a Changelog opens with one"
  fi

  has_unreleased=false
  versions_file=$(mktemp)
  lineno=0
  in_fenced_block=false
  while IFS= read -r line; do
    lineno=$((lineno + 1))

    if echo "$line" | grep -qE '^```'; then
      if $in_fenced_block; then in_fenced_block=false; else in_fenced_block=true; fi
      continue
    fi
    $in_fenced_block && continue

    echo "$line" | grep -qE '^## ' || continue

    if echo "$line" | grep -qiE '^## \[?Unreleased\]?'; then
      has_unreleased=true
      continue
    fi

    # A release section names its version somewhere in the heading, whichever
    # shape the tool writes it in.
    version=$(echo "$line" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    if [ -z "$version" ]; then
      annotate error "CHANGELOG.md" "$lineno" \
        "Section names no version: ${line#"## "} — a section is [Unreleased] or a release"
      continue
    fi
    echo "$version" >> "$versions_file"
  done < <(tr -d '\r' < CHANGELOG.md)

  while IFS= read -r dupe; do
    [ -z "$dupe" ] && continue
    annotate error "CHANGELOG.md" "" "Version ${dupe} appears more than once"
  done < <(sort "$versions_file" | uniq -d)

  echo "  checked $(wc -l < "$versions_file" | tr -d ' ') release section(s)"
  rm -f "$versions_file"

  if ! $has_unreleased && ! $changelog_managed; then
    annotate error "CHANGELOG.md" "" \
      "no [Unreleased] section — a hand-kept changelog stages the next release there"
  fi
  $changelog_managed && echo "  [Unreleased] not required — releases are tool-managed"
fi

# ------------------------------------------------------------------ summary ---
section "summary"
if [ "$errors" -gt 0 ]; then
  echo "  ${errors} error(s), ${warnings} warning(s)"
  exit 1
fi
echo "  governance contract satisfied — ${warnings} warning(s)"
