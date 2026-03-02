# Search System: Architecture Guide

## Overview

| Attribute | Details |
|-----------|---------|
| Duration | 60 minutes |
| Level | Intermediate to Advanced |
| Prerequisites | Cache session, Message Queue session |

## Learning Objectives

- Understand how full-text search works at scale
- Design indexing pipelines for near-real-time search
- Reason about relevance ranking, tokenization, and analyzers
- Handle search at scale with sharding, replication, and caching
- Evaluate trade-offs between search accuracy and latency

---

## 1. Why Search Is Hard

### Beyond SQL LIKE

~~~
SQL approach:
  SELECT * FROM products WHERE name LIKE '%wireless headphone%'
  
  Problems:
  ❌ No ranking (which result is best?)
  ❌ No typo tolerance ("wireles" returns nothing)
  ❌ No synonym matching ("earbuds" ≠ "headphones")
  ❌ Full table scan (O(n) on every query)
  ❌ No language awareness ("running" ≠ "run")

Search engine approach:
  Inverted index + relevance scoring + text analysis
  ✅ Sub-second queries over billions of documents
  ✅ Ranked results by relevance
  ✅ Fuzzy matching, synonyms, stemming
~~~

---

## 2. Core Concepts

### Inverted Index

~~~
Documents:
  doc1: "The quick brown fox"
  doc2: "The quick rabbit"
  doc3: "Brown fox jumps"

Forward Index (what DB stores):
  doc1 → [the, quick, brown, fox]
  doc2 → [the, quick, rabbit]
  doc3 → [brown, fox, jumps]

Inverted Index (what search engine builds):
  the    → [doc1, doc2]
  quick  → [doc1, doc2]
  brown  → [doc1, doc3]
  fox    → [doc1, doc3]
  rabbit → [doc2]
  jumps  → [doc3]

Query "brown fox":
  brown → [doc1, doc3]
  fox   → [doc1, doc3]
  Intersection: [doc1, doc3] → ranked by relevance
~~~

### Text Analysis Pipeline

~~~mermaid
flowchart LR
    RAW["Raw Text:<br/>'The Quick Brown Foxes!'"] 
    --> CHAR["Character Filter:<br/>'The Quick Brown Foxes'"]
    --> TOK["Tokenizer:<br/>['The','Quick','Brown','Foxes']"]
    --> FILTER["Token Filters:<br/>['quick','brown','fox']"]
    --> INDEX["Inverted Index"]
~~~

~~~
Analysis steps:
  1. Character filters: strip HTML, normalize unicode
  2. Tokenizer: split text into tokens (whitespace, punctuation)
  3. Token filters:
     - Lowercase: "Quick" → "quick"
     - Stemming: "foxes" → "fox", "running" → "run"
     - Stop words: remove "the", "a", "is"
     - Synonyms: "laptop" → ["laptop", "notebook"]
~~~

### Relevance Scoring (TF-IDF / BM25)

~~~
TF (Term Frequency):
  How often does the term appear in THIS document?
  "fox" appears 3 times in doc1 → high TF

IDF (Inverse Document Frequency):
  How rare is this term across ALL documents?
  "the" appears in every doc → low IDF (not useful)
  "elasticsearch" appears in 1 doc → high IDF (very useful)

BM25 (modern standard):
  Improved TF-IDF with:
  - Diminishing returns for repeated terms
  - Document length normalization
  - Tunable parameters (k1, b)

Score = Σ IDF(term) × (TF × (k1 + 1)) / (TF + k1 × (1 - b + b × docLen/avgDocLen))
~~~

---

## 3. Indexing Pipeline

### Near-Real-Time Indexing

~~~mermaid
sequenceDiagram
    participant App as Application
    participant DB as Database
    participant Q as Message Queue
    participant Idx as Indexer Service
    participant ES as Search Engine
    
    App->>DB: Write/Update document
    App->>Q: Publish change event
    Q->>Idx: Consume event
    Idx->>DB: Fetch full document (if needed)
    Idx->>ES: Index document
    
    Note over ES: Available for search<br/>within ~1 second
~~~

### Batch Reindexing

~~~mermaid
flowchart TB
    TRIGGER["Trigger:<br/>Schema change / Bug fix / New field"] 
    --> SCAN["Scan source DB<br/>(paginated)"]
    --> TRANSFORM["Transform to<br/>search schema"]
    --> BULK["Bulk index to<br/>new index"]
    --> ALIAS["Swap index alias<br/>(zero downtime)"]
~~~

~~~
Reindex strategy:
  1. Create new index (products_v2) alongside old (products_v1)
  2. Bulk index all documents into products_v2
  3. Swap alias: "products" → products_v2
  4. Delete products_v1
  
  Zero downtime, zero query interruption
~~~

### Dual-Write Problem

~~~
Problem: Writing to DB and search index separately

  App → DB (succeeds)
  App → Search (fails)
  → DB and search are out of sync

Solutions:
┌─────────────────────────────────────────────────────┐
│ 1. Change Data Capture (CDC)                        │
│    DB binlog → Kafka → Indexer → Search             │
│    Single source of truth (DB)                      │
│                                                     │
│ 2. Transactional Outbox                             │
│    Write to DB + outbox table in same transaction   │
│    Relay reads outbox → publishes to queue          │
│                                                     │
│ 3. Event sourcing                                   │
│    Events are the source of truth                   │
│    Both DB and search built from events             │
└─────────────────────────────────────────────────────┘
~~~

---

## 4. Search Architecture at Scale

### Sharding and Replication

~~~mermaid
flowchart TB
    Q[Search Query] --> COORD[Coordinator Node]
    
    COORD --> S1P[Shard 1 Primary]
    COORD --> S2R[Shard 2 Replica]
    COORD --> S3P[Shard 3 Primary]
    
    subgraph "Shard 1"
        S1P[Primary]
        S1R[Replica]
    end
    
    subgraph "Shard 2"
        S2P[Primary]
        S2R[Replica]
    end
    
    subgraph "Shard 3"
        S3P[Primary]
        S3R[Replica]
    end
    
    COORD --> MERGE[Merge & Rank<br/>Top-K results]
~~~

~~~
Scatter-gather pattern:
  1. Query hits coordinator node
  2. Coordinator fans out to all shards
  3. Each shard returns its top-K results
  4. Coordinator merges and re-ranks
  5. Returns final top-K to client

Shard sizing:
  - Too few shards: each shard too large, slow queries
  - Too many shards: overhead per shard, merge cost
  - Rule of thumb: 10-50GB per shard
~~~

### Caching Strategy

~~~
Multi-layer caching:

  Layer 1: Application cache (Redis)
    Key: hash(query + filters + page)
    TTL: 1-5 minutes
    Hit rate: 30-60% (popular queries)

  Layer 2: Search engine internal cache
    Filter cache: bitmap of matching docs per filter
    Query cache: results for recent identical queries
    Field data cache: column values for sorting/aggregation

  Layer 3: OS page cache
    Index files cached in memory by OS
    Most effective layer for warm indices
~~~

---

## 5. Advanced Search Features

### Autocomplete / Search-as-You-Type

~~~mermaid
sequenceDiagram
    participant U as User
    participant FE as Frontend
    participant API as API
    participant ES as Search Engine
    
    U->>FE: Types "wire"
    FE->>FE: Debounce 200ms
    FE->>API: GET /suggest?q=wire
    API->>ES: Prefix query on suggest field
    ES-->>API: ["wireless headphones", "wireless mouse", "wire cutter"]
    API-->>FE: Suggestions
    FE-->>U: Dropdown with suggestions
~~~

~~~
Implementation approaches:
  1. Prefix matching: "wire" → matches "wireless*"
  2. Edge n-grams: index "w", "wi", "wir", "wire", "wirel"...
  3. Completion suggester: FST-based, very fast
  4. Popular queries: log queries, suggest frequent ones
~~~

### Faceted Search

~~~
Query: "laptop"
Results: 2,340 laptops

Facets (aggregations):
  Brand:     Apple (450), Dell (380), Lenovo (320), ...
  Price:     $0-500 (800), $500-1000 (900), $1000+ (640)
  RAM:       8GB (600), 16GB (1200), 32GB (540)
  Rating:    4+ stars (1800), 3+ stars (2100)

User clicks "Apple" + "$500-1000":
  Filtered results: 180 laptops
  Facets update to reflect filtered counts
~~~

### Fuzzy Search and Typo Tolerance

~~~
Query: "wireles headphnes"

Edit distance matching:
  "wireles"  → "wireless"  (1 edit: add 's')
  "headphnes" → "headphones" (1 edit: add 'o')

Levenshtein distance:
  - 1 edit: insert, delete, substitute, or transpose
  - Typically allow 1-2 edits for short words
  - Performance cost: more edits = more candidates

Phonetic matching:
  "fone" → sounds like "phone" (Soundex/Metaphone)
~~~

---

## 6. Search Relevance Tuning

### Boosting and Custom Scoring

~~~
Default: BM25 text relevance only

Custom scoring factors:
┌─────────────────────────────────────────────────────┐
│ final_score = text_relevance                        │
│             × recency_boost(publish_date)           │
│             × popularity_boost(view_count)          │
│             × quality_boost(rating)                 │
│             + exact_match_bonus                     │
│             + personalization_score(user_prefs)     │
└─────────────────────────────────────────────────────┘

Example: E-commerce product search
  - Text match on title (boost 3x)
  - Text match on description (boost 1x)
  - Sales velocity boost (popular items rank higher)
  - In-stock boost (available items rank higher)
  - Sponsored boost (paid placement)
~~~

### Measuring Search Quality

~~~
Metrics:
  - Click-through rate (CTR): % of searches that get a click
  - Mean Reciprocal Rank (MRR): how high is the first relevant result?
  - Zero-result rate: % of queries returning nothing
  - Time to first click: how fast users find what they want
  - Precision@K: % of top-K results that are relevant
  - Recall: % of relevant docs that appear in results

A/B testing:
  - Test ranking changes on a % of traffic
  - Compare CTR, conversion, and engagement
  - Small ranking changes can have large business impact
~~~

---

## 7. Anti-Patterns

### Searching the Database Directly

~~~
Problem: Using SQL for search at scale

  SELECT * FROM products 
  WHERE title LIKE '%wireless%' OR description LIKE '%wireless%'
  ORDER BY relevance_score DESC  -- what even is this?

  → Full table scan on every query
  → No relevance ranking
  → No text analysis
  → Breaks at ~100K rows

Fix: Use a dedicated search engine
     Keep DB as source of truth, search engine as read model
~~~

### Over-Indexing

~~~
Problem: Indexing every field of every document

  → Index size explodes
  → Indexing throughput drops
  → Query performance degrades

Fix: Only index searchable/filterable fields
     Store display-only fields as non-indexed
     Use source DB for full document retrieval
~~~

### Ignoring Relevance

~~~
Problem: Returning results sorted by date or ID

  User searches "best laptop for programming"
  Results: newest products first, regardless of relevance

  → Users don't find what they need
  → Search becomes useless

Fix: Default to relevance sorting
     Allow explicit sort overrides (price, date, rating)
     Invest in relevance tuning
~~~

---

## 8. Key Takeaways

| # | Takeaway |
|---|----------|
| 1 | Inverted indices are the foundation — understand how they work |
| 2 | Text analysis (tokenization, stemming, synonyms) determines search quality |
| 3 | Use CDC or outbox pattern to keep search index in sync with DB |
| 4 | Scatter-gather across shards with coordinator merge for scale |
| 5 | Cache popular queries aggressively (short TTL is fine) |
| 6 | Relevance tuning is ongoing — measure with CTR, MRR, zero-result rate |
| 7 | Autocomplete and fuzzy search are table stakes for good UX |
| 8 | Search is a read model — the database remains the source of truth |

---

## 9. Practical Exercise

### Design Challenge

Design a search system for a job posting platform (like LinkedIn Jobs):

**Requirements:**
- 50 million job postings, 10 million searches per day
- Search by title, skills, company, location
- Filters: salary range, remote/onsite, experience level, posted date
- Autocomplete for job titles and company names
- Personalized ranking based on user profile and history
- Near-real-time: new postings searchable within 30 seconds

**Discussion Questions:**
1. How would you design the indexing pipeline from job posting creation to searchable?
2. What fields would you analyze differently (title vs description vs skills)?
3. How would you implement location-based search (jobs within 50km)?
4. What's your sharding strategy — by location, by date, or something else?
5. How would you personalize results without making search slow?
