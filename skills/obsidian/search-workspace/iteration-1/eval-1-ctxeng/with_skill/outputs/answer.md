# Wiki search: "context engineering"

The wiki has substantial, well-developed coverage of context engineering — a dedicated concept page, a tight cluster of technique pages around it, two primary sources, three analyses that touch it, and several topic overviews that frame it. The `#context-engineering` tag carries 12 pages and the Glossary "Context Engineering & Agents" cluster is one of the densest in the vault.

**Start here:** [[context-engineering]] — the discipline of curating the optimal set of tokens in an LLM's context during inference; framed as the successor to prompt engineering for long-running agents.

---

## Core Concept

- [[context-engineering]] — Context Engineering: curating the smallest set of high-signal tokens that maximize the likelihood of a desired outcome; the central page, links onward to every technique (wiki/concepts/context-engineering.md)

## Related Concepts (the technique cluster)

- [[context]] — Context (Context Window): the finite token budget context engineering operates within (wiki/concepts/context.md)
- [[context-rot]] — Context Rot: empirical recall degradation as context grows; the core constraint motivating curation (wiki/concepts/context-rot.md)
- [[just-in-time-context]] — Just-in-Time Context Retrieval: load data on demand via tools/references instead of pre-loading via embeddings (wiki/concepts/just-in-time-context.md)
- [[context-compaction]] — Context Compaction: summarizing/compressing history for long-horizon tasks (wiki/concepts/context-compaction.md)
- [[structured-note-taking]] — Structured Note-Taking (Agentic Memory): external notes as durable agent memory across turns (wiki/concepts/structured-note-taking.md)
- [[sub-agent-architecture]] — Sub-Agent Architecture: delegate to sub-agents to keep each context window focused (wiki/concepts/sub-agent-architecture.md)
- [[prompt-engineering]] — Prompt Engineering: the predecessor discipline; static instructions for one-shot tasks (wiki/concepts/prompt-engineering.md)
- [[harness-engineering]] — Harness Engineering: eval scaffolding for validating context tactics (wiki/concepts/harness-engineering.md)
- [[model-context-protocol]] — Model Context Protocol (MCP): standard for wiring tools/data into context (wiki/concepts/model-context-protocol.md)
- [[tool-use]] — Tool Use & Function Calling: tool definitions/outputs are a major part of the context budget (wiki/concepts/tool-use.md)
- [[rag]] — Retrieval-Augmented Generation: one retrieval technique within context engineering (wiki/concepts/rag.md)

## Sources (primary material)

- [[effective-context-engineering-anthropic]] — Anthropic Applied AI position piece; the canonical framing (attention budget, "right altitude" prompts, three long-horizon techniques) (wiki/sources/effective-context-engineering-anthropic.md)
- [[context-engineering-guide-promptingguide]] — Elvis Saravia / PromptingGuide.ai practitioner walk-through with concrete n8n multi-agent code/prompt examples (wiki/sources/context-engineering-guide-promptingguide.md)
- [[langgraph-multi-agent-patterns]] — LangGraph multi-agent patterns; applies context engineering across agent orchestration (wiki/sources/langgraph-multi-agent-patterns.md)

## Analyses (existing syntheses)

- [[persistent-synthesis-vs-ephemeral-retrieval]] — persistent synthesized context vs. ephemeral just-in-time retrieval (wiki/analyses/persistent-synthesis-vs-ephemeral-retrieval.md)
- [[three-angles-on-alignment-before-generation]] — alignment-before-generation, touching context curation (wiki/analyses/three-angles-on-alignment-before-generation.md)
- [[what-is-rag-and-related-retrieval-architectures]] — RAG and retrieval architectures as context-supply mechanisms (wiki/analyses/what-is-rag-and-related-retrieval-architectures.md)

## Topic Overviews (entry points that link onward)

- [[building-with-llms]] — building applications with LLMs; context engineering is a key section (wiki/topics/building-with-llms.md)
- [[multi-agent-systems]] — multi-agent systems; context per agent is a central concern (wiki/topics/multi-agent-systems.md)
- [[knowledge-management-with-llms]] — knowledge management with LLMs; ties to just-in-time context and notes (wiki/topics/knowledge-management-with-llms.md)
- [[ai-engineering-role]] — the AI Engineer discipline; context engineering listed as a core skill (wiki/topics/ai-engineering-role.md)

## Entities of note

- [[anthropic]] — formalized the context-engineering framing (wiki/entities/anthropic.md)
- [[andrej-karpathy]] — among those credited with coining/popularizing the term (wiki/entities/andrej-karpathy.md)
- [[claude-code]] — reference implementation of just-in-time context (glob/grep, CLAUDE.md) (wiki/entities/claude-code.md)

---

### How this was found
Three lookup channels were unioned and ranked: the `#context-engineering` tag (12 pages, highest precision), the Glossary "Context Engineering & Agents" cluster view, and full-text search. Pages hit by multiple channels (the core concept + the six technique pages + the two named sources) rank highest. Full-text search also surfaced many pages that merely mention "context" (e.g. llm.md, inference.md, gpt.md); those were dropped as low-signal.

This is a plain ranked lookup, so it was not saved as an analysis page (and this run is read-only by request).
