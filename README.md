# ai-rules-skills

## Install

```sh
./install.sh            # sync skills + /command wrappers into every harness on this machine
./install.sh --check    # report drift, change nothing, exit 1 if out of sync
./install.sh --init     # also create command dirs where the harness has none
./install.sh --only sweep find-problems
```

Harnesses are discovered as any `~/.<harness>/skills` or `~/.config/<harness>/skills`
that already exists, so a renamed or uninstalled harness is skipped rather than guessed at.

## Sweep — the problem pipeline

One command runs the whole cycle, and the last step makes it a loop:

```
/sweep
  ├─ find-problems   → findings report                              (read-only)
  ├─ create-issues   → priority:high|medium|low issues                     [gate]
  ├─ fix-issues      → stacked PR chain (gh-stack)                         [gate]
  ├─ review-issues   → PR review comments + agent instructions             [gate]
  └─ create-issues   → re-file unresolved review findings → next /fix-issues pass
```

Each phase is also a skill (and a `/command`) of its own; `/sweep --depth report|file|fix|review`
stops where you want. The skills live in [`skills/`](skills/), the slash-command wrappers in
[`commands/`](commands/).

- https://cursor.com/docs/context/skills
- https://vercel.com/blog/introducing-react-best-practices
- https://vercel.com/design/guidelines
- npx npx skills i vercel-labs/agent-skills
- npx skills add better-auth/skills
- curl -fsSL https://ui-skills.com/install | bash
- curl -fsSL https://rams.ai/install | bash
- https://github.com/millionco/react-doctor

## MCP

### Cursor

```json
{
  "mcpServers": {
    "strapi-docs": {
      "type": "http",
      "url": "https://strapi-docs.mcp.kapa.ai",
      "headers": {}
    },
    "next-devtools": {
      "command": "npx",
      "args": ["-y", "next-devtools-mcp@latest"]
    },
    "aem-content-readonly":{
      "url": "https://mcp.adobeaemcloud.com/adobe/mcp/content-readonly"
    },
    "aem-content":{
      "url": "https://mcp.adobeaemcloud.com/adobe/mcp/content"
    }
  }
}
```
