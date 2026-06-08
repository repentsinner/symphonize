#!/usr/bin/env bash
# Unit tests for reconcile-repo-state.sh.
#
# Each test crafts a throwaway git repo in a temp dir, drives the hook with a
# synthetic stdin payload, and asserts on stdout. `gh` is stubbed via PATH so
# tests stay offline and deterministic. The rate-limit window and stamp dir are
# overridden via env so the network fetch is skipped and timing is controllable.
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="$SCRIPT_DIR/reconcile-repo-state.sh"

pass=0
fail=0

# Shared scratch root, cleaned on exit.
ROOT="$(mktemp -d)"
trap 'rm -rf "$ROOT"' EXIT

# run_hook CWD [EXTRA_PATH_DIR]
# Feeds a minimal UserPromptSubmit payload on stdin. RECONCILE_FETCH_DISABLE=1
# keeps every test offline; RECONCILE_RATE_WINDOW_SECONDS and stamp dir are set
# per-test by callers as needed.
run_hook() {
  local cwd="$1"
  local extra_path="${2:-}"
  local path="$PATH"
  if [ -n "$extra_path" ]; then
    path="$extra_path:$PATH"
  fi
  printf '{"hook_event_name":"UserPromptSubmit","cwd":"%s","prompt":"hi"}' "$cwd" |
    PATH="$path" \
    RECONCILE_STAMP_DIR="$STAMP_DIR" \
    "$HOOK"
}

assert_contains() {
  local label="$1" haystack="$2" needle="$3"
  if printf '%s' "$haystack" | grep -qF "$needle"; then
    pass=$((pass + 1))
    echo "ok   - $label"
  else
    fail=$((fail + 1))
    echo "FAIL - $label"
    echo "       expected to find: $needle"
    echo "       in: $haystack"
  fi
}

assert_empty() {
  local label="$1" haystack="$2"
  if [ -z "$haystack" ]; then
    pass=$((pass + 1))
    echo "ok   - $label"
  else
    fail=$((fail + 1))
    echo "FAIL - $label (expected empty output)"
    echo "       got: $haystack"
  fi
}

assert_not_contains() {
  local label="$1" haystack="$2" needle="$3"
  if printf '%s' "$haystack" | grep -qF "$needle"; then
    fail=$((fail + 1))
    echo "FAIL - $label (did not expect to find: $needle)"
    echo "       in: $haystack"
  else
    pass=$((pass + 1))
    echo "ok   - $label"
  fi
}

# Create a gh stub directory that responds with a canned PR state.
# make_gh_stub DIR STATE   (STATE = MERGED | CLOSED | OPEN | NONE | UNAUTH)
make_gh_stub() {
  local dir="$1" state="$2"
  mkdir -p "$dir"
  cat >"$dir/gh" <<EOF
#!/usr/bin/env bash
case "\$1 \$2" in
  "auth status")
    if [ "$state" = "UNAUTH" ]; then exit 1; fi
    exit 0 ;;
esac
# pr view / pr list
if [ "$state" = "NONE" ]; then
  exit 1
fi
if [ "$state" = "UNAUTH" ]; then
  exit 1
fi
# Emit the requested --json field as a state string.
echo '{"state":"$state","number":42,"url":"https://example/pr/42"}'
exit 0
EOF
  chmod +x "$dir/gh"
}

# git wrapper that isolates from the user's global config and hooks
# (e.g. a global commit-msg hook enforcing conventional commits).
tgit() {
  git -c core.hooksPath=/dev/null \
      -c commit.gpgsign=false \
      -c user.email=t@t.t \
      -c user.name=t \
      "$@"
}

# A fresh local+remote git pair. Echoes the work-tree path.
# make_repo NAME
make_repo() {
  local name="$1"
  local remote="$ROOT/$name-remote.git"
  local work="$ROOT/$name"
  tgit init --quiet --bare "$remote"
  tgit init --quiet "$work"
  tgit -C "$work" checkout -q -b main
  echo "seed" >"$work/file"
  tgit -C "$work" add file
  tgit -C "$work" commit --quiet -m "seed"
  tgit -C "$work" remote add origin "$remote"
  tgit -C "$work" push --quiet -u origin main
  echo "$work"
}

# ---------------------------------------------------------------------------
# Test 1: not a git repo -> silent no-op
# ---------------------------------------------------------------------------
STAMP_DIR="$ROOT/stamps1"
NON_GIT="$ROOT/plain"
mkdir -p "$NON_GIT"
out="$(RECONCILE_FETCH_DISABLE=1 run_hook "$NON_GIT")"
assert_empty "non-git directory is a silent no-op" "$out"

# ---------------------------------------------------------------------------
# Test 2: clean, up-to-date branch -> injects nothing
# ---------------------------------------------------------------------------
STAMP_DIR="$ROOT/stamps2"
work="$(make_repo clean)"
ghdir="$ROOT/gh-none"
make_gh_stub "$ghdir" NONE
out="$(RECONCILE_FETCH_DISABLE=1 run_hook "$work" "$ghdir")"
assert_empty "clean up-to-date branch injects nothing" "$out"

# ---------------------------------------------------------------------------
# Test 3: branch behind origin/main -> reports behind
# ---------------------------------------------------------------------------
STAMP_DIR="$ROOT/stamps3"
work="$(make_repo behind)"
# Advance origin/main from a second clone, then update local remote-tracking ref.
clone="$ROOT/behind-clone"
tgit clone --quiet "$ROOT/behind-remote.git" "$clone"
echo "more" >"$clone/file2"
tgit -C "$clone" add file2
tgit -C "$clone" commit --quiet -m "advance main"
tgit -C "$clone" push --quiet origin main
# Put the local repo on a feature branch behind main, fetch so origin/main moves.
tgit -C "$work" checkout -q -b feature
tgit -C "$work" fetch --quiet origin
ghdir="$ROOT/gh-none3"
make_gh_stub "$ghdir" NONE
out="$(RECONCILE_FETCH_DISABLE=1 run_hook "$work" "$ghdir")"
assert_contains "branch behind origin/main is reported" "$out" "behind"
assert_contains "behind report names origin/main" "$out" "origin/main"

# ---------------------------------------------------------------------------
# Test 4: branch gone from remote -> reports gone
# ---------------------------------------------------------------------------
STAMP_DIR="$ROOT/stamps4"
work="$(make_repo gone)"
tgit -C "$work" checkout -q -b throwaway
tgit -C "$work" push --quiet -u origin throwaway
# Delete the branch on the remote, then prune so the upstream ref is "gone".
tgit -C "$work" push --quiet origin --delete throwaway
tgit -C "$work" fetch --quiet --prune origin
ghdir="$ROOT/gh-none4"
make_gh_stub "$ghdir" NONE
out="$(RECONCILE_FETCH_DISABLE=1 run_hook "$work" "$ghdir")"
assert_contains "branch gone from remote is reported" "$out" "no longer exists"

# ---------------------------------------------------------------------------
# Test 5: PR merged -> reports merged (with gh)
# ---------------------------------------------------------------------------
STAMP_DIR="$ROOT/stamps5"
work="$(make_repo prmerged)"
tgit -C "$work" checkout -q -b pr-branch
tgit -C "$work" push --quiet -u origin pr-branch
ghdir="$ROOT/gh-merged"
make_gh_stub "$ghdir" MERGED
out="$(RECONCILE_FETCH_DISABLE=1 run_hook "$work" "$ghdir")"
assert_contains "merged PR is reported" "$out" "MERGED"
assert_contains "merged PR output is valid hook JSON" "$out" "UserPromptSubmit"

# ---------------------------------------------------------------------------
# Test 6: PR open + clean branch -> injects nothing
# ---------------------------------------------------------------------------
STAMP_DIR="$ROOT/stamps6"
work="$(make_repo propen)"
tgit -C "$work" checkout -q -b open-branch
tgit -C "$work" push --quiet -u origin open-branch
ghdir="$ROOT/gh-open"
make_gh_stub "$ghdir" OPEN
out="$(RECONCILE_FETCH_DISABLE=1 run_hook "$work" "$ghdir")"
assert_empty "open PR on clean branch injects nothing" "$out"

# ---------------------------------------------------------------------------
# Test 7: gh absent -> still reports ahead/behind from local refs, no error
# ---------------------------------------------------------------------------
STAMP_DIR="$ROOT/stamps7"
work="$(make_repo noghbehind)"
clone="$ROOT/nogh-clone"
tgit clone --quiet "$ROOT/noghbehind-remote.git" "$clone"
echo "x" >"$clone/file2"
tgit -C "$clone" add file2
tgit -C "$clone" commit --quiet -m "advance"
tgit -C "$clone" push --quiet origin main
tgit -C "$work" checkout -q -b feat2
tgit -C "$work" fetch --quiet origin
# Build a PATH with only the dirs needed for git, deliberately omitting gh.
NOGH_BIN="$ROOT/nogh-bin"
mkdir -p "$NOGH_BIN"
for tool in git jq cat printf date stat mkdir tr cut shasum sha1sum \
            mktemp dirname basename grep sed env bash sh head find; do
  src="$(command -v "$tool" 2>/dev/null)" && ln -sf "$src" "$NOGH_BIN/$tool"
done
out="$(printf '{"hook_event_name":"UserPromptSubmit","cwd":"%s","prompt":"hi"}' "$work" |
  PATH="$NOGH_BIN" RECONCILE_STAMP_DIR="$STAMP_DIR" RECONCILE_FETCH_DISABLE=1 "$HOOK")"
rc=$?
assert_contains "gh absent still reports behind" "$out" "behind"
if [ "$rc" -eq 0 ]; then
  pass=$((pass + 1)); echo "ok   - gh absent exits 0"
else
  fail=$((fail + 1)); echo "FAIL - gh absent exits 0 (got $rc)"
fi

# ---------------------------------------------------------------------------
# Test 8: rate limit -> second call within window does not fetch
# ---------------------------------------------------------------------------
STAMP_DIR="$ROOT/stamps8"
work="$(make_repo ratelimit)"
ghdir="$ROOT/gh-none8"
make_gh_stub "$ghdir" NONE
# First call: fetch enabled, large window, against the real (bare) remote.
printf '{"hook_event_name":"UserPromptSubmit","cwd":"%s","prompt":"hi"}' "$work" |
  PATH="$ghdir:$PATH" RECONCILE_STAMP_DIR="$STAMP_DIR" \
  RECONCILE_RATE_WINDOW_SECONDS=3600 "$HOOK" >/dev/null
stamp="$(find "$STAMP_DIR" -type f | head -n1)"
if [ -n "$stamp" ]; then
  pass=$((pass + 1)); echo "ok   - first call creates a fetch stamp"
else
  fail=$((fail + 1)); echo "FAIL - first call creates a fetch stamp"
fi
mt1="$(stat -f %m "$stamp" 2>/dev/null || stat -c %Y "$stamp")"
# Second call within the window: stamp mtime must be unchanged (no fetch).
printf '{"hook_event_name":"UserPromptSubmit","cwd":"%s","prompt":"hi"}' "$work" |
  PATH="$ghdir:$PATH" RECONCILE_STAMP_DIR="$STAMP_DIR" \
  RECONCILE_RATE_WINDOW_SECONDS=3600 "$HOOK" >/dev/null
mt2="$(stat -f %m "$stamp" 2>/dev/null || stat -c %Y "$stamp")"
if [ "$mt1" = "$mt2" ]; then
  pass=$((pass + 1)); echo "ok   - second call within window skips fetch (stamp unchanged)"
else
  fail=$((fail + 1)); echo "FAIL - second call within window skips fetch (stamp changed $mt1 -> $mt2)"
fi

# ---------------------------------------------------------------------------
# Test 9: GNU `stat` form is probed before BSD (regression for #125)
# ---------------------------------------------------------------------------
# On GNU coreutils, `stat -f` means --file-system and `%m` is a bare filename:
# the probe exits non-zero but still prints a filesystem block to stdout. If the
# hook probes the BSD form (`stat -f %m`) first, that block leaks into the
# command substitution, the `|| stat -c %Y` fallback also runs, and the mtime
# read becomes a multi-word string. Arithmetic on it under `set -u` then throws
# `File: unbound variable`. The fix probes the GNU form (`stat -c %Y`) first.
#
# We stub `stat` on PATH to emulate GNU coreutils regardless of host platform:
#   stat -c %Y FILE  -> prints the mtime, exits 0
#   stat -f %m  FILE -> prints a filesystem block, exits 1 (GNU --file-system)
STAMP_DIR="$ROOT/stamps9"
work="$(make_repo gnustat)"
ghdir="$ROOT/gh-none9"
make_gh_stub "$ghdir" NONE

GNUSTAT_BIN="$ROOT/gnustat-bin"
mkdir -p "$GNUSTAT_BIN"
# Symlink the real tools the hook needs, but shadow `stat` with a GNU emulator.
for tool in git jq cat printf date mkdir tr cut shasum sha1sum \
            mktemp dirname basename grep sed env bash sh head find; do
  src="$(command -v "$tool" 2>/dev/null)" && ln -sf "$src" "$GNUSTAT_BIN/$tool"
done
REAL_STAT="$(command -v stat)"
cat >"$GNUSTAT_BIN/stat" <<EOF
#!/usr/bin/env bash
# GNU coreutils emulator: -c %Y works; -f %m is --file-system (prints a block,
# exits non-zero against a regular file).
if [ "\$1" = "-c" ]; then
  exec "$REAL_STAT" -f %m "\$3"
fi
if [ "\$1" = "-f" ]; then
  echo "  File: \"\$3\""
  echo "    ID: 0 Namelen: 255 Type: apfs"
  exit 1
fi
exec "$REAL_STAT" "\$@"
EOF
chmod +x "$GNUSTAT_BIN/stat"

# Pre-create a stamp inside the rate-limit window so the hook reads its mtime.
# The hook keys the stamp on the repo's resolved toplevel (which may differ from
# $work — e.g. /tmp vs /private/tmp on macOS), so derive the key the same way.
mkdir -p "$STAMP_DIR"
stamp_top="$(tgit -C "$work" rev-parse --show-toplevel)"
key="$(printf '%s' "$stamp_top" | shasum | cut -d' ' -f1)"
: >"$STAMP_DIR/$key"

out="$(printf '{"hook_event_name":"UserPromptSubmit","cwd":"%s","prompt":"hi"}' "$work" |
  PATH="$ghdir:$GNUSTAT_BIN" RECONCILE_STAMP_DIR="$STAMP_DIR" \
  RECONCILE_RATE_WINDOW_SECONDS=3600 "$HOOK" 2>&1)"
rc=$?
assert_not_contains "GNU stat: no 'File: unbound variable' crash" "$out" "unbound variable"
assert_not_contains "GNU stat: filesystem block does not leak to output" "$out" "Namelen"
assert_empty "GNU stat: clean rate-limited turn injects nothing" "$out"
if [ "$rc" -eq 0 ]; then
  pass=$((pass + 1)); echo "ok   - GNU stat: hook exits 0"
else
  fail=$((fail + 1)); echo "FAIL - GNU stat: hook exits 0 (got $rc)"
fi

# ---------------------------------------------------------------------------
# Test 10: trunk resolved from default branch (develop) -> reports behind develop
# ---------------------------------------------------------------------------
# A repo whose default branch is `develop`, not `main`. The hook must compare
# HEAD against origin/develop (resolved from origin/HEAD), not a non-existent
# origin/main. Regression for §spec:integration-ref.
STAMP_DIR="$ROOT/stamps10"
remote10="$ROOT/develop-remote.git"
work10="$ROOT/develop"
tgit init --quiet --bare "$remote10"
# Make `develop` the remote's default branch (HEAD).
tgit -C "$remote10" symbolic-ref HEAD refs/heads/develop
tgit init --quiet "$work10"
tgit -C "$work10" checkout -q -b develop
echo "seed" >"$work10/file"
tgit -C "$work10" add file
tgit -C "$work10" commit --quiet -m "seed"
tgit -C "$work10" remote add origin "$remote10"
tgit -C "$work10" push --quiet -u origin develop
# Record origin/HEAD locally so the hook can resolve the default branch.
tgit -C "$work10" remote set-head origin develop
# Advance origin/develop from a clone, then move the local feature branch behind it.
clone10="$ROOT/develop-clone"
tgit clone --quiet "$remote10" "$clone10"
echo "more" >"$clone10/file2"
tgit -C "$clone10" add file2
tgit -C "$clone10" commit --quiet -m "advance develop"
tgit -C "$clone10" push --quiet origin develop
tgit -C "$work10" checkout -q -b feature-x
tgit -C "$work10" fetch --quiet origin
ghdir="$ROOT/gh-none10"
make_gh_stub "$ghdir" NONE
out="$(RECONCILE_FETCH_DISABLE=1 run_hook "$work10" "$ghdir")"
assert_contains "behind report names resolved trunk origin/develop" "$out" "origin/develop"
assert_not_contains "behind report does not name origin/main" "$out" "origin/main"

# ---------------------------------------------------------------------------
echo
echo "passed: $pass  failed: $fail"
[ "$fail" -eq 0 ]
