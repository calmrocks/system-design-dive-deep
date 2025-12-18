# Distributed Transactions - Learning Materials

## Articles & Blogs

- [Saga Pattern: How to Implement Business Transactions Using Microservices](https://blog.couchbase.com/saga-pattern-implement-business-transactions-using-microservices-part/) - Comprehensive guide on Saga implementation
- [Pattern: Transactional Outbox](https://microservices.io/patterns/data/transactional-outbox.html) - Chris Richardson's definitive guide
- [Life Beyond Distributed Transactions](https://queue.acm.org/detail.cfm?id=3025012) - Pat Helland's influential paper on scalable systems

## Videos

- [Distributed Transactions are Dead](https://www.youtube.com/watch?v=5ZjhNTM8XU8) - Sergey Bykov on modern alternatives
- [Saga Pattern Explained](https://www.youtube.com/watch?v=xDuwrtwYHu8) - ByteByteGo's visual explanation
- [Outbox Pattern with Debezium](https://www.youtube.com/watch?v=b0Bz8Ys-Bes) - Gunnar Morling's deep dive

## Technical Documentation

- [Debezium Outbox Event Router](https://debezium.io/documentation/reference/transformations/outbox-event-router.html) - Official CDC implementation guide
- [AWS Step Functions for Saga](https://docs.aws.amazon.com/prescriptive-guidance/latest/patterns/implement-the-saga-pattern-with-aws-step-functions.html) - AWS implementation pattern
- [Temporal.io Saga Tutorial](https://docs.temporal.io/dev-guide/go/features#sagas) - Workflow-based Saga implementation

## Key Concepts to Explore

- Two-phase commit (2PC) and three-phase commit (3PC)
- Saga orchestration vs choreography
- Compensation and rollback strategies
- Eventual consistency and BASE properties
- Idempotency and exactly-once semantics
