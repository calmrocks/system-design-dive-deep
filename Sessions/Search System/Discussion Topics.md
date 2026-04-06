# Search System - Discussion Topics

Use these to drive conversation during or after the presentation. Focus on trade-offs and decision-making.

---

## Design Decisions

### 1. When do you choose a dedicated search engine vs staying with your database?

**Scenario:** You have 500K products and want to add search. Your team is debating whether to use Postgres full-text search or Elasticsearch.

**Discussion points:**
- What's the threshold where database search becomes inadequate?
- How do operational costs compare (DB resources vs new search cluster)?
- What features might push you toward a dedicated engine earlier?
- When is "good enough" actually good enough?

**Trade-off:** Simplicity vs capabilities

---

### 2. How do you keep search in sync with the database?

**Scenario:** Your database has user-generated content that changes frequently. You need search to reflect changes within 1 minute.

**Approaches to debate:**
- Dual-write from application
- Async message queue
- Change Data Capture (CDC)
- Transactional outbox

**Discussion points:**
- What happens when the indexing pipeline fails for 30 minutes?
- How do you backfill without disrupting live traffic?
- Is 1-second lag meaningfully different from 30-second lag?
- When is CDC worth the operational complexity?

**Trade-off:** Consistency guarantees vs complexity

---

### 3. How do you shard your search index?

**Scenario A:** E-commerce with 100M products across 20 categories
**Scenario B:** Job board with 50M listings across 150 countries
**Scenario C:** Document search with 1TB of PDFs, newest docs queried 10x more

**Discussion points:**
- Hash-based sharding: when is uniform distribution optimal?
- Logical partitioning (by category, location): when can you route queries?
- Time-based sharding (hot/warm/cold): when is recency a strong signal?
- What happens when one shard is 10x bigger than others?

**Trade-off:** Uniform distribution vs query routing efficiency

---

### 4. What relevance ranking should you implement?

**Scenario:** E-commerce site. Users search "running shoes."

**Option A:** Pure BM25
- Result 1: "Running Shoes Buyer's Guide" (blog post, perfect text match)
- Result 2: Actual running shoes for sale

**Option B:** BM25 + business signals (price, rating, sales count)
- Result 1: Popular running shoe (4.8 stars, 10K sales)
- Result 2: Running shoes buyer's guide

**Option C:** ML ranking trained on clicks
- Result 1: Running shoe this specific user is likely to buy based on history

**Discussion points:**
- When is "perfect text match" the wrong ranking?
- How do you balance popularity vs relevance? (Popular items get more clicks → rank higher → get even more clicks)
- What's the minimum data needed to make ML ranking worthwhile?
- How do you handle cold start (new products, new users)?

**Trade-off:** Implementation complexity vs relevance quality

---

### 5. Which search features do you build first?

**Scenario:** 3-month timeline, 2 engineers. You need search for a SaaS product with 10K users.

**Features to prioritize:**
- Basic search (text match + filters)
- Autocomplete
- Fuzzy search / typo tolerance
- Faceted search
- Saved searches
- Search analytics dashboard

**Discussion points:**
- Which features are table-stakes vs nice-to-have?
- What's the ROI of autocomplete given it's 10× the query volume?
- When is fuzzy search worth the latency hit?
- How do you decide what NOT to build?

**Trade-off:** Time to market vs feature completeness

---

## Real-World Scenarios

### 6. Your search index is 2 hours behind after a pipeline failure

**Context:**
- CDC pipeline went down
- Database had 50K writes during the outage
- Users are complaining about missing/stale results

**Discussion points:**
- How do you catch up without overloading the search cluster?
- Do you prioritize recent changes or process chronologically?
- Should you show a staleness indicator to users?
- How do you prevent this in the future?

---

### 7. Zero-result rate is 15% and growing

**Context:**
- E-commerce site
- Users search for niche products
- Query log shows lots of typos and synonyms

**Discussion points:**
- What's the diagnosis process? (Query log analysis, A/B testing)
- When do you add fuzzy search vs synonyms vs query suggestions?
- How do you measure improvement? (zero-result rate, CTR, conversion)
- What if users are searching for products you don't sell?

---

### 8. Design search for a marketplace with category-specific needs

**Context:**
- 100M products across 50 categories
- Electronics: specs matter (CPU, RAM, screen size)
- Clothing: size, color, material matter
- Books: author, genre, publication year matter

**Discussion points:**
- Single index or multiple indices (one per category)?
- Same ranking formula for all categories or category-specific?
- How do you handle cross-category searches ("electronics and books")?
- How do text analysis needs differ (tech specs vs prose)?

---

### 9. Implementing multi-language search

**Context:**
- Global e-commerce platform
- Support English, Spanish, French, German, Japanese
- Some products have translations, others are English-only

**Discussion points:**
- Per-language index or single index with language field?
- How do you handle text analysis (stemmers, stop words per language)?
- What happens when a user searches in Japanese but product is only in English?
- Auto-translation at search time or index time?

---

### 10. A/B testing a new ranking algorithm

**Context:**
- Current: BM25 + recency boost
- New: BM25 + recency + popularity + rating
- Want to test on 10% of traffic

**Discussion points:**
- What metrics do you track? (CTR, conversion, revenue, zero-result rate)
- How long do you run the test? (statistical significance)
- What if new algorithm is +5% CTR but -2% conversion?
- How do you avoid interaction effects (users in both groups)?

---

## Advanced Topics

### 11. When do you add machine learning ranking?

**Discussion points:**
- How much click/conversion data do you need?
- What features do you engineer? (text score, recency, popularity, user context, time-of-day)
- How do you handle the cold start problem?
- What's the latency budget for model inference? (50ms? 200ms?)
- How do you A/B test ML models without poisoning training data?

---

### 12. Multi-tenant search: one index or many?

**Context:**
- SaaS platform with 1000 tenants
- Each tenant has 10K-1M documents
- Tenants want custom ranking and analyzers

**Discussion points:**
- Shared index with tenant filtering vs index-per-tenant?
- How do you enforce tenant isolation (no data leakage)?
- How do you handle one tenant overwhelming the cluster?
- How do you allow custom analyzers per tenant?

**Trade-off:** Resource efficiency vs isolation and customization

---

## Guiding Questions for All Topics

When discussing any search design decision, consider:

1. **Scale:** What breaks at 10×? 100×?
2. **Trade-offs:** What are you giving up?
3. **Measurement:** How do you know if it's working?
4. **Failure modes:** What happens when it breaks?
5. **Cost:** Infrastructure, maintenance, opportunity cost?
