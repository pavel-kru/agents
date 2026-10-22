#!/usr/bin/env bash
# Stop hook: when changed files are covered by a doc, and that doc is older than
# the changes, block the stop once and ask Claude to update the doc or say why
# it doesn't need it.
#
# Coverage is declared in .claude/doc-coverage.json:
#   { "<doc path>": ["<repo-relative prefix or file>", ...], ... }
# A trailing "/" marks a directory prefix; anything else is an exact file.
#
# "Up to date" is decided by mtime, so it works before anything is committed:
# a doc newer than every changed file it covers is current.
#
# Must run on macOS /bin/bash 3.2 as well as Linux: no mapfile, no associative
# arrays, and no "${arr[@]}" on a possibly empty array (set -u trips on it).

set -u

ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
cd "$ROOT" || exit 0

MANIFEST=".claude/doc-coverage.json"
[ -f "$MANIFEST" ] || exit 0

INPUT="$(cat)"
SESSION_ID="$(printf '%s' "$INPUT" | jq -r '.session_id // "default"')"
STOP_ACTIVE="$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // false')"

# Already continuing because of a stop hook: never block twice in a row.
[ "$STOP_ACTIVE" = "true" ] && exit 0

# Changed files, one per line, from porcelain status (works before the first
# commit, unlike `git diff HEAD`). Renames keep the new path.
CHANGED="$(git status --porcelain -uall 2>/dev/null | cut -c4- | sed 's/.* -> //' | sort -u)"
[ -n "$CHANGED" ] || exit 0

# GNU stat (Linux) takes -c %Y, BSD stat (macOS) takes -f %m.
if stat -c %Y / >/dev/null 2>&1; then
  mtime() { stat -c %Y "$1" 2>/dev/null || echo 0; }
else
  mtime() { stat -f %m "$1" 2>/dev/null || echo 0; }
fi

# One "<doc>\t<file>" line per covered file changed after its doc.
STALE=""
while IFS=$'\t' read -r DOC PREFIX; do
  [ -n "$DOC" ] || continue
  [ -f "$DOC" ] || continue
  DOC_TS="$(mtime "$DOC")"
  while IFS= read -r F; do
    case "$PREFIX" in
      */) [[ "$F" == "$PREFIX"* ]] || continue ;;
      *)  [[ "$F" == "$PREFIX" ]]  || continue ;;
    esac
    [ -e "$F" ] || continue                       # deleted file: skip
    [ "$(mtime "$F")" -gt "$DOC_TS" ] || continue  # older than the doc
    STALE+="$DOC"$'\t'"$F"$'\n'
  done <<< "$CHANGED"
done < <(jq -r 'to_entries[] | .key as $k | .value[] | [$k, .] | @tsv' "$MANIFEST")

[ -n "$STALE" ] || exit 0

# "- <doc>: <file> <file> " per doc, docs sorted.
SUMMARY="$(printf '%s' "$STALE" | sort -u | awk -F'\t' '
  $1 != prev { if (NR > 1) printf "\n"; printf "- %s: ", $1; prev = $1 }
  { printf "%s ", $2 }
')"$'\n'

# Remind once per distinct set of affected files per session.
MARKER_DIR="${TMPDIR:-/tmp}/claude-agents-doc-coverage"
mkdir -p "$MARKER_DIR" 2>/dev/null
MARKER="$MARKER_DIR/$SESSION_ID"
SIGNATURE="$(printf '%s' "$SUMMARY" | cksum)"
if [ -f "$MARKER" ] && [ "$(cat "$MARKER")" = "$SIGNATURE" ]; then
  exit 0
fi
printf '%s' "$SIGNATURE" > "$MARKER"

REASON="Doc coverage check. Files covered by a doc changed after the doc did:
${SUMMARY}Check whether each doc still describes them (a new hook, a changed flag, a renamed file, a new step). If so, update the doc now. If nothing needs to change, say so in one sentence and finish."

jq -n --arg reason "$REASON" '{decision: "block", reason: $reason}'
exit 0
