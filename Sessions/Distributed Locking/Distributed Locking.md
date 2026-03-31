# Distributed Locking: Architecture Guide

## Overview

| Attribute | Details |
|-----------|---------|
| Duration | 60 minutes |
| Level | Intermediate to Advanced |
| Prerequisites | Data Replication & Consistency session, Cache session |

## Learning Objectives

- Understand why distributed locking is needed and when to use it
- Compare lock implementations (database, Redis, ZooKeeper)
- Design systems that handle lock failures, expiry, and contention
- Reason about correctness vs performance trade-offs in locking
- Apply distributed locking patterns to real-world use cases

---

## 1. Why Distributed Locking?

### The Problem

~~~
Single process:
  mutex.lock()
  balance -= 100
  mutex.unlock()
  → Simple, correct

Multiple processes on one machine:
  File lock or OS mutex
  → Still manageable

Multiple processes across machines:
  Process A (Server 1): read balance = 500, deduct 100, write 400
  Process B (Server 2): read balance = 500, deduct 100, write 400
  → Both succeed, but only 100 deducted instead of 200
  → Need coordination across network boundary
~~~

### Common Use Cases

~~~
1. Preventing double-processing
   → Two workers pick up the same job from a queue
   
2. Resource reservation
   → Two users book the last seat on a flight
   
3. Leader election
   → Only one instance runs the scheduled job
   
4. Rate-limited external API calls
   → Only N concurrent requests to a third-party
   
5. Distributed cron
   → Ensure a periodic task runs exactly once across a cluster
~~~

---

## 2. Lock Implementations

### Database Lock (Pessimistic)

~~~mermaid
sequenceDiagram
    participant A as Service A
    participant DB as Database
    participant B as Service B
    
    A->>DB: INSERT INTO locks (resource_id, owner, expires_at)
    DB-->>A: OK (lock acquired)
    
    B->>DB: INSERT INTO locks (resource_id, owner, expires_at)
    DB-->>B: UNIQUE CONSTRAINT VIOLATION (lock denied)
    
    A->>A: Do work...
    A->>DB: DELETE FROM locks WHERE resource_id = X AND owner = A
    DB-->>A: OK (lock released)
~~~

~~~sql
-- Acquire lock
INSERT INTO locks (resource_id, owner_id, acquired_at, expires_at)
VALUES ('order-123', 'worker-A', NOW(), NOW() + INTERVAL '30 seconds')
ON CONFLICT (resource_id) DO NOTHING;

-- Check if we got it
-- rows_affected = 1 → acquired
-- rows_affected = 0 → someone else holds it

-- Release lock
DELETE FROM locks 
WHERE resource_id = 'order-123' AND owner_id = 'worker-A';

-- Cleanup expired locks (background job)
DELETE FROM locks WHERE expires_at < NOW();
~~~

### Redis Lock (SET NX)

~~~mermaid
sequenceDiagram
    participant A as Service A
    participant R as Redis
    participant B as Service B
    
    A->>R: SET lock:order-123 workerA NX EX 30
    R-->>A: OK (acquired)
    
    B->>R: SET lock:order-123 workerB NX EX 30
    R-->>B: nil (denied)
    
    A->>A: Do work...
    A->>R: DEL lock:order-123 (if value == workerA)
    R-->>A: OK
~~~

~~~
SET lock:order-123 <unique-token> NX EX 30

NX  = only set if Not eXists
EX  = expire after 30 seconds
<unique-token> = ensures only the owner can release

Release (Lua script for atomicity):
  if redis.call("get", KEYS[1]) == ARGV[1] then
    return redis.call("del", KEYS[1])
  else
    return 0
  end
~~~

### ZooKeeper / etcd Lock

~~~mermaid
sequenceDiagram
    participant A as Service A
    participant ZK as ZooKeeper
    participant B as Service B
    
    A->>ZK: Create /locks/order-123/lock-0001 (ephemeral sequential)
    ZK-->>A: Created
    A->>ZK: Get children of /locks/order-123
    ZK-->>A: [lock-0001] → I'm lowest, lock acquired
    
    B->>ZK: Create /locks/order-123/lock-0002 (ephemeral sequential)
    ZK-->>B: Created
    B->>ZK: Get children of /locks/order-123
    ZK-->>B: [lock-0001, lock-0002] → Not lowest, watch lock-0001
    
    Note over A: Do work, then delete node
    A->>ZK: Delete /locks/order-123/lock-0001
    ZK->>B: Watch triggered: lock-0001 deleted
    B->>ZK: Get children → [lock-0002] → I'm lowest, lock acquired
~~~

~~~
Ephemeral nodes:
  - Auto-deleted when session ends (client crashes)
  - No stale locks from dead processes

Sequential nodes:
  - Fair ordering (FIFO queue)
  - No thundering herd (each waits on predecessor only)
~~~

### Implementation Comparison

| Aspect | Database | Redis | ZooKeeper/etcd |
|--------|----------|-------|----------------|
| Latency | ~5-10ms | ~1ms | ~5ms |
| Durability | Strong (ACID) | Weak (async replication) | Strong (consensus) |
| Auto-expiry | Manual cleanup | Built-in TTL | Ephemeral nodes |
| Fairness | No ordering | No ordering | FIFO via sequential |
| Complexity | Low | Low | Medium |
| Already have it? | Probably yes | Often yes | Dedicated infra |
| Correctness | High | Medium (see Redlock) | High |

---

## 3. The Redlock Debate

### Single Redis Lock Problem

~~~
Timeline:
  t=0   Service A acquires lock on Redis primary
  t=1   Redis primary crashes BEFORE replicating to replica
  t=2   Replica promoted to primary (no lock data)
  t=3   Service B acquires "same" lock on new primary
  t=4   Both A and B hold the lock → VIOLATION
~~~

### Redlock Algorithm

~~~mermaid
flowchart TB
    C[Client] -->|1. SET NX| R1[Redis 1]
    C -->|2. SET NX| R2[Redis 2]
    C -->|3. SET NX| R3[Redis 3]
    C -->|4. SET NX| R4[Redis 4]
    C -->|5. SET NX| R5[Redis 5]
    
    R1 -->|OK| C
    R2 -->|OK| C
    R3 -->|OK| C
    R4 -->|FAIL| C
    R5 -->|OK| C
    
    C --> CHECK{"Got lock on<br/>majority (≥3/5)?<br/>Within time limit?"}
    CHECK -->|Yes| ACQUIRED[Lock Acquired]
    CHECK -->|No| RELEASE[Release all & retry]
~~~

~~~
Redlock steps:
  1. Get current time
  2. Try to acquire lock on N independent Redis instances
  3. Lock acquired if:
     - Got lock on majority (N/2 + 1)
     - Total acquisition time < lock TTL
  4. Effective TTL = original TTL - acquisition time
  5. If failed, release all locks and retry after random delay
~~~

### The Criticism (Martin Kleppmann vs Antirez)

~~~
Kleppmann's argument:
  "Redlock is not safe for correctness-critical locks"
  
  Problem: GC pause or clock jump during lock hold
  
  t=0   Client A acquires Redlock (TTL=30s)
  t=0   Client A enters long GC pause...
  t=31  Lock expires on all Redis nodes
  t=31  Client B acquires Redlock
  t=32  Client A wakes from GC, thinks it still has lock
  t=32  Both clients operate on shared resource
  
Antirez's response:
  "Use lock extension (watchdog) to prevent expiry"
  "GC pauses affect any distributed system"

Practical takeaway:
  ┌─────────────────────────────────────────────────┐
  │ For efficiency (avoid duplicate work):          │
  │   Single Redis lock is fine                     │
  │                                                 │
  │ For correctness (must not violate invariant):   │
  │   Use fencing tokens + consensus system         │
  │   (ZooKeeper, etcd, or database)                │
  └─────────────────────────────────────────────────┘
~~~

---

## 4. Fencing Tokens

### The Problem Without Fencing

~~~mermaid
sequenceDiagram
    participant A as Client A
    participant LS as Lock Service
    participant S as Storage
    
    A->>LS: Acquire lock
    LS-->>A: Lock granted
    
    Note over A: Long GC pause...
    Note over LS: Lock expires
    
    participant B as Client B
    B->>LS: Acquire lock
    LS-->>B: Lock granted
    
    B->>S: Write data (valid)
    
    Note over A: Wakes from GC
    A->>S: Write data (STALE - overwrites B's write)
~~~

### The Solution With Fencing

~~~mermaid
sequenceDiagram
    participant A as Client A
    participant LS as Lock Service
    participant S as Storage
    
    A->>LS: Acquire lock
    LS-->>A: Lock granted, token=33
    
    Note over A: Long GC pause...
    Note over LS: Lock expires
    
    participant B as Client B
    B->>LS: Acquire lock
    LS-->>B: Lock granted, token=34
    
    B->>S: Write data, token=34
    S->>S: Accept (34 > last seen 0)
    
    Note over A: Wakes from GC
    A->>S: Write data, token=33
    S->>S: REJECT (33 < last seen 34)
~~~

~~~
Fencing token = monotonically increasing number
  - Lock service increments on each grant
  - Storage rejects writes with old tokens
  - Guarantees correctness even with expired locks

Requirement: storage must support token validation
  - Easy with databases (compare-and-swap)
  - Harder with external APIs or file systems
~~~

---

## 5. Lock Patterns

### Try-Lock with Timeout

~~~
acquire_lock(resource, timeout=5s):
  deadline = now() + timeout
  while now() < deadline:
    if try_lock(resource):
      return SUCCESS
    sleep(random(50ms, 200ms))  // jitter to avoid thundering herd
  return TIMEOUT
~~~

### Lock with Renewal (Watchdog)

~~~mermaid
flowchart TB
    ACQ[Acquire Lock<br/>TTL = 30s] --> WORK[Do Work]
    WORK --> CHECK{Work done?}
    CHECK -->|Yes| RELEASE[Release Lock]
    CHECK -->|No| RENEW[Renew Lock<br/>Reset TTL to 30s]
    RENEW --> WORK
    
    WATCHDOG[Background Watchdog<br/>Every 10s] -.->|Auto-renew| RENEW
~~~

~~~
Watchdog pattern (used by Redisson):
  1. Acquire lock with TTL=30s
  2. Background thread renews every TTL/3 (10s)
  3. If process crashes, watchdog stops, lock expires naturally
  4. If process is alive but slow, lock stays held
~~~

### Read-Write Lock

~~~
Multiple readers OR one writer:

  Reader:
    acquire_read_lock()   // multiple allowed
    read_data()
    release_read_lock()

  Writer:
    acquire_write_lock()  // exclusive
    write_data()
    release_write_lock()

Implementation with Redis:
  Read lock:  INCR lock:resource:readers
  Write lock: SET lock:resource:writer NX (only if readers == 0)
  
  Complexity increases significantly — consider if you really need it
~~~

---

## 6. Anti-Patterns

### Lock and Forget

~~~
Problem: Acquire lock, crash before release

  service.lock("resource-123")
  process_order()    // crashes here
  service.unlock()   // never reached
  
  → Resource locked forever

Fix: Always use TTL/expiry
     Always use try-finally (or equivalent)
     Ephemeral nodes in ZooKeeper handle this automatically
~~~

### Long-Held Locks

~~~
Problem: Lock held for minutes during batch processing

  lock("inventory-sync")
  for item in all_items:     // 100,000 items, takes 10 minutes
    sync_inventory(item)
  unlock("inventory-sync")
  
  → Everything else blocked for 10 minutes

Fix: Lock per item, not per batch
     Or: optimistic concurrency (no lock, detect conflicts)
~~~

### Distributed Lock as Distributed Mutex

~~~
Problem: Using locks to coordinate everything

  Every service call:
    lock("user-123")
    read_balance()
    update_balance()
    unlock("user-123")
  
  → Serialized all operations on user-123
  → Throughput = 1 operation at a time
  → Basically a single-threaded system

Fix: Use optimistic concurrency where possible
     Use database transactions for data consistency
     Reserve distributed locks for cross-system coordination
~~~

---

## 7. When to Use (and When Not To)

| ✅ Good Fit                              | ❌ Poor Fit                             |
| --------------------------------------- | -------------------------------------- |
| Preventing duplicate job processing     | Protecting every database write        |
| Leader election among instances         | High-throughput data updates           |
| Coordinating access to external APIs    | When optimistic concurrency works      |
| Distributed cron / scheduled tasks      | Single-service data consistency        |
| Resource reservation (seats, inventory) | When you can use database transactions |

### Decision Framework

~~~mermaid
flowchart TB
    Q1{"Need mutual exclusion<br/>across services?"} -->|No| DB["Use database<br/>transactions"]
    Q1 -->|Yes| Q2{"Correctness critical?<br/>(money, inventory)"}
    
    Q2 -->|Yes| Q3{"Have ZooKeeper/etcd?"}
    Q2 -->|No| REDIS["Redis lock<br/>(simple, fast)"]
    
    Q3 -->|Yes| ZK["ZooKeeper/etcd lock<br/>+ fencing tokens"]
    Q3 -->|No| DBLOCK["Database lock<br/>+ fencing tokens"]
~~~

---

## 8. Key Takeaways

| # | Takeaway |
|---|----------|
| 1 | Distributed locks solve cross-service coordination, not data consistency |
| 2 | Every lock must have a TTL — processes crash, networks partition |
| 3 | Redis locks are fast but not safe for correctness without fencing |
| 4 | ZooKeeper/etcd provide stronger guarantees via consensus |
| 5 | Fencing tokens protect against stale lock holders |
| 6 | Prefer optimistic concurrency over locks when possible |
| 7 | Lock granularity matters — too coarse kills throughput |
| 8 | Test lock expiry and failover scenarios, not just the happy path |

---

## 9. Practical Exercise

### Design Challenge

Design a distributed locking strategy for a ticket booking platform:

**Scenario:** Concert with 50,000 seats, flash sale with 500,000 concurrent users

**Requirements:**
- No double-booking (two users get the same seat)
- Users have 10 minutes to complete payment after selecting a seat
- If payment fails or times out, seat is released
- System must handle 10,000 seat selections per second
- Dashboard shows real-time seat availability

**Discussion Questions:**
1. Would you use a distributed lock per seat? Why or why not?
2. How do you handle the 10-minute reservation timeout?
3. What happens if the lock service goes down during peak load?
4. How would you design this differently with optimistic concurrency?
5. What's your strategy for the "last few seats" scenario where contention is highest?
