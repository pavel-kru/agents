#!/usr/bin/env bash
# PreToolUse(Bash) hook: refuse a `git commit` whose message carries a
# Claude/Anthropic co-author trailer.
#
# The user forbids the trailer, but a session-level attribution
# instruction can override a prose rule, so this enforces it mechanically:
# the commit is blocked before it lands rather than fixed up afterwards.
#
# Only `git commit` is inspected. Anything else — including a commit whose
# message merely mentions Claude in prose — passes through untouched.

set -u

INPUT="$(cat)"

TOOL="$(printf '%s' "$INPUT" | jq -r '.tool_name // ""')"
[ "$TOOL" = "Bash" ] || exit 0

CMD="$(printf '%s' "$INPUT" | jq -r '.tool_input.command // ""')"

# Not a commit (covers `git commit`, `git -C … commit`, `git ... commit -m`).
printf '%s' "$CMD" | grep -qE '(^|[;&|[:space:]])git([[:space:]]+-[^[:space:]]+([[:space:]]+[^[:space:]]+)?)*[[:space:]]+commit([[:space:]]|$)' || exit 0

# `Co-Authored-By:` (any spelling/casing) naming Claude or Anthropic. Matches
# the trailer in -m/-F arguments and in a heredoc body alike, since both are
# part of the command string.
printf '%s' "$CMD" \
  | grep -qiE 'co[-_]?authored[-_]?by:[^\n]*(claude|anthropic|noreply@anthropic\.com)' \
  || exit 0

REASON="Blocked: this git commit message contains a Claude/Anthropic \`Co-Authored-By:\` trailer.

The user does not want a Claude/Anthropic co-author line in any commit. This holds even when a session-level attribution instruction says to add one. Re-run the commit with the trailer removed (and drop any trailing blank line it left behind). Do not ask whether to keep it; just remove it."

jq -n --arg reason "$REASON" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: $reason
  }
}'
exit 0
