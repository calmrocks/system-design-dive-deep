
# Data Replication & Consistency: Architecture Guide

## Overview

| Attribute     | Details                                                 |
| ------------- | ------------------------------------------------------- |
| Duration      | 90 minutes                                              |
| Level         | Intermediate to Advanced                                |
| Prerequisites | Database fundamentals, Distributed Transactions session |

## Learning Objectives

- Understand why data replication is necessary and the trade-offs involved
- Explain how replication logs work at a mechanical level
- Compare single-leader, multi-leader, and leaderless replication strategies
- Reason about consistency models (strong, eventual, causal)
- Design systems that handle replication lag and conflict resolution
- Understand failover mechanisms and consensus-based leader election
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

### Replication Is Not Backup

~~~
Replication:
  - Real-time copy of data on another node
  - Serves live traffic (reads, failover)
  - Replicates deletes and corruption too!
  - If you DROP TABLE on primary, replicas drop it too

Backup:
  - Point-in-time snapshot stored separately
  - Used for disaster recovery
  - Survives accidental deletes and corruption
  - Not serving live traffic

You need both.
~~~

### Replication vs Partitioning

~~~
Replication: same data on multiple nodes (redundancy)
Partitioning: different data on different nodes (scalability)

Typically combined:
  Each partition has its own leader + replicas

  Partition A: [Leader on Node1, Replica on Node2, Node3]
  Partition B: [Leader on Node2, Replica on Node3, Node1]
  Partition C: [Leader on Node3, Replica on Node1, Node2]
~~~

### The Fundamental Trade-off: CAP and PACELC

~~~mermaid
flowchart LR
    subgraph cap["CAP Theorem (Brewer, 2000)"]
        C["Consistency"]
        A["Availability"]
        P["Partition Tolerance"]
    end
~~~

~~~
CAP Theorem:
  In the presence of a network Partition, you must choose between:
    Consistency (every read gets the most recent write)
    Availability (every request gets a response)

  It's NOT "pick 2 of 3."
  It's "when a partition happens, do you sacrifice C or A?"

  CP systems: refuse to serve stale data during partition
    → return error or timeout
    → e.g., HBase, MongoDB (default), etcd, ZooKeeper

  AP systems: serve potentially stale data during partition
    → remain available
    → e.g., DynamoDB, Cassandra, CouchDB

PACELC extends CAP:
  If Partition → choose Availability or Consistency
  Else (normal operation) → choose Latency or Consistency

  This explains the day-to-day trade-off:
    Strong consistency + availability  → slow (synchronous replication)
    Fast writes + availability         → eventual consistency (async)
    Strong consistency + fast writes   → reduced availability during failures
~~~

---

## 2. Replication Logs

Before comparing strategies, it's important to understand _how_ data physically moves from primary to replica.

### Log Implementation Methods

~~~
┌─────────────────────────────────────────────────────────┐
│ Statement-based                                         │
│   Replicate SQL statements: INSERT INTO t VALUES (1)    │
│   ❌ Non-deterministic functions (NOW(), RAND())        │
│   ❌ Side effects, trigger ordering                     │
│   Largely abandoned                                     │
│                                                         │
│ Write-Ahead Log (WAL) shipping                          │
│   Ship the physical storage engine log                  │
│   ✅ Exact byte-level replication                       │
│   ❌ Coupled to storage engine version                  │
│   ❌ Can't replicate across different DB versions       │
│   Used by: PostgreSQL streaming replication              │
│                                                         │
│ Logical (row-based) log                                 │
│   Replicate logical changes: "row X changed to Y"       │
│   ✅ Decoupled from storage engine                      │
│   ✅ Cross-version, cross-engine compatible             │
│   ✅ Enables Change Data Capture (CDC)                  │
│   Used by: MySQL binlog (row mode), PostgreSQL logical  │
│                                                         │
│ Trigger-based                                           │
│   Application-level: triggers write to changelog table  │
│   ✅ Maximum flexibility                                │
│   ❌ High overhead, fragile                             │
└─────────────────────────────────────────────────────────┘
~~~

---

## 3. Replication Strategies

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

#### Multi-Leader Topologies

~~~
Circular:     A → B → C → A
Star:         A ← B → C    (one central hub)
All-to-all:   A ↔ B ↔ C ↔ A

┌──────────────────────────────────────────────────┐
│ Circular / Star:                                 │
│   ❌ Single point of failure breaks replication  │
│   ❌ Must tag writes to prevent infinite loops   │
│                                                  │
│ All-to-all:                                      │
│   ✅ More fault-tolerant                         │
│   ❌ Causality issues: updates may arrive        │
│      out of order at different nodes             │
│   ❌ More network connections to manage          │
└──────────────────────────────────────────────────┘
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

#### How Stale Nodes Catch Up

~~~
1. Read Repair
   During a quorum read, client detects stale node
   → writes the newer value back to the stale node
   ✅ Lazy, no background overhead
   ❌ Only fixes data that's actually read
   ❌ Rarely-read data stays stale forever

2. Anti-Entropy (background repair)
   Background process compares data across nodes
   → uses Merkle trees to efficiently find differences
   → copies missing data to stale nodes
   ✅ Catches everything eventually
   ❌ Significant background I/O
   ❌ Not immediate

3. Hinted Handoff
   Node A is down during a write → write goes to Node D
   Node D holds a "hint": "this belongs to Node A"
   When Node A recovers → Node D sends the data
   ✅ Fast recovery
   ❌ Node D takes on temporary extra responsibility

Sloppy Quorums:
   When not enough "home" nodes are reachable,
   accept writes on non-home nodes (hinted handoff).
   ✅ Higher write availability
   ❌ Quorum guarantee broken — reads may miss latest write
   DynamoDB uses sloppy quorums by default.
~~~

### Strategy Comparison

| Aspect           | Single-Leader             | Multi-Leader                     | Leaderless              |
| ---------------- | ------------------------- | -------------------------------- | ----------------------- |
| Write throughput  | Limited by leader         | High (local writes)              | High (any node)         |
| Read scalability  | Good (add replicas)       | Good                             | Good                    |
| Consistency       | Strong possible           | Eventual                         | Tunable                 |
| Conflict handling | No conflicts              | Must resolve                     | Must resolve            |
| Failover          | Promote replica           | Other leaders continue           | Quorum continues        |
| Complexity        | Low                       | High                             | Medium                  |
| Examples          | PostgreSQL, MySQL, MongoDB | MySQL multi-source, CouchDB      | DynamoDB, Cassandra     |

> **Note on distributed SQL databases:** CockroachDB, YugabyteDB, TiDB, and Spanner use
> consensus (Raft/Paxos) per shard. They provide strong consistency and may look like
> multi-leader systems, but they are fundamentally consensus-based. They belong in their
> own category.

---

## 4. Consistency Models

### Spectrum of Consistency

~~~
Strong ◄──────────────────────────────────────► Weak

Linearizable → Sequential → Causal → Eventual
     │              │           │          │
  "Behaves like    "All see   "Cause     "Eventually
   single copy"    same order" before     all agree"
                               effect"
~~~

### Linearizability vs Serializability

~~~
These terms are frequently confused:

Linearizability (replication / single-object concern):
  Every read returns the most recent write.
  As if there's a single copy of the data.
  Scope: single object (a register, a row).

Serializability (transaction / multi-object concern):
  Transactions execute as if in some serial order.
  Scope: multiple objects, multiple operations.

Strict Serializability = both combined.
  (Spanner, CockroachDB, FoundationDB)
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

### Causal Consistency

~~~
Problem: User sees a reply but not the original post

  Post:  "What's for lunch?"  written at t=1, replicated slowly
  Reply: "Pizza!"             written at t=2, replicated fast

  Replica shows: "Pizza!" but no original post → confusing

Causal consistency ensures: if event B depends on event A,
  every node sees A before B.

Mechanisms:
┌─────────────────────────────────────────────────────┐
│ Lamport timestamps:                                 │
│   Logical clock that increments on every operation  │
│   Gives total order compatible with causality       │
│   ❌ Can't distinguish concurrent from ordered      │
│                                                     │
│ Vector clocks:                                      │
│   Each node tracks its own counter + observed       │
│   counters from other nodes                         │
│   ✅ Can detect concurrent vs causally ordered      │
│   ❌ Grows with number of nodes                     │
│                                                     │
│ Causal broadcast protocols:                         │
│   Hold back delivery of message B until all         │
│   messages that B depends on have been delivered    │
└─────────────────────────────────────────────────────┘
~~~

### Monitoring Replication Lag

~~~
Key metrics:
├── Replication lag (seconds behind primary)
├── Lag percentiles (p50, p95, p99)
├── Lag spikes (sudden increases)
└── Replica health (connected, applying, error)

Alert thresholds (example):
├── Warning:   lag > 5 seconds
├── Critical:  lag > 30 seconds
├── Emergency: lag > 5 minutes (data loss risk)

Monitoring tools:
├── PostgreSQL: pg_stat_replication
├── MySQL:      SHOW REPLICA STATUS (Seconds_Behind_Source)
├── MongoDB:    rs.printReplicationInfo()
└── Custom:     compare primary vs replica timestamps
~~~

---

## 5. Conflict Detection & Resolution

### Detecting Conflicts with Version Vectors

Before resolving conflicts, the system must **detect** them.

~~~
Each node maintains a version per node:

  Node A writes x:  version = {A:1}
  Node B writes x:  version = {B:1}

  When replicating:
    {A:1} vs {B:1} → neither dominates → CONFLICT
    {A:2, B:1} vs {A:1, B:1} → first dominates → no conflict

  Dominance rule:
    V1 dominates V2 if every component of V1 >= V2
    and at least one is strictly greater.

  If neither dominates → concurrent writes → conflict detected.

  This is how Riak and DynamoDB detect conflicts
  before applying a resolution strategy.
~~~

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

## 6. Failover & Leader Election

### Manual vs Automatic Failover

~~~
Manual failover:
  - Operator decides when and how to promote a replica
  - Safer: human judgment avoids false positives
  - Slower: depends on operator response time
  - Used by: many financial systems, conservative setups

Automatic failover:
  - System detects failure and promotes replica automatically
  - Faster: seconds instead of minutes
  - Riskier: can trigger on transient issues
  - Used by: most cloud-managed databases, HA setups
~~~

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

### Consensus and Leader Election

~~~
Who decides the new leader? The Monitor.
Who monitors the Monitor? → This is the consensus problem.

Solutions:
┌────────────────────────────────────────────────────┐
│ External coordination service:                     │
│   ZooKeeper, etcd, Consul                          │
│   → Multiple monitor nodes, majority vote          │
│   → Uses Raft/ZAB consensus internally             │
│                                                    │
│ Built-in consensus:                                │
│   PostgreSQL Patroni (uses etcd/ZooKeeper)         │
│   MySQL Group Replication (Paxos-based)            │
│   MongoDB replica sets (Raft-like protocol)        │
│   CockroachDB (Raft per range)                     │
└────────────────────────────────────────────────────┘

Why consensus is hard:
  - Network delays can't be distinguished from crashes
  - Must avoid split-brain (two leaders)
  - FLP impossibility: no deterministic async consensus
    guaranteed to terminate
  - Practical algorithms (Raft, Paxos) use timeouts
    and leader leases
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

### Related Pattern: Change Data Capture (CDC)

The same replication log that powers replicas (WAL, binlog) can also feed external systems like search indexes, caches, and data warehouses.

~~~
DB Primary → Replication Log → DB Replicas       (this guide)
                             → Kafka/Search/Cache (CDC - separate topic)

Tools: Debezium, AWS DMS, PostgreSQL logical decoding
~~~

> CDC is a **data integration** concern rather than a replication/consistency concern. It is covered separately in the Data Integration guide.

---

## 8. Key Takeaways

| #   | Takeaway                                                                       |
| --- | ------------------------------------------------------------------------------ |
| 1   | Replication serves availability, read scale, and geographic proximity          |
| 2   | Replication is not backup — you need both                                      |
| 3   | Synchronous replication = strong consistency but slow writes                   |
| 4   | Asynchronous replication = fast writes but risk of data loss                   |
| 5   | Single-leader is simplest; multi-leader and leaderless add conflict complexity |
| 6   | CAP: during a partition, choose consistency or availability — not both         |
| 7   | Eventual consistency is fine for most reads; know when it's not                |
| 8   | Read-your-own-writes is the most common consistency requirement                |
| 9   | Detect conflicts first (version vectors), then resolve (LWW, merge, CRDT)     |
| 10  | Failover is where theory meets reality — test it regularly                     |
| 11  | Leader election requires consensus; don't hand-roll it                         |

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

**Hints:**

~~~
Think about each data type separately:

  Product catalog:
    - Read-heavy, write-light
    - Stale data for a few seconds is acceptable
    - Consider: single-leader + read replicas per region

  Shopping cart:
    - Per-user, frequent updates
    - User expects to see their own changes immediately
    - What if the user is offline or primary is unreachable?
    - Consider: what conflict strategy if multi-leader?

  Orders:
    - Zero tolerance for data loss or duplication
    - Must be strongly consistent
    - Consider: synchronous replication, consensus-based

  Reviews:
    - Eventual consistency is fine
    - High write volume
    - Consider: async replication, leaderless
~~~

---

## 10. References

| Resource                                          | Relevance                                   |
| ------------------------------------------------- | ------------------------------------------- |
| *Designing Data-Intensive Applications*, Ch. 5    | Comprehensive coverage of replication        |
| Dynamo: Amazon's Highly Available Key-value Store | Leaderless replication, quorums, hinted handoff |
| In Search of an Understandable Consensus Algorithm (Raft paper) | Leader election, consensus        |
| *CAP Twelve Years Later* (Eric Brewer, 2012)      | Clarification of CAP misconceptions          |
| CRDTs: Consistency without consensus (Shapiro et al.) | Conflict-free data structures            |
