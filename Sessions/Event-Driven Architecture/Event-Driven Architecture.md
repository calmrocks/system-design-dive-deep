# Event-Driven Architecture: Architecture Guide

## Overview

| Attribute | Details |
|-----------|---------|
| Duration | 60 minutes |
| Level | Intermediate to Advanced |
| Prerequisites | Message Queue session, Distributed Transactions basics |

## Learning Objectives

- Understand event-driven architecture patterns and when to apply them
- Distinguish between event notification, event-carried state transfer, and event sourcing
- Design systems that react to domain events across service boundaries
- Handle failure, ordering, and consistency in event-driven systems
- Evaluate trade-offs between coupling, complexity, and reliability

---

## 1. Why Event-Driven?

### The Problem with Request-Response

~~~
Synchronous Chain:
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│  Order   │───▶│ Payment  │───▶│Inventory │───▶│ Shipping │
│ Service  │◀───│ Service  │◀───│ Service  │◀───│ Service  │
└──────────┘    └──────────┘    └──────────┘    └──────────┘
     Total latency = sum of all services
     Any failure = entire chain fails
     Adding a new step = modify caller

Event-Driven:
┌──────────┐    ┌─────────────────┐    ┌──────────┐
│  Order   │───▶│   Event Bus     │───▶│ Payment  │
│ Service  │    │                 │───▶│Inventory │
└──────────┘    │  OrderPlaced    │───▶│ Shipping │
                │                 │───▶│Analytics │ ← added without touching Order
                └─────────────────┘    └──────────┘
     Services react independently
     Failures are isolated
     New consumers added freely
~~~

### Core Principle

~~~
"Tell the world what happened, don't tell services what to do."

Command: "ProcessPayment" → tightly coupled
Event:   "OrderPlaced"    → loosely coupled
~~~

---

## 2. Types of Events

### Event Notification

~~~mermaid
sequenceDiagram
    participant OS as Order Service
    participant EB as Event Bus
    participant IS as Inventory Service
    
    OS->>EB: OrderPlaced { orderId: 123 }
    EB->>IS: OrderPlaced { orderId: 123 }
    IS->>OS: GET /orders/123 (callback for details)
    OS-->>IS: Order details
    IS->>IS: Reserve inventory
~~~

- Lightweight payload (just IDs)
- Consumer calls back for details
- Pro: Small messages, always fresh data
- Con: Temporal coupling (source must be available)

### Event-Carried State Transfer

~~~mermaid
sequenceDiagram
    participant OS as Order Service
    participant EB as Event Bus
    participant IS as Inventory Service
    
    OS->>EB: OrderPlaced { orderId: 123, items: [...], customer: {...} }
    EB->>IS: OrderPlaced { full payload }
    IS->>IS: Reserve inventory (no callback needed)
~~~

- Full payload in the event
- No callback needed
- Pro: Full decoupling, consumer works independently
- Con: Larger messages, potential stale data

### Event Sourcing (recap)

~~~
All state changes stored as immutable events:
  OrderCreated → ItemAdded → ItemAdded → PaymentReceived → OrderShipped

Current state = replay all events
~~~

### Comparison

| Aspect | Notification | State Transfer | Event Sourcing |
|--------|-------------|----------------|----------------|
| Payload size | Small (IDs) | Large (full data) | Medium (delta) |
| Coupling | Medium (callback) | Low | Low |
| Data freshness | Always fresh | Potentially stale | Authoritative |
| Complexity | Low | Low | High |
| Audit trail | No | No | Complete |

---

## 3. Architecture Patterns

### Event Bus / Broker Topology

~~~mermaid
flowchart TB
    subgraph producers["Producers"]
        OS[Order Service]
        US[User Service]
        PS[Product Service]
    end
    
    subgraph broker["Event Broker (Kafka / EventBridge)"]
        T1[orders.placed]
        T2[orders.shipped]
        T3[users.registered]
        T4[products.updated]
    end
    
    subgraph consumers["Consumers"]
        INV[Inventory Service]
        PAY[Payment Service]
        NOT[Notification Service]
        ANA[Analytics Service]
    end
    
    OS --> T1
    OS --> T2
    US --> T3
    PS --> T4
    
    T1 --> INV
    T1 --> PAY
    T1 --> ANA
    T2 --> NOT
    T3 --> NOT
    T3 --> ANA
    T4 --> INV
~~~

### Event Mesh (Multi-Region)

~~~
Region A                          Region B
┌─────────────────┐              ┌─────────────────┐
│  Kafka Cluster  │◄────────────▶│  Kafka Cluster  │
│  (Primary)      │   Mirroring  │  (Replica)      │
│                 │              │                 │
│  Order Service  │              │  Order Service  │
│  Payment Svc    │              │  Analytics Svc  │
└─────────────────┘              └─────────────────┘

Events replicated across regions for:
- Disaster recovery
- Local read performance
- Geo-distributed processing
~~~

### Mediator Topology

~~~mermaid
flowchart TB
    E[Incoming Event] --> M[Event Mediator]
    M -->|Step 1| S1[Service A]
    M -->|Step 2| S2[Service B]
    M -->|Step 3| S3[Service C]
    S1 -->|Result| M
    S2 -->|Result| M
    S3 -->|Result| M
~~~

- Central mediator coordinates complex event processing
- Good for workflows requiring ordering
- Trade-off: mediator becomes a coupling point

---

## 4. Designing Event Contracts

### Event Schema

~~~json
{
  "eventId": "evt-uuid-12345",
  "eventType": "order.placed",
  "version": "2.0",
  "timestamp": "2025-03-01T10:30:00Z",
  "source": "order-service",
  "correlationId": "req-uuid-67890",
  "causationId": "evt-uuid-11111",
  "data": {
    "orderId": "order-123",
    "customerId": "cust-456",
    "items": [
      { "productId": "prod-789", "quantity": 2, "price": 29.99 }
    ],
    "totalAmount": 59.98
  },
  "metadata": {
    "traceId": "trace-abc",
    "environment": "production"
  }
}
~~~

### Schema Evolution Rules

~~~
Safe changes (backward compatible):
  ✅ Add optional fields
  ✅ Add new event types
  ✅ Deprecate fields (keep sending)

Breaking changes (require versioning):
  ❌ Remove fields
  ❌ Rename fields
  ❌ Change field types
  ❌ Change semantics of existing fields

Strategy:
  1. Version your events (v1, v2)
  2. Support multiple versions during migration
  3. Use a schema registry (Confluent, AWS Glue)
  4. Consumer-driven contract testing
~~~

---

## 5. Handling Failures

### Retry & Dead Letter

~~~mermaid
flowchart TB
    Q[Event Topic] --> C[Consumer]
    C -->|Success| ACK[Acknowledge]
    C -->|Failure| RETRY{Retry?}
    RETRY -->|Attempts < 3| Q
    RETRY -->|Attempts >= 3| DLQ[Dead Letter Queue]
    DLQ --> ALERT[Alert + Manual Review]
    DLQ --> REPLAY[Replay after fix]
~~~

### Ordering Guarantees

~~~
Problem: Events arrive out of order

  Published: OrderPlaced → OrderPaid → OrderShipped
  Received:  OrderPaid → OrderPlaced → OrderShipped

Solutions:
┌─────────────────────────────────────────────────────┐
│ 1. Partition by entity ID (Kafka)                   │
│    → All events for order-123 go to same partition  │
│    → Ordered within partition                       │
│                                                     │
│ 2. Sequence numbers                                 │
│    → Each event has monotonic sequence              │
│    → Consumer buffers and reorders                  │
│                                                     │
│ 3. State machine validation                         │
│    → Consumer rejects invalid transitions           │
│    → Retry later when prerequisite arrives          │
│                                                     │
│ 4. Idempotent processing                            │
│    → Design so reprocessing is safe                 │
└─────────────────────────────────────────────────────┘
~~~

### Exactly-Once Processing

~~~
Reality: Brokers provide at-least-once delivery
         Exactly-once is the consumer's responsibility

Pattern: Idempotent Consumer + Transactional Outbox

┌─────────────────────────────────────────────────────┐
│  BEGIN TRANSACTION                                  │
│    1. Check: event_id in processed_events?          │
│       YES → skip                                    │
│       NO  → continue                                │
│    2. Process business logic                        │
│    3. Write results to DB                           │
│    4. Insert event_id into processed_events         │
│    5. Write outgoing events to outbox table         │
│  COMMIT                                             │
│                                                     │
│  Message relay publishes outbox → broker            │
└─────────────────────────────────────────────────────┘
~~~

---

## 6. Anti-Patterns

### Event Soup

~~~
Problem: Everything is an event, no clear boundaries

  UserClickedButton → FormValidated → FieldUpdated →
  UIRefreshed → LogWritten → MetricEmitted → ...

  Result: Impossible to trace flows, debug nightmares

Fix: Events should represent meaningful domain state changes
     Not UI actions or internal implementation details
~~~

### Distributed Monolith

~~~
Problem: Services depend on specific event schemas and ordering

  Order Service publishes OrderPlaced v1
  Payment Service expects exact field names
  Inventory Service expects events in exact order
  → Change one service, break them all

Fix: Consumer-driven contracts
     Tolerant reader pattern (ignore unknown fields)
     Version events properly
~~~

### Event Cycle

~~~
Problem: A → publishes event → B → publishes event → A → ...

  OrderService: OrderPlaced
  InventoryService: StockReserved
  OrderService: OrderUpdated (reacts to StockReserved)
  InventoryService: ??? (reacts to OrderUpdated?)

Fix: Clear event ownership
     Distinguish commands from events
     Break cycles with explicit workflow boundaries
~~~

---

## 7. When to Use (and When Not To)

| ✅ Good Fit | ❌ Poor Fit |
|------------|-----------|
| Multiple consumers need same data | Simple CRUD with one consumer |
| Services owned by different teams | Tight consistency required |
| Need to add consumers without changing producer | Low-latency synchronous response needed |
| Audit trail / event replay needed | Small monolithic application |
| Spike handling / load leveling | Team unfamiliar with async patterns |

### Decision Framework

~~~mermaid
flowchart TB
    Q1{"Multiple services need<br/>to react to a change?"} -->|Yes| Q2{"Need real-time<br/>response to caller?"}
    Q1 -->|No| SYNC["Use synchronous call"]
    
    Q2 -->|Yes| HYBRID["Hybrid: sync response +<br/>async side effects"]
    Q2 -->|No| Q3{"Complex multi-step<br/>workflow?"}
    
    Q3 -->|Yes| ORCH["Event-driven with<br/>orchestration"]
    Q3 -->|No| CHOREO["Event-driven with<br/>choreography"]
~~~

---

## 8. Key Takeaways

| # | Takeaway |
|---|----------|
| 1 | Events describe what happened, commands describe what to do |
| 2 | Choose event payload size based on coupling tolerance |
| 3 | Schema evolution is a first-class concern — version from day one |
| 4 | Partition by entity ID for ordering, use idempotency for safety |
| 5 | Dead letter queues are not optional — plan for failure |
| 6 | Avoid event soup: only publish meaningful domain events |
| 7 | Event-driven doesn't mean everything is async — hybrid is common |
| 8 | Distributed tracing with correlation IDs is essential for debugging |

---

## 9. Practical Exercise

### Design Challenge

Design an event-driven architecture for a food delivery platform:

**Services:** Restaurant, Order, Delivery, Payment, Notification

**Flow:**
1. Customer places order
2. Restaurant confirms or rejects
3. Payment is processed
4. Driver is assigned
5. Real-time tracking updates
6. Delivery confirmed

**Requirements:**
- Restaurant has 5 minutes to accept
- Payment failure after restaurant accepts must notify restaurant
- Customer sees real-time status updates
- Analytics team wants all events for reporting

**Discussion Questions:**
1. What events does each service publish?
2. How do you handle restaurant timeout (no response in 5 min)?
3. Choreography or orchestration for the order flow? Why?
4. How do you push real-time updates to the customer?
5. What happens if the delivery driver cancels mid-delivery?
