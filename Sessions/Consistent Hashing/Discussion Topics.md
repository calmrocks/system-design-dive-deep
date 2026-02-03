# Consistent Hashing - Discussion Topics

## Algorithm & Design

1. **Why does modulo hashing fail in distributed systems?**
   - Calculate the percentage of keys remapped when adding/removing nodes
   - Impact on cache hit rates and database performance

2. **How do virtual nodes improve load distribution?**
   - Trade-offs between number of vnodes and memory usage
   - Handling heterogeneous hardware with different capacities

3. **Compare consistent hashing with rendezvous hashing**
   - When would you choose one over the other?
   - Implementation complexity differences

## Real-World Scenarios

4. **Design a distributed cache using consistent hashing**
   - How to handle hot keys that receive disproportionate traffic?
   - Replication strategy for fault tolerance

5. **How does Cassandra use consistent hashing for data partitioning?**
   - Token ranges and vnode configuration
   - Impact on read/write performance

6. **What happens during a network partition in a consistent hash ring?**
   - Split-brain scenarios
   - Consistency vs availability trade-offs

## Implementation Challenges

7. **How do you synchronize ring metadata across nodes?**
   - Gossip protocols vs centralized coordination
   - Handling temporary inconsistencies

8. **Describe a data migration strategy when adding nodes**
   - Background migration vs lazy migration
   - Minimizing impact on live traffic

9. **How would you implement weighted consistent hashing?**
   - Supporting servers with different capacities
   - Dynamic weight adjustment

## Advanced Topics

10. **What is jump consistent hashing and when would you use it?**
    - Memory efficiency compared to ring-based approach
    - Limitations and use cases

