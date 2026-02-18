# ai-rules-skills

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
