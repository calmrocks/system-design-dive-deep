# Service Discovery - Discussion Topics

## Architecture & Design

1. **When to use client-side vs server-side service discovery?**
   - Trade-offs between complexity and flexibility
   - Impact on client libraries and coupling
   - Load balancing considerations

2. **How do you choose between Consul, etcd, and ZooKeeper?**
   - Consistency models (CP vs AP)
   - Operational complexity
   - Feature sets and ecosystem support

3. **What are the risks of DNS-based service discovery?**
   - TTL and caching issues
   - Propagation delays
   - Load balancing limitations

## Real-World Scenarios

4. **Design service discovery for a multi-region deployment**
   - Regional vs global registries
   - Failover strategies
   - Latency-aware routing

5. **How would you handle a service registry failure?**
   - Graceful degradation
   - Local caching strategies
   - Recovery procedures

## Health Checking & Reliability

6. **What's your approach to health check design?**
   - Shallow vs deep health checks
   - Check frequency and timeout tuning
   - Cascading failure prevention

7. **How do you prevent flapping services?**
   - Debouncing strategies
   - Gradual rollout/rollback
   - Circuit breaker integration

## Advanced Topics

8. **Service mesh vs traditional service discovery: When to use each?**
   - Sidecar proxy trade-offs
   - Operational complexity
   - Feature requirements

9. **How do you handle service discovery during deployments?**
   - Blue-green deployment integration
   - Canary release support
   - Connection draining strategies
