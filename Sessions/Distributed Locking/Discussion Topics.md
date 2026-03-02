# Distributed Locking - Discussion Topics

## Architecture & Design

1. **When would you choose a database lock over Redis or ZooKeeper?**
   - Existing infrastructure
   - Consistency requirements
   - Latency tolerance

2. **How do you decide the right lock TTL for your use case?**
   - Expected processing time
   - GC pause and network delay considerations
   - Renewal strategy trade-offs

3. **What are the trade-offs between pessimistic locking and optimistic concurrency?**
   - Contention levels
   - Throughput requirements
   - Retry cost and user experience

## Real-World Scenarios

4. **Design a locking strategy for a distributed cron system**
   - Ensuring exactly-once execution across a cluster
   - Handling leader failure mid-execution
   - Dealing with clock skew between nodes

5. **Your Redis lock service has a network partition — half your services can reach it, half can't. What happens?**
   - Impact on lock holders vs lock waiters
   - Failover strategy
   - Data consistency during and after partition

6. **How would you implement inventory reservation for a flash sale with millions of concurrent users?**
   - Lock granularity (per item vs per SKU vs global)
   - Timeout and release strategy
   - Fallback when lock service is overloaded

## Failure Handling

7. **A service acquires a lock, then experiences a 45-second GC pause. The lock TTL is 30 seconds. What happens?**
   - Impact on other services
   - Fencing token protection
   - How to detect and recover

8. **How do you handle deadlocks in a distributed system?**
   - Detection vs prevention
   - Lock ordering strategies
   - Timeout-based resolution

## Advanced Topics

9. **When would you use Redlock vs a single Redis instance for locking?**
   - Failure modes of each approach
   - The Kleppmann vs Antirez debate
   - Practical decision criteria

10. **How do you monitor and alert on distributed lock health?**
    - Lock contention metrics
    - Expired lock frequency
    - Lock hold duration percentiles
