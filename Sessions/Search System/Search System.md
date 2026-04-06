# Search System: Design Decisions Guide

## Overview

| Attribute | Details |
|-----------|---------|
| Duration | 60 minutes |
| Level | Intermediate to Advanced |
| Prerequisites | Cache session, Message Queue session |

## Learning Objectives

- Make informed trade-offs when designing search systems
- Evaluate different approaches for indexing, syncing, and scaling
- Understand when to use which search architecture pattern
- Balance complexity, cost, and features for your specific requirements
- Reason through real-world search design scenarios

---

## 1. Design Decision: Should We Use a Search Engine?

### The Core Question
You need to add search functionality to your application. What approach should you take?

### Option A: SQL Database with LIKE Queries

~~~
Implementation:
  SELECT * FROM products 
  WHERE name LIKE '%wireless headphone%' 
  OR description LIKE '%wireless headphone%'
  ORDER BY created_at DESC

When to use:
  ✅ < 10K records
  ✅ Simple exact substring matching is enough
  ✅ No ranking or relevance needed
  ✅ Minimal development time required

Trade-offs:
  ❌ Full table scan (O(n) on every query)
  ❌ No ranking (which result is best?)
  ❌ No typo tolerance ("wireles" returns nothing)
  ❌ No synonym matching ("earbuds" ≠ "headphones")
  ❌ No language awareness ("running" ≠ "run")
  ❌ Breaks at scale (>100K rows)

Cost: Low (use existing database)
Complexity: Very Low
~~~

### Option B: Database Full-Text Search

~~~
Implementation (Postgres):
  CREATE INDEX products_fts ON products 
  USING gin(to_tsvector('english', name || ' ' || description));
  
  SELECT * FROM products 
  WHERE to_tsvector('english', name || ' ' || description) 
  @@ to_tsquery('english', 'wireless & headphone')
  ORDER BY ts_rank(...) DESC

When to use:
  ✅ 10K - 1M records
  ✅ Need basic ranking and text analysis
  ✅ Want to minimize infrastructure (no new services)
  ✅ Can tolerate limited feature set

Trade-offs:
  ✅ Better than LIKE: uses inverted index (fast!)
  ✅ Basic stemming and ranking
  ✅ No new infrastructure
  ❌ Limited feature set (no fuzzy, limited facets)
  ❌ Resource intensive on your DB server
  ❌ Harder to tune than dedicated engines
  ❌ Scaling requires scaling entire DB

Cost: Low (use existing database)
Complexity: Low
~~~

### Option C: Dedicated Search Engine

~~~
Implementation (Elasticsearch, OpenSearch, Solr):
  POST /products/_search
  {
    "query": {
      "multi_match": {
        "query": "wireless headphone",
        "fields": ["name^3", "description"],
        "fuzziness": "AUTO"
      }
    }
  }

When to use:
  ✅ > 1M records or high query volume
  ✅ Need advanced features (fuzzy, facets, autocomplete)
  ✅ Need fine-grained relevance tuning
  ✅ Search is a core product feature

Trade-offs:
  ✅ Purpose-built for search at scale
  ✅ Rich feature set out of the box
  ✅ Sub-second queries over billions of docs
  ✅ Advanced ranking, text analysis
  ❌ New infrastructure to operate
  ❌ Eventual consistency with source DB
  ❌ Learning curve for team
  ❌ Higher operational cost

Cost: Medium-High (new infrastructure)
Complexity: Medium-High
~~~

### Decision Framework

| Scale | Query Volume | Feature Needs | Recommended Approach |
|-------|--------------|---------------|---------------------|
| < 10K rows | Low | Basic substring | SQL LIKE |
| 10K - 500K | Medium | Ranking, stemming | DB Full-Text Search |
| > 500K | High | Advanced search | Dedicated Engine |
| Any | Any | Fuzzy, facets, ML | Dedicated Engine |

---

## 2. Core Concepts You Need to Know

### Inverted Index: The Foundation of Search

~~~
Why it matters for your design:
  This is why dedicated search engines are fast.
  Understanding this helps you reason about index size and query performance.

How it works:

Documents (your data):
  doc1: "The quick brown fox"
  doc2: "The quick rabbit"
  doc3: "Brown fox jumps"

Inverted Index (what search engine builds):
  the    → [doc1, doc2]
  quick  → [doc1, doc2]
  brown  → [doc1, doc3]
  fox    → [doc1, doc3]
  rabbit → [doc2]
  jumps  → [doc3]

Query "brown fox" execution:
  1. Look up "brown" → [doc1, doc3]
  2. Look up "fox"   → [doc1, doc3]
  3. Intersection: [doc1, doc3]
  4. Rank by relevance score
  
Result: O(terms in query) instead of O(documents in database)
~~~

### Text Analysis: Why "Running Shoes" Matches "Run Shoe"

~~~
This pipeline determines what matches what in your search.
Your design decisions here affect search quality.

Analysis steps:
  1. Character filters: strip HTML, normalize unicode
  2. Tokenizer: split text into tokens (whitespace, punctuation)
  3. Token filters:
     - Lowercase: "Quick" → "quick"
     - Stemming: "foxes" → "fox", "running" → "run"
     - Stop words: remove "the", "a", "is"
     - Synonyms: "laptop" → ["laptop", "notebook"]

Example:
  Input:  "The Quick Brown Foxes!"
  Output: ["quick", "brown", "fox"]
  
Design implication:
  Different fields need different analyzers
  - Product names: minimal stemming, preserve brands
  - Descriptions: aggressive stemming, synonyms
  - IDs/SKUs: keyword (no analysis)
~~~

### Relevance Scoring: Why Results Are Ordered This Way

~~~
BM25 (industry standard):
  Combines two factors:
  
  1. Term Frequency (TF): 
     How often does the term appear in THIS document?
  
  2. Inverse Document Frequency (IDF):
     How rare is this term across ALL documents?
     "the" → appears everywhere → low score
     "elasticsearch" → appears rarely → high score

Why this matters for your design:
  - Default scoring works well for most cases
  - Custom scoring (Section 5) builds on top of BM25
  - Understanding this helps you debug relevance issues
~~~

---

## 3. Design Decision: How Do We Keep Search in Sync with the Database?

### The Core Question
Your database is the source of truth. How do you keep your search index up-to-date when data changes?

### Option A: Dual-Write (Synchronous)

~~~
Implementation:
  def create_product(product):
      db.save(product)           # Write to database
      search.index(product)       # Write to search engine
      return product

Architecture:
  Application → Database
            └→ Search Engine

When to use:
  ✅ Simple use cases
  ✅ Low write volume
  ✅ Can tolerate occasional sync issues

Trade-offs:
  ✅ Simple to implement
  ✅ Immediate consistency (when it works)
  ✅ No additional infrastructure
  ❌ If search fails, DB and search are out of sync
  ❌ Increases application write latency
  ❌ Hard to recover from failures
  ❌ Application must handle both systems

Recovery scenario:
  Search is down for 1 hour → 1000s of writes succeed to DB
  How do you backfill? Manual script? How do you track what's missing?

Cost: Low
Complexity: Low (but brittle)
~~~

### Option B: Application-Triggered Async (Message Queue)

~~~
Implementation:
  def create_product(product):
      db.save(product)
      queue.publish("product.created", product.id)
      return product
  
  # Separate indexer service
  def indexer_consumer():
      for event in queue.consume():
          product = db.get(event.product_id)
          search.index(product)

Architecture:
  Application → Database
            └→ Message Queue → Indexer Service → Search Engine

When to use:
  ✅ Need async processing
  ✅ Want to decouple write path
  ✅ Moderate write volume

Trade-offs:
  ✅ Doesn't slow down application writes
  ✅ Retry logic in consumer
  ✅ Can scale indexer independently
  ✅ Search available within seconds (near-real-time)
  ⚠️  Application must remember to publish events
  ❌ Still a dual-write (DB + Queue)
  ❌ If queue publish fails, same problem as Option A

Cost: Medium (message queue infrastructure)
Complexity: Medium

Near-Real-Time Flow:
~~~

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
    Idx->>DB: Fetch full document
    Idx->>ES: Index document
    
    Note over ES: Available for search<br/>within 1-5 seconds
~~~

### Option C: Change Data Capture (CDC)

~~~
Implementation:
  No application code changes needed!
  
  1. Enable DB binlog/WAL replication
  2. CDC tool reads binlog (Debezium, Maxwell, etc.)
  3. Publishes changes to Kafka
  4. Indexer consumes and indexes

Architecture:
  Application → Database → Binlog
                         ↓
                    CDC Tool → Kafka → Indexer → Search Engine

When to use:
  ✅ High write volume
  ✅ Multiple data sources to index
  ✅ Want single source of truth (DB)
  ✅ Can tolerate 1-5 second lag

Trade-offs:
  ✅ No application code changes
  ✅ Guaranteed capture of all DB changes
  ✅ Single source of truth (database)
  ✅ Can replay historical data
  ✅ Works for multiple consumers (analytics, cache, etc.)
  ❌ Additional infrastructure (CDC tool + Kafka)
  ❌ Operational complexity
  ❌ Lag during backlog (usually <5s, can spike)
  ❌ Schema changes need careful handling

Cost: High (CDC tool + Kafka + Indexer)
Complexity: High
~~~

### Option D: Transactional Outbox

~~~
Implementation:
  def create_product(product):
      with db.transaction():
          db.products.save(product)
          db.outbox.insert({
              "event_type": "product.created",
              "payload": product.to_json(),
              "status": "pending"
          })
      # Separate relay process reads outbox, publishes to queue

Architecture:
  Application → Database (products + outbox tables)
                    ↓
               Outbox Relay → Message Queue → Indexer → Search

When to use:
  ✅ Need guaranteed event publishing
  ✅ Can't use CDC (managed DB without binlog access)
  ✅ Want ACID guarantees on event publishing

Trade-offs:
  ✅ Atomicity: event published IFF DB write succeeds
  ✅ No dual-write problem
  ✅ Works with any database
  ✅ Simpler than CDC
  ❌ Application must write to outbox table
  ❌ Outbox relay adds operational burden
  ❌ Polling outbox can add DB load

Cost: Medium (outbox relay + queue)
Complexity: Medium
~~~

### Option E: Event Sourcing

~~~
Implementation:
  def create_product(product):
      event = ProductCreated(product)
      event_store.append(event)
      # DB and Search both built from events

Architecture:
  Application → Event Store
                  ├→ DB Projection
                  └→ Search Projection

When to use:
  ✅ Building new system from scratch
  ✅ Need full audit trail
  ✅ Multiple projections needed

Trade-offs:
  ✅ Events are source of truth
  ✅ Perfect consistency: both built from same events
  ✅ Can rebuild search from scratch anytime
  ✅ Audit trail for free
  ❌ Complete architecture change
  ❌ Steeper learning curve
  ❌ Eventual consistency everywhere
  ❌ Complex for teams new to event sourcing

Cost: High (new architecture paradigm)
Complexity: Very High
~~~

### Decision Matrix

| Approach | Sync Issues | Complexity | Scalability | When to Choose |
|----------|------------|------------|-------------|----------------|
| Dual-Write | High risk | Low | Poor | Prototypes, low volume |
| Async Queue | Medium risk | Medium | Good | Most applications |
| CDC | Low risk | High | Excellent | High volume, multiple consumers |
| Outbox | Low risk | Medium | Good | Need guarantees, no CDC access |
| Event Sourcing | No risk | Very High | Excellent | Greenfield, audit requirements |

### Batch Reindexing Strategy

~~~
When you need to rebuild the entire index:
  - Schema change (added new field)
  - Bug fix in indexing logic
  - Migrating to new search engine version

Zero-downtime reindex:
  1. Create new index (products_v2) alongside old (products_v1)
  2. Bulk index all documents into products_v2
  3. Swap index alias: "products" → products_v2
  4. Delete products_v1

This works with ANY of the sync approaches above.
~~~

~~~mermaid
flowchart TB
    TRIGGER["Trigger:<br/>Schema change / Bug fix"] 
    --> SCAN["Scan source DB<br/>(paginated)"]
    --> TRANSFORM["Transform to<br/>search schema"]
    --> BULK["Bulk index to<br/>new index (v2)"]
    --> ALIAS["Swap alias:<br/>products → v2"]
    --> DELETE["Delete old<br/>index (v1)"]
~~~

---

## 4. Design Decision: How Do We Scale Search?

### The Core Question
Your search workload is growing. How do you scale to handle more data and more queries?

### Horizontal Scaling Pattern: Scatter-Gather

~~~
All distributed search engines use this pattern:

1. Query hits coordinator node
2. Coordinator fans out to all shards (scatter)
3. Each shard searches its subset of data, returns top-K results
4. Coordinator merges and re-ranks across all shard results (gather)
5. Returns final top-K to client

Trade-off:
  More shards = more parallelism BUT more overhead
~~~

~~~mermaid
flowchart TB
    Q[Search Query:<br/>"wireless headphones"] --> COORD[Coordinator Node]
    
    COORD -- scatter --> S1P[Shard 1<br/>docs 0-33M]
    COORD -- scatter --> S2P[Shard 2<br/>docs 33M-66M]
    COORD -- scatter --> S3P[Shard 3<br/>docs 66M-100M]
    
    S1P -- top 10 --> COORD
    S2P -- top 10 --> COORD
    S3P -- top 10 --> COORD
    
    COORD --> MERGE[Merge & Re-rank<br/>30 results → top 10]
    MERGE --> CLIENT[Return to Client]
~~~

### Option A: Sharding by Document ID (Hash-Based)

~~~
Strategy:
  shard = hash(document_id) % num_shards
  
  Example with 3 shards:
    doc_123 → hash(123) % 3 → shard 0
    doc_456 → hash(456) % 3 → shard 1
    doc_789 → hash(789) % 3 → shard 2

When to use:
  ✅ Uniform data distribution desired
  ✅ No natural partitioning in your data
  ✅ All queries search all data

Trade-offs:
  ✅ Perfect balance (assuming good hash function)
  ✅ Simple to implement
  ✅ No hotspots
  ❌ EVERY query hits ALL shards (scatter-gather)
  ❌ Can't route queries to specific shards
  ❌ Hard to rebalance (changing shard count requires reindexing)

Performance:
  Query latency = slowest shard + merge overhead
  (If shard 2 is slow, entire query is slow)

Cost: Medium
Complexity: Low
~~~

### Option B: Sharding by Logical Partition

~~~
Strategy:
  Partition by category, tenant, geography, date, etc.
  
  Example (e-commerce by category):
    electronics → shard 0
    clothing    → shard 1
    home_goods  → shard 2

When to use:
  ✅ Queries often filter by partition key
  ✅ Different partitions have different characteristics
  ✅ Want to route queries to fewer shards

Trade-offs:
  ✅ Query routing: category=electronics → only query shard 0
  ✅ Can size shards differently
  ✅ Can tune relevance per partition
  ❌ Imbalanced shards (electronics might be 10x bigger)
  ❌ Hotspots (Black Friday electronics traffic)
  ❌ Cross-partition queries still hit all shards

Performance:
  Single-partition query: 1 shard lookup (fast!)
  Cross-partition query: N shards (same as hash-based)

Cost: Medium (same infrastructure, better query routing)
Complexity: Medium (requires partition key choice)
~~~

### Option C: Time-Based Sharding (Hot/Warm/Cold)

~~~
Strategy:
  Separate indices by time period
  
  Example (e-commerce orders):
    orders_2026_04 → recent orders (hot)
    orders_2026_03 → last month (warm)
    orders_2025_*  → historical (cold)

When to use:
  ✅ Most queries focus on recent data
  ✅ Have time-series-like data
  ✅ Want to optimize for recent data

Trade-offs:
  ✅ Query "recent orders": only search hot index (fast!)
  ✅ Can use different hardware (cold on cheaper storage)
  ✅ Can archive/delete old indices easily
  ❌ "Search all time" queries are expensive
  ❌ Managing index rotation adds complexity
  ❌ Time boundaries can be arbitrary

Tiering strategy:
  Hot (last 7 days):   Fast SSDs, heavy replication
  Warm (last 90 days): Standard SSDs, normal replication
  Cold (>90 days):     HDD, minimal replication

Cost: Can be lower (tiered storage)
Complexity: Medium-High (index lifecycle management)
~~~

### Shard Sizing Guidelines

~~~
Rule of thumb: 10-50GB per shard (Elasticsearch guidance)

Too few shards (100GB+ each):
  ❌ Slow queries (more docs to scan per shard)
  ❌ Slow recovery (rebalancing large shards)
  ❌ Heap pressure (large field data, aggregations)

Too many shards (< 1GB each):
  ❌ Overhead per shard (file handles, memory)
  ❌ Merge cost (coordinator merging 100+ result sets)
  ❌ Cluster state bloat

Sweet spot:
  100M documents × 10KB avg = 1TB total
  → 20-30 shards (30-50GB each)
  → Can search in parallel, manageable overhead
~~~

### Replication for High Availability

~~~
Every shard should have 1+ replicas:

Primary-Replica pattern:
  - Writes go to primary shard
  - Primary replicates to replica shards
  - Reads can go to primary OR replicas
  - If primary fails, replica is promoted

Replication factor:
  1 replica (2 copies total):  Can tolerate 1 node failure
  2 replicas (3 copies total): Can tolerate 2 node failures
  
Trade-off:
  More replicas = higher availability + query throughput
               BUT 2-3× storage cost

Recommendation:
  Production: 1-2 replicas
  Dev/Test:   0 replicas (save cost)
~~~

### Caching Strategies

### Option A: No Application Cache

~~~
When to use:
  ✅ Query patterns are highly diverse (low hit rate)
  ✅ Data changes frequently
  ✅ Search engine is fast enough (<100ms)

Trade-offs:
  ✅ Always fresh results
  ✅ No cache complexity
  ❌ Full load on search engine
  ❌ Higher latency for popular queries

Cost: Low (no cache infrastructure)
Complexity: Low
~~~

### Option B: Application-Level Cache (Redis)

~~~
Implementation:
  def search(query, filters, page):
      cache_key = hash(query + filters + page)
      cached = redis.get(cache_key)
      if cached:
          return cached
      
      results = search_engine.search(query, filters, page)
      redis.setex(cache_key, ttl=300, value=results)  # 5 min TTL
      return results

When to use:
  ✅ Query patterns are repetitive (30%+ hit rate)
  ✅ Can tolerate stale results (1-5 minutes)
  ✅ Popular queries are expensive

Trade-offs:
  ✅ Reduces load on search engine by 30-60%
  ✅ Faster response for popular queries
  ✅ Can cache at page level (query + filters + page number)
  ❌ Stale results (cache invalidation is hard)
  ❌ Cache infrastructure cost
  ❌ More complex debugging

TTL strategy:
  Short TTL (1-2 min): Fresher results, lower hit rate
  Long TTL (10+ min):  Higher hit rate, staler results

Cost: Medium (Redis cluster)
Complexity: Medium
~~~

### Option C: Multi-Layer Caching

~~~
Layer 1: Application cache (Redis)
  - Cache final results
  - TTL: 1-5 minutes
  - Hit rate: 30-60% for popular queries

Layer 2: Search engine internal caches
  - Filter cache: bitmap of matching docs per filter
  - Query cache: results for identical queries
  - Field data cache: column values for sorting/aggregation
  - Automatically managed by search engine

Layer 3: OS page cache
  - Index files cached in memory by OS
  - Most effective for frequently accessed indices
  - "Free" caching

When to use:
  ✅ High query volume
  ✅ Performance critical
  ✅ Mix of popular and long-tail queries

Cost: Medium-High
Complexity: Medium (Layer 1) + Free (Layers 2-3)
~~~

---

## 5. Design Decision: How Do We Implement Relevance Ranking?

### The Core Question
Search engines return matching documents, but in what order? How do you decide what's most relevant?

### Option A: Pure BM25 (Default Text Relevance)

~~~
What it is:
  Industry-standard algorithm that scores documents based on:
  - Term frequency in document
  - Inverse document frequency across all docs
  - Document length normalization

When to use:
  ✅ Text-focused search (documentation, articles)
  ✅ No strong business signals available
  ✅ Want to ship quickly

Trade-offs:
  ✅ Works out of the box
  ✅ No tuning required
  ✅ Fast (no additional scoring)
  ✅ Predictable and explainable
  ❌ Ignores business context (popularity, recency, etc.)
  ❌ Treats all documents equally
  ❌ "Best" is purely text-based

Example results for "laptop":
  1. "Laptop buying guide" (perfect text match)
  2. "Best laptop 2020" (older, less relevant?)
  3. "Gaming laptop review" (popular, but lower text score)

Cost: Low (built-in)
Complexity: Low
~~~

### Option B: BM25 + Business Signals (Field Boosting + Function Scores)

~~~
What it is:
  Combine text relevance with business signals
  
  final_score = text_relevance 
              × recency_boost(publish_date)
              × popularity_boost(view_count)
              × quality_boost(rating)
              + exact_match_bonus
              + in_stock_boost

Implementation example (Elasticsearch):
  {
    "query": {
      "function_score": {
        "query": {
          "multi_match": {
            "query": "laptop",
            "fields": ["title^3", "description^1"]  // title boost 3x
          }
        },
        "functions": [
          {"filter": {"range": {"rating": {"gte": 4}}}, "weight": 1.5},
          {"field_value_factor": {"field": "view_count", "modifier": "log1p"}},
          {"gauss": {"publish_date": {"scale": "30d"}}}  // prefer recent
        ]
      }
    }
  }

When to use:
  ✅ E-commerce, content platforms
  ✅ Have business metrics (views, sales, ratings)
  ✅ Relevance means more than just text match

Trade-offs:
  ✅ Incorporates business context
  ✅ Can boost in-stock, popular, or recent items
  ✅ Still relatively simple and explainable
  ✅ Easy to tune with A/B testing
  ❌ Requires domain knowledge to tune
  ❌ Can over-optimize for popularity
  ❌ Manual feature engineering

Common signals:
  E-commerce: price, in_stock, sales_count, rating, recency
  Job search: salary, company_rating, application_count, freshness
  Content: views, shares, recency, author_reputation

Cost: Low (built-in to search engines)
Complexity: Medium (requires tuning)
~~~

### Option C: Machine Learning Ranking (Learning to Rank)

~~~
What it is:
  Train an ML model to predict relevance based on features
  
  Features: [text_score, recency, popularity, user_location, 
            time_of_day, user_past_clicks, ...]
  Label: user clicked this result (positive) or not (negative)
  
  Model: XGBoost, neural net, etc.
  Output: relevance score

Implementation:
  1. Search engine returns candidate documents + BM25 scores
  2. Extract features for each document
  3. Run ML model to re-rank candidates
  4. Return re-ranked results

When to use:
  ✅ Have significant click/conversion data
  ✅ Complex ranking requirements
  ✅ Search is a core product feature
  ✅ Have ML infrastructure and expertise

Trade-offs:
  ✅ Can learn complex patterns
  ✅ Personalization at scale
  ✅ Continuous improvement as data grows
  ❌ Requires labeled training data (clicks, purchases)
  ❌ Cold start problem (new items, new users)
  ❌ Black box (hard to explain rankings)
  ❌ Significant infrastructure (feature store, model serving)
  ❌ Latency overhead (50-200ms for model inference)

Cost: High (ML infrastructure + data pipeline)
Complexity: High
~~~

### Decision Matrix

| Approach | Best For | Latency Overhead | Setup Time | Ongoing Effort |
|----------|----------|------------------|------------|----------------|
| Pure BM25 | Text search, simple | 0ms | 1 day | Low |
| BM25 + Business | E-commerce, content | 0-5ms | 1-2 weeks | Medium |
| ML Ranking | Core product feature | 50-200ms | 3-6 months | High |

### Measuring Search Quality

~~~
Before you tune, you need metrics:

Business metrics:
  - Click-through rate (CTR): % of searches that get a click
  - Conversion rate: % of searches that lead to purchase/goal
  - Zero-result rate: % of queries returning nothing
  - Time to first click: how fast users find what they want

Technical metrics:
  - Mean Reciprocal Rank (MRR): 1/rank of first relevant result
    Example: first click at position 3 → MRR = 1/3 = 0.33
  - Precision@K: % of top-K results that are relevant
  - NDCG: considers both relevance and position

A/B testing workflow:
  1. Change ranking formula/model
  2. Deploy to 10% of traffic
  3. Measure CTR, conversion for 1-2 weeks
  4. If +5% CTR increase → rollout to 100%
  
Warning: Small ranking changes can have large business impact
         (e.g., +2% CTR might mean +$1M annual revenue)
~~~

---

## 6. Design Decision: What Search Features Do We Build?

### The Core Question
Beyond basic search, what features should you invest in? When is each worth the complexity?

### Feature 1: Autocomplete / Search-as-You-Type

~~~
What users see:
  User types: "wire"
  Dropdown shows: ["wireless headphones", "wireless mouse", "wire cutter"]

When to build:
  ✅ Users often search for known items
  ✅ High search volume (>1000 queries/day)
  ✅ Limited search space (products, people, places)

Trade-offs:
  ✅ Improves discovery and UX
  ✅ Reduces typos (select from suggestions)
  ✅ Can surface popular queries
  ❌ 5-10× more queries than regular search
  ❌ High cache hit rate critical
  ❌ Needs aggressive debouncing (200-300ms)

Implementation approaches:

Option A: Prefix matching
  Index: ["wireless headphones", "wireless mouse"]
  Query: "wire*"
  ✅ Simple
  ❌ No mid-word matching

Option B: Edge n-grams
  Index "wireless" as: ["w", "wi", "wir", "wire", "wirel", "wirele", "wireless"]
  Query: "wire"
  ✅ Fast, works mid-word
  ❌ Large index size

Option C: Completion suggester (FST)
  Purpose-built data structure for suggestions
  ✅ Very fast (<10ms)
  ✅ Can weight by popularity
  ❌ Elasticsearch/OpenSearch specific

Recommendation: Start with prefix matching, upgrade to FST if needed

Cost: Medium (index size + query volume)
Complexity: Medium
~~~

~~~mermaid
sequenceDiagram
    participant U as User
    participant FE as Frontend
    participant API as API
    participant Cache as Redis
    participant ES as Search Engine
    
    U->>FE: Types "wire"
    FE->>FE: Debounce 200ms
    FE->>API: GET /suggest?q=wire
    API->>Cache: Check cache
    Cache-->>API: Miss
    API->>ES: Prefix query
    ES-->>API: ["wireless headphones", ...]
    API->>Cache: Cache for 5 min
    API-->>FE: Suggestions
    FE-->>U: Dropdown
~~~

### Feature 2: Fuzzy Search and Typo Tolerance

~~~
What users see:
  User types: "wireles headphnes"
  Still finds: "wireless headphones"

When to build:
  ✅ Users prone to typos (mobile, fast typing)
  ✅ Complex terminology or spellings
  ✅ High zero-result rate (>10%)

Trade-offs:
  ✅ Reduces zero-result queries by 20-40%
  ✅ Better mobile experience
  ❌ Slower queries (2-5× with fuzzy=2)
  ❌ Can return unexpected results
  ❌ Needs careful tuning (too fuzzy = bad results)

Implementation:
  Levenshtein distance (edit distance):
    "wireles" → "wireless" (1 edit: add 's')
    
  Fuzzy settings:
    fuzzy=0: No typo tolerance (exact match)
    fuzzy=1: Allow 1 character difference
    fuzzy=2: Allow 2 character differences (slow!)
    fuzzy=AUTO: 0 for 1-2 chars, 1 for 3-5 chars, 2 for 6+ chars

Recommendation: Use fuzzy=AUTO as fallback (not default)
  1. Try exact match first
  2. If zero results, retry with fuzzy=AUTO

Cost: Low (built-in)
Complexity: Low
~~~

### Feature 3: Faceted Search (Filters + Aggregations)

~~~
What users see:
  Query: "laptop"
  Results: 2,340 laptops
  
  Filters:
    Brand:  □ Apple (450)  □ Dell (380)  □ Lenovo (320)
    Price:  □ $0-500 (800)  □ $500-1000 (900)  □ $1000+ (640)
    RAM:    □ 8GB (600)  □ 16GB (1200)  □ 32GB (540)
  
  User checks "Apple" + "$500-1000":
    → 180 results, facets update

When to build:
  ✅ Catalog/marketplace with many items
  ✅ Users need to filter/narrow results
  ✅ Have structured attributes

Trade-offs:
  ✅ Essential for e-commerce UX
  ✅ Helps users discover and narrow
  ✅ Built-in to search engines (aggregations)
  ❌ Adds query latency (10-50ms)
  ❌ Needs careful UI design
  ❌ Complex with many facets

Implementation:
  Elasticsearch aggregations run alongside search query
  
  {
    "query": {...},
    "aggs": {
      "brands": {"terms": {"field": "brand"}},
      "price_ranges": {"range": {"field": "price", "ranges": [...]}}
    }
  }

Performance tip: Cache facet counts separately (change less often)

Cost: Low (built-in)
Complexity: Medium (UI complexity)
~~~

### Feature 4: Synonyms and Query Expansion

~~~
What users see:
  User types: "laptop"
  Also finds: "notebook", "portable computer"

When to build:
  ✅ Domain-specific terminology
  ✅ Multiple terms for same concept
  ✅ Improve recall for long-tail queries

Trade-offs:
  ✅ Improves recall (find more relevant docs)
  ✅ Handles industry jargon
  ❌ Can reduce precision (more false positives)
  ❌ Requires domain expertise to build synonym list
  ❌ Maintenance overhead

Implementation:
  Define synonym filter:
    laptop => laptop, notebook
    smartphone => smartphone, mobile phone, cell phone
  
  Apply at index time OR query time
    Index time: expands during indexing (larger index)
    Query time: expands during search (more flexible)

Cost: Low (built-in)
Complexity: Medium (building synonym list)
~~~

### Priority Matrix

| Feature | Impact | Complexity | Build First? |
|---------|--------|------------|--------------|
| Autocomplete | High | Medium | If high search volume |
| Fuzzy search | Medium | Low | Yes (as fallback) |
| Faceted search | High | Medium | If catalog/marketplace |
| Synonyms | Medium | Medium | After basics work |

---

## 7. Common Mistakes to Avoid

### Mistake 1: Using SQL LIKE for Search at Scale

~~~
❌ Don't do this:
   SELECT * FROM products 
   WHERE title LIKE '%wireless%' 
   ORDER BY created_at DESC

Problems:
  - Full table scan on every query
  - No relevance ranking
  - Breaks at >100K rows

✅ Do this instead:
   - < 10K rows: OK to use LIKE or DB full-text search
   - > 10K rows: Use dedicated search engine
   - Keep DB as source of truth, search as read model
~~~

### Mistake 2: Indexing Everything

~~~
❌ Don't do this:
   Index all 50 fields of every document
   → Index size explodes, indexing slows down

✅ Do this instead:
   Only index fields you search/filter on:
     - Search: title, description, tags
     - Filter: price, category, brand, in_stock
   Store display-only fields without indexing (source storage)
~~~

### Mistake 3: Ignoring Relevance

~~~
❌ Don't do this:
   Return results sorted by date or ID
   User searches "best laptop" → newest items first (irrelevant)

✅ Do this instead:
   - Default to relevance sorting (BM25 + business signals)
   - Allow explicit overrides (sort by price, date)
   - Measure and tune relevance (CTR, MRR)
~~~

### Mistake 4: Synchronous Dual-Write Without Fallbacks

~~~
❌ Don't do this:
   def create_product(product):
       db.save(product)
       search.index(product)  # Fails → DB and search out of sync
       
✅ Do this instead:
   - Use CDC, outbox pattern, or async queue
   - Have a backfill strategy for failures
   - Accept eventual consistency
~~~

### Mistake 5: Over-Sharding or Under-Sharding

~~~
❌ Don't do this:
   - 1 shard for 1TB of data (slow queries, slow recovery)
   - 1000 shards for 100GB of data (massive overhead)

✅ Do this instead:
   - Target 10-50GB per shard
   - 100GB → 2-5 shards
   - 1TB → 20-30 shards
~~~

---

## 8. Key Takeaways: Decision Framework

When designing a search system, make these decisions deliberately:

| Decision | Questions to Ask | Default Recommendation |
|----------|------------------|------------------------|
| **1. Search Engine Choice** | Scale? Feature needs? | <100K rows: DB full-text<br/>100K-1M: DB or Engine<br/>>1M: Dedicated engine |
| **2. Keeping in Sync** | Consistency needs? Complexity tolerance? | Start: Async queue<br/>Scale: CDC<br/>Greenfield: Event sourcing |
| **3. Sharding Strategy** | Query patterns? Data characteristics? | Hash-based for uniform access<br/>Logical partition if queries filter by it<br/>Time-based for time-series |
| **4. Scaling** | Query volume? Query latency SLA? | Shard to 10-50GB each<br/>Add replicas for read throughput<br/>Cache popular queries |
| **5. Relevance** | Business signals available? ML capability? | Start: Pure BM25<br/>Add: Business signals<br/>Advanced: ML ranking |
| **6. Features** | User needs? Development resources? | Must: Fuzzy search fallback<br/>Should: Faceted search (catalogs)<br/>Nice: Autocomplete (high volume) |

### Core Principles

1. **Search is a read model** — Database is source of truth, search is optimized for queries
2. **Inverted index is the magic** — Understand why it's O(terms) not O(documents)
3. **Eventual consistency is OK** — 1-5 second lag acceptable for most use cases
4. **Start simple, add complexity as needed** — Don't build ML ranking on day 1
5. **Measure, measure, measure** — CTR, zero-result rate, conversion are your north stars
6. **Scatter-gather is unavoidable** — Design for it, optimize coordinator merge
7. **Caching has huge ROI** — Even 30% hit rate dramatically reduces load
8. **Text analysis determines quality** — Invest time in analyzers, synonyms, stopwords

---

## 9. Practical Exercise: Make the Decisions

### Scenario: Job Search Platform (LinkedIn Jobs)

You're building a job search platform. Here are the requirements:

**Scale:**
- 50 million active job postings
- 10 million searches per day (peak: 5K queries/second)
- 100K new job postings per day
- Avg job posting: 2KB (title, description, skills, location, salary, etc.)

**Features:**
- Search by title, skills, company, location
- Filters: salary range, remote/onsite, experience level, posted date
- Autocomplete for job titles and company names
- Personalized ranking based on user profile and search history
- Near-real-time: new postings searchable within 30 seconds

### Your Design Decisions

Work through each decision in order. For each, choose an option and justify it.

#### Decision 1: Do we need a dedicated search engine?

Consider:
- Total data: 50M jobs × 2KB = 100GB
- Query volume: 10M searches/day
- Feature requirements: autocomplete, facets, ranking, location search

**Your choice:** ⬜ DB full-text search  ⬜ Dedicated search engine

**Why?**

---

#### Decision 2: How do we keep search in sync with the database?

Consider:
- Write volume: 100K new jobs/day = ~1 write/second (manageable)
- Consistency requirement: 30-second lag acceptable
- Database: Postgres (has binlog/WAL available)

**Your choice:** ⬜ Dual-write  ⬜ Async queue  ⬜ CDC  ⬜ Outbox  ⬜ Event sourcing

**Why?**

---

#### Decision 3: How do we shard the search index?

Consider:
- Data size: 100GB total
- Query patterns: Most queries filter by location
- Growth: Jobs expire, so data is relatively stable

**Your choice:** ⬜ Hash by job_id  ⬜ Partition by location  ⬜ Time-based (hot/warm/cold)

**Why?**

**How many shards?**

---

#### Decision 4: How do we implement relevance ranking?

Consider:
- Have data: job posting date, application count, company rating
- Have user data: user profile (skills, location, seniority), search history
- ML team: Available but small (2 engineers)

**Your choice:** ⬜ Pure BM25  ⬜ BM25 + business signals  ⬜ ML ranking

**If BM25 + business signals, which signals would you use?**

---

#### Decision 5: What search features do we build? (Pick priorities)

Consider:
- Development time: 3 engineers for 2 months
- Must-haves vs nice-to-haves

**Rank these features (1 = build first):**
- ____ Autocomplete for job titles
- ____ Fuzzy search / typo tolerance
- ____ Faceted search (salary, location, experience, remote)
- ____ Location-based search (jobs within 50km of user)
- ____ Saved searches with email alerts

**Why this priority?**

---

#### Decision 6: How do we handle location search?

Consider:
- Requirement: "Find jobs within 50km of me"
- User provides: zipcode, city, or coordinates
- Jobs have: city, state, country (some have coordinates)

**Implementation approach:**
- How do you structure location data in the index?
- How do you query for "within 50km"?
- What if a job doesn't have coordinates?

---

### Sample Solution (One Possible Approach)

<details>
<summary>Click to reveal one possible solution</summary>

#### 1. Search Engine Choice
**Decision:** Dedicated search engine (Elasticsearch/OpenSearch)

**Why:**
- 100GB data + complex features (autocomplete, location, facets) → need dedicated engine
- 5K QPS at peak → need horizontal scaling
- DB full-text search can't handle location radius queries well

---

#### 2. Keeping in Sync
**Decision:** CDC (Change Data Capture) with Debezium + Kafka

**Why:**
- 1 write/second is low enough that async queue would work
- BUT: CDC means no application code changes when adding fields
- 30-second lag is acceptable, CDC typically achieves 1-5 seconds
- Can replay for backfills

Architecture:
```
Postgres → Debezium → Kafka → Indexer Service → Elasticsearch
```

---

#### 3. Sharding
**Decision:** Partition by location (country → shard)

**Why:**
- Most queries filter by location ("jobs in USA")
- 100GB / 10 countries ≈ 10GB per shard (within 10-50GB guideline)
- Query routing: US jobs → query US shard only

Sharding:
- us_jobs (60GB, 30M jobs) → 2 shards
- uk_jobs (10GB, 5M jobs) → 1 shard
- ca_jobs (8GB, 4M jobs) → 1 shard
- etc.

Total: ~8-10 shards across all regions

---

#### 4. Relevance Ranking
**Decision:** BM25 + business signals (phase 1), ML ranking (phase 2)

**Phase 1 signals:**
```
final_score = text_match_score
            × recency_boost(posted_date)      // prefer recent jobs
            × popularity_boost(application_count)
            × quality_boost(company_rating)
            + exact_title_match_bonus
            + location_proximity_score(user_location, job_location)
```

**Why defer ML ranking:**
- Business signals get 80% of the value with 20% of the effort
- Can build ML ranking in parallel once click data accumulates

---

#### 5. Feature Priority
1. **Faceted search** (salary, location, experience, remote) — core to job search UX
2. **Fuzzy search** — handles typos, low effort, high impact
3. **Location-based search** — required for "jobs near me"
4. **Autocomplete** — nice-to-have, high QPS, build after basics work
5. **Saved searches** — backend feature, not search engine work

---

#### 6. Location Search
**Implementation:**

Geocoding at index time:
```
Job document:
{
  "title": "Senior Engineer",
  "location": {
    "city": "San Francisco",
    "state": "CA",
    "coordinates": { "lat": 37.7749, "lon": -122.4194 }
  }
}
```

Elasticsearch geo query:
```
{
  "query": {
    "bool": {
      "must": {...},  // text match
      "filter": {
        "geo_distance": {
          "distance": "50km",
          "location.coordinates": {
            "lat": 37.7749,
            "lon": -122.4194
          }
        }
      }
    }
  }
}
```

**Handling missing coordinates:**
- At index time, geocode city/state to approximate coordinates
- Use geocoding service (Google Maps API, Mapbox, etc.)
- Cache geocoding results to reduce API costs

</details>

---

### Discussion Questions

1. **Would time-based sharding (hot/warm/cold) work better?** Why or why not?
2. **What happens if 80% of jobs are in one country (e.g., USA)?** How do you avoid hotspots?
3. **How would you implement "jobs posted in last 24 hours" efficiently?**
4. **Should autocomplete suggestions be personalized?** What's the trade-off?
5. **How would you handle "remote jobs" — are they in all shards or a separate index?**
