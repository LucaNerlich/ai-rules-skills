#!/usr/bin/env bash
# Re-sync the pstack port from a newer upstream copy.
#
# Usage: refresh.sh <plugin-dir>
#   <plugin-dir> contains skills/ (e.g. a new
#   ~/.cursor/plugins/cache/cursor-public/pstack/<hash>, or a clone of
#   github.com/cursor/plugins at pstack/).
#
# Run it against the repo copy (skills/pstack/), then fan out with
# `./install.sh --only pstack`. It wipes the ported skill dirs, recopies from
# the source, re-applies the OpenCode adaptations, and fails if any Cursor
# rule reference survived.
set -euo pipefail

SRC="${1:?usage: refresh.sh <plugin-dir containing skills/>}"
DST="$(cd "$(dirname "$0")/.." && pwd)"

[ -d "$SRC/skills" ] || { echo "no skills/ under $SRC" >&2; exit 1; }

# 1. Replace skill dirs (keep docs/agents/port and the root files we own).
for d in "$DST"/*/; do
  case "$(basename "$d")" in
    docs|agents|port) ;;
    *) rm -rf "$d" ;;
  esac
done
rsync -a --exclude '.DS_Store' "$SRC/skills/" "$DST/"
rsync -a --exclude '.DS_Store' "$SRC/docs" "$SRC/agents" "$DST/"
cp "$SRC/README.md" "$SRC/LICENSE" "$SRC/plugin.json" "$DST/"

# 2. OpenCode adaptations (keep in lockstep with PORTING.md).
cd "$DST"
find . -name '*.md' ! -name 'PORTING.md' -not -path './port/*' -print0 | xargs -0 sed -i '' \
  -e 's|~/.cursor/rules/pstack-models\.mdc|~/.agents/skills/pstack/pstack-models.md|g' \
  -e 's|pstack-models\.mdc|pstack-models.md|g' \
  -e 's|~/.cursor/skills|~/.agents/skills|g' \
  -e 's|\.cursor/skills|.agents/skills|g' \
  -e 's|Task tool|subagent tool|g' \
  -e 's|AskQuestion|question tool|g'

# 3. Normalize frontmatter name to the directory name.
for d in */; do
  b=${d%/}
  [ -f "$d/SKILL.md" ] || continue
  sed -i '' "s/^name: .*/name: $b/" "$d/SKILL.md"
done

# 4. Assert no Cursor rule reference survived.
if grep -rlq 'pstack-models\.mdc' --include='*.md' .; then
  echo 'FATAL: pstack-models.mdc references survived the port' >&2
  exit 1
fi

echo "pstack port refreshed from: $SRC"
echo "skills: $(find . -name SKILL.md -mindepth 2 | wc -l | tr -d ' ')"
