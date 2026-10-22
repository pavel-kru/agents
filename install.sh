#!/usr/bin/env bash
#
# Makes this repo's skills available in every Claude Code session on the
# machine by symlinking them into ~/.claude/skills. Safe to re-run; it never
# overwrites a real directory (it backs it up to .bak), and it removes only
# links that point into this repo's skills/ and whose target is gone.
#
# Usage: ./install.sh            link
#        ./install.sh --check    report only, change nothing (exit 1 on problems)

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS="$HOME/.claude/skills"
CHECK=0
[ "${1:-}" = "--check" ] && CHECK=1
problems=0

mkdir -p "$SKILLS"

for src in "$REPO"/skills/*/; do
  [ -f "$src/SKILL.md" ] || continue
  name="$(basename "$src")"
  dest="$SKILLS/$name"
  target="${src%/}"

  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$target" ] && [ -e "$dest" ]; then
    echo "  = $dest"
    continue
  fi

  if [ "$CHECK" = 1 ]; then
    if [ -L "$dest" ]; then echo "  ! $dest points elsewhere: $(readlink "$dest")"
    elif [ -e "$dest" ]; then echo "  ! $dest is a real directory shadowing the repo copy"
    else echo "  ! $dest missing (run ./install.sh)"; fi
    problems=$((problems + 1))
    continue
  fi

  if [ -L "$dest" ]; then
    rm "$dest"
  elif [ -e "$dest" ]; then
    echo "  ! backing up $dest -> $dest.bak"
    mv "$dest" "$dest.bak"
  fi
  ln -s "$target" "$dest"
  echo "  + $dest"
done

# Links into this repo whose skill was deleted would keep offering a dead skill.
for l in "$SKILLS"/*; do
  [ -L "$l" ] || continue
  case "$(readlink "$l")" in
    "$REPO/skills/"*) ;;
    *) continue ;;
  esac
  [ -e "$l" ] && continue
  if [ "$CHECK" = 1 ]; then
    echo "  ! $l is stale (skill gone from repo)"
    problems=$((problems + 1))
  else
    rm "$l"
    echo "  - $l (stale: gone from repo)"
  fi
done

[ "$problems" -eq 0 ] || exit 1
