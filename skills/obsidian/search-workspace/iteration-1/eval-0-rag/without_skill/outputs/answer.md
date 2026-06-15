# RAG & Vector Databases — Relevant Wiki Pages

The wiki has substantial coverage of both RAG (retrieval-augmented generation) and vector databases, organized below by category. The strongest starting points are flagged.

## Best starting points

- **[[what-is-rag-and-related-retrieval-architectures]]** (analysis) — canonical "what is RAG" deep dive synthesized across six wiki sources. *Start here for RAG.*
- **[[rag]]** (concept) — the core retrieval-augmented generation concept page.
- **[[vector-database]]** (concept) — specialized similarity-search storage; the core vector-DB concept page.
- **[[building-with-llms]]** (topic) — umbrella tying together context engineering, RAG, vectorization, and KM.

## Concepts — Vectorization / RAG cluster
- [[rag]] — retrieval-augmented generation
- [[vectorization]] — converting data to numeric vectors; full historical spectrum
- [[vector-embeddings]] — dense, semantic representations
- [[vector-database]] — specialized similarity-search storage
- [[vector-quantization]] — compress embeddings 8×+ for local/in-memory RAG; MSE ≠ inner product
- [[cosine-similarity]] — dominant text similarity metric
- [[semantic-search]] — search by meaning, not keywords

## Concepts — related / adjacent
- [[hallucination]] — RAG is one of the layered mitigations
- [[just-in-time-context]] — retrieve on demand via tools vs. pre-inference embeddings (contrast to RAG)
- [[data-pipelines-elt]] — the data foundation under RAG/agents
- [[bedrock-knowledge-bases]] — managed RAG: chunking, 4 retrieval modes (semantic/GraphRAG/NL→SQL/multimodal), 7 vector backends

## Entities — Tools / Frameworks (vector databases & retrieval)
- [[pinecone]] — managed vector database; hybrid search; namespaces
- [[pgvector]] — Postgres extension for vector similarity search; HNSW / IVFFlat
- [[opensearch]] — open-source search engine with vector + ML Commons embedding hosting
- [[faiss]] — Meta's reference vector-search library
- [[turbovec]] — training-free vector index implementing TurboQuant
- [[vertex-ai]] — Google Cloud managed AI platform; includes Vector Search
- [[llamaindex]] — Python data framework for LLM retrieval and agentic (RAG) apps
- [[langchain]] — Python LLM framework used in the vectorization/RAG code examples
- [[openai]] — embedding models referenced across vectorization sources
- [[aws]] / [[aws-bedrock]] — RAG explainer + Bedrock Knowledge Bases (managed RAG)

## Topics
- [[building-with-llms]] — umbrella for context engineering, RAG, vectorization, KM
- [[embeddings]] — practical AI-engineering view: model landscape, choice criteria, Matryoshka + quantization, hybrid retrieval, pitfalls
- [[knowledge-management-with-llms]] — RAG vs LLM-wiki vs llms.txt spectrum

## Sources — Vector databases (clippings)
- [[pinecone-concepts]] — Pinecone's index/namespace/record hierarchy + hybrid search
- [[pgvector-readme]] — pgvector v0.8.2 canonical reference (HNSW, IVFFlat, six distance functions)
- [[opensearch-vector-search]] — OpenSearch + ML Commons + hybrid search pipelines

## Sources — Vectorization / RAG (clippings)
- [[what-is-rag-aws]] — AWS canonical RAG explainer
- [[vectorization-in-ai-datanorth]] — comprehensive vectorization history and deployments
- [[understanding-embedding-models-medium]] — Word2Vec, GloVe, BERT
- [[ai-vectorization-langchain-devoteam]] — LangChain RAG code examples
- [[turbovec-rag-roettig]] — training-free vector quantization for local RAG (TurboQuant)

## Sources — related
- [[llamaindex-starter-tutorial]] — hands-on agent → memory → RAG → persistence progression
- [[amazon-bedrock-platform-2026]] — includes Knowledge Bases (managed RAG)

## Analyses
- [[what-is-rag-and-related-retrieval-architectures]] — canonical "what is RAG" deep dive across six sources
- [[four-vectorization-sources-deduplicated]] — reader's guide to the four overlapping vectorization/RAG sources
- [[persistent-synthesis-vs-ephemeral-retrieval]] — architectural axis tying together RAG, JIT context, note-taking, LLM-wiki, and llms.txt
- [[mcp-synthesis-analysis]] — includes how MCP relates to RAG

---
*Tip: [[four-vectorization-sources-deduplicated]] is the fastest way to navigate the overlapping vectorization/RAG source clippings without reading all four.*
