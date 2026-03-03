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

<grid drag="80 30" drop="center" style="place-items: center;">

# 🔷 Event-Driven Architecture

## Architecture Guide

</grid>

<grid drag="60 20" drop="center" pad="80px 0 0 0" style="place-items: center;">

| Attribute | Details |
|-----------|---------|
| ⏱ Duration | 60 minutes |
| 📊 Level | Intermediate → Advanced |
| 📋 Prerequisites | Message Queues, Distributed Txns |

</grid>

---

<!-- slide bg="#0b1120" -->

## 🎯 Learning Objectives

<grid drag="85 70" drop="center" style="font-size: 0.78em;">

| # | Objective |
|---|-----------|
| 1 | Understand event-driven patterns and **when to apply** them |
| 2 | Distinguish **notification**, **state transfer**, and **event sourcing** |
| 3 | Design systems reacting to **domain events** across boundaries |
| 4 | Handle **failure**, **ordering**, and **consistency** properly |
| 5 | Evaluate trade-offs: **coupling** vs **complexity** vs **reliability** |
| 6 | Apply **schema evolution** and **contract management** strategies |
| 7 | Identify and avoid common **anti-patterns** |
| 8 | Choose between **choreography** and **orchestration** |

</grid>

---

<!-- slide bg="#0b1120" -->

## 📑 Agenda

<grid drag="80 65" drop="center" style="font-size: 0.75em;">

| Section | Topic |
|---------|-------|
| **1** | Why Event-Driven? |
| **2** | Types of Events |
| **3** | Architecture Patterns |
| **4** | Designing Event Contracts |
| **5** | Handling Failures |
| **6** | Observability & Tracing |
| **7** | Anti-Patterns |
| **8** | Technology Comparison |
| **9** | When to Use (and When Not To) |
| **10** | Key Takeaways |
| **11** | Practical Exercise |

</grid>

---

<!-- slide bg="#0f1b33" -->

<grid drag="80 15" drop="center">

# 1️⃣ Why Event-Driven?

### The Problem with Request-Response

</grid>

---

<!-- slide bg="#0f1b33" -->

## ⛓️ Synchronous Chain

~~~mermaid
flowchart LR
    OS[Order\nService] -->|req| PS[Payment\nService]
    PS -->|req| IS[Inventory\nService]
    IS -->|req| SS[Shipping\nService]
    SS -->|res| IS
    IS -->|res| PS
    PS -->|res| OS
~~~

<grid drag="80 35" drop="center" pad="20px 0 0 0" style="font-size: 0.8em;">

| Problem | Impact |
|---------|--------|
| 🕐 **Latency** | Total = sum of all service times |
| 💥 **Availability** | Any failure = entire chain fails |
| 🔗 **Coupling** | Adding a step = modify the caller |
| 📈 **Scalability** | Bottleneck at slowest service |

</grid>

---

<!-- slide bg="#0f1b33" -->

## ✅ Event-Driven Alternative

~~~mermaid
flowchart LR
    OS[Order\nService] -->|publish| EB[Event Bus\nOrderPlaced]
    EB --> PAY[Payment]
    EB --> INV[Inventory]
    EB --> SHIP[Shipping]
    EB --> ANA[Analytics]

    style ANA fill:#1e3a5f,stroke:#3b82f6,color:#93c5fd
~~~

<grid drag="80 30" drop="center" pad="10px 0 0 0" style="font-size: 0.8em;">

| Benefit | Description |
|---------|-------------|
| 🔓 **Decoupled** | Services react independently |
| 🛡️ **Resilient** | Failures are isolated |
| 🔌 **Extensible** | New consumers added without touching producer |
| ⚡ **Scalable** | Each consumer scales independently |

</grid>

---

<!-- slide bg="#0f1b33" -->

## 💡 Core Principle

<grid drag="80 25" drop="center" style="font-size: 1em; text-align: center; background: #1a2744; border-radius: 12px; padding: 20px; border-left: 4px solid #3b82f6;">

> *"Tell the world what happened, don't tell services what to do."*

</grid>

<grid drag="80 30" drop="center" pad="60px 0 0 0" style="font-size: 0.85em;">

| Approach | Example | Coupling |
|----------|---------|----------|
| **Command** | `ProcessPayment` | 🔴 Tightly coupled |
| **Event** | `OrderPlaced` | 🟢 Loosely coupled |

</grid>

<grid drag="80 10" drop="bottom" style="font-size: 0.7em; color: #64748b; text-align: center;">

Commands **direct** a target. Events **inform** the world.

</grid>

---

<!-- slide bg="#0f1b33" -->

# 2️⃣ Types of Events

### Three Fundamental Patterns

---

<!-- slide bg="#0f1b33" -->

## 🔔 Event Notification

~~~mermaid
sequenceDiagram
    participant OS as Order Service
    participant EB as Event Bus
    participant IS as Inventory Service

    OS->>EB: OrderPlaced { orderId: 123 }
    EB->>IS: OrderPlaced { orderId: 123 }
    IS->>OS: GET /orders/123 (callback)
    OS-->>IS: Full order details
    IS->>IS: Reserve inventory
~~~

<grid drag="80 20" drop="bottom" pad="0 0 10px 0" style="font-size: 0.72em;">

| Pros | Cons |
|------|------|
| ✅ Small messages | ❌ Temporal coupling — source must be up |
| ✅ Always fresh data | ❌ Extra network hop per consumer |

</grid>

---

<!-- slide bg="#0f1b33" -->

## 📦 Event-Carried State Transfer

~~~mermaid
sequenceDiagram
    participant OS as Order Service
    participant EB as Event Bus
    participant IS as Inventory Service

    OS->>EB: OrderPlaced { orderId, items[], customer{} }
    EB->>IS: OrderPlaced { full payload }
    IS->>IS: Reserve inventory (no callback)
~~~

<grid drag="80 20" drop="bottom" pad="0 0 10px 0" style="font-size: 0.72em;">

| Pros | Cons |
|------|------|
| ✅ Full decoupling — consumer self-sufficient | ❌ Larger message size |
| ✅ Works even if producer is down | ❌ Potentially stale data |

</grid>

---

<!-- slide bg="#0f1b33" -->

## 📜 Event Sourcing (Recap)

~~~mermaid
flowchart LR
    E1[OrderCreated] --> E2[ItemAdded]
    E2 --> E3[ItemAdded]
    E3 --> E4[PaymentReceived]
    E4 --> E5[OrderShipped]
    E5 --> STATE["Current State\n= replay all events"]

    subgraph store["Event Store (append-only)"]
        E1
        E2
        E3
        E4
        E5
    end
~~~

<grid drag="80 25" drop="bottom" pad="0 0 10px 0" style="font-size: 0.72em;">

| Aspect | Detail |
|--------|--------|
| ✅ **Complete audit trail** | Every state change is recorded |
| ✅ **Temporal queries** | Reconstruct state at any point in time |
| ✅ **Debugging** | Replay events to reproduce bugs |
| ❌ **Complexity** | Snapshots, projections, schema migration |

</grid>

---

<!-- slide bg="#0f1b33" -->

## 📊 Event Types Comparison

<grid drag="90 55" drop="center" style="font-size: 0.72em;">

| Aspect | Notification | State Transfer | Event Sourcing |
|--------|:-----------:|:--------------:|:--------------:|
| **Payload size** | Small (IDs) | Large (full) | Medium (delta) |
| **Coupling** | 🟡 Medium | 🟢 Low | 🟢 Low |
| **Data freshness** | Always fresh | Potentially stale | Authoritative |
| **Complexity** | 🟢 Low | 🟢 Low | 🔴 High |
| **Audit trail** | ❌ No | ❌ No | ✅ Complete |
| **Consumer autonomy** | Low | High | High |
| **Storage cost** | Low | Medium | High |

</grid>

---

<!-- slide bg="#0f1b33" -->

# 3️⃣ Architecture Patterns

### Broker, Mediator, Mesh

---

<!-- slide bg="#0f1b33" -->

## 🔀 Broker Topology

~~~mermaid
flowchart TB
    subgraph P["Producers"]
        OS[Order Service]
        US[User Service]
        PS[Product Service]
    end

    subgraph B["Event Broker — Kafka / EventBridge"]
        T1[orders.placed]
        T2[orders.shipped]
        T3[users.registered]
        T4[products.updated]
    end

    subgraph C["Consumers"]
        INV[Inventory]
        PAY[Payment]
        NOT[Notification]
        ANA[Analytics]
    end

    OS --> T1 & T2
    US --> T3
    PS --> T4
    T1 --> INV & PAY & ANA
    T2 --> NOT
    T3 --> NOT & ANA
    T4 --> INV
~~~

---

<!-- slide bg="#0f1b33" -->

## 🌐 Event Mesh (Multi-Region)

~~~mermaid
flowchart LR
    subgraph RA["Region A"]
        KA[Kafka Cluster\nPrimary]
        OSA[Order Service]
        PSA[Payment Service]
        OSA & PSA --- KA
    end

    subgraph RB["Region B"]
        KB[Kafka Cluster\nReplica]
        OSB[Order Service]
        ANB[Analytics Service]
        OSB & ANB --- KB
    end

    KA <-->|"Mirroring\n(MirrorMaker / Replicator)"| KB
~~~

<grid drag="80 20" drop="bottom" pad="0 0 10px 0" style="font-size: 0.72em;">

| Purpose | Detail |
|---------|--------|
| 🛡️ **Disaster recovery** | Automatic failover to replica |
| ⚡ **Local performance** | Read from nearest region |
| 🌍 **Geo-distribution** | Process events where users are |

</grid>

---

<!-- slide bg="#0f1b33" -->

## 🎛️ Mediator Topology

~~~mermaid
flowchart TB
    E[Incoming Event] --> M[Event Mediator / Orchestrator]
    M -->|Step 1| S1[Service A]
    M -->|Step 2| S2[Service B]
    M -->|Step 3| S3[Service C]
    S1 -->|Result| M
    S2 -->|Result| M
    S3 -->|Result| M
~~~

<grid drag="80 22" drop="bottom" pad="0 0 10px 0" style="font-size: 0.72em;">

| Aspect | Detail |
|--------|--------|
| ✅ **Ordered workflows** | Central coordinator manages steps |
| ✅ **Error handling** | Compensating actions from one place |
| ❌ **Trade-off** | Mediator becomes a coupling & failure point |

</grid>

---

<!-- slide bg="#0f1b33" -->

## ⚖️ Choreography vs Orchestration

<grid drag="90 60" drop="center" style="font-size: 0.7em;">

| Aspect | Choreography | Orchestration |
|--------|:------------:|:-------------:|
| **Control** | Decentralized — each service decides | Central orchestrator directs |
| **Coupling** | 🟢 Low | 🟡 Medium |
| **Visibility** | 🔴 Hard to trace full flow | 🟢 Single place shows flow |
| **Error handling** | Each service handles own errors | Orchestrator manages compensation |
| **Scalability** | 🟢 Scales independently | 🟡 Orchestrator can bottleneck |
| **Complexity** | Grows with # of services | Concentrated in orchestrator |
| **Best for** | Simple reactive flows | Multi-step business processes |

</grid>

---

<!-- slide bg="#0f1b33" -->

# 4️⃣ Designing Event Contracts

### Schema, Versioning, Registry

---

<!-- slide bg="#0f1b33" -->

## 📋 Event Schema Anatomy

~~~json
{
  "eventId":       "evt-uuid-12345",
  "eventType":     "order.placed",
  "version":       "2.0",
  "timestamp":     "2025-03-01T10:30:00Z",
  "source":        "order-service",
  "correlationId": "req-uuid-67890",
  "causationId":   "evt-uuid-11111",
  "data": {
    "orderId":     "order-123",
    "customerId":  "cust-456",
    "items":       [{ "productId": "prod-789", "qty": 2, "price": 29.99 }],
    "totalAmount": 59.98
  },
  "metadata": {
    "traceId": "trace-abc",
    "environment": "production"
  }
}
~~~

---

<!-- slide bg="#0f1b33" -->

## 🔑 Key Envelope Fields

<grid drag="88 60" drop="center" style="font-size: 0.68em;">

| Field | Purpose |
|-------|---------|
| `eventId` | Globally unique — used for **idempotency** |
| `eventType` | Routing key — consumers filter on this |
| `version` | Enables **schema evolution** without breakage |
| `timestamp` | Wall-clock ordering reference |
| `source` | Which service produced the event |
| `correlationId` | Ties all events in a **user request** together |
| `causationId` | The specific event that **caused** this one |
| `traceId` | Links to **distributed tracing** (Jaeger / Zipkin) |

</grid>

---

<!-- slide bg="#0f1b33" -->

## 🔄 Schema Evolution Rules

<grid drag="85 65" drop="center" style="font-size: 0.72em;">

**✅ Safe Changes (backward compatible)**

| Change | Why Safe |
|--------|----------|
| Add **optional** fields | Old consumers ignore them |
| Add **new event types** | No existing consumer subscribed |
| Deprecate fields (keep sending) | Consumers still receive expected data |

**❌ Breaking Changes (require versioning)**

| Change | Why Breaking |
|--------|-------------|
| Remove fields | Consumers expecting them will fail |
| Rename fields | Same as remove + add |
| Change field types | Deserialization breaks |
| Change semantics | Silent data corruption |

</grid>

---

<!-- slide bg="#0f1b33" -->

## 🗂️ Schema Registry Strategy

~~~mermaid
flowchart LR
    P[Producer] -->|"1. Register schema"| SR[Schema Registry\nConfluent / Glue / Apicurio]
    SR -->|"2. Validate\ncompatibility"| SR
    SR -->|"3. Provide schema"| C[Consumer]
    P -->|"4. Publish event"| B[Broker]
    B --> C
    SR -.->|"❌ Reject if breaking"| P
~~~

<grid drag="80 20" drop="bottom" pad="0 0 10px 0" style="font-size: 0.72em;">

| Practice | Detail |
|----------|--------|
| Version events from **day one** | `v1`, `v2` in type or topic |
| Support **multiple versions** during migration | Sunset old after consumers upgrade |
| Use **consumer-driven contract tests** | Pact / Spring Cloud Contract |

</grid>

---

<!-- slide bg="#0f1b33" -->

# 5️⃣ Handling Failures

### Retries, DLQ, Ordering, Exactly-Once

---

<!-- slide bg="#0f1b33" -->

## 🔁 Retry & Dead Letter Queue

~~~mermaid
flowchart TB
    Q[Event Topic] --> C[Consumer]
    C -->|Success| ACK["Acknowledge ✅"]
    C -->|Failure| RETRY{"Retry?"}
    RETRY -->|"Attempts < 3"| Q
    RETRY -->|"Attempts ≥ 3"| DLQ["Dead Letter Queue ☠️"]
    DLQ --> ALERT["Alert + Manual Review"]
    DLQ --> REPLAY["Replay After Fix 🔄"]
~~~

<grid drag="80 15" drop="bottom" pad="0 0 10px 0" style="font-size: 0.7em;">

| Strategy | Detail |
|----------|--------|
| **Exponential backoff** | 1s → 2s → 4s to avoid thundering herd |
| **DLQ monitoring** | Alerts on DLQ depth — never ignore it |

</grid>

---

<!-- slide bg="#0f1b33" -->

## 🔢 Ordering Guarantees

~~~mermaid
flowchart LR
    PUB["Published:\nOrderPlaced → OrderPaid → OrderShipped"]
    REC["Received:\nOrderPaid → OrderPlaced → OrderShipped ❌"]
    PUB -.->|"out of order"| REC
~~~

<grid drag="88 45" drop="center" pad="10px 0 0 0" style="font-size: 0.7em;">

| # | Solution | How It Works |
|---|----------|-------------|
| 1 | **Partition by entity ID** | All events for `order-123` → same partition → ordered |
| 2 | **Sequence numbers** | Monotonic seq per entity; consumer buffers & reorders |
| 3 | **State machine validation** | Consumer rejects invalid transitions; retries later |
| 4 | **Idempotent processing** | Design so reprocessing is safe regardless of order |

</grid>

<grid drag="80 8" drop="bottom" style="font-size: 0.65em; color: #94a3b8; text-align: center;">

Kafka guarantees order **within a partition** — choose partition key wisely.

</grid>

---

<!-- slide bg="#0f1b33" -->

## 🎯 Exactly-Once Processing

~~~mermaid
flowchart TB
    subgraph TX["BEGIN TRANSACTION"]
        CHK{"event_id in\nprocessed_events?"}
        CHK -->|YES| SKIP[Skip — idempotent guard]
        CHK -->|NO| BIZ[Execute business logic]
        BIZ --> WR[Write results to DB]
        WR --> INS[Insert event_id\ninto processed_events]
        INS --> OUT[Write outgoing events\nto outbox table]
    end
    OUT --> COMMIT[COMMIT]
    COMMIT --> RELAY[Outbox Relay\npolls or CDC]
    RELAY --> BROKER[Event Broker]
~~~

<grid drag="80 8" drop="bottom" style="font-size: 0.65em; color: #94a3b8; text-align: center;">

Reality: Brokers provide **at-least-once**. Exactly-once is the **consumer's job**.

</grid>

---

<!-- slide bg="#0f1b33" -->

## 📤 Transactional Outbox Deep Dive

~~~mermaid
flowchart TB
    subgraph DB["Service Database"]
        BT["Business Tables\n(orders, payments)"]
        OB["outbox_events\nid | event_type | payload | published"]
        BT <-->|"same transaction"| OB
    end

    OB --> RELAY["Outbox Relay\n(Debezium CDC / Polling)"]
    RELAY --> BROKER["Event Broker\n(Kafka / SQS)"]
~~~

<grid drag="80 15" drop="bottom" pad="0 0 10px 0" style="font-size: 0.68em;">

| Approach | Detail |
|----------|--------|
| **Polling** | Relay queries outbox on interval — simple but adds latency |
| **CDC (Debezium)** | Reads DB write-ahead log → near real-time, no polling |

</grid>

---

<!-- slide bg="#0f1b33" -->

# 6️⃣ Observability & Tracing

### Seeing Through Async Flows

---

<!-- slide bg="#0f1b33" -->

## 🔍 Distributed Tracing for Events

~~~mermaid
flowchart TB
    REQ["User Request\ncorrelationId: req-67890"] --> OS[Order Service]
    OS -->|publish| OP["OrderPlaced\ntraceId: abc"]

    OP --> PAY[Payment Svc\nspan: pay]
    OP --> INV[Inventory Svc\nspan: inv]
    OP --> ANA[Analytics Svc\nspan: ana]

    PAY --> PP[PaymentProcessed]
    INV --> SR[StockReserved]

    PP --> NOT[Notification Svc\nspan: notify]
~~~

<grid drag="80 15" drop="bottom" pad="0 0 5px 0" style="font-size: 0.68em;">

| Field | Role |
|-------|------|
| `correlationId` | Groups **all events** from one user action |
| `causationId` | Links **parent → child** event |
| `traceId` | Bridges into **Jaeger / Zipkin / OTEL** spans |

</grid>

---

<!-- slide bg="#0f1b33" -->

## 📈 Essential Metrics

<grid drag="88 60" drop="center" style="font-size: 0.7em;">

| Metric | What to Monitor | Alert Threshold |
|--------|----------------|-----------------|
| **Consumer lag** | Events unprocessed per partition | > 10k or growing |
| **Processing latency** | p50 / p95 / p99 per consumer | p99 > SLA |
| **DLQ depth** | Messages in dead letter queue | > 0 |
| **Throughput** | Events/sec produced & consumed | Drop > 50% |
| **Error rate** | Failed processing attempts | > 1% |
| **Redelivery rate** | Retried messages / total | > 5% |
| **End-to-end latency** | Time from publish to final effect | > business SLA |

</grid>

<grid drag="80 8" drop="bottom" style="font-size: 0.6em; color: #94a3b8; text-align: center;">

Tools: **Prometheus + Grafana**, **Datadog**, **AWS CloudWatch**, **Kafka Manager**

</grid>

---

<!-- slide bg="#0f1b33" -->

# 7️⃣ Anti-Patterns

### What NOT to Do

---

<!-- slide bg="#0f1b33" -->

## 🍜 Event Soup

~~~mermaid
flowchart LR
    A[UserClickedButton] --> B[FormValidated]
    B --> C[FieldUpdated]
    C --> D[UIRefreshed]
    D --> E[LogWritten]
    E --> F[MetricEmitted]
    F --> G["... 🤯"]
~~~

<grid drag="80 30" drop="center" pad="20px 0 0 0" style="font-size: 0.75em;">

| Problem | Fix |
|---------|-----|
| Everything is an event | Only publish **meaningful domain state changes** |
| No clear boundaries | Define **bounded contexts** first |
| UI events on the bus | Keep UI events **inside the frontend** |

</grid>

---

<!-- slide bg="#0f1b33" -->

## 🏗️ Distributed Monolith

~~~mermaid
flowchart LR
    OS[Order Service\nOrderPlaced v1] --> PAY[Payment\nexpects EXACT fields]
    OS --> INV[Inventory\nexpects EXACT order]
    PAY -.->|"change one"| BREAK["💥 Break them all"]
    INV -.-> BREAK
~~~

<grid drag="80 30" drop="center" pad="20px 0 0 0" style="font-size: 0.75em;">

| Problem | Fix |
|---------|-----|
| Tight schema coupling | **Tolerant reader** — ignore unknown fields |
| Assumed ordering | **Consumer-driven contracts** |
| Shared event models | Each consumer owns its **own projection** |

</grid>

---

<!-- slide bg="#0f1b33" -->

## 🔄 Event Cycles & Other Traps

~~~mermaid
flowchart LR
    OS[OrderService] -->|OrderPlaced| IS[InventoryService]
    IS -->|StockReserved| OS
    OS -->|OrderUpdated| IS
    IS -->|"??? ♾️"| OS
~~~

<grid drag="80 35" drop="center" pad="15px 0 0 0" style="font-size: 0.7em;">

| Anti-Pattern | Fix |
|-------------|-----|
| **Event Cycles** | Clear ownership; distinguish commands vs events |
| **God Event** | One event with 50 fields → split by concern |
| **Missing DLQ** | Always configure dead letter handling |
| **Fire & Forget** | No monitoring = silent data loss |
| **Sync over Async** | Consumer blocks waiting for response event → use HTTP |

</grid>

---

<!-- slide bg="#0f1b33" -->

# 8️⃣ Technology Comparison

### Choosing Your Event Backbone

---

<!-- slide bg="#0f1b33" -->

## 🛠️ Broker Comparison

<grid drag="92 60" drop="center" style="font-size: 0.6em;">

| Feature | Apache Kafka | RabbitMQ | AWS EventBridge | AWS SNS+SQS | Pulsar |
|---------|:---:|:---:|:---:|:---:|:---:|
| **Model** | Log-based | Queue-based | Serverless bus | Pub-Sub + Queue | Log-based |
| **Ordering** | Per partition | Per queue | Best-effort | FIFO option | Per partition |
| **Replay** | ✅ Retention | ❌ | ✅ Archive | ❌ | ✅ |
| **Throughput** | 🟢 Very high | 🟡 Medium | 🟡 Medium | 🟡 Medium | 🟢 Very high |
| **Latency** | ~ms | ~µs | ~100ms | ~ms | ~ms |
| **Ops burden** | 🔴 High | 🟡 Medium | 🟢 None | 🟢 None | 🔴 High |
| **Best for** | High-vol streaming | Task queues | AWS-native | Simple fan-out | Multi-tenant |

</grid>

---

<!-- slide bg="#0f1b33" -->

# 9️⃣ When to Use

### (and When NOT To)

---

<!-- slide bg="#0f1b33" -->

## ✅ Good Fit vs ❌ Poor Fit

<grid drag="88 55" drop="center" style="font-size: 0.72em;">

| ✅ Good Fit | ❌ Poor Fit |
|------------|-----------|
| Multiple consumers need same data | Simple CRUD with one consumer |
| Services owned by different teams | Tight consistency required |
| Add consumers without changing producer | Low-latency sync response needed |
| Audit trail / event replay needed | Small monolithic application |
| Spike handling / load leveling | Team unfamiliar with async patterns |
| Event sourcing for complex domains | Simple request-response suffices |
| Cross-region data replication | Single-region, single-database |

</grid>

---

<!-- slide bg="#0f1b33" -->

## 🧭 Decision Framework

~~~mermaid
flowchart TB
    Q1{"Multiple services need\nto react to a change?"} -->|Yes| Q2{"Need real-time\nresponse to caller?"}
    Q1 -->|No| SYNC["✅ Synchronous call"]

    Q2 -->|Yes| HYBRID["✅ Hybrid: sync response\n+ async side effects"]
    Q2 -->|No| Q3{"Complex multi-step\nworkflow?"}

    Q3 -->|Yes| ORCH["✅ Event-driven\nwith Orchestration"]
    Q3 -->|No| CHOREO["✅ Event-driven\nwith Choreography"]
~~~

---

<!-- slide bg="#0f1b33" -->

# 🔟 Key Takeaways

---

<!-- slide bg="#0f1b33" -->

## 📌 Eight Things to Remember

<grid drag="88 65" drop="center" style="font-size: 0.72em;">

| # | Takeaway |
|---|----------|
| 1 | **Events** = what happened · **Commands** = what to do |
| 2 | Choose **payload size** based on coupling tolerance |
| 3 | **Schema evolution** is first-class — version from **day one** |
| 4 | **Partition by entity ID** for ordering + **idempotency** for safety |
| 5 | **Dead letter queues** are not optional — plan for failure |
| 6 | Avoid **event soup** — only publish meaningful domain events |
| 7 | **Hybrid** sync + async is common — not everything must be async |
| 8 | **Correlation IDs** + distributed tracing = essential debugging |

</grid>

---

<!-- slide bg="#0f1b33" -->

# 1️⃣1️⃣ Practical Exercise

### 🍔 Food Delivery Platform

---

<!-- slide bg="#0f1b33" -->

## 🍔 Design Challenge

<grid drag="85 70" drop="center" style="font-size: 0.68em;">

**Services:** `Restaurant` · `Order` · `Delivery` · `Payment` · `Notification`

**Flow:**

| Step | Action |
|------|--------|
| 1 | Customer places order |
| 2 | Restaurant confirms or rejects (5 min timeout) |
| 3 | Payment is processed |
| 4 | Driver is assigned |
| 5 | Real-time tracking updates |
| 6 | Delivery confirmed |

**Constraints:**
- Restaurant has **5 minutes** to accept
- Payment failure after accept → **notify restaurant**
- Customer sees **real-time status** updates
- Analytics team wants **all events** for reporting

</grid>

---

<!-- slide bg="#0f1b33" -->

## 💬 Discussion Questions

<grid drag="85 65" drop="center" style="font-size: 0.78em;">

| # | Question |
|---|----------|
| 1 | What events does **each service** publish? |
| 2 | How do you handle **restaurant timeout** (no response in 5 min)? |
| 3 | **Choreography or orchestration** for the order flow? Why? |
| 4 | How do you push **real-time updates** to the customer? |
| 5 | What happens if the **driver cancels** mid-delivery? |
| 6 | Where does the **analytics service** subscribe? |
| 7 | How do you guarantee **payment ↔ restaurant** consistency? |

</grid>

---

<!-- slide bg="#0f1b33" -->

## 🗺️ Possible Event Flow

~~~mermaid
flowchart TB
    CUST[Customer] --> OS[OrderService]
    OS -->|publish| OP[OrderPlaced]

    OP --> RS[RestaurantSvc]
    OP --> ANA[Analytics]
    OP --> NOT1["NotificationSvc\n(order received)"]

    RS -->|publish| OA[OrderAccepted]

    OA --> PAY[PaymentService]
    OA --> NOT2["NotificationSvc\n(restaurant confirmed)"]

    PAY -->|publish| PP[PaymentProcessed]

    PP --> DEL[DeliveryService]
    DEL -->|publish| DA[DriverAssigned]
    DA -->|stream| LU["LocationUpdated\n(real-time)"]
    LU --> DC[DeliveryCompleted]

    DC --> NOT3[NotificationSvc]
    DC --> ANA2[Analytics]
~~~

---

<!-- slide bg="#0b1120" -->

<grid drag="80 30" drop="center" style="place-items: center;">

# 🔷 Thank You

### Questions & Discussion

</grid>

<grid drag="60 10" drop="center" pad="60px 0 0 0" style="font-size: 0.8em; color: #64748b; text-align: center;">

Event-Driven Architecture Guide — v2.0

</grid>