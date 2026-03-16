# Data Replication & Consistency: Architecture Guide

## Overview

| Attribute | Details |
|-----------|---------|
| Duration | 60 minutes |
| Level | Intermediate to Advanced |
| Prerequisites | Database fundamentals, Distributed Transactions session |

## Learning Objectives

- Understand why data replication is necessary and the trade-offs involved
- Compare single-leader, multi-leader, and leaderless replication strategies
- Reason about consistency models (strong, eventual, causal)
- Design systems that handle replication lag and conflict resolution
- Apply the right consistency model for different use cases

---

## 1. Why Replicate Data?

### The Three Reasons

~~~
1. High Availability
   Primary DB crashes → Replica takes over → No downtime
   
2. Read Scalability
   1 writer + 10 readers → 10x read throughput
   
3. Geographic Proximity
   User in Tokyo → reads from Tokyo replica (5ms)
                  → reads from US primary (200ms)
~~~

### The Fundamental Trade-off

~~~mermaid
flowchart LR
    subgraph tradeoff["You can't have all three"]
        FAST["Fast Writes"]
        CONSISTENT["Strong Consistency"]
        AVAILABLE["High Availability"]
    end
    
    FAST -.- note1["Sync replication is slow"]
    CONSISTENT -.- note2["Requires coordination"]
    AVAILABLE -.- note3["Partitions break consistency"]
~~~

~~~
Strong consistency + availability  → slow (synchronous replication)
Fast writes + availability         → eventual consistency (async replication)
Strong consistency + fast writes   → reduced availability during failures
~~~

---

## 2. Replication Strategies

### Single-Leader (Primary-Replica)

~~~mermaid
flowchart TB
    C1[Client Write] --> P[(Primary)]
    P -->|Replication Log| R1[(Replica 1)]
    P -->|Replication Log| R2[(Replica 2)]
    P -->|Replication Log| R3[(Replica 3)]
    
    C2[Client Read] --> R1
    C3[Client Read] --> R2
    C4[Client Read] --> R3
~~~

~~~
How it works:
  1. All writes go to the primary
  2. Primary writes to its local log
  3. Replication log sent to replicas
  4. Replicas apply changes in order

Sync vs Async replication:
┌─────────────────────────────────────────────────────┐
│ Synchronous:                                        │
│   Primary waits for replica ACK before confirming   │
│   ✅ No data loss on primary failure                │
│   ❌ Write latency = max(replica latencies)         │
│   ❌ One slow replica blocks all writes             │
│                                                     │
│ Asynchronous:                                       │
│   Primary confirms immediately, replicates later    │
│   ✅ Fast writes                                    │
│   ❌ Data loss if primary fails before replication  │
│   ❌ Replicas may serve stale data                  │
│                                                     │
│ Semi-synchronous (practical choice):                │
│   1 replica sync, rest async                        │
│   ✅ At least one replica always up-to-date         │
│   ✅ Reasonable write latency                       │
└─────────────────────────────────────────────────────┘
~~~

### Multi-Leader

~~~mermaid
flowchart LR
    subgraph DC1["Datacenter 1"]
        L1[(Leader 1)]
    end
    subgraph DC2["Datacenter 2"]
        L2[(Leader 2)]
    end
    subgraph DC3["Datacenter 3"]
        L3[(Leader 3)]
    end
    
    L1 <-->|Async Replication| L2
    L2 <-->|Async Replication| L3
    L1 <-->|Async Replication| L3
    
    C1[Client US] --> L1
    C2[Client EU] --> L2
    C3[Client Asia] --> L3
~~~

~~~
Use cases:
  - Multi-datacenter deployments
  - Collaborative editing (Google Docs)
  - Offline-capable apps (mobile, laptop)

The big problem: WRITE CONFLICTS
  User A updates row X in DC1 → name = "Alice"
  User B updates row X in DC2 → name = "Bob"
  Both succeed locally → conflict when replicating
~~~

### Leaderless (Dynamo-style)

~~~mermaid
flowchart TB
    C[Client Write] -->|Write to 3 nodes| N1[(Node 1 ✓)]
    C -->|Write to 3 nodes| N2[(Node 2 ✓)]
    C -->|Write to 3 nodes| N3[(Node 3 ✗ down)]
    
    C2[Client Read] -->|Read from 3 nodes| N1
    C2 -->|Read from 3 nodes| N2
    C2 -->|Read from 3 nodes| N3
~~~

~~~
Quorum: W + R > N

  N = 3 nodes total
  W = 2 (write to at least 2)
  R = 2 (read from at least 2)
  
  W + R = 4 > 3 → guaranteed overlap
  At least one node has the latest value

Tunable consistency:
  W=3, R=1 → fast reads, slow writes, strong consistency
  W=1, R=3 → fast writes, slow reads, strong consistency
  W=1, R=1 → fast everything, weak consistency (no overlap)
~~~

### Strategy Comparison

| Aspect | Single-Leader | Multi-Leader | Leaderless |
|--------|--------------|-------------|------------|
| Write throughput | Limited by leader | High (local writes) | High (any node) |
| Read scalability | Good (add replicas) | Good | Good |
| Consistency | Strong possible | Eventual | Tunable |
| Conflict handling | No conflicts | Must resolve | Must resolve |
| Failover | Promote replica | Other leaders continue | Quorum continues |
| Complexity | Low | High | Medium |
| Examples | PostgreSQL, MySQL | CockroachDB, Cassandra (multi-DC) | DynamoDB, Cassandra |

---

## 3. Consistency Models

### Spectrum of Consistency

~~~
Strong ◄──────────────────────────────────────► Weak

Linearizable → Sequential → Causal → Eventual
     │              │           │          │
  "Behaves like    "All see   "Cause     "Eventually
   single copy"    same order" before     all agree"
                               effect"
~~~

### Eventual Consistency in Practice

~~~mermaid
sequenceDiagram
    participant U as User
    participant P as Primary
    participant R as Replica
    
    U->>P: UPDATE profile SET name='Alice'
    P-->>U: OK (confirmed)
    
    Note over P,R: Replication lag: 500ms
    
    U->>R: SELECT name FROM profile
    R-->>U: name = 'Bob' (stale!)
    
    Note over P,R: 500ms later...
    P->>R: Replicate: name='Alice'
    
    U->>R: SELECT name FROM profile
    R-->>U: name = 'Alice' (consistent)
~~~

### Read-Your-Own-Writes Consistency

~~~
Problem: User updates profile, refreshes page, sees old data

Solutions:
┌─────────────────────────────────────────────────────┐
│ 1. Read from primary after own writes               │
│    → Track "last write timestamp" per user           │
│    → If recent write, route read to primary          │
│                                                     │
│ 2. Sticky sessions                                  │
│    → Route user to same replica                     │
│    → Breaks if replica fails                        │
│                                                     │
│ 3. Client-side versioning                           │
│    → Client sends "I last saw version X"            │
│    → Replica waits until it has version X           │
└─────────────────────────────────────────────────────┘
~~~

### Monotonic Reads

~~~
Problem: User sees newer data, then older data on refresh

  Request 1 → Replica A (up-to-date)    → sees 5 comments
  Request 2 → Replica B (lagging)       → sees 3 comments
  User thinks: "comments disappeared!"

Solution: Route same user to same replica (sticky sessions)
          Or: track replica version, only read from >= last seen
~~~

---

## 4. Conflict Resolution

### Last Writer Wins (LWW)

~~~
Timestamp-based: highest timestamp wins

  DC1: SET x = "A" at t=100
  DC2: SET x = "B" at t=101
  
  Resolution: x = "B" (t=101 > t=100)

Problems:
  - Clock skew between nodes
  - Silently drops writes
  - Not suitable when all writes matter
~~~

### Merge / Custom Resolution

~~~
Application-level merge:

  Shopping cart example:
  DC1: cart = {apple, banana}
  DC2: cart = {apple, cherry}
  
  LWW: one cart wins, items lost
  Merge: cart = {apple, banana, cherry} (union)

  Counter example:
  DC1: counter = 5 (was 3, added 2)
  DC2: counter = 4 (was 3, added 1)
  
  LWW: counter = 5 or 4 (wrong either way)
  CRDT: counter = 6 (3 + 2 + 1, correct)
~~~

### CRDTs (Conflict-free Replicated Data Types)

~~~
Data structures that automatically merge without conflicts:

  G-Counter: grow-only counter
    Node A: {A:3, B:0}
    Node B: {A:0, B:2}
    Merge:  {A:3, B:2} → total = 5

  OR-Set: observed-remove set
    Add and remove operations merge correctly
    Used in collaborative editing

  LWW-Register: last-writer-wins register
    Simple but lossy

Used by: Riak, Redis CRDT, Automerge, Yjs
~~~

---

## 5. Replication Lag Patterns

### Common Lag Scenarios

~~~mermaid
flowchart TB
    subgraph scenarios["Replication Lag Impact"]
        S1["User updates profile<br/>→ reads stale data<br/>(read-your-writes)"]
        S2["User sees comment<br/>→ refreshes, it's gone<br/>(monotonic reads)"]
        S3["User sees reply<br/>→ but not original post<br/>(causal consistency)"]
    end
~~~

### Measuring and Monitoring

~~~
Key metrics:
├── Replication lag (seconds behind primary)
├── Lag percentiles (p50, p95, p99)
├── Lag spikes (sudden increases)
└── Replica health (connected, applying, error)

Alert thresholds (example):
├── Warning: lag > 5 seconds
├── Critical: lag > 30 seconds
├── Emergency: lag > 5 minutes (data loss risk)

Monitoring tools:
├── PostgreSQL: pg_stat_replication
├── MySQL: SHOW SLAVE STATUS (Seconds_Behind_Master)
├── MongoDB: rs.printReplicationInfo()
└── Custom: compare primary vs replica timestamps
~~~

---

## 6. Failover

### Automatic Failover Process

~~~mermaid
sequenceDiagram
    participant P as Primary
    participant R1 as Replica 1
    participant R2 as Replica 2
    participant M as Monitor
    
    Note over P: Primary crashes
    P->>P: ❌ DOWN
    
    M->>P: Health check failed
    M->>P: Health check failed (2nd)
    M->>P: Health check failed (3rd)
    
    Note over M: Primary declared dead
    
    M->>R1: You are the new primary
    R1->>R1: Promote to primary
    M->>R2: New primary is R1
    R2->>R1: Replicate from R1
    
    Note over R1: Accepting writes
~~~

### Failover Pitfalls

~~~
1. Split Brain
   Both old and new primary accept writes
   → Data divergence, corruption
   Solution: Fencing (STONITH), consensus-based election

2. Data Loss
   Async replica promoted, missing recent writes
   → Those writes are lost forever
   Solution: Semi-sync replication, or accept the risk

3. Stale Reads During Failover
   Clients still reading from old primary
   → Serving stale or inconsistent data
   Solution: DNS TTL, connection draining

4. Cascading Failures
   Failover triggers load spike on new primary
   → New primary also fails
   Solution: Capacity planning, gradual traffic shift
~~~

---

## 7. Real-World Patterns

### Read Replicas for Scale

~~~
E-commerce product catalog:
  - 1 primary: handles writes (admin updates products)
  - 10 replicas: handle reads (customers browsing)
  - Acceptable lag: 1-2 seconds (product info not time-critical)
  
Social media timeline:
  - 1 primary: handles posts, likes, comments
  - Regional replicas: serve feeds per geography
  - Acceptable lag: seconds (users tolerate slight delay)
  
Financial ledger:
  - 1 primary: all transactions
  - Sync replica: hot standby (zero data loss)
  - Async replicas: reporting and analytics
  - Acceptable lag for reads: 0 (must read from primary)
~~~

### Multi-Region Deployment

~~~mermaid
flowchart TB
    subgraph US["US-East (Primary)"]
        P[(Primary DB)]
    end
    subgraph EU["EU-West"]
        R1[(Read Replica)]
    end
    subgraph ASIA["AP-Southeast"]
        R2[(Read Replica)]
    end
    
    P -->|Async ~100ms| R1
    P -->|Async ~200ms| R2
    
    US_USER[US Users] --> P
    EU_USER[EU Users] -->|Reads| R1
    EU_USER -->|Writes| P
    ASIA_USER[Asia Users] -->|Reads| R2
    ASIA_USER -->|Writes| P
~~~

---

## 8. Key Takeaways

| #   | Takeaway                                                                       |
| --- | ------------------------------------------------------------------------------ |
| 1   | Replication serves availability, read scale, and geographic proximity          |
| 2   | Synchronous replication = strong consistency but slow writes                   |
| 3   | Asynchronous replication = fast writes but risk of data loss                   |
| 4   | Single-leader is simplest; multi-leader and leaderless add conflict complexity |
| 5   | Eventual consistency is fine for most reads; know when it's not                |
| 6   | Read-your-own-writes is the most common consistency requirement                |
| 7   | Conflict resolution strategy must match your domain (LWW vs merge vs CRDT)     |
| 8   | Failover is where theory meets reality — test it regularly                     |

---

## 9. Practical Exercise

### Design Challenge

Design a replication strategy for a global e-commerce platform:

**Requirements:**
- Users in US, EU, and Asia
- Product catalog: millions of items, updated by sellers
- Shopping cart: per-user, updated frequently
- Order placement: must not lose data, must not double-charge
- Product reviews: eventual consistency acceptable

**Discussion Questions:**
1. Which replication strategy for each data type (catalog, cart, orders, reviews)?
2. What consistency model does each require?
3. How do you handle a user in Asia adding to cart while the US primary is down?
4. What's your failover strategy for the order database?
5. How do you monitor replication lag and alert on problems?
