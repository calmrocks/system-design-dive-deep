# Event-Driven Architecture - Discussion Topics

## Architecture & Design

1. **When would you choose event notification vs event-carried state transfer?**
   - Payload size considerations
   - Coupling between producer and consumer
   - Data freshness requirements

2. **How do you define event boundaries in a microservices system?**
   - Domain-driven design and bounded contexts
   - Avoiding event soup
   - Ownership and responsibility

3. **What are the trade-offs of using a central event broker vs direct service-to-service events?**
   - Single point of failure
   - Operational complexity
   - Ordering and delivery guarantees

## Real-World Scenarios

4. **Design an event-driven notification system for a banking app**
   - Transaction alerts, low balance warnings, fraud detection
   - Multiple channels (push, SMS, email)
   - User preferences and throttling

5. **How would you migrate a synchronous REST-based system to event-driven?**
   - Strangler fig pattern
   - Dual-write risks during migration
   - Testing strategy

6. **Your event broker goes down for 10 minutes — what happens to your system?**
   - Buffering and retry strategies
   - Graceful degradation
   - Data loss vs duplication trade-offs

## Failure Handling

7. **How do you handle poison events that crash consumers repeatedly?**
   - Dead letter queues
   - Circuit breaker on consumers
   - Alerting and manual intervention

8. **What's your strategy for replaying events after a bug fix?**
   - Selective replay vs full replay
   - Side effects during replay (emails, payments)
   - Idempotency requirements

## Advanced Topics

9. **How do you implement event versioning across dozens of services?**
   - Schema registry
   - Consumer-driven contract testing
   - Deprecation and migration timelines

10. **When does event-driven architecture become more trouble than it's worth?**
    - Debugging complexity
    - Eventual consistency confusion
    - Team skill and operational maturity
