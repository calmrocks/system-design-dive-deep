# Load Balancer - Discussion Topics

## Architecture & Design

1. **Layer 4 vs Layer 7 load balancing: When to use which?**
   - Performance implications
   - Feature trade-offs
   - Use case scenarios

2. **How do you design for high availability in load balancing?**
   - Active-active vs active-passive
   - Health check strategies
   - Failover mechanisms

3. **What are the trade-offs of client-side vs server-side load balancing?**
   - Service mesh patterns
   - Complexity and control
   - Performance considerations

## Real-World Scenarios

4. **Design a load balancing strategy for a microservices architecture**
   - Service discovery integration
   - Dynamic scaling considerations
   - Circuit breaker patterns

5. **How would you handle sticky sessions in a distributed system?**
   - Session affinity approaches
   - Stateless design alternatives
   - Trade-offs with scalability

## Performance & Optimization

6. **How do you choose the right load balancing algorithm?**
   - Round-robin vs least connections vs weighted
   - Application characteristics
   - Monitoring and tuning

7. **What metrics matter most for load balancer performance?**
   - Latency (P50, P99)
   - Connection pooling efficiency
   - Backend health and distribution

## Advanced Topics

8. **How do you implement global load balancing across regions?**
   - DNS-based GSLB
   - Anycast routing
   - Latency-based routing

9. **What's your approach to zero-downtime deployments with load balancers?**
   - Blue-green deployments
   - Canary releases
   - Connection draining strategies

10. **How do you handle WebSocket connections with load balancers?**
    - Connection persistence
    - Scaling challenges
    - Protocol upgrade handling
