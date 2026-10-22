#!/usr/bin/env bash
# Stop hook: this repo is the source of truth for the patterns and is used from
# more than one machine, so work left uncommitted or unpushed is stranded.
#
# Blocks the stop once per distinct state when the repo has uncommitted changes
# or commits not pushed to origin, and asks Claude to show them and ask the user.
# It never commits: commits need the user's go-ahead (require-commit-review.sh).
#
# stop_hook_active is deliberately not honoured: a pattern fixed because another
# Stop hook blocked is written in exactly such a continuation. Loops are
# prevented by the signature instead — an unchanged state never blocks twice.
#
# Must run on macOS /bin/bash 3.2 as well as Linux: no mapfile, no associative
# arrays.

set -u

ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0

INPUT="$(cat)"
SESSION_ID="$(printf '%s' "$INPUT" | jq -r '.session_id // "default"')"

PROBLEMS=""

DIRTY="$(git -C "$ROOT" status --porcelain 2>/dev/null)"
[ -n "$DIRTY" ] && PROBLEMS+="- uncommitted changes:"$'\n'"$(printf '%s' "$DIRTY" | sed 's/^/    /')"$'\n'

BRANCH="$(git -C "$ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null)"
if git -C "$ROOT" rev-parse --verify --quiet "origin/$BRANCH" >/dev/null 2>&1; then
  AHEAD="$(git -C "$ROOT" rev-list --count "origin/$BRANCH..$BRANCH" 2>/dev/null || echo 0)"
  [ "${AHEAD:-0}" -gt 0 ] && PROBLEMS+="- $AHEAD commit(s) not pushed to origin/$BRANCH"$'\n'
fi

[ -n "$PROBLEMS" ] || exit 0

# Remind once per distinct state per session. HEAD is part of the signature:
# after a commit, editing the same file again yields the same problem text.
MARKER_DIR="${TMPDIR:-/tmp}/claude-agents-sync"
mkdir -p "$MARKER_DIR" 2>/dev/null
MARKER="$MARKER_DIR/$SESSION_ID"
SIGNATURE="$({ git -C "$ROOT" rev-parse HEAD 2>/dev/null; printf '%s' "$PROBLEMS"; } | cksum)"
if [ -f "$MARKER" ] && [ "$(cat "$MARKER")" = "$SIGNATURE" ]; then
  exit 0
fi
printf '%s' "$SIGNATURE" > "$MARKER"

REASON="The patterns repo is out of sync with its remote:
${PROBLEMS}
Show the user what changed (git status --short, git diff --stat) and ask whether
to commit and push. Do not commit on your own: the commit hook needs the user's
own words in this turn. If the changes are meant to stay local, say so in one
sentence and finish."

jq -n --arg reason "$REASON" '{decision: "block", reason: $reason}'
exit 0
