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
# A skill ships SKILL.md plus everything under references/. Any other file in an
# installed skill dir is stale: --check reports it, a sync removes it.
# Keep this bash 3.2 compatible (macOS /bin/bash).
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHAIN=(sweep find-problems create-issues fix-issues review-issues)

CHECK=0; INIT=0; declare -a ONLY=()
while [ $# -gt 0 ]; do
  case "$1" in
    --check) CHECK=1 ;;
    --init)  INIT=1 ;;
    --only)  shift; while [ $# -gt 0 ] && [[ "$1" != --* ]]; do ONLY+=("$1"); shift; done; continue ;;
    -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
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

drift=0; synced=0; removed=0
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

shipped() { # skill -> files it ships, relative to its dir
  printf '%s\n' SKILL.md
  if [ -d "$REPO/skills/$1/references" ]; then
    (cd "$REPO/skills/$1" && find references -type f ! -name .DS_Store | LC_ALL=C sort)
  fi
}

stale() { # skill dst -> installed files the repo no longer ships
  [ -d "$2" ] || return 0
  (cd "$2" && find . -type f ! -name .DS_Store | LC_ALL=C sort) | while IFS= read -r rel; do
    rel="${rel#./}"
    case "$rel" in
      SKILL.md|references/*) if [ -f "$REPO/skills/$1/$rel" ]; then continue; fi ;;
    esac
    printf '%s\n' "$2/$rel"
  done
}

for h in $(harnesses); do
  for s in "${CHAIN[@]}"; do
    [ -f "$REPO/skills/$s/SKILL.md" ] || { echo "no such skill: $s" >&2; exit 2; }
    dst="$h/skills/$s"
    while IFS= read -r rel; do
      sync_file "$REPO/skills/$s/$rel" "$dst/$rel"
    done < <(shipped "$s")
    while IFS= read -r f; do
      if [ "$CHECK" = 1 ]; then printf 'STALE    %s\n' "$f"; drift=1
      else rm -f "$f"; removed=$((removed + 1)); fi
    done < <(stale "$s" "$dst")
    [ "$CHECK" = 1 ] || find "$dst" -mindepth 1 -type d -empty -delete
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
      # point the wrapper at the copy installed in this harness, not at the repo
      sed "s|{{SKILLS_DIR}}|$h/skills|g" "$src" > "$tmp"
      sync_file "$tmp" "$cmd_dir/$s.md"
      rm -f "$tmp"
    done
  fi
done

if [ "$CHECK" = 1 ]; then
  if [ "$drift" = 0 ]; then echo "in sync (${#CHAIN[@]} skills)"; else echo "drift detected" >&2; exit 1; fi
else
  printf 'synced %s files, removed %s stale, across %s harnesses\n' \
    "$synced" "$removed" "$(harnesses | wc -l | tr -d ' ')"
fi
