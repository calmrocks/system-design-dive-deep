# Notification System - Discussion Topics

## Architecture & Design

1. **How do you design a preference system that scales to millions of users with dozens of notification types?**
   - Storage model (row per user vs row per preference)
   - Caching strategy for hot preferences
   - Default preferences and inheritance

2. **When should you use separate queues per channel vs a single queue with routing?**
   - Isolation and independent scaling
   - Priority handling across channels
   - Operational complexity

3. **How do you handle notification aggregation (batching similar notifications)?**
   - Time-window vs count-based batching
   - Template design for aggregated notifications
   - Real-time vs digest trade-offs

## Real-World Scenarios

4. **Design a notification system for a banking app with strict delivery requirements**
   - Transaction alerts must arrive within 5 seconds
   - Fraud alerts must reach the user on at least one channel
   - Regulatory requirements for record keeping

5. **Your push notification provider is down for 30 minutes during peak hours — what's your strategy?**
   - Fallback to other channels
   - Queue management and backpressure
   - User communication

6. **How would you migrate from a single email provider to a multi-provider setup?**
   - Failover vs load balancing across providers
   - Maintaining sender reputation
   - Cost optimization

## Reliability & Scale

7. **How do you handle a flash sale that triggers 10 million notifications in 5 minutes?**
   - Backpressure and rate limiting
   - Provider capacity planning
   - Graceful degradation

8. **What's your strategy for ensuring exactly-once delivery of critical notifications like 2FA codes?**
   - Idempotency at each layer
   - Timeout and retry design
   - Fallback channel escalation

## Advanced Topics

9. **How do you measure notification effectiveness and avoid notification fatigue?**
   - Open rate, click rate, opt-out rate tracking
   - Smart frequency capping
   - ML-based send time optimization

10. **How do you handle cross-device notification synchronization?**
    - Read status sync across devices
    - Badge count consistency
    - Notification dismissal propagation
