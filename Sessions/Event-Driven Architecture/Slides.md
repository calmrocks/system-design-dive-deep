---
theme: css/eda-theme.css
transition: slide
slideNumber: true
controls: true
progress: true
center: true
hash: true
---

<!-- slide bg="#0b1120" -->

# 🔷 Event-Driven Architecture

## Architecture Guide

| | |
|---|---|
| ⏱ Duration | 60 min |
| 📊 Level | Intermediate → Advanced |
| 📋 Prerequisites | Message Queues, Distributed Txns |

---

<!-- slide bg="#0b1120" -->

## 🎯 Learning Objectives

- Understand EDA patterns and **when to apply** them
- Distinguish **notification**, **state transfer**, and **event sourcing**
- Handle **failure**, **ordering**, and **consistency**
- Evaluate **coupling** vs **complexity** vs **reliability**
- Choose between **choreography** and **orchestration**

---

<!-- slide bg="#0f1b33" -->

# 1️⃣ Why Event-Driven?

---

<!-- slide bg="#0f1b33" -->

## ⛓️ Synchronous Chain

~~~mermaid
flowchart LR
    OS[Order] -->|req| PS[Payment]
    PS -->|req| IS[Inventory]
    IS -->|req| SS[Shipping]
    SS -->|res| IS -->|res| PS -->|res| OS
~~~

| Problem | Impact |
|---------|--------|
| 🕐 Latency | Sum of all services |
| 💥 Availability | One fails = all fail |
| 🔗 Coupling | New step = modify caller |

---

<!-- slide bg="#0f1b33" -->

## ✅ Event-Driven Alternative

~~~mermaid
flowchart LR
    OS[Order] -->|publish| EB[Event Bus<br>OrderPlaced]
    EB --> PAY[Payment]
    EB --> INV[Inventory]
    EB --> SHIP[Shipping]
    EB --> ANA[Analytics]
~~~

| Benefit | |
|---------|---|
| 🔓 Decoupled | Services react independently |
| 🛡️ Resilient | Failures isolated |
| 🔌 Extensible | Add consumers freely |

---

<!-- slide bg="#0f1b33" -->

## 💡 Core Principle

> *"Tell the world what happened, don't tell services what to do."*

| Approach | Example | Coupling |
|----------|---------|----------|
| **Command** | `ProcessPayment` | 🔴 Tight |
| **Event** | `OrderPlaced` | 🟢 Loose |

---

<!-- slide bg="#0f1b33" -->

# 2️⃣ Types of Events

---

<!-- slide bg="#0f1b33" -->

## 🔔 Event Notification

~~~mermaid
sequenceDiagram
    participant OS as Order Svc
    participant EB as Event Bus
    participant IS as Inventory Svc

    OS->>EB: OrderPlaced { orderId: 123 }
    EB->>IS: OrderPlaced { orderId: 123 }
    IS->>OS: GET /orders/123
    OS-->>IS: Full details
    IS->>IS: Reserve inventory
~~~

- ✅ Small messages, always fresh
- ❌ Source must be available (temporal coupling)

---

<!-- slide bg="#0f1b33" -->

## 📦 Event-Carried State Transfer

~~~mermaid
sequenceDiagram
    participant OS as Order Svc
    participant EB as Event Bus
    participant IS as Inventory Svc

    OS->>EB: OrderPlaced { orderId, items[], customer{} }
    EB->>IS: Full payload
    IS->>IS: Reserve inventory
~~~

- ✅ Fully decoupled, no callback needed
- ❌ Larger messages, potentially stale

---

<!-- slide bg="#0f1b33" -->

## 📜 Event Sourcing

~~~mermaid
flowchart LR
    E1[OrderCreated] --> E2[ItemAdded] --> E3[PaymentReceived] --> E4[OrderShipped]
    E4 --> S["Current State<br>= replay all"]
~~~

- ✅ Complete audit trail, temporal queries
- ❌ High complexity (snapshots, projections)

---

<!-- slide bg="#0f1b33" -->

## 📊 Comparison

| | Notification | State Transfer | Sourcing |
|---|:---:|:---:|:---:|
| **Payload** | Small | Large | Medium |
| **Coupling** | 🟡 Medium | 🟢 Low | 🟢 Low |
| **Freshness** | Fresh | Stale risk | Authoritative |
| **Complexity** | 🟢 Low | 🟢 Low | 🔴 High |
| **Audit** | ❌ | ❌ | ✅ |

---

<!-- slide bg="#0f1b33" -->

# 3️⃣ Architecture Patterns

---

<!-- slide bg="#0f1b33" -->

## 🔀 Broker Topology

~~~mermaid
flowchart TB
    subgraph P["Producers"]
        OS[Order Svc]
        US[User Svc]
    end
    subgraph B["Broker"]
        T1[orders.placed]
        T2[users.registered]
    end
    subgraph C["Consumers"]
        INV[Inventory]
        PAY[Payment]
        NOT[Notification]
    end
    OS --> T1
    US --> T2
    T1 --> INV & PAY
    T2 --> NOT
~~~

---

<!-- slide bg="#0f1b33" -->

## 🌐 Event Mesh

~~~mermaid
flowchart LR
    subgraph RA["Region A"]
        KA[Kafka Primary]
    end
    subgraph RB["Region B"]
        KB[Kafka Replica]
    end
    KA <-->|Mirroring| KB
~~~

- 🛡️ Disaster recovery via failover
- ⚡ Local read performance
- 🌍 Geo-distributed processing

---

<!-- slide bg="#0f1b33" -->

## 🎛️ Mediator Topology

~~~mermaid
flowchart TB
    E[Event] --> M[Mediator]
    M -->|Step 1| S1[Svc A]
    M -->|Step 2| S2[Svc B]
    S1 & S2 -->|Result| M
~~~

- ✅ Ordered workflows, central error handling
- ❌ Mediator = coupling & failure point

---

<!-- slide bg="#0f1b33" -->

## ⚖️ Choreography vs Orchestration

| | Choreography | Orchestration |
|---|:---:|:---:|
| **Control** | Decentralized | Central |
| **Coupling** | 🟢 Low | 🟡 Medium |
| **Visibility** | 🔴 Hard to trace | 🟢 Clear |
| **Best for** | Simple flows | Multi-step processes |

---

<!-- slide bg="#0f1b33" -->

# 4️⃣ Event Contracts

---

<!-- slide bg="#0f1b33" -->

## 📋 Event Schema

~~~json
{
  "eventId": "evt-uuid-12345",
  "eventType": "order.placed",
  "version": "2.0",
  "timestamp": "2025-03-01T10:30:00Z",
  "source": "order-service",
  "correlationId": "req-uuid-67890",
  "data": {
    "orderId": "order-123",
    "customerId": "cust-456",
    "items": [{ "productId": "prod-789", "qty": 2 }],
    "totalAmount": 59.98
  }
}
~~~

---

<!-- slide bg="#0f1b33" -->

## 🔑 Key Fields

| Field | Purpose |
|-------|---------|
| `eventId` | Idempotency key |
| `eventType` | Consumer routing |
| `version` | Schema evolution |
| `correlationId` | Trace user request across services |
| `causationId` | Parent → child event link |

---

<!-- slide bg="#0f1b33" -->

## 🔄 Schema Evolution

| ✅ Safe | ❌ Breaking |
|---------|------------|
| Add optional fields | Remove fields |
| Add new event types | Rename fields |
| Deprecate (keep sending) | Change field types |

**Strategy:** Version from day one → schema registry → consumer-driven contract tests

---

<!-- slide bg="#0f1b33" -->

# 5️⃣ Handling Failures

---

<!-- slide bg="#0f1b33" -->

## 🔁 Retry & Dead Letter Queue

~~~mermaid
flowchart TB
    Q[Topic] --> C[Consumer]
    C -->|Success| ACK[Ack ✅]
    C -->|Failure| R{"Retry < 3?"}
    R -->|Yes| Q
    R -->|No| DLQ[DLQ ☠️]
    DLQ --> ALERT[Alert]
    DLQ --> REPLAY[Replay 🔄]
~~~

- Use **exponential backoff**: 1s → 2s → 4s
- **Monitor DLQ depth** — never ignore it

---

<!-- slide bg="#0f1b33" -->

## 🔢 Ordering Solutions

| Solution | How |
|----------|-----|
| **Partition by entity ID** | Same entity → same partition → ordered |
| **Sequence numbers** | Consumer buffers & reorders |
| **State machine** | Reject invalid transitions, retry later |
| **Idempotent processing** | Safe to reprocess regardless of order |

---

<!-- slide bg="#0f1b33" -->

## 🎯 Exactly-Once Pattern

~~~mermaid
flowchart TB
    subgraph TX["Transaction"]
        CHK{"event_id<br>seen?"} -->|Yes| SKIP[Skip]
        CHK -->|No| BIZ[Business logic]
        BIZ --> WR[Write DB + mark processed]
        WR --> OUT[Write to outbox]
    end
    OUT --> RELAY["CDC / Polling"] --> BROKER[Broker]
~~~

Brokers give **at-least-once**. Exactly-once is the **consumer's job**.

---

<!-- slide bg="#0f1b33" -->

# 6️⃣ Observability

---

<!-- slide bg="#0f1b33" -->

## 🔍 Tracing Async Flows

~~~mermaid
flowchart TB
    OS[Order Svc] -->|OrderPlaced| PAY[Payment]
    OS -->|OrderPlaced| INV[Inventory]
    OS -->|OrderPlaced| ANA[Analytics]
    PAY -->|PaymentProcessed| NOT[Notification]
~~~

| Field | Role |
|-------|------|
| `correlationId` | Groups all events from one action |
| `causationId` | Parent → child link |
| `traceId` | Bridges to Jaeger / Zipkin |

---

<!-- slide bg="#0f1b33" -->

## 📈 Key Metrics

| Metric | Alert When |
|--------|-----------|
| Consumer lag | > 10k or growing |
| Processing latency (p99) | > SLA |
| DLQ depth | > 0 |
| Error rate | > 1% |
| End-to-end latency | > business SLA |

---

<!-- slide bg="#0f1b33" -->

# 7️⃣ Anti-Patterns

---

<!-- slide bg="#0f1b33" -->

## 🍜 Event Soup

~~~mermaid
flowchart LR
    A[ButtonClick] --> B[FormValidated] --> C[FieldUpdated] --> D[UIRefreshed] --> E["... 🤯"]
~~~

**Fix:** Only publish **meaningful domain state changes**, not UI or internal details.

---

<!-- slide bg="#0f1b33" -->

## 🏗️ Distributed Monolith

~~~mermaid
flowchart LR
    OS[Order Svc] --> PAY[Payment<br>expects exact fields]
    OS --> INV[Inventory<br>expects exact order]
    PAY & INV -.-> BREAK["💥 Change one = break all"]
~~~

**Fix:** Tolerant reader, consumer-driven contracts, own projections.

---

<!-- slide bg="#0f1b33" -->

## 🔄 Event Cycles

~~~mermaid
flowchart LR
    OS[OrderSvc] -->|OrderPlaced| IS[InventorySvc]
    IS -->|StockReserved| OS
    OS -->|OrderUpdated| IS
    IS -->|"??? ♾️"| OS
~~~

**Fix:** Clear ownership, distinguish commands vs events, break with workflow boundaries.

---

<!-- slide bg="#0f1b33" -->

# 8️⃣ Technology Comparison

---

<!-- slide bg="#0f1b33" -->

## 🛠️ Brokers

| | Kafka | RabbitMQ | EventBridge | SNS+SQS |
|---|:---:|:---:|:---:|:---:|
| **Model** | Log | Queue | Serverless | Pub-Sub |
| **Ordering** | Partition | Queue | Best-effort | FIFO opt |
| **Replay** | ✅ | ❌ | ✅ | ❌ |
| **Throughput** | 🟢 High | 🟡 Med | 🟡 Med | 🟡 Med |
| **Ops** | 🔴 High | 🟡 Med | 🟢 None | 🟢 None |

---

<!-- slide bg="#0f1b33" -->

# 9️⃣ When to Use

---

<!-- slide bg="#0f1b33" -->

## ✅ vs ❌

| ✅ Good Fit | ❌ Poor Fit |
|------------|-----------|
| Multiple consumers | Simple CRUD |
| Different team ownership | Tight consistency needed |
| Audit trail / replay | Low-latency sync response |
| Spike / load leveling | Small monolith |

---

<!-- slide bg="#0f1b33" -->

## 🧭 Decision Framework

~~~mermaid
flowchart TB
    Q1{"Multiple services<br>react?"} -->|No| SYNC[Sync call]
    Q1 -->|Yes| Q2{"Need real-time<br>response?"}
    Q2 -->|Yes| HYB["Hybrid:<br>sync + async"]
    Q2 -->|No| Q3{"Complex<br>workflow?"}
    Q3 -->|Yes| ORCH[Orchestration]
    Q3 -->|No| CHOREO[Choreography]
~~~

---

<!-- slide bg="#0f1b33" -->

# 🔟 Key Takeaways

| # | Takeaway |
|---|----------|
| 1 | Events = what happened · Commands = what to do |
| 2 | Payload size ↔ coupling tolerance |
| 3 | Version schemas from **day one** |
| 4 | Partition by entity ID + idempotency |
| 5 | DLQs are **not optional** |
| 6 | Only publish **meaningful** domain events |
| 7 | Hybrid sync+async is common |
| 8 | Correlation IDs + tracing = essential |

---

<!-- slide bg="#0f1b33" -->

# 1️⃣1️⃣ Exercise

### 🍔 Food Delivery Platform

---

<!-- slide bg="#0f1b33" -->

## 🍔 Design Challenge

**Services:** Restaurant · Order · Delivery · Payment · Notification

| Step | Action |
|------|--------|
| 1 | Customer places order |
| 2 | Restaurant confirms/rejects (5 min timeout) |
| 3 | Payment processed |
| 4 | Driver assigned |
| 5 | Real-time tracking |
| 6 | Delivery confirmed |

---

<!-- slide bg="#0f1b33" -->

## 🗺️ Possible Event Flow

~~~mermaid
flowchart TB
    OS[OrderSvc] -->|OrderPlaced| RS[RestaurantSvc]
    OS -->|OrderPlaced| ANA[Analytics]
    RS -->|OrderAccepted| PAY[PaymentSvc]
    PAY -->|PaymentProcessed| DEL[DeliverySvc]
    DEL -->|DriverAssigned| LOC["LocationUpdated<br>(stream)"]
    LOC --> DC[DeliveryCompleted]
    DC --> NOT[NotificationSvc]
~~~

---

<!-- slide bg="#0f1b33" -->

## 💬 Discussion

1. What events does **each service** publish?
2. How to handle **restaurant timeout**?
3. **Choreography or orchestration**? Why?
4. How to push **real-time updates** to customer?
5. What if the **driver cancels** mid-delivery?

---

<!-- slide bg="#0b1120" -->

# 🔷 Thank You

### Questions & Discussion
