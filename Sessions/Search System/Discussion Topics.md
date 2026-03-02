# Search System - Discussion Topics

## Architecture & Design

1. **When should you use a dedicated search engine vs database full-text search?**
   - Scale and performance thresholds
   - Feature requirements (fuzzy, facets, ranking)
   - Operational complexity trade-offs

2. **How do you keep your search index in sync with the source database?**
   - CDC vs outbox vs dual-write
   - Handling failures and retries
   - Acceptable lag for different use cases

3. **How do you decide on shard count and shard sizing?**
   - Document count and size
   - Query throughput requirements
   - Reindexing and scaling considerations

## Real-World Scenarios

4. **Design a search system for a marketplace with 100M products across 50 categories**
   - Category-specific ranking (electronics vs clothing)
   - Multi-language support
   - Seller quality signals in ranking

5. **Your search index is 2 hours behind the database after a pipeline failure — how do you recover?**
   - Backfill strategy
   - Prioritizing recent changes
   - Communicating staleness to users

6. **How would you implement "Did you mean?" suggestions for misspelled queries?**
   - Spell correction approaches
   - Query log mining
   - Balancing correction accuracy with latency

## Performance & Relevance

7. **How do you handle search queries that return zero results?**
   - Query relaxation strategies
   - Synonym expansion
   - Fallback to broader matches

8. **What's your approach to A/B testing search ranking changes?**
   - Metrics to track
   - Interleaving vs split testing
   - Statistical significance for search

## Advanced Topics

9. **When would you add a machine learning ranking layer on top of BM25?**
   - Learning to Rank (LTR) basics
   - Feature engineering for search
   - Cold start problem for new documents

10. **How do you handle multi-tenant search where each tenant has different data and ranking needs?**
    - Index per tenant vs shared index with filtering
    - Custom analyzers per tenant
    - Resource isolation and fair scheduling
