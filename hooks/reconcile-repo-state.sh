#!/usr/bin/env bash
#
# Symphonize repo-state reconciliation hook (UserPromptSubmit).
#
# Before each turn, reconcile the agent's view of the repo with the remote and
# inject context ONLY when reality diverges from the naive "nothing changed
# since I last looked" assumption: the current branch's PR is merged/closed,
# the branch is behind origin/main, or the branch is gone from the remote.
#
# Contract (see SPEC.md §spec:repo-state-reconciliation):
#   - Read-only. Performs at most a rate-limited `git fetch`; never checks out,
#     pulls, rebases, pushes, or mutates the working tree or remote.
#   - Silent no-op outside a git repo, or when git/gh/network are unavailable.
#     Absence of remote state is never reported as divergence.
#   - Always exits 0. Never blocks the prompt. Emits nothing on clean state.
#   - On divergence, prints a single JSON object on stdout:
#       {"hookSpecificOutput":{"hookEventName":"UserPromptSubmit",
#        "additionalContext":"..."}}
#
# Env overrides (testing / tuning):
#   RECONCILE_STAMP_DIR          stamp directory (default $TMPDIR/symphonize-reconcile)
#   RECONCILE_RATE_WINDOW_SECONDS  fetch rate-limit window (default 300)
#   RECONCILE_FETCH_DISABLE=1    skip the network fetch entirely

# Never let an unexpected failure surface; reconciliation is best-effort.
set -u

# Any failure short-circuits to a clean, silent exit.
bail() { exit 0; }

command -v git >/dev/null 2>&1 || bail
command -v jq >/dev/null 2>&1 || bail

payload="$(cat)"
[ -n "$payload" ] || bail

cwd="$(printf '%s' "$payload" | jq -r '.cwd // empty' 2>/dev/null)"
[ -n "$cwd" ] || bail
[ -d "$cwd" ] || bail

# Must be inside a git work tree; otherwise silent no-op.
git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1 || bail

toplevel="$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)" || bail
[ -n "$toplevel" ] || bail

branch="$(git -C "$cwd" symbolic-ref --quiet --short HEAD 2>/dev/null || true)"
# Detached HEAD: no branch to reconcile.
[ -n "$branch" ] || bail

# --- Rate-limited fetch ----------------------------------------------------
# Stamp keyed by the repo's absolute toplevel path so distinct repos do not
# share a window. Skip the fetch when a recent stamp exists.
window="${RECONCILE_RATE_WINDOW_SECONDS:-300}"
stamp_dir="${RECONCILE_STAMP_DIR:-${TMPDIR:-/tmp}/symphonize-reconcile}"
# Hash the path with a portable tool; fall back to a sanitized path.
if command -v shasum >/dev/null 2>&1; then
  key="$(printf '%s' "$toplevel" | shasum | cut -d' ' -f1)"
elif command -v sha1sum >/dev/null 2>&1; then
  key="$(printf '%s' "$toplevel" | sha1sum | cut -d' ' -f1)"
else
  key="$(printf '%s' "$toplevel" | tr -c 'A-Za-z0-9' '_')"
fi
stamp="$stamp_dir/$key"

should_fetch=1
[ "${RECONCILE_FETCH_DISABLE:-0}" = "1" ] && should_fetch=0

if [ "$should_fetch" = "1" ] && [ -f "$stamp" ]; then
  now="$(date +%s 2>/dev/null || echo 0)"
  # Probe the GNU form first: `stat -c %Y` fails cleanly (no stdout) on BSD/macOS
  # and falls through to `stat -f %m`. The reverse order is unsafe — GNU `stat -f`
  # means --file-system and prints a block to stdout while exiting non-zero, which
  # leaks into the substitution and crashes the arithmetic below under set -u (#125).
  stamp_mtime="$(stat -c %Y "$stamp" 2>/dev/null || stat -f %m "$stamp" 2>/dev/null || echo 0)"
  age=$((now - stamp_mtime))
  if [ "$age" -ge 0 ] && [ "$age" -lt "$window" ]; then
    should_fetch=0
  fi
fi

if [ "$should_fetch" = "1" ]; then
  mkdir -p "$stamp_dir" 2>/dev/null || true
  # Read-only: fetch updates remote-tracking refs only. Prune so deleted
  # upstream branches register as gone. Ignore failures (offline, no remote).
  if git -C "$cwd" fetch --quiet --prune origin >/dev/null 2>&1; then
    : >"$stamp" 2>/dev/null || true
  fi
fi

# --- Divergence detection --------------------------------------------------
messages=()

# 1. PR state for the current branch (requires gh, authenticated). Degrades
#    silently when gh is absent or unauthenticated — never a divergence itself.
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  pr_json="$(gh pr view "$branch" --json state,number,url 2>/dev/null || true)"
  if [ -n "$pr_json" ]; then
    pr_state="$(printf '%s' "$pr_json" | jq -r '.state // empty' 2>/dev/null)"
    pr_number="$(printf '%s' "$pr_json" | jq -r '.number // empty' 2>/dev/null)"
    case "$pr_state" in
      MERGED)
        messages+=("PR #${pr_number} for this branch (\`${branch}\`) is MERGED on the remote. Work on this branch is already integrated; do not push further commits here or treat the PR as open.")
        ;;
      CLOSED)
        messages+=("PR #${pr_number} for this branch (\`${branch}\`) is CLOSED (not merged) on the remote. Do not treat it as an open review surface.")
        ;;
    esac
  fi
fi

# 2/3. Branch position relative to its upstream and to origin/main, using
#      local remote-tracking refs (no network — works without gh).
upstream="$(git -C "$cwd" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null || true)"
if [ -n "$upstream" ]; then
  # Upstream ref configured but missing locally after prune => branch gone.
  if ! git -C "$cwd" rev-parse --verify --quiet "$upstream" >/dev/null 2>&1; then
    messages+=("This branch's upstream (\`${upstream}\`) no longer exists on the remote. The branch was deleted upstream (likely after merge); pushing will recreate it.")
  fi
fi

# Behind origin/main: commits on origin/main not reachable from HEAD. Only
# meaningful when origin/main exists and is not the current branch itself.
if git -C "$cwd" rev-parse --verify --quiet origin/main >/dev/null 2>&1; then
  head_sha="$(git -C "$cwd" rev-parse HEAD 2>/dev/null || true)"
  main_sha="$(git -C "$cwd" rev-parse origin/main 2>/dev/null || true)"
  if [ -n "$head_sha" ] && [ "$head_sha" != "$main_sha" ]; then
    behind="$(git -C "$cwd" rev-list --count "HEAD..origin/main" 2>/dev/null || echo 0)"
    if [ "${behind:-0}" -gt 0 ]; then
      messages+=("This branch is ${behind} commit(s) behind \`origin/main\`. Its base is stale; rebase or merge \`origin/main\` before relying on it being current.")
    fi
  fi
fi

# --- Emit ------------------------------------------------------------------
# Clean state: emit nothing, inject no context.
[ "${#messages[@]}" -eq 0 ] && bail

context="Repo-state reconciliation detected divergence from your assumed state:"
for m in "${messages[@]}"; do
  context="${context}"$'\n'"- ${m}"
done

jq -nc --arg ctx "$context" \
  '{hookSpecificOutput:{hookEventName:"UserPromptSubmit",additionalContext:$ctx}}'

exit 0
