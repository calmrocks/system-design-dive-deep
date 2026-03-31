# Concurrency Problem-Solving: A Decision Guide

## 1. Do I Even Need a Lock?

Many concurrency problems can be solved **without any lock at all**.

### Option A: Idempotent Design

Make your operation safe to execute multiple times with the same result.

~~~java
public void processPayment(String orderId) {
    Order order = orderDao.findById(orderId);
    if (order.getStatus() == PAID) {
        return; // already processed, safe to skip
    }
    // CAS update: only UNPAID → PAID succeeds
    int rows = orderDao.updateStatus(orderId, UNPAID, PAID);
    if (rows == 0) return; // someone else handled it
    // proceed with business logic...
}
~~~

### Option B: Database Unique Constraint

Let the database reject duplicates for you.

~~~sql
CREATE UNIQUE INDEX uk_order ON orders(user_id, product_id, order_date);

-- duplicate insert simply fails, no lock needed
INSERT INTO orders(user_id, product_id, order_date) VALUES(1001, 2001, '2024-01-01');
~~~

### Option C: Message Queue Serialization

Route related requests to the same queue, consume them one by one.

~~~
Producer → [Queue partitioned by userId] → Consumer (single-threaded)
                                              process request 1
                                              process request 2
                                              process request 3
~~~

- ✅ Works when: async processing is acceptable
- ❌ Doesn't work when: you need a synchronous response

---

## 2. If I Need a Lock, But Only on a Single Machine

Use language-level locks. No need for Redis or ZooKeeper.

### Java Example

~~~java
// Simple mutual exclusion
private final ReentrantLock lock = new ReentrantLock();

public void doBusiness() {
    lock.lock();
    try {
        // critical section
    } finally {
        lock.unlock();
    }
}
~~~

~~~java
// Or simply
public synchronized void doBusiness() {
    // critical section
}
~~~

- ✅ Works when: single JVM / single machine deployment
- ❌ Doesn't work when: multiple machines run the same code

---

## 3. If I Need a Lock Across Machines, But Low Concurrency

Use the **database** as a simple distributed lock. No extra infrastructure needed.

### Option A: Database Pessimistic Lock

~~~sql
BEGIN;
SELECT * FROM resource WHERE id = 1 FOR UPDATE;  -- locks the row
-- do business
COMMIT;  -- releases the lock
~~~

### Option B: Database Optimistic Lock (Version Field)

~~~sql
UPDATE inventory
SET stock = stock - 1,
    version = version + 1
WHERE product_id = 1001
  AND version = 5;  -- only succeeds if no one else changed it

-- affected rows = 0 → conflict, retry
-- affected rows = 1 → success
~~~

### Option C: Lock Table

~~~sql
CREATE TABLE distributed_lock (
    lock_name  VARCHAR(64) PRIMARY KEY,
    owner      VARCHAR(255),
    expire_at  TIMESTAMP
);

-- acquire lock
INSERT INTO distributed_lock VALUES('order_lock', 'server-1', NOW() + INTERVAL 30 SECOND);
-- success = got lock
-- duplicate key error = didn't get lock

-- release lock
DELETE FROM distributed_lock WHERE lock_name = 'order_lock' AND owner = 'server-1';
~~~

- ✅ Works when: low concurrency, no Redis/ZK in your stack
- ❌ Doesn't work when: high concurrency (database becomes bottleneck)

---

## 4. If I Need a High-Performance Distributed Lock

Use **Redis** (via Redisson).

~~~java
// Redisson — production-ready Redis distributed lock
RLock lock = redissonClient.getLock("order:lock:" + orderId);

try {
    if (lock.tryLock(5, 30, TimeUnit.SECONDS)) {
        // got the lock, do business
        doBusiness();
    }
} finally {
    if (lock.isHeldByCurrentThread()) {
        lock.unlock();
    }
}
~~~

**How it works under the hood:**

~~~
Client-A → SET lock_key unique_value NX PX 30000 → success ✅ (got lock)
Client-B → SET lock_key unique_value NX PX 30000 → fail ❌ (key exists)

Client-A done → DEL lock_key (via Lua script, checks unique_value)
Client-B retries → success ✅
~~~

**Why Redisson over hand-written Redis lock:**

- Auto-renewal (Watch Dog): prevents lock expiry during long operations
- Reentrant: same thread can acquire the same lock multiple times
- Fair lock option: FIFO ordering
- Handles edge cases you'll forget about

- ✅ Works when: most distributed lock scenarios, high throughput
- ❌ Doesn't work when: you need **strong consistency** (Redis replication is async)

---

## 5. If I Need a Strongly Consistent Distributed Lock

Use **ZooKeeper** (via Curator).

~~~java
// Curator — production-ready ZooKeeper distributed lock
InterProcessMutex lock = new InterProcessMutex(curatorClient, "/lock/order");

try {
    if (lock.acquire(5, TimeUnit.SECONDS)) {
        // got the lock, do business
        doBusiness();
    }
} finally {
    lock.release();
}
~~~

**How it works under the hood:**

~~~
Client-A → creates /lock/seq-0001 (ephemeral + sequential) → smallest → got lock ✅
Client-B → creates /lock/seq-0002 → not smallest → watches 0001, waits
Client-C → creates /lock/seq-0003 → not smallest → watches 0002, waits

Client-A done → deletes /lock/seq-0001
  → ZK notifies Client-B → B is now smallest → got lock ✅
    → Client-C still watches 0002, undisturbed
~~~

- ✅ Works when: strong consistency required, can't tolerate lock loss
- ❌ Doesn't work when: you need very high throughput (ZK handles ~10K QPS vs Redis ~100K QPS)

---

## Decision Flowchart

~~~
Can I avoid shared mutable state entirely?
  └─ YES → No lock needed. Done.
  └─ NO ↓

Can idempotent design / DB unique constraint solve it?
  └─ YES → No lock needed. Done.
  └─ NO ↓

Can I serialize via message queue?
  └─ YES → No lock needed. Done.
  └─ NO ↓

Is it single-machine only?
  └─ YES → Use synchronized / ReentrantLock. Done.
  └─ NO ↓

Is concurrency low + no Redis/ZK available?
  └─ YES → Use database lock (FOR UPDATE / version field). Done.
  └─ NO ↓

Do I need strong consistency guarantee?
  └─ NO  → Use Redisson (Redis lock). Done.     ← most common choice
  └─ YES → Use Curator (ZooKeeper lock). Done.
~~~

---

## Quick Comparison Table

| Approach                  | Distributed? | Consistency | Performance | Complexity |
|---------------------------|:---:|:---:|:---:|:---:|
| Idempotent / DB Constraint| N/A          | N/A         | ★★★★★       | Low        |
| Message Queue             | ✅           | Eventual    | ★★★★        | Medium     |
| synchronized / ReentrantLock | ❌ single JVM | Strong | ★★★★★  | Low        |
| Database Lock             | ✅           | Strong      | ★★          | Low        |
| **Redis (Redisson)**      | ✅           | Eventual    | ★★★★★       | Low        |
| **ZooKeeper (Curator)**   | ✅           | Strong      | ★★★         | Medium     |

---

## Rule of Thumb

> 1. **Don't lock** if you can avoid it.
> 2. **Don't distribute** the lock if a local lock works.
> 3. **Don't build your own** if a mature library exists.
> 4. **Default to Redisson** unless you have a specific reason not to.
