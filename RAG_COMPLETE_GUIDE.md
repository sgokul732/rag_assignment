# RAG Assignment - Complete Setup & Execution Guide

This document provides step-by-step instructions to run the entire RAG (Retrieval-Augmented Generation) pipeline from start to finish.

## Prerequisites

- Docker & Docker Compose installed
- Ollama installed and running on Windows host
- Windows PowerShell
- Ruby on Rails environment configured in Docker

## 1. Start the Application

### Step 1.1: Start the Database Container

```bash
docker compose up -d db
```

This starts the PostgreSQL database with pgvector extension on port 5432.

**Expected Output:**
```
✔ Container rag_assignment-db-1 Running
```

### Step 1.2: Verify Database Connection

```bash
docker compose run --rm -e RAILS_ENV=development -e DATABASE_URL=postgresql://postgres:password@db:5432/myapp_development web ruby -e "require './config/environment'; puts 'Database connected!'"
```

## 2. Download PDFs

### Step 2.1: Download All 5 Research Papers

```bash
docker compose run --rm -e RAILS_ENV=development -e DATABASE_URL=postgresql://postgres:password@db:5432/myapp_development web ruby -e "require './config/environment'; Pdf::Downloader.download_all; puts 'All PDFs downloaded'"
```

**Expected Output:**
```
attention.pdf downloaded
bert.pdf downloaded
rag.pdf downloaded
t5.pdf downloaded
xlnet.pdf downloaded
All PDFs downloaded
```

**Downloaded Files Location:** `storage/pdfs/`

## 3. Ingest PDFs into Database

### Step 3.1: Prepare Database

First, run migrations to create the necessary tables:

```bash
docker compose run --rm -e RAILS_ENV=development -e DATABASE_URL=postgresql://postgres:password@db:5432/myapp_development web ruby bin/rails db:migrate:reset
```

**Expected Output:**
```
== 20260813000000 EnablePgvector: migrating
== 20260813000000 EnablePgvector: migrated
== 20260814000001 CreateDocuments: migrating
== 20260814000001 CreateDocuments: migrated
== 20260814000002 CreateChunks: migrating
== 20260814000002 CreateChunks: migrated
```

### Step 3.2: Ensure Ollama is Running

Make sure Ollama is running on your Windows host before proceeding. Open a PowerShell terminal and run:

```bash
$env:Path += ';C:\Users\sgoku\AppData\Local\Programs\Ollama'
& 'C:\Users\sgoku\AppData\Local\Programs\Ollama\ollama.exe' serve
```

Keep this terminal open. You should see:
```
Ollama is running
```

### Step 3.3: Ingest All 5 PDFs

In a different PowerShell terminal (not the one running Ollama), run:

```bash
docker compose run --rm -e RAILS_ENV=development -e DATABASE_URL=postgresql://postgres:password@db:5432/myapp_development web ruby -e "require './config/environment'; %w[attention bert rag t5 xlnet].each { |name| file = Rails.root.join('storage/pdfs/' + name + '.pdf'); puts '⏳ Processing ' + name + '.pdf...'; doc = Pdf::Ingestor.import(file); puts '✅ ' + name + ' - Doc ID ' + doc.id.to_s + ', ' + doc.chunks.count.to_s + ' chunks' }"
```

**Expected Output:**
```
⏳ Processing attention.pdf...
✅ attention - Doc ID 2, 17 chunks
⏳ Processing bert.pdf...
✅ bert - Doc ID 3, 26 chunks
⏳ Processing rag.pdf...
✅ rag - Doc ID 4, 96 chunks
⏳ Processing t5.pdf...
✅ t5 - Doc ID 5, 82 chunks
⏳ Processing xlnet.pdf...
✅ xlnet - Doc ID 6, 19 chunks
```

**What Happens During Ingestion:**
1. Extracts text from each PDF
2. Cleans the text
3. Chunks the text into 500-word segments
4. Generates embeddings for each chunk using Ollama's `nomic-embed-text` model
5. Stores documents and chunks with embeddings in PostgreSQL database

**Total Data Stored:** 240 chunks with vector embeddings

## 4. Evaluate RAG System

### Step 4.1: Run RAG Evaluation

```bash
docker compose run --rm -e RAILS_ENV=development -e DATABASE_URL=postgresql://postgres:password@db:5432/myapp_development web ruby -e "require './config/environment'; require './lib/vector_search'; require './lib/generation/ollama'; puts 'Running RAG Evaluation with Vector Similarity...'; results = Evaluation::RagEvaluator.new.evaluate; puts ''; puts '📊 RAG EVALUATION RESULTS'; puts '=' * 60; puts 'Total: ' + results[:total].to_s + ' | Passed: ' + results[:passed].to_s + ' | Accuracy: ' + results[:accuracy].to_s + '%'; puts '=' * 60; results[:details].each_with_index { |d,i| puts ''; puts (i+1).to_s + '. ' + d[:question]; puts '   Keywords: ' + d[:expected_keywords].join(', '); puts '   Answer: ' + d[:answer][0,150]; puts '   Result: ' + (d[:passed] ? '✅ PASS' : '❌ FAIL') }"
```

**Expected Output:**
```
Running RAG Evaluation with Vector Similarity...

📊 RAG EVALUATION RESULTS
============================================================
Total: 3 | Passed: 2 | Accuracy: 66.67%
============================================================

1. What is the transformer architecture?
   Keywords: attention, encoder, decoder
   Answer: The Transformer architecture consists of an encoder-decoder structure...
   Result: ✅ PASS

2. Explain BERT model
   Keywords: bidirectional, pre-training, masked
   Answer: BERT (Bidirectional Encoder Representations from Transformers)...
   Result: ✅ PASS

3. What is RAG?
   Keywords: retrieval, generation, augmented
   Answer: The answer to the question "What is RAG?" cannot be determined...
   Result: ❌ FAIL
```

**What RAG Evaluation Does:**
1. Loads evaluation questions from `config/evaluation_questions.yml`
2. For each question:
   - Generates query embedding using Ollama
   - Performs vector similarity search across 240 chunks
   - Retrieves top 5 most relevant chunks
   - Generates answer using Ollama's `llama3.2` model with retrieved context
   - Checks if answer contains all expected keywords
3. Reports accuracy and detailed results

## 5. Close the Application

### Step 5.1: Stop Docker Containers

```bash
docker compose down
```

**Expected Output:**
```
Container rag_assignment-db-1 Stopping
Container rag_assignment-db-1 Stopped
Container rag_assignment-web-run-XXX Stopped
```

### Step 5.2: Stop Ollama Service

In the PowerShell terminal running Ollama, press:
```
Ctrl + C
```

This stops the Ollama service gracefully.

## Complete Workflow Summary

| Step | Command | Time | Purpose |
|------|---------|------|---------|
| 1 | `docker compose up -d db` | 5 sec | Start database |
| 2 | PDF Download | 30 sec | Download 5 PDFs |
| 3 | DB Migration | 10 sec | Create tables |
| 4 | PDF Ingestion | 5-10 min | Extract, chunk, embed PDFs |
| 5 | RAG Evaluation | 2-3 min | Test retrieval & generation |
| 6 | `docker compose down` | 5 sec | Cleanup |

**Total Time:** ~10-15 minutes

## Key Configuration Files

- `config/database.yml` - PostgreSQL connection settings
- `config/evaluation_questions.yml` - RAG evaluation test questions
- `lib/pdf/downloader.rb` - PDF download URLs
- `lib/pdf/extractor.rb` - PDF text extraction
- `lib/pdf/ingestor.rb` - PDF processing pipeline
- `lib/vector_search.rb` - Vector similarity search
- `lib/generation/ollama.rb` - Ollama API integration
- `lib/evaluation/rag_evaluator.rb` - RAG evaluation logic

## Data Pipeline Architecture

```
PDFs (arXiv)
    ↓
Pdf::Downloader → storage/pdfs/
    ↓
Pdf::Extractor → Raw Text
    ↓
Pdf::Cleaner → Cleaned Text
    ↓
Chunking::TextChunker → Text Chunks (500 words, 100 overlap)
    ↓
Embedding::Ollama (nomic-embed-text) → Vector Embeddings
    ↓
PostgreSQL Database
    ↓
VectorSearch (Cosine Similarity) → Top 5 Relevant Chunks
    ↓
Generation::Ollama (llama3.2) → Generated Answer
    ↓
Evaluation::RagEvaluator → Accuracy Score (66.67%)
```

## Troubleshooting

### Issue: "Ollama connection refused"
**Solution:** Make sure Ollama is running:
```bash
ollama serve
```

### Issue: "Database connection failed"
**Solution:** Verify PostgreSQL is running:
```bash
docker compose ps
```

### Issue: "Vector search slow"
**Solution:** This is normal - cosine similarity across 240 chunks takes ~1-2 seconds per query. For production, use pgvector with native PostgreSQL operators.

### Issue: "Out of memory during ingestion"
**Solution:** Reduce chunk size in `lib/chunking/text_chunker.rb` from 500 to 300 words.

## Next Steps to Improve Accuracy

1. **Fine-tune Embeddings:** Use domain-specific embeddings trained on ML papers
2. **Implement pgvector:** Replace Python cosine similarity with PostgreSQL vector operators
3. **Add Reranking:** Use cross-encoder to rerank top-k chunks before generation
4. **Prompt Engineering:** Improve the RAG prompt in `lib/generation/ollama.rb`
5. **Hybrid Search:** Combine vector search with BM25 keyword search

## References

- **Attention Is All You Need:** https://arxiv.org/pdf/1706.03762.pdf
- **BERT:** https://arxiv.org/pdf/1810.04805.pdf
- **Language Models are Few-Shot Learners (GPT-3):** https://arxiv.org/pdf/2005.14165.pdf
- **T5:** https://arxiv.org/pdf/1910.10683.pdf
- **XLNet:** https://arxiv.org/pdf/1907.11692.pdf

---

**Last Updated:** August 14, 2026  
**RAG Accuracy:** 66.67% (2/3 questions passed)  
**Total Chunks:** 240  
**Vector Dimension:** 768 (nomic-embed-text)
