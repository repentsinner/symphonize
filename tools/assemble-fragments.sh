#!/usr/bin/env bash
# Assemble canonical fragments into consuming command files.
#
# Cross-plugin fragment assembly (SPEC §spec:plugin-packaging): installed
# plugins are copied into ~/.claude/plugins/cache/ and cannot read files
# outside their own directory, so shared content must physically live inside
# each plugin. Hand-duplication drifts; this script keeps one canonical
# source and writes it into every consumer between marker comments.
#
# Idempotent: running it when everything is in sync produces no changes.
# CI runs it then `git diff --exit-code` to fail on drift (see
# .github/workflows/ci.yml). Local fix on drift: run this script and commit.
#
# Usage: tools/assemble-fragments.sh
set -euo pipefail

# Resolve repo root from this script's location so the tool works regardless
# of the caller's working directory.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
FRAGMENTS_DIR="${REPO_ROOT}/fragments"

# Consumer registry: "fragment_name|relative/path/to/command.md".
# Each consumer wraps the assembled region in:
#   <!-- assembled:<fragment_name> --> ... <!-- /assembled:<fragment_name> -->
# Everything outside the markers is hand-authored and untouched.
CONSUMERS=(
  "governance-root|plugins/compose/commands/discover.md"
  "governance-root|plugins/compose/commands/plan.md"
  "governance-root|plugins/compose/commands/roadmap.md"
  "governance-root|plugins/conduct/commands/next.md"
  "governance-root|plugins/notation/commands/lint.md"
  "governance-root|plugins/conduct/commands/clean.md"
)

# assemble FRAGMENT_NAME TARGET_FILE
# Replaces the content between the fragment's markers in TARGET_FILE with the
# canonical fragment. Fails loudly if a marker is missing or unbalanced.
assemble() {
  local fragment_name="$1"
  local target_rel="$2"
  local target="${REPO_ROOT}/${target_rel}"
  local fragment_file="${FRAGMENTS_DIR}/${fragment_name}.md"
  local open_marker="<!-- assembled:${fragment_name} -->"
  local close_marker="<!-- /assembled:${fragment_name} -->"

  if [ ! -f "$fragment_file" ]; then
    echo "error: missing canonical fragment: ${fragment_file}" >&2
    exit 1
  fi
  if [ ! -f "$target" ]; then
    echo "error: missing consumer file: ${target}" >&2
    exit 1
  fi

  local open_count close_count
  open_count="$(grep -cF "$open_marker" "$target" || true)"
  close_count="$(grep -cF "$close_marker" "$target" || true)"
  if [ "$open_count" != "1" ] || [ "$close_count" != "1" ]; then
    echo "error: ${target_rel} must contain exactly one '${open_marker}'" \
         "and one '${close_marker}' (found ${open_count} open," \
         "${close_count} close)" >&2
    exit 1
  fi

  # Rewrite the file: keep everything up to and including the open marker,
  # emit the canonical fragment, then resume from the close marker onward.
  # awk handles arbitrary marker content without shell-escaping the body.
  local tmp
  tmp="$(mktemp)"
  awk -v openm="$open_marker" -v closem="$close_marker" \
      -v frag="$fragment_file" '
    $0 == openm {
      print
      while ((getline line < frag) > 0) print line
      close(frag)
      skip = 1
      next
    }
    $0 == closem { skip = 0 }
    !skip { print }
  ' "$target" > "$tmp"

  mv "$tmp" "$target"
  echo "assembled ${fragment_name} -> ${target_rel}"
}

for entry in "${CONSUMERS[@]}"; do
  fragment_name="${entry%%|*}"
  target_rel="${entry#*|}"
  assemble "$fragment_name" "$target_rel"
done

echo "done"
