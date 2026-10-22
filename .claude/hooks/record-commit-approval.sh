#!/usr/bin/env bash
# UserPromptSubmit hook: turn the user's own words into the per-turn commit
# approval that require-commit-review.sh checks for.
#
# Approval comes from the prompt text, so Claude never has to create the
# marker itself (the auto-mode classifier rightly treats that as a bypass).
#
# Every prompt first clears any leftover marker, so approval never carries
# over from an earlier turn. The marker is then created only when the prompt
# STARTS with an approval word:
#   - `PR` / `pr` / `/pr` (the /pr skill: commit + push + PR, optionally merge)
#   - `commit`, `ship it`, `lgtm`
# Anchoring to the start avoids approving "don't commit yet" or
# "why was the PR blocked?".

set -u

INPUT="$(cat)"

PROMPT="$(printf '%s' "$INPUT" | jq -r '.prompt // ""')"
SESSION_ID="$(printf '%s' "$INPUT" | jq -r '.session_id // "default"')"

MARKER_DIR="${TMPDIR:-/tmp}/claude-commit-approval"
MARKER="$MARKER_DIR/$SESSION_ID"

rm -f "$MARKER"

# First non-blank line, leading whitespace stripped.
FIRST_LINE="$(printf '%s\n' "$PROMPT" | sed -n '/[^[:space:]]/{s/^[[:space:]]*//;p;q;}')"

if printf '%s' "$FIRST_LINE" | grep -qiE '^(/?pr|commit|ship it|lgtm)([[:space:][:punct:]]|$)'; then
  mkdir -p "$MARKER_DIR"
  touch "$MARKER"
fi

exit 0
