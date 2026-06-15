# Wiki Results: Context Engineering

Everything in the wiki that bears on **context engineering**, grouped by relevance. All links are `[[wikilinks]]` to pages under `/Users/nerlich/Documents/ai-wiki/wiki/`.

## Core concept

- **[[context-engineering]]** — *the* page. The discipline of curating the optimal set of high-signal tokens in an LLM's context during inference; framed as the successor to prompt engineering for the agentic era. Covers definition, why it diverged from prompt engineering, the finite-attention constraint, and the technique list. (2 sources)
  - File: `wiki/concepts/context-engineering.md`

## Directly supporting concepts ("Context & prompts" cluster)

- **[[context]]** (Context Window) — the finite, stateless token budget an LLM reads from; what goes into it, why it is an engineered resource, context vs. training knowledge. The foundational page underneath the discipline.
- **[[prompt-engineering]]** — the predecessor discipline; the blind-prompting → prompt-engineering → context-engineering progression. Still foundational.
- **[[context-rot]]** — the core constraint: recall degrades as context length grows (O(n²) attention + training-distribution skew). "Attention budget" framing; the "Smart Zone / Dumb Zone" practitioner language.
- **[[context-compaction]]** — summarize-and-reinitialize a near-full context window; the Claude Code example, recall-then-precision tuning, tool-result clearing as the lightest-touch variant.
- **[[structured-note-taking]]** — agent writes to persistent external memory (Claude Code to-do list, Claude-plays-Pokémon notes, NOTES.md, Anthropic memory tool). Best for iterative milestone work.
- **[[sub-agent-architecture]]** — main agent coordinates; specialized sub-agents explore in clean context windows and return distilled 1–2K-token summaries. Best for parallel research.
- **[[just-in-time-context]]** — agent holds lightweight references (paths, queries, URLs) and loads data on demand via tools, instead of pre-loading via embeddings. Contrast with traditional RAG; the hybrid model Claude Code uses.

These four — compaction, note-taking, sub-agents, just-in-time — are the techniques for long-horizon tasks listed on the main page.

## Source pages (the original material)

- **[[effective-context-engineering-anthropic]]** — Anthropic Applied AI team's position piece; the theoretical/architectural framing. Attention budget, right-altitude system prompts, unambiguous tools, curated few-shot, just-in-time retrieval, and the three long-horizon techniques. *This is the primary source.*
  - File: `wiki/sources/effective-context-engineering-anthropic.md`
- **[[context-engineering-guide-promptingguide]]** — Elvis Saravia (DAIR.AI) practitioner walk-through building a multi-agent deep-research app in n8n. Concrete prompt/code snippets, structured-outputs emphasis, subquery caching, who-coined-it credits.
  - File: `wiki/sources/context-engineering-guide-promptingguide.md`

## Analyses (synthesis pages)

- **[[three-angles-on-alignment-before-generation]]** — ties context engineering together with Architect-as-Orchestrator and SPDD around one insight: catching an AI's misunderstanding before generation is cheaper than after. Anthropic's "right altitude" context curation is one of the three framings.
- **[[persistent-synthesis-vs-ephemeral-retrieval]]** — the architectural axis connecting RAG, just-in-time context, structured note-taking, the LLM-wiki, and llms.txt.
- **[[mcp-synthesis-analysis]]** — relates MCP to RAG, context engineering, and sub-agents (context engineering appears as a connected theme).

## Related concepts and topics

- **[[harness-engineering]]** — sibling discipline; the eval/trace scaffolding that *measures whether context curation worked*. Prompt engineering optimizes the input; harness engineering optimizes your ability to know it worked.
- **[[building-with-llms]]** (topic) — umbrella topic whose first section is "Prompt → Context Engineering," summarizing the whole cluster plus the RAG/embeddings layer.
- **[[rag]]** — treated throughout as one technique *within* context engineering (and the foil for just-in-time retrieval).
- **[[tool-use]]** / **[[tool-use-with-claude]]** — tool definitions and outputs are a major component of the context being engineered.

## Key cross-cutting points

- **Central constraint:** attention is a finite budget. Bigger context windows do not fix [[context-rot]]; curation does. The goal is "the smallest set of high-signal tokens that maximize the likelihood of the desired outcome" (Anthropic).
- **Scope:** context engineering extends well beyond the system prompt to tool definitions, tool outputs, MCP integrations, retrieved data, message history, few-shot examples, structured I/O, and short/long-term memory.
- **Origin of the term:** coalesced around [[andrej-karpathy]], Tobi Lutke, Walden Yan, Ankur Goyal, and Dex Horthy; formalized by [[anthropic]].
- **Two sources, two angles:** Anthropic = theoretical/architectural; PromptingGuide = practitioner with working n8n code. They are explicit companions.

---

*Reading-order suggestion:* start with [[context]] for foundations → [[context-engineering]] for the discipline → the two source pages → the long-horizon technique pages ([[context-compaction]], [[structured-note-taking]], [[sub-agent-architecture]], [[just-in-time-context]]) → [[three-angles-on-alignment-before-generation]] for synthesis.
