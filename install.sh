#!/usr/bin/env bash
# Install / refresh the ai-rules-skills chain into the harnesses this setup uses.
#
#   ./install.sh                     sync into agents, copilot, cursor, opencode
#   ./install.sh --check             report drift, change nothing, exit 1 if any
#   ./install.sh --init              also create command dirs where the harness has none
#   ./install.sh --harness <name|path>  add a harness (repeatable)
#   ./install.sh --all-harnesses     discover every ~/.<name>/skills
#   ./install.sh --list-harnesses    print the resolved target set, change nothing
#   ./install.sh --only <names>      install only these skills (default: the chain)
#   ./install.sh --only pstack       install the pstack bundle + its wrappers
#
# The default targets are ~/.agents, ~/.copilot, ~/.cursor, and ~/.config/opencode.
# A harness is any of those dirs that already has a skills/ dir. --all-harnesses
# restores the old discovery of every $HOME/.<name>/skills, for a machine with
# other agents. A skill ships every file in its repo dir; an installed file the
# repo no longer ships is stale (--check reports it, a sync removes it).
# pstack-models.md is machine state, never synced or pruned. A bundle may ship
# commands/<name>/*.md wrappers. Keep this bash 3.2 compatible (macOS /bin/bash).
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHAIN=(sweep find-problems create-issues fix-issues review-issues fix-findings merge-prs release-version)
DEFAULT_HARNESSES=(agents copilot cursor opencode)

CHECK=0; INIT=0; ALL=0; LIST=0; declare -a ONLY=() HARNESS_ARGS=() HARNESS_PATHS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --check) CHECK=1 ;;
    --init)  INIT=1 ;;
    --all-harnesses) ALL=1 ;;
    --list-harnesses) LIST=1 ;;
    --harness)
      shift
      [ $# -gt 0 ] || { echo "missing value for --harness" >&2; exit 2; }
      HARNESS_ARGS+=("$1")
      ;;
    --only)  shift; while [ $# -gt 0 ] && [[ "$1" != --* ]]; do ONLY+=("$1"); shift; done; continue ;;
    -h|--help) sed -n '2,19p' "$0"; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
  shift
done
[ ${#ONLY[@]} -gt 0 ] && CHAIN=("${ONLY[@]}")

if [ ${#HARNESS_ARGS[@]} -gt 0 ] && [ "$ALL" = 1 ]; then
  echo "use --harness or --all-harnesses, not both" >&2; exit 2
fi

resolve_harness() { # name|path -> dir with a skills/ subdir
  case "$1" in
    ~/*) d="$HOME/${1#~/}" ;;
    /*)  d="$1" ;;
    */*) d="$HOME/$1" ;;
    *)
      for d in "$HOME/.$1" "$HOME/.config/$1"; do
        [ -d "$d/skills" ] && { printf '%s\n' "$d"; return 0; }
      done
      return 1
      ;;
  esac
  [ -d "$d/skills" ] || return 1
  printf '%s\n' "$d"
}

# Resolve explicit --harness values up front so a typo fails loudly.
if [ ${#HARNESS_ARGS[@]} -gt 0 ]; then
  for name in "${HARNESS_ARGS[@]}"; do
    if ! d=$(resolve_harness "$name"); then
      echo "no harness with a skills/ dir: $name" >&2
      exit 2
    fi
    HARNESS_PATHS+=("$d")
  done
fi

harnesses() {
  if [ ${#HARNESS_PATHS[@]} -gt 0 ]; then
    for d in "${HARNESS_PATHS[@]}"; do printf '%s\n' "$d"; done
    return
  fi
  if [ "$ALL" = 0 ]; then
    for name in "${DEFAULT_HARNESSES[@]}"; do
      d=$(resolve_harness "$name" 2>/dev/null) || continue
      printf '%s\n' "$d"
    done
    return
  fi
  for d in "$HOME"/.[!.]* "$HOME"/.config/*; do
    [ -d "$d/skills" ] || continue
    printf '%s\n' "$d"
  done
}

if [ "$LIST" = 1 ]; then
  harnesses | sed "s|^$HOME/|~/|"
  exit 0
fi

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
  (cd "$REPO/skills/$1" && find . -type f ! -name .DS_Store ! -name pstack-models.md |
    sed 's|^\./||' | LC_ALL=C sort)
}

stale() { # skill dst -> installed files the repo no longer ships
  [ -d "$2" ] || return 0
  (cd "$2" && find . -type f ! -name .DS_Store ! -name pstack-models.md | LC_ALL=C sort) | while IFS= read -r rel; do
    rel="${rel#./}"
    [ -f "$REPO/skills/$1/$rel" ] || printf '%s\n' "$2/$rel"
  done
}

while IFS= read -r h; do
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
      # one wrapper per skill, or every wrapper in a bundle's commands/<name>/ dir
      for src in "$REPO/commands/$s.md" "$REPO/commands/$s"/*.md; do
        [ -f "$src" ] || continue
        tmp="$(mktemp)"
        # point the wrapper at the copy installed in this harness, not at the repo
        sed "s|{{SKILLS_DIR}}|$h/skills|g" "$src" > "$tmp"
        sync_file "$tmp" "$cmd_dir/$(basename "$src")"
        rm -f "$tmp"
      done
    done
  fi
done < <(harnesses)

harness_count=$(harnesses | wc -l | tr -d ' ')
if [ "$CHECK" = 1 ]; then
  if [ "$drift" = 0 ]; then echo "in sync (${#CHAIN[@]} skills, $harness_count harnesses)"; else echo "drift detected" >&2; exit 1; fi
else
  printf 'synced %s files, removed %s stale, across %s harnesses\n' \
    "$synced" "$removed" "$harness_count"
fi
