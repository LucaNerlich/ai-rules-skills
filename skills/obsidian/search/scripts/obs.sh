#!/bin/bash
# Thin wrapper around the Obsidian CLI for the ai-wiki vault.
# - Targets the ai-wiki vault explicitly (multiple vaults exist on this machine).
# - Drops the noisy "Loading updated app package / installer" banner on stderr.
# - Forwards every argument straight through, so usage mirrors `obsidian <cmd> ...`.
#
# Requires the Obsidian desktop app to be RUNNING — the CLI is a thin client that
# talks to the live app over IPC. base:query / search read from that running instance.
#
# Override the binary or vault with env vars if your setup differs (note: these are
# skill-specific names, chosen to NOT collide with a global OBSIDIAN_VAULT that may
# already point at a different vault):
#   AI_WIKI_OBSIDIAN_BIN    (default: /Applications/Obsidian.app/Contents/MacOS/obsidian)
#   AI_WIKI_VAULT           (default: ai-wiki — must be the vault NAME, not a path)
#
# Examples:
#   obs.sh base:query path="wiki/Glossary.base" view="A–Z" format=md
#   obs.sh search query="reward model" format=json
#   obs.sh read path="wiki/concepts/rag.md"
BIN="${AI_WIKI_OBSIDIAN_BIN:-/Applications/Obsidian.app/Contents/MacOS/obsidian}"
VAULT="${AI_WIKI_VAULT:-ai-wiki}"
exec "$BIN" vault="$VAULT" "$@" 2>/dev/null
