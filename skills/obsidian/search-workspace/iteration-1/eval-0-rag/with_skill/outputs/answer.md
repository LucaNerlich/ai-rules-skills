# RAG & Vector Databases — what the wiki has

The wiki has substantial coverage of Retrieval-Augmented Generation (RAG) and vector databases: a `#rag` tag spanning 29 pages and a `#vectorization` tag spanning 14, plus a dedicated "Vectorization & RAG" Glossary cluster. RAG is the core pattern — retrieve relevant info from an external knowledge source (documents → [[vector-embeddings]] → [[vector-database]], queried by similarity) and inject it into the prompt before generation, as a cheaper alternative to fine-tuning. Vector databases are the infrastructure that makes this practical via approximate-nearest-neighbor search. Below are the relevant pages, ranked.

## Core Concepts (start here)

- [[rag]] — Retrieval-Augmented Generation: the standard 4-step pipeline (embed → store → retrieve → augment), why it beats fine-tuning for fresh/proprietary data, and the LLM failure modes it fixes (6 sources) (wiki/concepts/rag.md)
- [[vector-database]] — Specialized store for high-dimensional embeddings; similarity vs. exact match, ANN tradeoffs, product comparison (Pinecone/Weaviate/Milvus/Chroma) (3 sources) (wiki/concepts/vector-database.md)
- [[vectorization]] — Turning text/data into numeric vectors; the foundation of semantic retrieval (4 sources) (wiki/concepts/vectorization.md)
- [[vector-embeddings]] — What embeddings are and how they encode meaning (4 sources) (wiki/concepts/vector-embeddings.md)
- [[semantic-search]] — Similarity search over embeddings; the retrieval half of RAG (4 sources) (wiki/concepts/semantic-search.md)
- [[cosine-similarity]] — The distance metric used to rank retrieved vectors (2 sources) (wiki/concepts/cosine-similarity.md)
- [[vector-quantization]] — Compressing vectors to cut memory/storage cost of vector stores (1 source) (wiki/concepts/vector-quantization.md)
- [[bedrock-knowledge-bases]] — AWS managed RAG: vector ops abstracted behind Bedrock (1 source) (wiki/concepts/bedrock-knowledge-bases.md)
- [[just-in-time-context]] — Just-in-time context retrieval; RAG framed as an agent context-engineering strategy (1 source) (wiki/concepts/just-in-time-context.md)

## Topics

- [[embeddings]] — Overview tying vectorization, embeddings, RAG, and vector DBs together; the best single entry point (9 sources) (wiki/topics/embeddings.md)

## Entities (tools, products, people)

- [[pinecone]] — Hosted vector DB popular for production RAG (2 sources) (wiki/entities/pinecone.md)
- [[pgvector]] — Postgres extension adding vector search to a relational DB (2 sources) (wiki/entities/pgvector.md)
- [[faiss]] — Meta's open-source library for fast similarity search / ANN (1 source) (wiki/entities/faiss.md)
- [[opensearch]] — OpenSearch vector search capabilities (1 source) (wiki/entities/opensearch.md)
- [[langchain]] — Framework for building RAG / LLM apps, incl. vector-store integrations (2 sources) (wiki/entities/langchain.md)
- [[llamaindex]] — Data framework for indexing and RAG over private data (1 source) (wiki/entities/llamaindex.md)
- [[turbovec]] — Tool for local RAG with quantized vectors (small footprint) (1 source) (wiki/entities/turbovec.md)
- [[lars-roettig]] — Author behind the local/quantized RAG (turbovec) material (1 source) (wiki/entities/lars-roettig.md)

## Sources (primary material)

- [[what-is-rag-aws]] — AWS's canonical explainer of RAG and its pipeline (wiki/sources/what-is-rag-aws.md)
- [[pinecone-concepts]] — Pinecone's managed vector-DB model and concepts (wiki/sources/pinecone-concepts.md)
- [[pgvector-readme]] — pgvector README: vector search inside Postgres (wiki/sources/pgvector-readme.md)
- [[opensearch-vector-search]] — OpenSearch vector search documentation (wiki/sources/opensearch-vector-search.md)
- [[vectorization-in-ai-datanorth]] — Overview of vectorization approaches and when to use which (wiki/sources/vectorization-in-ai-datanorth.md)
- [[ai-vectorization-langchain-devoteam]] — Semantic understanding with LangChain (Chroma-backed RAG walkthrough) (wiki/sources/ai-vectorization-langchain-devoteam.md)
- [[understanding-embedding-models-medium]] — How embedding models work (wiki/sources/understanding-embedding-models-medium.md)
- [[turbovec-rag-roettig]] — Local RAG without the heavy storage tax (quantized vectors) (wiki/sources/turbovec-rag-roettig.md)
- [[llamaindex-high-level-concepts]] — LlamaIndex's high-level RAG concepts (wiki/sources/llamaindex-high-level-concepts.md)
- [[llamaindex-starter-tutorial]] — LlamaIndex starter tutorial (build a RAG app) (wiki/sources/llamaindex-starter-tutorial.md)
- [[amazon-bedrock-agents-overview]] — Bedrock agents, incl. knowledge-base retrieval (wiki/sources/amazon-bedrock-agents-overview.md)
- [[amazon-bedrock-platform-2026]] — Bedrock platform overview incl. managed RAG (wiki/sources/amazon-bedrock-platform-2026.md)
- [[llmops-workflows-databricks]] — LLMOps on Databricks, incl. RAG/vector workflows (wiki/sources/llmops-workflows-databricks.md)
- [[context-engineering-guide-promptingguide]] — Context engineering guide; RAG as a context technique (wiki/sources/context-engineering-guide-promptingguide.md)

## Analyses (existing syntheses)

- [[what-is-rag-and-related-retrieval-architectures]] — Synthesis of RAG and related retrieval architectures — likely answers most RAG questions directly (wiki/analyses/what-is-rag-and-related-retrieval-architectures.md)
- [[four-vectorization-sources-deduplicated]] — De-duplicated synthesis of four vectorization sources (wiki/analyses/four-vectorization-sources-deduplicated.md)
- [[persistent-synthesis-vs-ephemeral-retrieval]] — Compares persistent knowledge synthesis vs. ephemeral RAG retrieval (wiki/analyses/persistent-synthesis-vs-ephemeral-retrieval.md)

---

*Method: ranked by union of three lookup channels — the `Vectorization & RAG` Glossary cluster, the `#rag` (29 pages) and `#vectorization` (14 pages) tag memberships, and full-text search for "rag" / "vector database". Multi-channel hits and dedicated term pages rank highest; broad full-text-only matches (e.g. general LLM/agent topic pages that merely mention RAG) were excluded as not specifically about RAG or vector databases.*
