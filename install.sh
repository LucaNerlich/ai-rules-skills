#!/usr/bin/env bash
# Install / refresh the ai-rules-skills chain into every harness on this machine.
#
#   ./install.sh                 sync skills + command wrappers into existing harnesses
#   ./install.sh --check         report drift, change nothing, exit 1 if any
#   ./install.sh --init          also create command dirs where the harness has none
#   ./install.sh --only <names>  install only these skills (default: the chain)
#
# Harnesses are discovered as any $HOME/.<harness> that already has a skills/ dir,
# so an uninstalled or renamed harness is simply skipped rather than guessed at.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHAIN=(sweep find-problems create-issues fix-issues review-issues)

CHECK=0; INIT=0; declare -a ONLY=()
while [ $# -gt 0 ]; do
  case "$1" in
    --check) CHECK=1 ;;
    --init)  INIT=1 ;;
    --only)  shift; while [ $# -gt 0 ] && [[ "$1" != --* ]]; do ONLY+=("$1"); shift; done; continue ;;
    -h|--help) sed -n '2,9p' "$0"; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
  shift
done
[ ${#ONLY[@]} -gt 0 ] && CHAIN=("${ONLY[@]}")

harnesses() {
  for d in "$HOME"/.[!.]* "$HOME"/.config/*; do
    [ -d "$d/skills" ] || continue
    printf '%s\n' "$d"
  done
}

drift=0; synced=0
sync_file() { # src dst
  if [ "$CHECK" = 1 ]; then
    if [ ! -f "$2" ]; then printf 'MISSING  %s\n' "$2"; drift=1
    elif ! cmp -s "$1" "$2"; then printf 'DRIFT    %s\n' "$2"; drift=1
    fi
    return
  fi
  mkdir -p "$(dirname "$2")"
  cp "$1" "$2"
  synced=$((synced + 1))
}

for h in $(harnesses); do
  for s in "${CHAIN[@]}"; do
    src="$REPO/skills/$s/SKILL.md"
    [ -f "$src" ] || { echo "no such skill: $s" >&2; exit 2; }
    sync_file "$src" "$h/skills/$s/SKILL.md"
    # ship a skill's bundled references too (e.g. find-problems/references/ponytail.md)
    if [ -d "$REPO/skills/$s/references" ]; then
      for ref in "$REPO/skills/$s/references"/*; do
        sync_file "$ref" "$h/skills/$s/references/$(basename "$ref")"
      done
    fi
  done

  # command wrappers: prefer the harness's own convention
  cmd_dir=""
  for c in "$h/command" "$h/commands"; do [ -d "$c" ] && { cmd_dir="$c"; break; }; done
  if [ -z "$cmd_dir" ] && [ "$INIT" = 1 ]; then
    case "$(basename "$h")" in opencode) cmd_dir="$h/command" ;; *) cmd_dir="$h/commands" ;; esac
  fi
  if [ -n "$cmd_dir" ]; then
    for s in "${CHAIN[@]}"; do
      src="$REPO/commands/$s.md"
      [ -f "$src" ] || continue
      tmp="$(mktemp)"
      sed "s|{{SKILLS_DIR}}|$REPO|g" "$src" > "$tmp"
      sync_file "$tmp" "$cmd_dir/$s.md"
      rm -f "$tmp"
    done
  fi
done

if [ "$CHECK" = 1 ]; then
  if [ "$drift" = 0 ]; then echo "in sync (${#CHAIN[@]} skills)"; else echo "drift detected" >&2; exit 1; fi
else
  printf 'synced %s files across %s harnesses\n' "$synced" "$(harnesses | wc -l | tr -d ' ')"
fi
