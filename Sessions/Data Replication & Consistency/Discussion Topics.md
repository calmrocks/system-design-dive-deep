# Data Replication & Consistency - Discussion Topics

## Architecture & Design

1. **When would you choose synchronous over asynchronous replication?**
   - Data loss tolerance
   - Write latency requirements
   - Number of replicas

2. **How do you decide between single-leader and multi-leader replication?**
   - Geographic distribution of users
   - Write patterns and frequency
   - Conflict resolution complexity

3. **What consistency model is appropriate for different types of data?**
   - User profiles vs financial transactions
   - Social media feeds vs inventory counts
   - Session data vs audit logs

## Real-World Scenarios

4. **Design a replication strategy for a collaborative document editor**
   - Multiple users editing simultaneously
   - Offline editing support
   - Conflict resolution for concurrent edits

5. **Your primary database fails and the most up-to-date replica is 30 seconds behind — what do you do?**
   - Accept data loss vs wait for recovery
   - Communicating to users
   - Reconciliation after primary recovers

6. **How would you handle a split-brain scenario where two nodes both think they're the primary?**
   - Detection mechanisms
   - Fencing strategies
   - Data reconciliation after resolution

## Performance & Reliability

7. **How do you handle replication lag spikes during peak traffic?**
   - Read routing strategies
   - Capacity planning
   - Degraded mode operation

8. **What's your approach to testing failover in production?**
   - Chaos engineering practices
   - Game day exercises
   - Automated failover validation

## Advanced Topics

9. **When would you use CRDTs instead of traditional conflict resolution?**
   - Data structure requirements
   - Merge semantics
   - Performance implications

10. **How do you migrate from single-region to multi-region replication without downtime?**
    - Data migration strategy
    - Traffic cutover plan
    - Rollback considerations
