# Feed Generation - Discussion Topics

## Architecture & Design

1. **How do you decide the fan-out threshold (when to push vs pull)?**
   - Follower count breakpoints
   - User activity patterns
   - Infrastructure cost analysis

2. **What's the right data structure for storing pre-computed feeds?**
   - Redis sorted sets vs lists
   - Memory vs disk trade-offs
   - Feed size limits and trimming

3. **How do you balance chronological ordering with algorithmic ranking?**
   - User expectations and transparency
   - Ranking signal selection
   - A/B testing ranking changes

## Real-World Scenarios

4. **Design a feed for a news aggregation app where content comes from publishers, not user connections**
   - Topic-based vs follow-based feeds
   - Content freshness and decay
   - Deduplication of the same story from multiple sources

5. **A celebrity with 50M followers posts during peak hours — how does your system handle it?**
   - Fan-out timing and prioritization
   - Impact on other users' feed freshness
   - Resource isolation

6. **Users complain they're seeing the same posts repeatedly — how do you debug and fix?**
   - "Seen" tracking implementation
   - Pagination bugs
   - Cache staleness issues

## Performance & Scale

7. **How do you keep feed latency under 200ms when merging pre-computed and pull-based content?**
   - Parallel fetching strategies
   - Cache warming for celebrity posts
   - Timeout and fallback for slow sources

8. **What's your strategy for feed cache warming after a cold start or cache failure?**
   - Lazy vs eager rebuilding
   - Prioritizing active users
   - Graceful degradation during rebuild

## Advanced Topics

9. **How do you implement "interest-based" feed items from users you don't follow?**
   - Collaborative filtering
   - Content similarity
   - Exploration vs exploitation

10. **How do you handle feed generation for group/community feeds vs personal feeds?**
    - Shared feed computation
    - Permission-aware content filtering
    - Activity-based vs membership-based ranking
