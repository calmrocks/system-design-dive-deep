
# Data Replication & Consistency: Architecture Guide

## Overview

| Attribute     | Details                                                 |
| ------------- | ------------------------------------------------------- |
| Duration      | 60 minutes                                              |
| Level         | Intermediate to Advanced                                |
| Prerequisites | Database fundamentals, Distributed Transactions session |

## Learning Objectives

- Understand why replication is necessary and the trade-offs involved
- Compare single-leader, multi-leader, and leaderless strategies
- Reason about consistency models and conflict resolution
- Design systems that handle replication lag and failover

---

## 1. Why Replicate Data?

~~~
1. High Availability   → Replica takes over when primary crashes
2. Read Scalability    → Spread reads across multiple replicas
3. Geographic Proximity → Serve reads from nearby replica (5ms vs 200ms)

⚠️ Replication ≠ Backup
   Replication copies deletes and corruption too.
   You need both replication AND backups.
~~~

### CAP Theorem

~~~
During a network partition, choose one:
  CP → Consistency: refuse to serve stale data (e.g., etcd, HBase)
  AP → Availability: serve possibly stale data (e.g., DynamoDB, Cassandra)

In normal operation (PACELC extension):
  Strong consistency → higher latency (sync replication)
  Low latency        → weaker consistency (async replication)
~~~

---

## 2. How Replication Works

~~~
Replication Log Methods:
  WAL shipping     → physical byte-level log (PostgreSQL)
  Logical/row-based → "row X changed to Y" (MySQL binlog)
  Statement-based  → replicate SQL statements (largely abandoned)

Sync vs Async:
  Synchronous    → no data loss, slow writes, one slow replica blocks all
  Asynchronous   → fast writes, possible data loss, stale reads
  Semi-synchronous → 1 sync + rest async (practical middle ground)
~~~

---

## 3. Replication Strategies

### Single-Leader

~~~
All writes → Primary → Replication log → Replicas → Serve reads

✅ Simple, no conflicts
❌ Write throughput limited by single leader
Examples: PostgreSQL, MySQL, MongoDB
~~~

### Multi-Leader

~~~
Each datacenter has its own leader, async replication between them.

✅ Low-latency local writes, survives DC failure
❌ Write conflicts (same row updated in two DCs)

Topologies: circular, star, all-to-all (most fault-tolerant)
Examples: MySQL multi-source, CouchDB
~~~

### Leaderless (Dynamo-style)

~~~
Write to W nodes, read from R nodes. If W + R > N → guaranteed overlap.

  N=3, W=2, R=2 → at least one node has latest value

Stale node recovery:
  Read repair     → fix stale node during reads
  Anti-entropy    → background Merkle tree comparison
  Hinted handoff  → temporary node holds data for downed node

Examples: DynamoDB, Cassandra
~~~

### Comparison

| Aspect      | Single-Leader    | Multi-Leader        | Leaderless       |
| ----------- | ---------------- | ------------------- | ---------------- |
| Consistency | Strong possible  | Eventual            | Tunable          |
| Conflicts   | None             | Must resolve        | Must resolve     |
| Complexity  | Low              | High                | Medium           |
| Failover    | Promote replica  | Other leaders continue | Quorum continues |

> **Note:** Distributed SQL databases (CockroachDB, Spanner, TiDB) use consensus per shard.
> They look like multi-leader but provide strong consistency — a separate category.

---

## 4. Consistency Models

~~~
Strong ◄──────────────────────────────► Weak
Linearizable → Causal → Eventual
~~~

### Common Replication Lag Problems

~~~
Read-your-writes:  User updates profile, refreshes, sees old data
  → Route reads to primary after own writes, or use sticky sessions

Monotonic reads:   User sees 5 comments, refreshes, sees 3
  → Route same user to same replica

Causal consistency: User sees a reply but not the original post
  → Use vector clocks / causal broadcast to preserve ordering
~~~

### Linearizability vs Serializability

~~~
Linearizability → single-object: "behaves like one copy" (replication concern)
Serializability → multi-object: "transactions appear serial" (transaction concern)
Strict serializability = both (Spanner, CockroachDB)
~~~

---

## 5. Conflict Resolution

~~~
Detection: Version vectors
  {A:1} vs {B:1} → neither dominates → conflict
  {A:2, B:1} vs {A:1, B:1} → first dominates → no conflict

Resolution strategies:
  LWW (Last Writer Wins) → simple but silently drops writes
  Merge                  → application-level union (e.g., shopping cart)
  CRDTs                  → data structures that auto-merge (counters, sets)
                           Used by: Riak, Redis CRDT, Automerge
~~~

---

## 6. Failover

~~~
Process: detect failure → elect new leader → redirect traffic

Pitfalls:
  Split brain    → two primaries accept writes → use fencing / consensus
  Data loss      → async replica missing recent writes → use semi-sync
  Cascading fail → new primary overloaded → capacity planning

Leader election: don't hand-roll it
  Use: ZooKeeper, etcd, Consul, or built-in consensus
  (PostgreSQL Patroni, MySQL Group Replication, MongoDB replica sets)
~~~

---

## 7. Real-World Patterns

~~~
Product catalog:  single-leader + read replicas, 1-2s lag acceptable
Shopping cart:    consider multi-leader/leaderless for offline support
Order processing: sync replication, zero data loss, read from primary
Reviews/feeds:    async replication, eventual consistency fine
~~~

### Related: Change Data Capture (CDC)

~~~
Same replication log can feed external systems (Kafka, search, cache).
Tools: Debezium, AWS DMS. Separate topic — see Data Integration guide.
~~~

---

## 8. Key Takeaways

| # | Takeaway |
|---|----------|
| 1 | Replication serves availability, read scale, and geo-proximity |
| 2 | CAP: during partition, choose consistency or availability |
| 3 | Single-leader is simplest; multi-leader/leaderless add conflict complexity |
| 4 | Detect conflicts (version vectors) then resolve (LWW, merge, CRDT) |
| 5 | Failover is where theory meets reality — test it regularly |

---

## 9. Exercise

Design replication for a global e-commerce platform (US, EU, Asia):

1. Which strategy for each: catalog, cart, orders, reviews?
2. What consistency model does each require?
3. How do you handle cart updates when the primary is down?
4. What's your failover strategy for orders?

---

## 10. References

- *Designing Data-Intensive Applications*, Chapter 5
- Dynamo paper (leaderless, quorums)
- Raft paper (consensus, leader election)
- *CAP Twelve Years Later* (Brewer, 2012)
