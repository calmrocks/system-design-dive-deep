# Feed Generation: Architecture Guide

## Overview

| Attribute | Details |
|-----------|---------|
| Duration | 60 minutes |
| Level | Intermediate to Advanced |
| Prerequisites | Cache session, Message Queue session, Data Replication & Consistency session |

## Learning Objectives

- Understand fan-out on write vs fan-out on read trade-offs
- Design feed systems that handle millions of users and posts
- Reason about ranking, pagination, and real-time updates
- Handle the celebrity problem and mixed fan-out strategies
- Evaluate storage and caching strategies for feed data

---

## 1. The Feed Problem

### What Is a Feed?

~~~
Examples:
  Twitter/X:    tweets from people you follow, ranked by time/relevance
  Instagram:    photos/videos from followed accounts + suggested content
  LinkedIn:     posts, articles, job changes from connections
  Facebook:     posts from friends, groups, pages, ads
  GitHub:       activity from repos you watch and people you follow

Core question:
  User follows 500 people, each posts 3 times/day
  → 1,500 potential items per day
  → Which ones to show? In what order? How fast?
~~~

### Why It's Hard

~~~
Scale:
  500M users × 500 follows average = 250 billion follow edges
  100M posts per day
  Each post must appear in followers' feeds
  Feed must load in < 200ms

Trade-offs:
  Write time vs read time
  Storage vs computation
  Freshness vs relevance
  Consistency vs availability
~~~

---

## 2. Fan-Out Strategies

### Fan-Out on Write (Push Model)

~~~mermaid
sequenceDiagram
    participant U as User A (posts)
    participant PS as Post Service
    participant Q as Fan-Out Queue
    participant W as Fan-Out Workers
    participant FC as Feed Cache (Redis)
    
    U->>PS: Create post
    PS->>PS: Store post in DB
    PS->>Q: Enqueue fan-out job
    Q->>W: Process fan-out
    
    Note over W: User A has 10,000 followers
    
    W->>FC: LPUSH feed:follower1 post_id
    W->>FC: LPUSH feed:follower2 post_id
    W->>FC: ... (10,000 writes)
    W->>FC: LPUSH feed:follower10000 post_id
    
    Note over FC: Each user's feed is pre-computed
    
    participant R as Reader (Follower)
    R->>FC: LRANGE feed:follower1 0 19
    FC-->>R: [post_ids...] (instant!)
~~~

~~~
Pros:
  ✅ Read is extremely fast (pre-computed, just fetch from cache)
  ✅ Simple read path
  ✅ Consistent feed experience

Cons:
  ❌ Write amplification (1 post → N feed writes)
  ❌ Celebrity problem (1 post → 50M feed writes)
  ❌ Wasted work for inactive users
  ❌ Delay between post and appearing in all feeds
~~~

### Fan-Out on Read (Pull Model)

~~~mermaid
sequenceDiagram
    participant U as User A (posts)
    participant PS as Post Service
    participant R as Reader
    participant FS as Feed Service
    participant DB as Database
    participant Cache as Cache
    
    U->>PS: Create post
    PS->>PS: Store post in DB (done)
    
    Note over R: Later, reader opens feed...
    
    R->>FS: GET /feed
    FS->>DB: Get reader's follow list
    DB-->>FS: [user_A, user_B, ..., user_500]
    FS->>DB: Get recent posts from each followed user
    DB-->>FS: Posts from all followed users
    FS->>FS: Merge, rank, paginate
    FS->>Cache: Cache result (short TTL)
    FS-->>R: Feed page 1
~~~

~~~
Pros:
  ✅ No write amplification
  ✅ No wasted work (only compute when user requests)
  ✅ Celebrity posts are just one DB row

Cons:
  ❌ Slow reads (merge N users' posts at read time)
  ❌ High read-time computation
  ❌ Hard to rank across sources in real-time
~~~

### Hybrid Approach (What Real Systems Use)

~~~mermaid
flowchart TB
    POST[New Post] --> CHECK{Author has<br/>> 100K followers?}
    
    CHECK -->|No: Regular user| PUSH[Fan-out on Write<br/>Push to all followers' feeds]
    CHECK -->|Yes: Celebrity| STORE[Store post only<br/>No fan-out]
    
    READ[User opens feed] --> MERGE[Merge:]
    PUSH -.-> CACHED[Pre-computed feed<br/>from cache]
    STORE -.-> PULL[Pull celebrity posts<br/>at read time]
    
    CACHED --> MERGE
    PULL --> MERGE
    MERGE --> RANK[Rank & Return]
~~~

~~~
Hybrid strategy:
  Regular users (< 100K followers):
    Fan-out on write → push to followers' feed caches
    
  Celebrities (> 100K followers):
    Store post only → pull at read time
    
  At read time:
    1. Fetch pre-computed feed from cache (fast)
    2. Fetch recent posts from followed celebrities (small set)
    3. Merge and rank
    4. Return top N

  This is roughly what Twitter/X uses.
~~~

---

## 3. Feed Storage

### Feed Cache Structure (Redis)

~~~
Per-user feed in Redis:
  Key: feed:{user_id}
  Type: Sorted Set (score = timestamp or ranking score)
  
  ZADD feed:user123 1709312400 post:abc
  ZADD feed:user123 1709312500 post:def
  ZADD feed:user123 1709312600 post:ghi
  
  Read feed (newest first):
  ZREVRANGE feed:user123 0 19  → page 1 (20 items)
  ZREVRANGE feed:user123 20 39 → page 2

  Trim old entries:
  ZREMRANGEBYRANK feed:user123 0 -801  → keep only 800 items

Memory estimation:
  500M users × 800 post IDs × ~50 bytes each
  = ~20 TB of Redis
  → Sharded across cluster
~~~

### Post Storage

~~~
Posts stored separately (database):
┌─────────────────────────────────────────────────────┐
│ post_id:     "post-uuid-abc"                        │
│ author_id:   "user-456"                             │
│ content:     "Just shipped a new feature..."        │
│ media:       ["img-url-1", "img-url-2"]             │
│ created_at:  1709312400                             │
│ likes_count: 42                                     │
│ reply_count: 7                                      │
│ repost_count: 3                                     │
│ visibility:  "public"                               │
└─────────────────────────────────────────────────────┘

Feed cache stores only post IDs
Full post data fetched in batch when rendering feed
  → Multiget: GET post:abc, post:def, post:ghi (one round trip)
~~~

---

## 4. Ranking

### Chronological vs Algorithmic

~~~
Chronological (simple):
  Score = timestamp
  Newest first
  ✅ Predictable, no "why am I seeing this?"
  ❌ Misses important posts if you follow many people

Algorithmic (modern):
  Score = f(relevance, recency, engagement, relationship)
  
  Ranking signals:
  ┌─────────────────────────────────────────────────────┐
  │ Recency:      how new is the post?                  │
  │ Engagement:   likes, comments, reposts              │
  │ Relationship: how often do you interact with author?│
  │ Content type: do you engage more with images/video? │
  │ Author:       verified? close friend? same company? │
  │ Freshness:    have you seen similar content?        │
  │ Negative:     posts you've hidden, muted authors    │
  └─────────────────────────────────────────────────────┘

  Simple scoring formula:
  score = recency_decay(age) 
        × (1 + 0.1 × likes + 0.3 × comments)
        × relationship_weight(author, reader)
        × content_type_preference(reader)
~~~

### Two-Phase Ranking

~~~mermaid
flowchart LR
    CANDIDATES[Candidate Pool<br/>~1000 posts] 
    --> FILTER[Filter<br/>Remove seen,<br/>blocked, muted]
    --> LIGHT[Light Ranking<br/>Simple score<br/>→ top 200]
    --> HEAVY[Heavy Ranking<br/>ML model<br/>→ top 50]
    --> DIVERSE[Diversify<br/>Mix content types<br/>Inject ads]
    --> FINAL[Final Feed<br/>20 items per page]
~~~

---

## 5. Pagination

### Cursor-Based Pagination

~~~
Problem with offset pagination:
  Page 1: SELECT ... OFFSET 0 LIMIT 20
  Page 2: SELECT ... OFFSET 20 LIMIT 20
  
  New post inserted → page 2 shows duplicate from page 1

Cursor-based (correct):
  Page 1: GET /feed?limit=20
  Response: {posts: [...], cursor: "post_id=xyz&ts=1709312400"}
  
  Page 2: GET /feed?limit=20&cursor=post_id=xyz&ts=1709312400
  → "Give me 20 posts older than this cursor"
  → No duplicates, no skips

Implementation:
  WHERE (created_at, post_id) < (cursor_ts, cursor_id)
  ORDER BY created_at DESC, post_id DESC
  LIMIT 20
~~~

### Infinite Scroll with Real-Time Updates

~~~mermaid
sequenceDiagram
    participant C as Client
    participant API as Feed API
    participant WS as WebSocket
    
    C->>API: GET /feed (initial load)
    API-->>C: {posts: [...], cursor: "abc"}
    
    Note over C: User scrolling...
    C->>API: GET /feed?cursor=abc
    API-->>C: {posts: [...], cursor: "def"}
    
    Note over WS: New post from followed user
    WS->>C: {type: "new_posts", count: 3}
    
    Note over C: Shows "3 new posts" banner
    C->>C: User taps banner
    C->>API: GET /feed (fresh load)
    API-->>C: Updated feed with new posts
~~~

---

## 6. Real-Time Feed Updates

### Push vs Pull for New Content

~~~
Options for notifying users of new feed content:

  1. Polling (simple):
     Client polls every 30 seconds: "any new posts?"
     ✅ Simple, works everywhere
     ❌ Wasteful, 30s delay

  2. Long polling:
     Client holds connection open until new content
     ✅ Near real-time
     ❌ Connection management overhead

  3. WebSocket:
     Persistent connection, server pushes updates
     ✅ True real-time
     ❌ Connection state management at scale

  4. Server-Sent Events (SSE):
     One-way push from server
     ✅ Simpler than WebSocket for one-way
     ❌ Limited browser connections

Practical approach:
  - WebSocket for active users (app in foreground)
  - Push notification for inactive users (app in background)
  - Don't push every post — push "N new posts" indicator
~~~

---

## 7. Anti-Patterns

### Computing Feed from Scratch Every Time

~~~
Problem: No caching, query all follows and posts on every request

  GET /feed →
    Get 500 followed users
    Get recent posts from each (500 queries)
    Merge and sort
    Return top 20
  
  → 2-5 seconds per feed load
  → Database melts under load

Fix: Pre-compute feeds (fan-out on write)
     Cache aggressively
     Hybrid approach for celebrities
~~~

### Unbounded Fan-Out

~~~
Problem: Celebrity with 50M followers posts → 50M cache writes

  Time to fan out: 50M × 0.1ms = 83 minutes
  → Feed is stale for most followers

Fix: Hybrid model
     Don't fan out for users with > N followers
     Pull their posts at read time instead
~~~

### Offset Pagination

~~~
Problem: Using OFFSET for feed pagination

  Page 100: SELECT ... OFFSET 2000 LIMIT 20
  → Database scans and discards 2000 rows
  → Gets slower with deeper pages
  → New posts cause duplicates/gaps

Fix: Cursor-based pagination
     Always paginate by (timestamp, id) pair
~~~

---

## 8. Key Takeaways

| # | Takeaway |
|---|----------|
| 1 | Fan-out on write for fast reads, fan-out on read for celebrities |
| 2 | Hybrid approach is what real systems use — push for regular users, pull for celebrities |
| 3 | Feed cache stores post IDs only — fetch full posts in batch |
| 4 | Cursor-based pagination prevents duplicates and gaps |
| 5 | Ranking transforms a feed from "latest" to "most relevant" |
| 6 | Real-time updates via WebSocket with "N new posts" indicator |
| 7 | Trim feed caches to bounded size (e.g., 800 items per user) |
| 8 | Measure feed latency at p99 — slow feeds kill engagement |

---

## 9. Practical Exercise

### Design Challenge

Design a feed system for a professional networking platform (like LinkedIn):

**Content types:** Text posts, articles, job changes, work anniversaries, shared links, polls

**Requirements:**
- 200 million active users, average 300 connections each
- 5 million new posts per day
- Feed must load in < 300ms at p95
- Mix of chronological and algorithmic ranking
- Sponsored content (ads) injected every 5th position
- "Seen" tracking — don't show the same post twice

**Discussion Questions:**
1. Fan-out on write, read, or hybrid? Justify with numbers.
2. How do you handle a company page with 10M followers posting a job?
3. What ranking signals would you use for a professional network vs a social network?
4. How do you inject ads without degrading feed load time?
5. How do you handle "seen" tracking across multiple devices?
