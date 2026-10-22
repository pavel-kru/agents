#!/usr/bin/env bash
# PreToolUse(Bash) hook: refuse `git commit` until the user has reviewed the
# changes and said to commit.
#
# The user reviews the diff themselves and decides when work is ready to land.
# Claude does not commit on its own initiative, does not commit as the tail end
# of "make this change", and does not treat earlier approval in the session as
# standing permission for later commits.
#
# Approval is per-commit and comes from the user's own words in the CURRENT
# turn — "commit", "commit it", "ship it", "lgtm, commit", or "PR" / "/pr" in
# any case (the /pr skill: commit + push + pull request). Claude records that
# by touching the approval marker (path printed below) immediately before
# running the commit. The marker is consumed on use, so each commit needs its
# own approval.
#
# Claude must NOT touch the marker on its own judgment. Creating it without the
# user having asked in that turn defeats the rule this hook exists to enforce.
#
set -u

INPUT="$(cat)"

TOOL="$(printf '%s' "$INPUT" | jq -r '.tool_name // ""')"
[ "$TOOL" = "Bash" ] || exit 0

CMD="$(printf '%s' "$INPUT" | jq -r '.tool_input.command // ""')"
SESSION_ID="$(printf '%s' "$INPUT" | jq -r '.session_id // "default"')"

# Not a commit (covers `git commit`, `git -C … commit`, `git ... commit -m`).
printf '%s' "$CMD" | grep -qE '(^|[;&|[:space:]])git([[:space:]]+-[^[:space:]]+([[:space:]]+[^[:space:]]+)?)*[[:space:]]+commit([[:space:]]|$)' || exit 0

MARKER_DIR="${TMPDIR:-/tmp}/claude-commit-approval"
MARKER="$MARKER_DIR/$SESSION_ID"

# Approved for exactly one commit: consume the marker and let it through.
if [ -f "$MARKER" ]; then
  rm -f "$MARKER"
  exit 0
fi

REASON="Blocked: the user reviews changes before anything is committed.

Do not commit on your own initiative, and do not treat an earlier approval in this session as permission for this one — approval is per-commit.

What to do instead:
1. Leave the changes in the working tree.
2. Show the user what is staged/unstaged so they can review it — e.g. \`git status --short\` and \`git diff\` (or name the files and what changed).
3. Stop and wait. Let them read it and decide.

When the user asks for the commit IN THEIR OWN WORDS in the current turn (\"commit\", \"commit it\", \"ship it\", \"lgtm — commit\", or \"PR\" / \"pr\" / \"/pr\" — asking for a pull request includes the commit), record that approval and re-run:

  mkdir -p '$MARKER_DIR' && touch '$MARKER'

Only create that marker when the user actually asked in this turn. Never create it because you judge the work ready, because tests pass, or to get past this message."

jq -n --arg reason "$REASON" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: $reason
  }
}'
exit 0
