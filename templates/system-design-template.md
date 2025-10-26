# [System Name] - System Design Document

> **Document Status**: [Draft | In Review | Approved | Deprecated]  
> **Version**: [1.0]  
> **Last Updated**: [YYYY-MM-DD]  
> **Authors**: [Name(s)]  
> **Reviewers**: [Name(s)]  
> **Approvers**: [Name(s)]

---

## Table of Contents

1. [Overview & Requirements](#1-overview--requirements)
2. [High Level Design](#2-high-level-design)
3. [API Design](#3-api-design)
4. [Data Schema Design](#4-data-schema-design)
5. [Low Level Design](#5-low-level-design)
6. [Key Dependencies](#6-key-dependencies)
7. [System Qualities](#7-system-qualities)
8. [Cost Estimation](#8-cost-estimation)
9. [Testing Strategy](#9-testing-strategy)
10. [Operations & Observability](#10-operations--observability)
11. [Migration & Rollout Plan](#11-migration--rollout-plan)

---

## 1. Overview & Requirements

### 1.1 Background & Context

**Problem Statement**

[Describe the problem this system solves. Be specific about pain points.]

**Example**: Our e-commerce platform currently processes orders synchronously, causing timeouts during peak traffic (Black Friday). 
Customers experience 30% cart abandonment when checkout takes >5 seconds. We need an asynchronous order processing system 
that can handle 10,000 orders/minute with <2s response time.

**Business Context**

- **Current State**: [What exists today?]
- **Desired State**: [What should exist?]
- **Business Impact**: [Revenue, cost savings, user satisfaction]
- **Timeline**: [Launch date, milestones]

**Stakeholders**

| Role | Name | Responsibility |
|------|------|----------------|
| Product Owner | [Name] | Requirements, priorities |
| Tech Lead | [Name] | Architecture decisions |
| Engineering Manager | [Name] | Resource allocation |
| Security Lead | [Name] | Security review |


### 1.2 User Experience & User Stories

**Target Users**

- **Primary**: [End customers, internal users, API consumers]
- **Secondary**: [Admins, support staff, developers]

**User Stories**

```
As a [user type]
I want to [action]
So that [benefit]

Acceptance Criteria:
- [ ] [Specific, measurable criterion]
- [ ] [Another criterion]
```

**Example - E-commerce Order Placement**:

```
As a customer
I want to place an order and receive immediate confirmation
So that I know my purchase is being processed

Acceptance Criteria:
- [ ] Order confirmation appears within 2 seconds
- [ ] Confirmation email sent within 30 seconds
- [ ] Order appears in "My Orders" immediately
- [ ] Payment is authorized before confirmation
- [ ] Inventory is reserved for 15 minutes
```

**User Journey**

1. User adds items to cart
2. User proceeds to checkout
3. User enters shipping/payment info
4. System validates payment → **[Critical path]**
5. System creates order → **[Critical path]**
6. User receives confirmation → **[Critical path]**
7. System processes order asynchronously
8. User receives shipping notification

### 1.3 Functional Requirements

| ID | Requirement | Priority | Complexity | Dependencies |
|----|-------------|----------|------------|--------------|
| FR-1 | User can place order with multiple items | P0 (Must Have) | Medium | Payment service, Inventory service |
| FR-2 | System validates inventory availability | P0 (Must Have) | High | Inventory service |
| FR-3 | System processes payment authorization | P0 (Must Have) | High | Payment gateway |
| FR-4 | User receives order confirmation | P0 (Must Have) | Low | Email service |
| FR-5 | System handles order cancellation | P1 (Should Have) | Medium | Payment service, Inventory service |
| FR-6 | User can track order status | P1 (Should Have) | Low | Shipping service |
| FR-7 | System supports promotional codes | P2 (Nice to Have) | Medium | Pricing service |
| FR-8 | User can save cart for later | P2 (Nice to Have) | Low | None |

**Priority Definitions**:
- **P0 (Must Have)**: MVP requirement, system cannot launch without it
- **P1 (Should Have)**: Important but can be added post-launch
- **P2 (Nice to Have)**: Enhances experience but not critical
- **P3 (Won't Have)**: Out of scope for this phase


### 1.4 Non-Functional Requirements

#### Performance

| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| API Response Time (P50) | < 100ms | Application metrics |
| API Response Time (P95) | < 300ms | Application metrics |
| API Response Time (P99) | < 500ms | Application metrics |
| Throughput | 10,000 requests/second | Load testing |
| Database Query Time (P95) | < 50ms | Database metrics |
| Cache Hit Rate | > 90% | Cache metrics |

#### Availability & Reliability

| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| Uptime SLA | 99.9% (43.8 min downtime/month) | Monitoring |
| Error Rate | < 0.1% | Application logs |
| Mean Time To Recovery (MTTR) | < 15 minutes | Incident tracking |
| Mean Time Between Failures (MTBF) | > 720 hours (30 days) | Incident tracking |

#### Scalability

| Dimension | Current | 1 Year | 3 Years |
|-----------|---------|--------|---------|
| Daily Active Users (DAU) | 100K | 500K | 2M |
| Requests Per Second (RPS) | 1,000 | 5,000 | 20,000 |
| Data Storage | 100 GB | 1 TB | 10 TB |
| Database Transactions/sec | 500 | 2,500 | 10,000 |

**Scaling Strategy**: Horizontal scaling with auto-scaling groups, database read replicas, CDN for static assets

#### Security

- **Authentication**: OAuth 2.0 / JWT tokens with 1-hour expiry
- **Authorization**: Role-Based Access Control (RBAC)
- **Data Encryption**: 
  - At rest: AES-256
  - In transit: TLS 1.3
- **Compliance**: [GDPR, PCI-DSS, SOC 2, HIPAA - select applicable]
- **Data Retention**: [Specify retention policies]
- **Audit Logging**: All sensitive operations logged with user ID, timestamp, action

#### Maintainability

- **Code Coverage**: > 80% for critical paths
- **Documentation**: API docs auto-generated from code
- **Deployment Frequency**: Multiple times per day
- **Lead Time for Changes**: < 1 hour from commit to production

### 1.5 Success Metrics

#### Business Metrics

| Metric | Baseline | Target | Timeline |
|--------|----------|--------|----------|
| Order Completion Rate | 70% | 85% | 3 months |
| Revenue Per User | $50 | $65 | 6 months |
| Customer Acquisition Cost | $25 | $20 | 6 months |
| Cart Abandonment Rate | 30% | 15% | 3 months |

#### Technical Metrics

| Metric | Baseline | Target | Timeline |
|--------|----------|--------|----------|
| API P99 Latency | 2000ms | 500ms | 1 month |
| System Uptime | 99.5% | 99.9% | 3 months |
| Error Rate | 1% | 0.1% | 2 months |
| Infrastructure Cost per Order | $0.10 | $0.05 | 6 months |

#### User Satisfaction Metrics

| Metric | Baseline | Target | Timeline |
|--------|----------|--------|----------|
| Net Promoter Score (NPS) | 30 | 50 | 6 months |
| Customer Satisfaction (CSAT) | 3.5/5 | 4.5/5 | 3 months |
| Support Ticket Volume | 1000/month | 500/month | 6 months |


---

## 2. High Level Design

### 2.1 Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                           Client Layer                               │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐           │
│  │ Web App  │  │ Mobile   │  │  Admin   │  │ Partner  │           │
│  │          │  │   App    │  │  Portal  │  │   API    │           │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘           │
└───────┼─────────────┼─────────────┼─────────────┼──────────────────┘
        │             │             │             │
        └─────────────┴─────────────┴─────────────┘
                      │
        ┌─────────────▼─────────────┐
        │     CDN / API Gateway     │  ← Rate limiting, SSL termination
        │   (CloudFront / Kong)     │
        └─────────────┬─────────────┘
                      │
        ┌─────────────▼─────────────┐
        │    Load Balancer (ALB)    │  ← Health checks, SSL offload
        └─────────────┬─────────────┘
                      │
┌─────────────────────┼─────────────────────────────────────────────┐
│                Application Layer                                   │
│     ┌───────────────┴───────────────┐                             │
│     │                                │                             │
│  ┌──▼────────┐  ┌──────────┐  ┌────▼──────┐  ┌──────────┐       │
│  │  Order    │  │ Payment  │  │ Inventory │  │  User    │       │
│  │  Service  │  │ Service  │  │  Service  │  │ Service  │       │
│  └─────┬─────┘  └────┬─────┘  └─────┬─────┘  └────┬─────┘       │
│        │             │               │             │              │
└────────┼─────────────┼───────────────┼─────────────┼──────────────┘
         │             │               │             │
         └─────────────┴───────────────┴─────────────┘
                       │
         ┌─────────────▼─────────────┐
         │    Message Queue (SQS)    │  ← Async processing
         └─────────────┬─────────────┘
                       │
         ┌─────────────▼─────────────┐
         │   Background Workers      │  ← Order fulfillment, emails
         └───────────────────────────┘
                       │
┌──────────────────────┼────────────────────────────────────────────┐
│                  Data Layer                                        │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐        │
│  │   Primary DB  │  │   Read        │  │   Cache       │        │
│  │  (PostgreSQL) │  │   Replicas    │  │   (Redis)     │        │
│  │   Master      │──│   (3x)        │  │               │        │
│  └───────────────┘  └───────────────┘  └───────────────┘        │
│                                                                    │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐        │
│  │   Object      │  │   Search      │  │   Analytics   │        │
│  │   Storage     │  │   Engine      │  │   DB          │        │
│  │   (S3)        │  │ (Elasticsearch)│  │ (Redshift)    │        │
│  └───────────────┘  └───────────────┘  └───────────────┘        │
└────────────────────────────────────────────────────────────────────┘
```

**Architecture Style**: Microservices with event-driven communication

**Key Characteristics**:
- **Stateless services**: All application servers are stateless for easy horizontal scaling
- **Async processing**: Heavy operations (email, fulfillment) handled asynchronously
- **Database separation**: Read replicas for queries, master for writes
- **Caching layer**: Redis for session data, frequently accessed data
- **Message queue**: Decouples services, enables retry logic

### 2.2 Component Overview

| Component | Responsibility | Technology | Scaling Strategy |
|-----------|---------------|------------|------------------|
| API Gateway | Request routing, rate limiting, auth | Kong / AWS API Gateway | Horizontal (auto-scale) |
| Load Balancer | Traffic distribution, health checks | AWS ALB / NGINX | Managed service |
| Order Service | Order creation, validation, status | Node.js / Express | Horizontal (K8s pods) |
| Payment Service | Payment processing, refunds | Java / Spring Boot | Horizontal (K8s pods) |
| Inventory Service | Stock management, reservations | Go / Gin | Horizontal (K8s pods) |
| User Service | Authentication, user profiles | Python / FastAPI | Horizontal (K8s pods) |
| Message Queue | Async task distribution | AWS SQS / RabbitMQ | Managed service |
| Background Workers | Email, fulfillment, analytics | Python / Celery | Horizontal (worker pool) |
| Primary Database | Transactional data (orders, users) | PostgreSQL 14 | Vertical + read replicas |
| Cache | Session data, hot data | Redis 7 | Cluster mode (3 nodes) |
| Object Storage | Images, documents, backups | AWS S3 | Managed service |
| Search Engine | Product search, filtering | Elasticsearch 8 | Cluster (3 nodes) |
| Analytics DB | Business intelligence, reporting | AWS Redshift | Managed service |


### 2.3 Technology Stack

| Layer | Technology | Rationale | Alternatives Considered |
|-------|-----------|-----------|------------------------|
| **Frontend** | React 18 + TypeScript | ✅ Large ecosystem, TypeScript safety, component reusability | ❌ Vue.js (smaller team), ❌ Angular (too heavy) |
| **API Gateway** | Kong | ✅ Plugin ecosystem, rate limiting, auth built-in | ❌ AWS API Gateway (vendor lock-in), ❌ NGINX (manual config) |
| **Backend Services** | Node.js + Express | ✅ Fast development, async I/O, JavaScript everywhere | ❌ Java Spring (verbose), ❌ Python (slower) |
| **Database** | PostgreSQL 14 | ✅ ACID compliance, JSON support, mature ecosystem | ❌ MySQL (weaker JSON), ❌ MongoDB (no transactions) |
| **Cache** | Redis 7 | ✅ Fast, data structures, pub/sub support | ❌ Memcached (limited features), ❌ DynamoDB (cost) |
| **Message Queue** | AWS SQS | ✅ Managed, reliable, scales automatically | ❌ RabbitMQ (ops overhead), ❌ Kafka (overkill) |
| **Search** | Elasticsearch 8 | ✅ Full-text search, faceted search, analytics | ❌ Algolia (expensive), ❌ PostgreSQL FTS (limited) |
| **Container Orchestration** | Kubernetes (EKS) | ✅ Industry standard, auto-scaling, self-healing | ❌ ECS (AWS lock-in), ❌ Docker Swarm (limited) |
| **CI/CD** | GitHub Actions | ✅ Integrated with repo, free for public repos | ❌ Jenkins (maintenance), ❌ CircleCI (cost) |
| **Monitoring** | Datadog | ✅ Unified observability, APM, log aggregation | ❌ Prometheus+Grafana (ops overhead), ❌ New Relic (cost) |
| **Object Storage** | AWS S3 | ✅ Durable, cheap, CDN integration | ❌ Google Cloud Storage (multi-cloud), ❌ MinIO (ops) |

### 2.4 Design Decisions & Trade-offs

#### Decision 1: Microservices vs Monolith

**Decision**: Start with modular monolith, migrate to microservices as needed

| Aspect | Monolith | Microservices | Our Choice |
|--------|----------|---------------|------------|
| Development Speed | ✅ Faster initially | ❌ Slower setup | ✅ Monolith (MVP) |
| Operational Complexity | ✅ Simpler | ❌ Complex (networking, monitoring) | ✅ Monolith |
| Scalability | ❌ Scale entire app | ✅ Scale individual services | ⚠️ Acceptable for now |
| Team Independence | ❌ Shared codebase | ✅ Independent teams | ⚠️ Small team now |
| Technology Flexibility | ❌ One stack | ✅ Polyglot | ⚠️ Not needed yet |

**Rationale**: Team of 5 engineers, need to ship MVP in 3 months. Microservices overhead not justified. Will extract services when:
- Service needs independent scaling (e.g., payment processing)
- Team grows beyond 15 engineers
- Clear service boundaries emerge

#### Decision 2: SQL vs NoSQL

**Decision**: PostgreSQL for primary database

| Aspect | PostgreSQL | MongoDB | DynamoDB |
|--------|-----------|---------|----------|
| ACID Transactions | ✅ Full support | ⚠️ Limited | ❌ No multi-item |
| Schema Flexibility | ⚠️ Requires migrations | ✅ Schemaless | ✅ Schemaless |
| Query Flexibility | ✅ Complex joins, aggregations | ⚠️ Limited joins | ❌ No joins |
| Operational Cost | ✅ Predictable | ✅ Moderate | ❌ Expensive at scale |
| Scaling | ⚠️ Vertical + sharding | ✅ Horizontal | ✅ Automatic |

**Rationale**: Order processing requires ACID transactions (payment + inventory + order creation). Complex reporting queries need joins. 
Team has PostgreSQL expertise. Will use DynamoDB for specific use cases (session storage, real-time features).

#### Decision 3: Synchronous vs Asynchronous Processing

**Decision**: Hybrid approach

| Operation | Approach | Rationale |
|-----------|----------|-----------|
| Order Creation | Synchronous | User needs immediate feedback |
| Payment Authorization | Synchronous | Must confirm before order creation |
| Inventory Reservation | Synchronous | Prevent overselling |
| Email Notification | Asynchronous | Not time-critical, can retry |
| Order Fulfillment | Asynchronous | Long-running process |
| Analytics Updates | Asynchronous | Not user-facing |

**Trade-off**: Synchronous = better UX but higher latency. Asynchronous = better performance but eventual consistency.

### 2.5 Data Flow

**Order Placement Flow**:

1. **Client** → API Gateway: POST /api/v1/orders
2. **API Gateway** → Order Service: Validate request, check auth
3. **Order Service** → Inventory Service: Reserve items (sync)
4. **Order Service** → Payment Service: Authorize payment (sync)
5. **Order Service** → Database: Create order record (transaction)
6. **Order Service** → Message Queue: Publish OrderCreated event
7. **Order Service** → Client: Return order confirmation (200 OK)
8. **Background Worker** ← Message Queue: Process OrderCreated event
9. **Background Worker** → Email Service: Send confirmation email
10. **Background Worker** → Analytics DB: Update metrics

**Critical Path** (must complete for user response): Steps 1-7 (~500ms target)  
**Async Path** (can fail and retry): Steps 8-10 (~30s target)


---

## 3. API Design

> 💡 **Note**: This section is optional but highly recommended for production systems. Include if cost is a significant factor.

### 3.1 Infrastructure Costs (Monthly)

| Component | Specification | Unit Cost | Quantity | Monthly Cost |
|-----------|--------------|-----------|----------|--------------|
| **Compute** |
| Application Servers | t3.medium (2 vCPU, 4GB) | $30 | 10 | $300 |
| Background Workers | t3.small (2 vCPU, 2GB) | $15 | 5 | $75 |
| **Database** |
| Primary DB | db.r5.xlarge (4 vCPU, 32GB) | $350 | 1 | $350 |
| Read Replicas | db.r5.large (2 vCPU, 16GB) | $175 | 3 | $525 |
| **Cache** |
| Redis Cluster | cache.r5.large (2 vCPU, 13GB) | $150 | 3 | $450 |
| **Storage** |
| S3 Storage | $0.023/GB | - | 5TB | $115 |
| S3 Requests | $0.0004/1K requests | - | 100M | $40 |
| Database Storage | $0.115/GB | - | 500GB | $58 |
| **Networking** |
| Data Transfer Out | $0.09/GB | - | 10TB | $900 |
| Load Balancer | $16 + $0.008/LCU | - | - | $50 |
| **CDN** |
| CloudFront | $0.085/GB + requests | - | 20TB | $1,700 |
| **Monitoring & Logs** |
| Datadog | $15/host | - | 15 hosts | $225 |
| CloudWatch Logs | $0.50/GB | - | 100GB | $50 |
| **Message Queue** |
| SQS | $0.40/million requests | - | 50M | $20 |
| **Total** | | | | **$4,858/month** |

**Cost per User**: $4,858 / 100,000 DAU = **$0.049 per DAU**

### 3.2 Third-Party Service Costs (Monthly)

| Service | Purpose | Pricing Model | Monthly Cost |
|---------|---------|---------------|--------------|
| Stripe | Payment processing | 2.9% + $0.30 per transaction | $5,800 (on $200K GMV) |
| SendGrid | Email delivery | $0.0006 per email | $180 (300K emails) |
| Twilio | SMS notifications | $0.0075 per SMS | $75 (10K SMS) |
| Auth0 | Authentication | $240/month (up to 1000 MAU) | $240 |
| Algolia | Product search | $1/1000 searches | $500 (500K searches) |
| **Total** | | | **$6,795/month** |

### 3.3 Total Cost Summary

| Category | Monthly Cost | Annual Cost |
|----------|--------------|-------------|
| Infrastructure | $4,858 | $58,296 |
| Third-Party Services | $6,795 | $81,540 |
| **Total** | **$11,653** | **$139,836** |

**Cost Metrics**:
- Cost per DAU: $0.117
- Cost per Order: $1.17 (assuming 10K orders/month)
- Cost per Transaction: $0.58 (assuming 20K transactions/month)

### 3.4 Cost Optimization Strategies

| Strategy | Potential Savings | Implementation Effort | Priority |
|----------|------------------|----------------------|----------|
| Reserved Instances (1-year) | 30% on compute ($113/month) | Low | High |
| S3 Intelligent Tiering | 20% on storage ($23/month) | Low | High |
| CloudFront optimization | 15% on CDN ($255/month) | Medium | Medium |
| Database query optimization | 10% on DB ($88/month) | High | Medium |
| Compress images/assets | 25% on bandwidth ($225/month) | Medium | High |
| Self-hosted search (Elasticsearch) | 100% on Algolia ($500/month) | High | Low |
| **Total Potential Savings** | **$1,204/month (10%)** | | |

**Cost Scaling Projections**:

| Metric | Current | 6 Months | 1 Year | 3 Years |
|--------|---------|----------|--------|---------|
| DAU | 100K | 250K | 500K | 2M |
| Monthly Cost | $11,653 | $22,000 | $38,000 | $120,000 |
| Cost per DAU | $0.117 | $0.088 | $0.076 | $0.060 |

> 💡 **Cost Efficiency Improves with Scale**: Due to reserved instances, volume discounts, and better resource utilization.


### 3.1 API Overview

**API Style**: RESTful HTTP API  
**Base URL**: `https://api.example.com/v1`  
**Protocol**: HTTPS only (TLS 1.3)  
**Data Format**: JSON  
**Character Encoding**: UTF-8

### 3.2 Authentication & Authorization

**Authentication Method**: JWT (JSON Web Tokens)

**Token Structure**:
```json
{
  "header": {
    "alg": "RS256",
    "typ": "JWT"
  },
  "payload": {
    "sub": "user_12345",
    "email": "user@example.com",
    "roles": ["customer"],
    "iat": 1640000000,
    "exp": 1640003600
  }
}
```

**Authorization Header**:
```
Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Token Lifecycle**:
- Access Token: 1 hour expiry
- Refresh Token: 30 days expiry
- Refresh endpoint: `POST /api/v1/auth/refresh`

**Role-Based Access Control (RBAC)**:

| Role | Permissions |
|------|-------------|
| `customer` | Create orders, view own orders, update profile |
| `admin` | All customer permissions + view all orders, manage inventory |
| `support` | View orders, update order status, issue refunds |
| `partner` | Create orders via API, view partner orders |

### 3.3 Core API Endpoints

#### 3.3.1 Create Order

**Endpoint**: `POST /api/v1/orders`

**Request Headers**:
```
Authorization: Bearer {token}
Content-Type: application/json
Idempotency-Key: {unique-request-id}
```

**Request Body**:
```json
{
  "items": [
    {
      "product_id": "prod_abc123",
      "quantity": 2,
      "price": 29.99
    },
    {
      "product_id": "prod_xyz789",
      "quantity": 1,
      "price": 49.99
    }
  ],
  "shipping_address": {
    "name": "John Doe",
    "street": "123 Main St",
    "city": "San Francisco",
    "state": "CA",
    "zip": "94102",
    "country": "US"
  },
  "payment_method": {
    "type": "card",
    "token": "tok_visa_4242"
  },
  "promo_code": "SUMMER2024"
}
```

**Success Response** (201 Created):
```json
{
  "order_id": "ord_1234567890",
  "status": "confirmed",
  "created_at": "2024-01-15T10:30:00Z",
  "items": [
    {
      "product_id": "prod_abc123",
      "name": "Wireless Headphones",
      "quantity": 2,
      "unit_price": 29.99,
      "total": 59.98
    },
    {
      "product_id": "prod_xyz789",
      "name": "Phone Case",
      "quantity": 1,
      "unit_price": 49.99,
      "total": 49.99
    }
  ],
  "subtotal": 109.97,
  "discount": 10.00,
  "tax": 8.80,
  "shipping": 5.99,
  "total": 114.76,
  "payment": {
    "status": "authorized",
    "method": "Visa ending in 4242",
    "transaction_id": "txn_abc123xyz"
  },
  "shipping_address": {
    "name": "John Doe",
    "street": "123 Main St",
    "city": "San Francisco",
    "state": "CA",
    "zip": "94102",
    "country": "US"
  },
  "estimated_delivery": "2024-01-20T00:00:00Z"
}
```

**Error Response** (400 Bad Request):
```json
{
  "error": {
    "code": "INSUFFICIENT_INVENTORY",
    "message": "Product 'prod_abc123' has insufficient inventory",
    "details": {
      "product_id": "prod_abc123",
      "requested": 2,
      "available": 1
    },
    "request_id": "req_xyz789"
  }
}
```

#### 3.3.2 Get Order

**Endpoint**: `GET /api/v1/orders/{order_id}`

**Request Headers**:
```
Authorization: Bearer {token}
```

**Success Response** (200 OK):
```json
{
  "order_id": "ord_1234567890",
  "status": "shipped",
  "created_at": "2024-01-15T10:30:00Z",
  "updated_at": "2024-01-16T14:20:00Z",
  "items": [...],
  "total": 114.76,
  "shipping": {
    "carrier": "UPS",
    "tracking_number": "1Z999AA10123456784",
    "estimated_delivery": "2024-01-20T00:00:00Z"
  },
  "timeline": [
    {
      "status": "confirmed",
      "timestamp": "2024-01-15T10:30:00Z"
    },
    {
      "status": "processing",
      "timestamp": "2024-01-15T11:00:00Z"
    },
    {
      "status": "shipped",
      "timestamp": "2024-01-16T14:20:00Z"
    }
  ]
}
```

#### 3.3.3 List Orders

**Endpoint**: `GET /api/v1/orders`

**Query Parameters**:
- `status`: Filter by status (confirmed, processing, shipped, delivered, cancelled)
- `from_date`: ISO 8601 date (e.g., 2024-01-01)
- `to_date`: ISO 8601 date
- `page`: Page number (default: 1)
- `limit`: Items per page (default: 20, max: 100)
- `sort`: Sort field (created_at, total, status)
- `order`: Sort order (asc, desc)

**Example Request**:
```
GET /api/v1/orders?status=shipped&from_date=2024-01-01&page=1&limit=20&sort=created_at&order=desc
```

**Success Response** (200 OK):
```json
{
  "data": [
    {
      "order_id": "ord_1234567890",
      "status": "shipped",
      "created_at": "2024-01-15T10:30:00Z",
      "total": 114.76,
      "items_count": 2
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total_pages": 5,
    "total_items": 87,
    "has_next": true,
    "has_prev": false
  }
}
```


### 3.4 Error Handling

**Error Response Format**:
```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable error message",
    "details": {
      "field": "additional context"
    },
    "request_id": "req_xyz789",
    "timestamp": "2024-01-15T10:30:00Z"
  }
}
```

**HTTP Status Codes**:

| Status Code | Meaning | Use Case |
|-------------|---------|----------|
| 200 OK | Success | GET, PUT, PATCH requests |
| 201 Created | Resource created | POST requests |
| 204 No Content | Success, no body | DELETE requests |
| 400 Bad Request | Invalid input | Validation errors |
| 401 Unauthorized | Missing/invalid auth | No token or expired token |
| 403 Forbidden | Insufficient permissions | User lacks required role |
| 404 Not Found | Resource doesn't exist | Invalid order_id |
| 409 Conflict | Resource conflict | Duplicate order (idempotency) |
| 422 Unprocessable Entity | Business logic error | Insufficient inventory |
| 429 Too Many Requests | Rate limit exceeded | Exceeded 1000 req/hour |
| 500 Internal Server Error | Server error | Unexpected errors |
| 503 Service Unavailable | Service down | Maintenance mode |

**Error Codes**:

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `INVALID_REQUEST` | 400 | Malformed request body |
| `VALIDATION_ERROR` | 400 | Field validation failed |
| `UNAUTHORIZED` | 401 | Missing or invalid token |
| `FORBIDDEN` | 403 | Insufficient permissions |
| `NOT_FOUND` | 404 | Resource not found |
| `DUPLICATE_REQUEST` | 409 | Idempotency key already used |
| `INSUFFICIENT_INVENTORY` | 422 | Not enough stock |
| `PAYMENT_FAILED` | 422 | Payment authorization failed |
| `RATE_LIMIT_EXCEEDED` | 429 | Too many requests |
| `INTERNAL_ERROR` | 500 | Unexpected server error |
| `SERVICE_UNAVAILABLE` | 503 | Service temporarily down |

### 3.5 API Versioning

**Strategy**: URL path versioning

**Current Version**: v1  
**Deprecation Policy**: 
- New version announced 6 months before old version deprecation
- Old version supported for 12 months after new version release
- Deprecation warnings in response headers

**Version Header**:
```
X-API-Version: 1
X-API-Deprecated: false
X-API-Sunset: 2025-12-31
```

### 3.6 Rate Limiting

**Rate Limits**:

| User Type | Requests per Hour | Burst Limit |
|-----------|------------------|-------------|
| Anonymous | 100 | 10/minute |
| Authenticated | 1,000 | 50/minute |
| Premium | 10,000 | 200/minute |
| Partner API | 50,000 | 1,000/minute |

**Rate Limit Headers**:
```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 987
X-RateLimit-Reset: 1640003600
```

**Rate Limit Exceeded Response** (429):
```json
{
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Rate limit exceeded. Try again in 45 seconds.",
    "details": {
      "limit": 1000,
      "remaining": 0,
      "reset_at": "2024-01-15T11:00:00Z"
    },
    "request_id": "req_xyz789"
  }
}
```

**Rate Limiting Strategy**:
- Algorithm: Token bucket
- Storage: Redis (distributed rate limiting)
- Key: `rate_limit:{user_id}:{endpoint}`
- TTL: 1 hour

### 3.7 Idempotency

**Idempotency Key**: Required for POST, PUT, PATCH requests

**Header**:
```
Idempotency-Key: {unique-request-id}
```

**Behavior**:
- Same key within 24 hours returns cached response
- Different request body with same key returns 409 Conflict
- Key format: UUID v4 or client-generated unique string

**Example**:
```bash
# First request
curl -X POST https://api.example.com/v1/orders \
  -H "Idempotency-Key: 550e8400-e29b-41d4-a716-446655440000" \
  -d '{"items": [...]}'
# Returns 201 Created

# Retry with same key (network error, timeout, etc.)
curl -X POST https://api.example.com/v1/orders \
  -H "Idempotency-Key: 550e8400-e29b-41d4-a716-446655440000" \
  -d '{"items": [...]}'
# Returns 200 OK with cached response (no duplicate order)
```

### 3.8 Pagination

**Cursor-Based Pagination** (recommended for large datasets):

**Request**:
```
GET /api/v1/orders?limit=20&cursor=eyJpZCI6MTIzNDU2fQ==
```

**Response**:
```json
{
  "data": [...],
  "pagination": {
    "next_cursor": "eyJpZCI6MTIzNDc2fQ==",
    "has_more": true
  }
}
```

**Offset-Based Pagination** (simpler, less efficient):

**Request**:
```
GET /api/v1/orders?page=2&limit=20
```

**Response**:
```json
{
  "data": [...],
  "pagination": {
    "page": 2,
    "limit": 20,
    "total_pages": 10,
    "total_items": 187
  }
}
```


---

## 4. Data Schema Design

### 4.1 Storage Selection & Rationale

| Data Type | Storage | Rationale |
|-----------|---------|-----------|
| **Transactional Data** (orders, payments) | PostgreSQL | ACID compliance, complex queries, referential integrity |
| **User Sessions** | Redis | Fast access, TTL support, distributed |
| **Product Catalog** | PostgreSQL + Elasticsearch | PostgreSQL for source of truth, Elasticsearch for search |
| **User Activity Logs** | S3 + Redshift | Cost-effective storage, analytics queries |
| **Images & Documents** | S3 + CloudFront | Scalable object storage, CDN delivery |
| **Real-time Features** (notifications) | Redis Pub/Sub | Low latency, ephemeral data |
| **Time-series Metrics** | InfluxDB / TimescaleDB | Optimized for time-series data |

### 4.2 Database Schema (PostgreSQL)

#### 4.2.1 Users Table

```sql
CREATE TABLE users (
    user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    phone VARCHAR(20),
    role VARCHAR(50) DEFAULT 'customer',
    status VARCHAR(20) DEFAULT 'active',
    email_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMP,
    metadata JSONB
);

-- Indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_users_created_at ON users(created_at DESC);
CREATE INDEX idx_users_metadata ON users USING GIN(metadata);
```

#### 4.2.2 Orders Table

```sql
CREATE TABLE orders (
    order_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(user_id),
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    subtotal DECIMAL(10, 2) NOT NULL,
    discount DECIMAL(10, 2) DEFAULT 0,
    tax DECIMAL(10, 2) NOT NULL,
    shipping DECIMAL(10, 2) NOT NULL,
    total DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    payment_status VARCHAR(50) DEFAULT 'pending',
    payment_method VARCHAR(50),
    shipping_address JSONB NOT NULL,
    billing_address JSONB,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    confirmed_at TIMESTAMP,
    shipped_at TIMESTAMP,
    delivered_at TIMESTAMP,
    cancelled_at TIMESTAMP,
    metadata JSONB
);

-- Indexes
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_created_at ON orders(created_at DESC);
CREATE INDEX idx_orders_user_status ON orders(user_id, status);
CREATE INDEX idx_orders_payment_status ON orders(payment_status);
CREATE INDEX idx_orders_metadata ON orders USING GIN(metadata);

-- Composite index for common query pattern
CREATE INDEX idx_orders_user_created ON orders(user_id, created_at DESC);
```

#### 4.2.3 Order Items Table

```sql
CREATE TABLE order_items (
    order_item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(product_id),
    product_name VARCHAR(255) NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10, 2) NOT NULL,
    total DECIMAL(10, 2) NOT NULL,
    discount DECIMAL(10, 2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);
```

#### 4.2.4 Products Table

```sql
CREATE TABLE products (
    product_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sku VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100),
    price DECIMAL(10, 2) NOT NULL,
    cost DECIMAL(10, 2),
    inventory_count INTEGER DEFAULT 0,
    status VARCHAR(50) DEFAULT 'active',
    images JSONB,
    attributes JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_products_sku ON products(sku);
CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_products_status ON products(status);
CREATE INDEX idx_products_name ON products USING GIN(to_tsvector('english', name));
CREATE INDEX idx_products_attributes ON products USING GIN(attributes);
```

#### 4.2.5 Payments Table

```sql
CREATE TABLE payments (
    payment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES orders(order_id),
    user_id UUID NOT NULL REFERENCES users(user_id),
    amount DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    payment_method VARCHAR(50) NOT NULL,
    transaction_id VARCHAR(255),
    gateway VARCHAR(50),
    gateway_response JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    authorized_at TIMESTAMP,
    captured_at TIMESTAMP,
    failed_at TIMESTAMP,
    refunded_at TIMESTAMP
);

-- Indexes
CREATE INDEX idx_payments_order_id ON payments(order_id);
CREATE INDEX idx_payments_user_id ON payments(user_id);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_payments_transaction_id ON payments(transaction_id);
```

### 4.3 Entity Relationship Diagram

```
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│    Users    │         │   Orders    │         │  Payments   │
├─────────────┤         ├─────────────┤         ├─────────────┤
│ user_id PK  │────────<│ order_id PK │>────────│ payment_id  │
│ email       │    1:N  │ user_id FK  │   1:N   │ order_id FK │
│ password    │         │ status      │         │ amount      │
│ first_name  │         │ total       │         │ status      │
│ role        │         │ created_at  │         │ gateway     │
└─────────────┘         └──────┬──────┘         └─────────────┘
                               │
                               │ 1:N
                               │
                        ┌──────▼──────┐
                        │ Order Items │
                        ├─────────────┤
                        │ item_id PK  │
                        │ order_id FK │
                        │ product_id  │
                        │ quantity    │
                        │ unit_price  │
                        └──────┬──────┘
                               │
                               │ N:1
                               │
                        ┌──────▼──────┐
                        │  Products   │
                        ├─────────────┤
                        │ product_id  │
                        │ sku         │
                        │ name        │
                        │ price       │
                        │ inventory   │
                        └─────────────┘
```


### 4.4 Indexing Strategy

**Index Selection Criteria**:
1. Columns in WHERE clauses (filtering)
2. Columns in JOIN conditions
3. Columns in ORDER BY clauses
4. Columns in GROUP BY clauses
5. Columns with high cardinality (many unique values)

**Index Types**:

| Index Type | Use Case | Example |
|------------|----------|---------|
| B-tree (default) | Equality, range queries | `CREATE INDEX idx_orders_created_at ON orders(created_at)` |
| Hash | Equality only, faster than B-tree | `CREATE INDEX idx_users_email ON users USING HASH(email)` |
| GIN (Generalized Inverted) | JSONB, arrays, full-text search | `CREATE INDEX idx_products_attrs ON products USING GIN(attributes)` |
| GiST (Generalized Search Tree) | Geometric data, full-text | `CREATE INDEX idx_locations ON stores USING GIST(location)` |
| Partial Index | Subset of rows | `CREATE INDEX idx_active_users ON users(email) WHERE status = 'active'` |
| Composite Index | Multiple columns | `CREATE INDEX idx_orders_user_date ON orders(user_id, created_at DESC)` |

**Composite Index Guidelines**:
- Order matters: Most selective column first
- Use for common query patterns
- Example: `WHERE user_id = ? AND status = ? ORDER BY created_at DESC`
  - Index: `(user_id, status, created_at DESC)`

**Index Maintenance**:
```sql
-- Analyze query performance
EXPLAIN ANALYZE SELECT * FROM orders WHERE user_id = '...' AND status = 'shipped';

-- Check index usage
SELECT schemaname, tablename, indexname, idx_scan, idx_tup_read, idx_tup_fetch
FROM pg_stat_user_indexes
WHERE idx_scan = 0 AND schemaname = 'public';

-- Rebuild index (if fragmented)
REINDEX INDEX idx_orders_created_at;
```

### 4.5 Caching Strategy

**Cache Layers**:

```
┌─────────────────────────────────────────────────────────────┐
│                      Application Layer                       │
└───────────────────────────┬─────────────────────────────────┘
                            │
                ┌───────────▼───────────┐
                │   L1: In-Memory Cache │  ← 10ms, 100MB per instance
                │   (Node.js Map/LRU)   │
                └───────────┬───────────┘
                            │ Miss
                ┌───────────▼───────────┐
                │   L2: Redis Cache     │  ← 1-5ms, 10GB cluster
                │   (Distributed)       │
                └───────────┬───────────┘
                            │ Miss
                ┌───────────▼───────────┐
                │   L3: Database        │  ← 10-50ms
                │   (PostgreSQL)        │
                └───────────────────────┘
```

**Caching Patterns**:

| Pattern | Use Case | TTL | Invalidation |
|---------|----------|-----|--------------|
| **Cache-Aside** | User profiles, product details | 1 hour | On update |
| **Write-Through** | Session data | 30 min | On write |
| **Write-Behind** | Analytics counters | N/A | Async flush |
| **Read-Through** | Product catalog | 5 min | On update |

**Cache Keys**:

```
user:{user_id}                          → User object
user:{user_id}:orders                   → User's orders list
product:{product_id}                    → Product details
product:category:{category}:page:{n}    → Product listing
order:{order_id}                        → Order details
session:{session_id}                    → User session
rate_limit:{user_id}:{endpoint}         → Rate limit counter
```

**Cache Invalidation**:

```javascript
// Example: Update product price
async function updateProductPrice(productId, newPrice) {
  // 1. Update database
  await db.query('UPDATE products SET price = $1 WHERE product_id = $2', 
                 [newPrice, productId]);
  
  // 2. Invalidate cache
  await cache.del(`product:${productId}`);
  
  // 3. Invalidate related caches
  const category = await db.query('SELECT category FROM products WHERE product_id = $1', 
                                   [productId]);
  await cache.del(`product:category:${category}:*`);
}
```

**Cache Warming**:
- Pre-populate cache on deployment
- Background job refreshes popular items
- Predictive caching based on user behavior

### 4.6 Data Consistency

**Consistency Models**:

| Operation | Consistency Level | Rationale |
|-----------|------------------|-----------|
| Order Creation | Strong (ACID) | Money involved, must be consistent |
| Inventory Update | Strong (ACID) | Prevent overselling |
| Product Catalog | Eventual | Stale data acceptable for seconds |
| User Profile | Eventual | Not time-critical |
| Analytics | Eventual | Batch processing acceptable |

**Transaction Example**:

```sql
BEGIN;

-- 1. Create order
INSERT INTO orders (user_id, total, status) 
VALUES ('user_123', 100.00, 'pending')
RETURNING order_id;

-- 2. Reserve inventory
UPDATE products 
SET inventory_count = inventory_count - 2
WHERE product_id = 'prod_abc' AND inventory_count >= 2;

-- 3. Create payment record
INSERT INTO payments (order_id, amount, status)
VALUES ('order_456', 100.00, 'pending');

-- If any step fails, rollback entire transaction
COMMIT;
```

**Distributed Transaction (Saga Pattern)**:

```
Order Service → Payment Service → Inventory Service
     ↓               ↓                  ↓
  Success         Success            Success
     ↓               ↓                  ↓
  Commit          Commit             Commit

If any fails:
     ↓               ↓                  ↓
  Rollback    ←   Rollback    ←    Rollback
```

### 4.7 Scaling Considerations

#### 4.7.1 Vertical Scaling (Scale Up)

**When to Use**: Initial growth, simpler operations

| Metric | Small | Medium | Large |
|--------|-------|--------|-------|
| Instance | db.t3.medium | db.r5.xlarge | db.r5.4xlarge |
| vCPU | 2 | 4 | 16 |
| RAM | 4 GB | 32 GB | 128 GB |
| Storage | 100 GB | 500 GB | 2 TB |
| Cost/month | $60 | $350 | $1,400 |
| Max Connections | 100 | 500 | 2,000 |

#### 4.7.2 Horizontal Scaling (Scale Out)

**Read Replicas**:

```
                    ┌─────────────┐
                    │   Master    │  ← Writes only
                    │  (Primary)  │
                    └──────┬──────┘
                           │
            ┌──────────────┼──────────────┐
            │              │              │
     ┌──────▼──────┐ ┌─────▼─────┐ ┌─────▼─────┐
     │  Replica 1  │ │ Replica 2 │ │ Replica 3 │  ← Reads only
     │   (Read)    │ │  (Read)   │ │  (Read)   │
     └─────────────┘ └───────────┘ └───────────┘
```

**Sharding Strategy**:

| Sharding Key | Pros | Cons |
|--------------|------|------|
| `user_id` | Even distribution, user data co-located | Cross-shard queries for global data |
| `order_date` | Time-based queries efficient | Hot shard for recent data |
| `region` | Geographic locality | Uneven distribution |

**Sharding Example** (by user_id):

```
Shard 0: user_id % 4 = 0  → Users 0, 4, 8, 12...
Shard 1: user_id % 4 = 1  → Users 1, 5, 9, 13...
Shard 2: user_id % 4 = 2  → Users 2, 6, 10, 14...
Shard 3: user_id % 4 = 3  → Users 3, 7, 11, 15...
```

**Partitioning** (PostgreSQL native):

```sql
-- Range partitioning by date
CREATE TABLE orders (
    order_id UUID,
    created_at TIMESTAMP,
    ...
) PARTITION BY RANGE (created_at);

CREATE TABLE orders_2024_01 PARTITION OF orders
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

CREATE TABLE orders_2024_02 PARTITION OF orders
    FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');
```

**Benefits**:
- Query performance (scan only relevant partitions)
- Easier archival (drop old partitions)
- Parallel query execution


---

## 5. Low Level Design

### 5.1 Sequence Diagrams

#### 5.1.1 Order Creation Flow

```
Client          API Gateway    Order Service   Inventory    Payment     Database    Queue
  │                 │                │              │           │           │          │
  │─POST /orders───>│                │              │           │           │          │
  │                 │─validate────>  │              │           │           │          │
  │                 │  auth          │              │           │           │          │
  │                 │<─────────────  │              │           │           │          │
  │                 │                │              │           │           │          │
  │                 │─forward────────>│              │           │           │          │
  │                 │  request       │              │           │           │          │
  │                 │                │─check────────>│           │           │          │
  │                 │                │  inventory   │           │           │          │
  │                 │                │<─available───│           │           │          │
  │                 │                │              │           │           │          │
  │                 │                │─authorize─────────────────>│          │          │
  │                 │                │  payment     │           │           │          │
  │                 │                │<─success──────────────────│           │          │
  │                 │                │              │           │           │          │
  │                 │                │─BEGIN TRANSACTION─────────>│          │          │
  │                 │                │─create order──────────────>│          │          │
  │                 │                │─reserve inventory─────────>│          │          │
  │                 │                │─create payment────────────>│          │          │
  │                 │                │─COMMIT────────────────────>│          │          │
  │                 │                │              │           │           │          │
  │                 │                │─publish OrderCreated──────────────────>│          │
  │                 │                │              │           │           │          │
  │                 │<─200 OK────────│              │           │           │          │
  │<─response───────│                │              │           │           │          │
  │                 │                │              │           │           │          │
  │                 │                │              │           │           │          │
  │                 │                │         [Async Processing]            │          │
  │                 │                │              │           │           │          │
  │                 │                │              │           │      Worker│<─consume─│
  │                 │                │              │           │           │  message │
  │                 │                │              │           │      Worker│──────────>│
  │                 │                │              │           │           │ send email│
```

#### 5.1.2 Payment Failure & Rollback

```
Order Service   Payment Service   Inventory Service   Database
      │                │                  │               │
      │─authorize──────>│                  │               │
      │  payment       │                  │               │
      │<─FAILED────────│                  │               │
      │                │                  │               │
      │─BEGIN TRANSACTION─────────────────────────────────>│
      │─mark order as failed──────────────────────────────>│
      │─release inventory────────────────>│               │
      │                │                  │─update────────>│
      │─COMMIT────────────────────────────────────────────>│
      │                │                  │               │
      │─return error to client            │               │
```

### 5.2 State Machine Diagrams

#### 5.2.1 Order Status State Machine

```
                    ┌─────────┐
                    │ PENDING │  ← Initial state
                    └────┬────┘
                         │
                         │ payment authorized
                         │ inventory reserved
                         ▼
                  ┌──────────────┐
                  │  CONFIRMED   │
                  └──────┬───────┘
                         │
                         │ order processing started
                         ▼
                  ┌──────────────┐
                  │  PROCESSING  │
                  └──────┬───────┘
                         │
                         │ shipped to carrier
                         ▼
                  ┌──────────────┐
                  │   SHIPPED    │
                  └──────┬───────┘
                         │
                         │ delivered to customer
                         ▼
                  ┌──────────────┐
                  │  DELIVERED   │  ← Final state (success)
                  └──────────────┘

                  ┌──────────────┐
                  │  CANCELLED   │  ← Final state (cancelled)
                  └──────────────┘
                         ▲
                         │
                         │ user/admin cancellation
                         │
                  ┌──────┴───────┐
                  │ Any state    │
                  │ before ship  │
                  └──────────────┘
```

**State Transitions**:

| From State | To State | Trigger | Validation |
|------------|----------|---------|------------|
| PENDING | CONFIRMED | Payment authorized | Payment success, inventory available |
| PENDING | CANCELLED | Payment failed | - |
| CONFIRMED | PROCESSING | Fulfillment started | Order not cancelled |
| CONFIRMED | CANCELLED | User cancellation | Within cancellation window |
| PROCESSING | SHIPPED | Carrier pickup | Tracking number assigned |
| PROCESSING | CANCELLED | Admin cancellation | Refund processed |
| SHIPPED | DELIVERED | Carrier confirmation | Tracking shows delivered |
| SHIPPED | CANCELLED | Return initiated | Return policy allows |

### 5.3 Key Algorithms

#### 5.3.1 Inventory Reservation Algorithm

**Problem**: Prevent overselling when multiple users order simultaneously

**Solution**: Optimistic locking with retry

```python
def reserve_inventory(product_id, quantity, max_retries=3):
    """
    Reserve inventory with optimistic locking
    
    Args:
        product_id: Product to reserve
        quantity: Quantity to reserve
        max_retries: Maximum retry attempts
    
    Returns:
        bool: True if reservation successful
    
    Raises:
        InsufficientInventoryError: Not enough stock
    """
    for attempt in range(max_retries):
        # 1. Read current inventory with version
        product = db.query(
            "SELECT inventory_count, version FROM products WHERE product_id = %s",
            [product_id]
        )
        
        # 2. Check availability
        if product.inventory_count < quantity:
            raise InsufficientInventoryError(
                f"Only {product.inventory_count} available"
            )
        
        # 3. Attempt to reserve with optimistic lock
        rows_updated = db.execute(
            """
            UPDATE products 
            SET inventory_count = inventory_count - %s,
                version = version + 1
            WHERE product_id = %s 
              AND version = %s
              AND inventory_count >= %s
            """,
            [quantity, product_id, product.version, quantity]
        )
        
        # 4. Check if update succeeded
        if rows_updated == 1:
            return True  # Success!
        
        # 5. Retry if concurrent update detected
        time.sleep(0.01 * (2 ** attempt))  # Exponential backoff
    
    raise ConcurrentUpdateError("Failed to reserve after retries")
```

**Time Complexity**: O(1) per attempt  
**Space Complexity**: O(1)  
**Concurrency**: Safe with optimistic locking


#### 5.3.2 Rate Limiting Algorithm (Token Bucket)

**Problem**: Prevent API abuse, ensure fair usage

**Solution**: Token bucket algorithm with Redis

```python
def check_rate_limit(user_id, endpoint, limit=1000, window=3600):
    """
    Token bucket rate limiting
    
    Args:
        user_id: User identifier
        endpoint: API endpoint
        limit: Max requests per window
        window: Time window in seconds
    
    Returns:
        tuple: (allowed: bool, remaining: int, reset_at: int)
    """
    key = f"rate_limit:{user_id}:{endpoint}"
    now = time.time()
    
    # Redis Lua script for atomic operation
    lua_script = """
    local key = KEYS[1]
    local limit = tonumber(ARGV[1])
    local window = tonumber(ARGV[2])
    local now = tonumber(ARGV[3])
    
    local current = redis.call('GET', key)
    
    if current == false then
        -- First request, initialize
        redis.call('SET', key, limit - 1, 'EX', window)
        return {1, limit - 1, now + window}
    else
        current = tonumber(current)
        if current > 0 then
            -- Tokens available
            redis.call('DECR', key)
            local ttl = redis.call('TTL', key)
            return {1, current - 1, now + ttl}
        else
            -- No tokens available
            local ttl = redis.call('TTL', key)
            return {0, 0, now + ttl}
        end
    end
    """
    
    allowed, remaining, reset_at = redis.eval(
        lua_script, 
        keys=[key], 
        args=[limit, window, now]
    )
    
    return (allowed == 1, remaining, reset_at)
```

**Time Complexity**: O(1)  
**Space Complexity**: O(1) per user-endpoint pair  
**Accuracy**: Exact within Redis atomic operations

#### 5.3.3 Recommendation Algorithm (Collaborative Filtering)

**Problem**: Recommend products based on user behavior

**Solution**: Item-based collaborative filtering

```python
def get_recommendations(user_id, num_recommendations=10):
    """
    Generate product recommendations using item-based collaborative filtering
    
    Args:
        user_id: User to generate recommendations for
        num_recommendations: Number of recommendations to return
    
    Returns:
        list: Product IDs ranked by relevance
    """
    # 1. Get user's purchase history
    user_products = db.query(
        """
        SELECT DISTINCT product_id 
        FROM order_items oi
        JOIN orders o ON oi.order_id = o.order_id
        WHERE o.user_id = %s
        """,
        [user_id]
    )
    
    # 2. Find similar products (pre-computed similarity matrix)
    similar_products = {}
    for product_id in user_products:
        # Get top 20 similar products from cache
        similar = cache.get(f"similar_products:{product_id}")
        
        for sim_product_id, similarity_score in similar:
            if sim_product_id not in user_products:
                similar_products[sim_product_id] = \
                    similar_products.get(sim_product_id, 0) + similarity_score
    
    # 3. Rank by aggregated similarity score
    recommendations = sorted(
        similar_products.items(), 
        key=lambda x: x[1], 
        reverse=True
    )[:num_recommendations]
    
    return [product_id for product_id, score in recommendations]
```

**Time Complexity**: O(n * k) where n = user's products, k = similar products per item  
**Space Complexity**: O(m) where m = total unique similar products  
**Offline Processing**: Similarity matrix computed daily via batch job

### 5.4 Component Interaction Details

#### 5.4.1 Order Service Internal Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Order Service                           │
│                                                              │
│  ┌──────────────┐      ┌──────────────┐                    │
│  │   API Layer  │      │  Validation  │                    │
│  │  (Express)   │─────>│    Layer     │                    │
│  └──────┬───────┘      └──────┬───────┘                    │
│         │                     │                             │
│         │                     ▼                             │
│         │              ┌──────────────┐                    │
│         │              │   Business   │                    │
│         └─────────────>│     Logic    │                    │
│                        │    Layer     │                    │
│                        └──────┬───────┘                    │
│                               │                             │
│         ┌─────────────────────┼─────────────────────┐      │
│         │                     │                     │      │
│         ▼                     ▼                     ▼      │
│  ┌──────────────┐      ┌──────────────┐    ┌──────────────┐│
│  │  Repository  │      │   External   │    │    Event     ││
│  │    Layer     │      │   Services   │    │  Publisher   ││
│  │  (Database)  │      │   (HTTP)     │    │   (Queue)    ││
│  └──────────────┘      └──────────────┘    └──────────────┘│
└─────────────────────────────────────────────────────────────┘
```

**Layer Responsibilities**:

| Layer | Responsibility | Example |
|-------|---------------|---------|
| API Layer | HTTP handling, routing, middleware | Express routes, auth middleware |
| Validation Layer | Input validation, sanitization | Joi schemas, custom validators |
| Business Logic | Core domain logic, orchestration | Order creation workflow |
| Repository Layer | Data access, query building | Database queries, ORM |
| External Services | Third-party integrations | Payment gateway, shipping API |
| Event Publisher | Async event publishing | SQS message publishing |

### 5.5 Implementation Trade-offs

#### 5.5.1 Synchronous vs Asynchronous Order Processing

**Option A: Fully Synchronous**

```javascript
// All operations in request-response cycle
async function createOrder(orderData) {
  const order = await db.createOrder(orderData);
  await inventoryService.reserve(order.items);
  await paymentService.authorize(order.payment);
  await emailService.sendConfirmation(order);  // ← Blocks response
  await analyticsService.track(order);         // ← Blocks response
  return order;
}
```

✅ **Pros**: Simple, immediate feedback, easier debugging  
❌ **Cons**: Slow (500ms+), email/analytics failures block order creation

**Option B: Hybrid (Chosen)**

```javascript
// Critical path synchronous, non-critical async
async function createOrder(orderData) {
  const order = await db.createOrder(orderData);
  await inventoryService.reserve(order.items);  // ← Must succeed
  await paymentService.authorize(order.payment); // ← Must succeed
  
  // Async operations
  await queue.publish('OrderCreated', order);    // ← Fire and forget
  
  return order;  // Fast response (~200ms)
}
```

✅ **Pros**: Fast response, resilient to downstream failures  
❌ **Cons**: Eventual consistency, need retry logic

**Decision**: Hybrid approach balances UX and reliability


---

## 6. Key Dependencies

### 6.1 External Services

| Service | Purpose | Criticality | Fallback Strategy | SLA |
|---------|---------|-------------|-------------------|-----|
| **Stripe** | Payment processing | Critical | Queue orders, process later | 99.99% |
| **AWS S3** | Image/file storage | High | CDN cache, retry | 99.99% |
| **SendGrid** | Email delivery | Medium | Queue emails, retry | 99.95% |
| **Twilio** | SMS notifications | Low | Skip, log failure | 99.95% |
| **Google Maps** | Address validation | Medium | Skip validation | 99.9% |
| **Elasticsearch** | Product search | High | Fallback to DB search | Self-hosted |
| **Datadog** | Monitoring/logging | Medium | Local logs, CloudWatch | 99.9% |

### 6.2 Third-Party Libraries

#### Backend (Node.js)

| Library | Version | Purpose | Alternatives Considered |
|---------|---------|---------|------------------------|
| `express` | ^4.18.0 | Web framework | Fastify (faster), Koa (smaller) |
| `pg` | ^8.11.0 | PostgreSQL client | Sequelize (ORM), TypeORM |
| `ioredis` | ^5.3.0 | Redis client | node-redis (official) |
| `joi` | ^17.9.0 | Validation | Yup, Zod |
| `jsonwebtoken` | ^9.0.0 | JWT handling | jose (modern) |
| `bcrypt` | ^5.1.0 | Password hashing | argon2 (more secure) |
| `axios` | ^1.4.0 | HTTP client | fetch (native), got |
| `winston` | ^3.10.0 | Logging | Pino (faster), Bunyan |
| `bull` | ^4.11.0 | Job queue | BullMQ (TypeScript), Agenda |

#### Frontend (React)

| Library | Version | Purpose | Alternatives Considered |
|---------|---------|---------|------------------------|
| `react` | ^18.2.0 | UI framework | Vue.js, Svelte |
| `react-router-dom` | ^6.14.0 | Routing | TanStack Router |
| `@tanstack/react-query` | ^4.29.0 | Data fetching | SWR, Apollo Client |
| `axios` | ^1.4.0 | HTTP client | fetch (native) |
| `zustand` | ^4.3.0 | State management | Redux, Jotai, Recoil |
| `react-hook-form` | ^7.45.0 | Form handling | Formik |
| `zod` | ^3.21.0 | Validation | Yup, Joi |
| `tailwindcss` | ^3.3.0 | CSS framework | Bootstrap, Material-UI |

### 6.3 Infrastructure Dependencies

| Component | Provider | Purpose | Backup/DR |
|-----------|----------|---------|-----------|
| **Compute** | AWS EKS | Container orchestration | Multi-AZ deployment |
| **Database** | AWS RDS PostgreSQL | Primary data store | Multi-AZ, automated backups |
| **Cache** | AWS ElastiCache Redis | Caching layer | Multi-AZ replication |
| **Storage** | AWS S3 | Object storage | Cross-region replication |
| **CDN** | CloudFront | Content delivery | Multi-region edge locations |
| **DNS** | Route 53 | Domain management | Health checks, failover |
| **Load Balancer** | AWS ALB | Traffic distribution | Multi-AZ |
| **Message Queue** | AWS SQS | Async processing | Managed service, no backup needed |

### 6.4 Risk Mitigation Strategies

#### 6.4.1 Payment Service Failure

**Risk**: Stripe API down, orders cannot be processed

**Mitigation**:
1. **Circuit Breaker**: Stop sending requests after 5 consecutive failures
2. **Fallback**: Queue orders for later processing
3. **Alternative**: Secondary payment provider (PayPal) as backup
4. **Monitoring**: Alert on payment failure rate > 1%

```javascript
const circuitBreaker = new CircuitBreaker(paymentService.authorize, {
  timeout: 5000,
  errorThresholdPercentage: 50,
  resetTimeout: 30000
});

circuitBreaker.fallback(() => {
  // Queue order for later processing
  return queue.publish('PendingPayment', orderData);
});
```

#### 6.4.2 Database Failure

**Risk**: Primary database becomes unavailable

**Mitigation**:
1. **Multi-AZ Deployment**: Automatic failover to standby (30-60s)
2. **Read Replicas**: Continue serving read traffic
3. **Connection Pooling**: Reuse connections, handle reconnection
4. **Graceful Degradation**: Show cached data, disable writes

**RTO (Recovery Time Objective)**: 2 minutes  
**RPO (Recovery Point Objective)**: 5 minutes (last backup)

#### 6.4.3 Third-Party API Rate Limits

**Risk**: Exceed rate limits on external APIs

**Mitigation**:
1. **Rate Limiting**: Track usage, stay under limits
2. **Exponential Backoff**: Retry with increasing delays
3. **Caching**: Cache responses to reduce API calls
4. **Batch Operations**: Combine multiple requests

```javascript
async function callExternalAPI(endpoint, data, retries = 3) {
  for (let i = 0; i < retries; i++) {
    try {
      return await axios.post(endpoint, data);
    } catch (error) {
      if (error.response?.status === 429) {
        // Rate limited, wait and retry
        const delay = Math.pow(2, i) * 1000;
        await sleep(delay);
      } else {
        throw error;
      }
    }
  }
  throw new Error('Max retries exceeded');
}
```

#### 6.4.4 Dependency Version Updates

**Risk**: Breaking changes in library updates

**Mitigation**:
1. **Semantic Versioning**: Use `^` for minor updates, lock major versions
2. **Automated Testing**: CI/CD runs tests on every update
3. **Dependabot**: Automated PRs for security updates
4. **Staging Environment**: Test updates before production
5. **Rollback Plan**: Keep previous version deployable

**Update Schedule**:
- Security patches: Immediate
- Minor updates: Weekly
- Major updates: Quarterly (with testing)


---

## 7. System Qualities

### 7.1 Scaling Strategy

#### 7.1.1 Horizontal Scaling (Preferred)

**Application Servers**:
```yaml
# Kubernetes HorizontalPodAutoscaler
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: order-service
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: order-service
  minReplicas: 3
  maxReplicas: 20
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

**Scaling Triggers**:

| Metric | Scale Up Threshold | Scale Down Threshold | Cooldown |
|--------|-------------------|---------------------|----------|
| CPU | > 70% for 2 min | < 30% for 5 min | 3 min |
| Memory | > 80% for 2 min | < 40% for 5 min | 5 min |
| Request Rate | > 1000 RPS | < 300 RPS | 5 min |
| Response Time | P95 > 500ms | P95 < 200ms | 5 min |

#### 7.1.2 Vertical Scaling

**Database Scaling**:

| Load Level | Instance Type | vCPU | RAM | IOPS | Cost/month |
|------------|--------------|------|-----|------|------------|
| Low | db.r5.large | 2 | 16 GB | 3,000 | $175 |
| Medium | db.r5.xlarge | 4 | 32 GB | 6,000 | $350 |
| High | db.r5.2xlarge | 8 | 64 GB | 12,000 | $700 |
| Very High | db.r5.4xlarge | 16 | 128 GB | 24,000 | $1,400 |

**When to Scale Up**:
- CPU > 80% sustained
- Memory > 85% sustained
- IOPS > 80% of provisioned
- Connection pool exhausted

#### 7.1.3 Caching for Scale

**Cache Hit Rate Impact**:

| Cache Hit Rate | Database Load | Response Time | Cost Savings |
|----------------|---------------|---------------|--------------|
| 0% (no cache) | 100% | 50ms | $0 |
| 50% | 50% | 30ms | $200/month |
| 80% | 20% | 15ms | $500/month |
| 95% | 5% | 5ms | $800/month |

**Cache Warming Strategy**:
```python
# Pre-populate cache on deployment
async def warm_cache():
    # 1. Popular products
    popular_products = await db.query(
        "SELECT * FROM products ORDER BY view_count DESC LIMIT 1000"
    )
    for product in popular_products:
        await cache.set(f"product:{product.id}", product, ttl=3600)
    
    # 2. Active user sessions
    active_sessions = await db.query(
        "SELECT * FROM sessions WHERE last_active > NOW() - INTERVAL '1 hour'"
    )
    for session in active_sessions:
        await cache.set(f"session:{session.id}", session, ttl=1800)
```

### 7.2 Availability & Fault Tolerance

#### 7.2.1 High Availability Architecture

```
Region: us-east-1
├── Availability Zone A
│   ├── Application Servers (3 pods)
│   ├── Database Primary
│   └── Redis Node 1
├── Availability Zone B
│   ├── Application Servers (3 pods)
│   ├── Database Standby
│   └── Redis Node 2
└── Availability Zone C
    ├── Application Servers (3 pods)
    └── Redis Node 3
```

**Availability Calculation**:

| Component | Availability | Redundancy | Effective Availability |
|-----------|--------------|------------|----------------------|
| Application | 99.9% | 3 AZs | 99.999% |
| Database | 99.95% | Multi-AZ | 99.995% |
| Cache | 99.9% | 3-node cluster | 99.99% |
| Load Balancer | 99.99% | AWS managed | 99.99% |
| **Overall** | | | **99.9%** |

Formula: `1 - (1 - 0.999) * (1 - 0.99995) * (1 - 0.9999) * (1 - 0.9999) ≈ 0.999`

#### 7.2.2 Redundancy & Failover

**Database Failover**:
1. Primary failure detected (health check fails)
2. Route 53 updates DNS to standby (30s)
3. Standby promoted to primary (30s)
4. Application reconnects automatically
5. **Total downtime**: ~60 seconds

**Application Failover**:
1. Pod health check fails (3 consecutive failures)
2. Kubernetes removes pod from service
3. New pod started automatically
4. Health check passes, pod added to service
5. **Total downtime**: 0 (other pods handle traffic)

#### 7.2.3 Circuit Breaker Pattern

```javascript
class CircuitBreaker {
  constructor(service, options = {}) {
    this.service = service;
    this.failureThreshold = options.failureThreshold || 5;
    this.resetTimeout = options.resetTimeout || 60000;
    this.state = 'CLOSED';  // CLOSED, OPEN, HALF_OPEN
    this.failures = 0;
    this.nextAttempt = Date.now();
  }
  
  async call(...args) {
    if (this.state === 'OPEN') {
      if (Date.now() < this.nextAttempt) {
        throw new Error('Circuit breaker is OPEN');
      }
      this.state = 'HALF_OPEN';
    }
    
    try {
      const result = await this.service(...args);
      this.onSuccess();
      return result;
    } catch (error) {
      this.onFailure();
      throw error;
    }
  }
  
  onSuccess() {
    this.failures = 0;
    this.state = 'CLOSED';
  }
  
  onFailure() {
    this.failures++;
    if (this.failures >= this.failureThreshold) {
      this.state = 'OPEN';
      this.nextAttempt = Date.now() + this.resetTimeout;
    }
  }
}
```

### 7.3 Security Considerations

#### 7.3.1 Authentication & Authorization

**Authentication Flow**:
```
1. User submits credentials
2. Server validates against database
3. Server generates JWT with claims
4. Client stores JWT (httpOnly cookie or localStorage)
5. Client includes JWT in Authorization header
6. Server validates JWT signature and expiry
7. Server checks user permissions (RBAC)
```

**JWT Claims**:
```json
{
  "sub": "user_12345",
  "email": "user@example.com",
  "roles": ["customer"],
  "permissions": ["orders:read", "orders:create"],
  "iat": 1640000000,
  "exp": 1640003600
}
```

**Authorization Matrix**:

| Resource | Customer | Admin | Support | Partner |
|----------|----------|-------|---------|---------|
| Create Order | ✅ Own | ✅ All | ❌ | ✅ Own |
| View Order | ✅ Own | ✅ All | ✅ All | ✅ Own |
| Cancel Order | ✅ Own (24h) | ✅ All | ✅ All | ❌ |
| Refund Order | ❌ | ✅ All | ✅ All | ❌ |
| View Users | ❌ | ✅ All | ✅ Limited | ❌ |
| Manage Inventory | ❌ | ✅ All | ❌ | ❌ |

#### 7.3.2 Data Encryption

**At Rest**:
- Database: AES-256 encryption (AWS RDS encryption)
- S3: Server-side encryption (SSE-S3 or SSE-KMS)
- Backups: Encrypted with AWS KMS

**In Transit**:
- HTTPS only (TLS 1.3)
- Certificate: Let's Encrypt or AWS Certificate Manager
- HSTS header: `Strict-Transport-Security: max-age=31536000`

**Sensitive Data**:
```javascript
// Encrypt PII before storing
const crypto = require('crypto');

function encryptPII(data, key) {
  const iv = crypto.randomBytes(16);
  const cipher = crypto.createCipheriv('aes-256-gcm', key, iv);
  
  let encrypted = cipher.update(data, 'utf8', 'hex');
  encrypted += cipher.final('hex');
  
  const authTag = cipher.getAuthTag();
  
  return {
    encrypted,
    iv: iv.toString('hex'),
    authTag: authTag.toString('hex')
  };
}
```

#### 7.3.3 Security Best Practices

| Practice | Implementation | Priority |
|----------|---------------|----------|
| **Input Validation** | Joi schemas, sanitization | Critical |
| **SQL Injection Prevention** | Parameterized queries | Critical |
| **XSS Prevention** | Content Security Policy, output encoding | Critical |
| **CSRF Protection** | CSRF tokens, SameSite cookies | High |
| **Rate Limiting** | Token bucket, per-user limits | High |
| **Secrets Management** | AWS Secrets Manager, env vars | Critical |
| **Dependency Scanning** | Snyk, npm audit | High |
| **Security Headers** | Helmet.js middleware | Medium |
| **Audit Logging** | Log all sensitive operations | High |
| **Penetration Testing** | Annual third-party audit | Medium |

**Security Headers**:
```javascript
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
    },
  },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true
  }
}));
```

#### 7.3.4 Compliance

| Regulation | Applicability | Requirements | Implementation |
|------------|--------------|--------------|----------------|
| **GDPR** | EU users | Data privacy, right to deletion | User data export, deletion API |
| **PCI-DSS** | Payment processing | Secure card data handling | Tokenization (Stripe), no card storage |
| **SOC 2** | Enterprise customers | Security controls, audits | Annual audit, security policies |
| **CCPA** | California users | Data privacy, opt-out | Privacy policy, data deletion |

### 7.4 Performance Optimization

#### 7.4.1 Database Query Optimization

**Before Optimization**:
```sql
-- Slow query (500ms)
SELECT o.*, u.email, u.first_name, u.last_name
FROM orders o
JOIN users u ON o.user_id = u.user_id
WHERE o.status = 'shipped'
ORDER BY o.created_at DESC
LIMIT 20;
```

**After Optimization**:
```sql
-- Fast query (20ms)
-- 1. Add composite index
CREATE INDEX idx_orders_status_created ON orders(status, created_at DESC);

-- 2. Use covering index (include columns)
CREATE INDEX idx_orders_status_created_covering 
ON orders(status, created_at DESC) 
INCLUDE (user_id, total);

-- 3. Denormalize user data in orders table
ALTER TABLE orders ADD COLUMN user_email VARCHAR(255);
ALTER TABLE orders ADD COLUMN user_name VARCHAR(255);

-- 4. Optimized query
SELECT order_id, user_email, user_name, total, created_at
FROM orders
WHERE status = 'shipped'
ORDER BY created_at DESC
LIMIT 20;
```

#### 7.4.2 API Response Time Optimization

| Technique | Before | After | Improvement |
|-----------|--------|-------|-------------|
| Database indexing | 500ms | 50ms | 10x |
| Redis caching | 50ms | 5ms | 10x |
| Response compression | 5ms | 3ms | 1.7x |
| CDN for static assets | 200ms | 20ms | 10x |
| Connection pooling | 100ms | 10ms | 10x |
| Async processing | 1000ms | 200ms | 5x |

#### 7.4.3 Frontend Performance

| Technique | Implementation | Impact |
|-----------|---------------|--------|
| Code Splitting | React.lazy(), dynamic imports | -60% initial bundle |
| Image Optimization | WebP format, lazy loading | -70% image size |
| CDN | CloudFront for static assets | -80% load time |
| Service Worker | Cache API responses | Offline support |
| Tree Shaking | Remove unused code | -30% bundle size |
| Minification | Terser, CSS minification | -40% file size |


---

## 8. Cost Estimation

> 💡 **Note**: This section is optional but highly recommended for production systems. Include if cost is a significant factor.

### 8.1 Infrastructure Costs (Monthly)

| Component | Specification | Unit Cost | Quantity | Monthly Cost |
|-----------|--------------|-----------|----------|--------------|
| **Compute** |
| Application Servers | t3.medium (2 vCPU, 4GB) | $30 | 10 | $300 |
| Background Workers | t3.small (2 vCPU, 2GB) | $15 | 5 | $75 |
| **Database** |
| Primary DB | db.r5.xlarge (4 vCPU, 32GB) | $350 | 1 | $350 |
| Read Replicas | db.r5.large (2 vCPU, 16GB) | $175 | 3 | $525 |
| **Cache** |
| Redis Cluster | cache.r5.large (2 vCPU, 13GB) | $150 | 3 | $450 |
| **Storage** |
| S3 Storage | $0.023/GB | - | 5TB | $115 |
| S3 Requests | $0.0004/1K requests | - | 100M | $40 |
| Database Storage | $0.115/GB | - | 500GB | $58 |
| **Networking** |
| Data Transfer Out | $0.09/GB | - | 10TB | $900 |
| Load Balancer | $16 + $0.008/LCU | - | - | $50 |
| **CDN** |
| CloudFront | $0.085/GB + requests | - | 20TB | $1,700 |
| **Monitoring & Logs** |
| Datadog | $15/host | - | 15 hosts | $225 |
| CloudWatch Logs | $0.50/GB | - | 100GB | $50 |
| **Message Queue** |
| SQS | $0.40/million requests | - | 50M | $20 |
| **Total** | | | | **$4,858/month** |

**Cost per User**: $4,858 / 100,000 DAU = **$0.049 per DAU**

### 8.2 Third-Party Service Costs (Monthly)

| Service | Purpose | Pricing Model | Monthly Cost |
|---------|---------|---------------|--------------|
| Stripe | Payment processing | 2.9% + $0.30 per transaction | $5,800 (on $200K GMV) |
| SendGrid | Email delivery | $0.0006 per email | $180 (300K emails) |
| Twilio | SMS notifications | $0.0075 per SMS | $75 (10K SMS) |
| Auth0 | Authentication | $240/month (up to 1000 MAU) | $240 |
| Algolia | Product search | $1/1000 searches | $500 (500K searches) |
| **Total** | | | **$6,795/month** |

### 8.3 Total Cost Summary

| Category | Monthly Cost | Annual Cost |
|----------|--------------|-------------|
| Infrastructure | $4,858 | $58,296 |
| Third-Party Services | $6,795 | $81,540 |
| **Total** | **$11,653** | **$139,836** |

**Cost Metrics**:
- Cost per DAU: $0.117
- Cost per Order: $1.17 (assuming 10K orders/month)
- Cost per Transaction: $0.58 (assuming 20K transactions/month)

### 8.4 Cost Optimization Strategies

| Strategy | Potential Savings | Implementation Effort | Priority |
|----------|------------------|----------------------|----------|
| Reserved Instances (1-year) | 30% on compute ($113/month) | Low | High |
| S3 Intelligent Tiering | 20% on storage ($23/month) | Low | High |
| CloudFront optimization | 15% on CDN ($255/month) | Medium | Medium |
| Database query optimization | 10% on DB ($88/month) | High | Medium |
| Compress images/assets | 25% on bandwidth ($225/month) | Medium | High |
| Self-hosted search (Elasticsearch) | 100% on Algolia ($500/month) | High | Low |
| **Total Potential Savings** | **$1,204/month (10%)** | | |

**Cost Scaling Projections**:

| Metric | Current | 6 Months | 1 Year | 3 Years |
|--------|---------|----------|--------|---------|
| DAU | 100K | 250K | 500K | 2M |
| Monthly Cost | $11,653 | $22,000 | $38,000 | $120,000 |
| Cost per DAU | $0.117 | $0.088 | $0.076 | $0.060 |

> 💡 **Cost Efficiency Improves with Scale**: Due to reserved instances, volume discounts, and better resource utilization.

---

## 9. Testing Strategy

### 9.1 Test Pyramid

```
                    ┌─────────────┐
                    │     E2E     │  ← 5% (Slow, brittle)
                    │   Tests     │
                    └─────────────┘
                  ┌─────────────────┐
                  │  Integration    │  ← 20% (Medium speed)
                  │     Tests       │
                  └─────────────────┘
              ┌───────────────────────┐
              │    Unit Tests         │  ← 75% (Fast, reliable)
              │                       │
              └───────────────────────┘
```

**Test Distribution**:

| Test Type | Count | Coverage | Execution Time | Frequency |
|-----------|-------|----------|----------------|-----------|
| Unit Tests | 500 | 85% | 30 seconds | Every commit |
| Integration Tests | 100 | 60% | 5 minutes | Every commit |
| E2E Tests | 20 | 30% | 20 minutes | Before deploy |
| Performance Tests | 10 | N/A | 30 minutes | Nightly |
| Security Tests | 5 | N/A | 10 minutes | Weekly |

### 9.2 Unit Testing

**Framework**: Jest (Node.js), React Testing Library (React)

**Example - Order Service Unit Test**:

```javascript
describe('OrderService', () => {
  describe('createOrder', () => {
    it('should create order with valid data', async () => {
      // Arrange
      const orderData = {
        user_id: 'user_123',
        items: [{ product_id: 'prod_abc', quantity: 2 }],
        total: 100.00
      };
      
      const mockDb = {
        createOrder: jest.fn().mockResolvedValue({ order_id: 'order_456' })
      };
      
      const orderService = new OrderService(mockDb);
      
      // Act
      const result = await orderService.createOrder(orderData);
      
      // Assert
      expect(result.order_id).toBe('order_456');
      expect(mockDb.createOrder).toHaveBeenCalledWith(orderData);
    });
    
    it('should throw error when inventory insufficient', async () => {
      // Arrange
      const orderData = {
        user_id: 'user_123',
        items: [{ product_id: 'prod_abc', quantity: 100 }]
      };
      
      const mockInventory = {
        checkAvailability: jest.fn().mockResolvedValue(false)
      };
      
      const orderService = new OrderService(null, mockInventory);
      
      // Act & Assert
      await expect(orderService.createOrder(orderData))
        .rejects
        .toThrow('Insufficient inventory');
    });
  });
});
```

**Coverage Goals**:
- Critical paths: 100%
- Business logic: 90%
- Utilities: 80%
- Overall: 85%

### 9.3 Integration Testing

**Framework**: Jest + Supertest (API testing)

**Example - API Integration Test**:

```javascript
describe('POST /api/v1/orders', () => {
  let app;
  let db;
  
  beforeAll(async () => {
    // Setup test database
    db = await setupTestDatabase();
    app = createApp(db);
  });
  
  afterAll(async () => {
    await db.close();
  });
  
  beforeEach(async () => {
    // Clean database before each test
    await db.query('TRUNCATE orders, order_items CASCADE');
  });
  
  it('should create order and return 201', async () => {
    // Arrange
    const token = await generateTestToken({ user_id: 'user_123' });
    
    // Act
    const response = await request(app)
      .post('/api/v1/orders')
      .set('Authorization', `Bearer ${token}`)
      .send({
        items: [
          { product_id: 'prod_abc', quantity: 2, price: 29.99 }
        ],
        shipping_address: {
          street: '123 Main St',
          city: 'San Francisco',
          state: 'CA',
          zip: '94102'
        }
      });
    
    // Assert
    expect(response.status).toBe(201);
    expect(response.body.order_id).toBeDefined();
    expect(response.body.total).toBe(59.98);
    
    // Verify database
    const order = await db.query(
      'SELECT * FROM orders WHERE order_id = $1',
      [response.body.order_id]
    );
    expect(order.rows[0].status).toBe('confirmed');
  });
  
  it('should return 401 without auth token', async () => {
    const response = await request(app)
      .post('/api/v1/orders')
      .send({ items: [] });
    
    expect(response.status).toBe(401);
  });
});
```

### 9.4 End-to-End Testing

**Framework**: Playwright / Cypress

**Example - E2E Test**:

```javascript
describe('Order Placement Flow', () => {
  it('should complete full order flow', async () => {
    // 1. Login
    await page.goto('https://example.com/login');
    await page.fill('[name="email"]', 'test@example.com');
    await page.fill('[name="password"]', 'password123');
    await page.click('button[type="submit"]');
    await page.waitForURL('**/dashboard');
    
    // 2. Browse products
    await page.goto('https://example.com/products');
    await page.click('[data-testid="product-abc"]');
    
    // 3. Add to cart
    await page.click('[data-testid="add-to-cart"]');
    await expect(page.locator('[data-testid="cart-count"]')).toHaveText('1');
    
    // 4. Checkout
    await page.click('[data-testid="cart-icon"]');
    await page.click('[data-testid="checkout-button"]');
    
    // 5. Enter shipping info
    await page.fill('[name="street"]', '123 Main St');
    await page.fill('[name="city"]', 'San Francisco');
    await page.fill('[name="state"]', 'CA');
    await page.fill('[name="zip"]', '94102');
    
    // 6. Enter payment info (test card)
    await page.fill('[name="card_number"]', '4242424242424242');
    await page.fill('[name="exp_month"]', '12');
    await page.fill('[name="exp_year"]', '2025');
    await page.fill('[name="cvc"]', '123');
    
    // 7. Place order
    await page.click('[data-testid="place-order"]');
    
    // 8. Verify confirmation
    await page.waitForURL('**/orders/**/confirmation');
    await expect(page.locator('h1')).toContainText('Order Confirmed');
    
    // 9. Verify email sent (check test inbox)
    const email = await checkTestInbox('test@example.com');
    expect(email.subject).toContain('Order Confirmation');
  });
});
```

### 9.5 Performance & Load Testing

**Framework**: k6, Artillery

**Example - Load Test**:

```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '2m', target: 100 },   // Ramp up to 100 users
    { duration: '5m', target: 100 },   // Stay at 100 users
    { duration: '2m', target: 200 },   // Ramp up to 200 users
    { duration: '5m', target: 200 },   // Stay at 200 users
    { duration: '2m', target: 0 },     // Ramp down to 0 users
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'],  // 95% of requests < 500ms
    http_req_failed: ['rate<0.01'],    // Error rate < 1%
  },
};

export default function () {
  // 1. Login
  const loginRes = http.post('https://api.example.com/v1/auth/login', {
    email: 'test@example.com',
    password: 'password123',
  });
  
  check(loginRes, {
    'login successful': (r) => r.status === 200,
  });
  
  const token = loginRes.json('token');
  
  // 2. Create order
  const orderRes = http.post(
    'https://api.example.com/v1/orders',
    JSON.stringify({
      items: [{ product_id: 'prod_abc', quantity: 1 }],
    }),
    {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
    }
  );
  
  check(orderRes, {
    'order created': (r) => r.status === 201,
    'response time OK': (r) => r.timings.duration < 500,
  });
  
  sleep(1);
}
```

**Performance Targets**:

| Metric | Target | Load Test Result | Status |
|--------|--------|-----------------|--------|
| Throughput | 1,000 RPS | 1,200 RPS | ✅ Pass |
| P50 Latency | < 100ms | 85ms | ✅ Pass |
| P95 Latency | < 300ms | 280ms | ✅ Pass |
| P99 Latency | < 500ms | 450ms | ✅ Pass |
| Error Rate | < 0.1% | 0.05% | ✅ Pass |
| CPU Usage | < 70% | 65% | ✅ Pass |
| Memory Usage | < 80% | 72% | ✅ Pass |

### 9.6 Security Testing

**Tools**: OWASP ZAP, Snyk, npm audit

**Security Test Checklist**:

- [ ] SQL Injection testing
- [ ] XSS (Cross-Site Scripting) testing
- [ ] CSRF (Cross-Site Request Forgery) testing
- [ ] Authentication bypass attempts
- [ ] Authorization bypass attempts
- [ ] Rate limiting verification
- [ ] Input validation testing
- [ ] Dependency vulnerability scanning
- [ ] Secrets exposure check
- [ ] API security testing (OWASP API Top 10)

**Example - Security Test**:

```javascript
describe('Security Tests', () => {
  it('should prevent SQL injection', async () => {
    const maliciousInput = "'; DROP TABLE users; --";
    
    const response = await request(app)
      .get('/api/v1/users')
      .query({ email: maliciousInput });
    
    // Should not execute SQL, should return error or empty result
    expect(response.status).not.toBe(500);
    
    // Verify users table still exists
    const users = await db.query('SELECT COUNT(*) FROM users');
    expect(users.rows[0].count).toBeGreaterThan(0);
  });
  
  it('should prevent XSS attacks', async () => {
    const xssPayload = '<script>alert("XSS")</script>';
    
    const response = await request(app)
      .post('/api/v1/orders')
      .send({ notes: xssPayload });
    
    // Response should escape HTML
    expect(response.body.notes).not.toContain('<script>');
    expect(response.body.notes).toContain('&lt;script&gt;');
  });
});
```

### 9.7 Chaos Engineering

**Tool**: Chaos Monkey, Gremlin

**Chaos Experiments**:

| Experiment | Hypothesis | Expected Behavior |
|------------|-----------|-------------------|
| Kill random pod | System continues serving traffic | Other pods handle requests, new pod starts |
| Introduce 500ms latency | Response time increases but < 1s | Circuit breaker activates, fallback used |
| Simulate database failure | System degrades gracefully | Read replicas serve reads, writes queued |
| Network partition | Services handle isolation | Retry logic works, eventual consistency |
| Spike traffic (10x) | Auto-scaling handles load | Pods scale up, performance maintained |

**Example - Chaos Test**:

```bash
# Kill random pod every 5 minutes
kubectl delete pod -l app=order-service --random

# Introduce network latency
tc qdisc add dev eth0 root netem delay 500ms

# Simulate CPU stress
stress-ng --cpu 4 --timeout 60s
```


---

## 10. Operations & Observability

### 10.1 Deployment Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     GitHub Repository                        │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        │ git push
                        ▼
┌─────────────────────────────────────────────────────────────┐
│                   GitHub Actions (CI/CD)                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │  Lint    │→ │  Test    │→ │  Build   │→ │  Deploy  │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        │ push image
                        ▼
┌─────────────────────────────────────────────────────────────┐
│              Container Registry (ECR)                        │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        │ pull image
                        ▼
┌─────────────────────────────────────────────────────────────┐
│              Kubernetes Cluster (EKS)                        │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Namespace: production                                │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐           │  │
│  │  │  Order   │  │ Payment  │  │Inventory │           │  │
│  │  │ Service  │  │ Service  │  │ Service  │           │  │
│  │  │ (3 pods) │  │ (3 pods) │  │ (3 pods) │           │  │
│  │  └──────────┘  └──────────┘  └──────────┘           │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

**Deployment Environments**:

| Environment | Purpose | Auto-Deploy | Approval Required |
|-------------|---------|-------------|-------------------|
| Development | Feature development | Yes (on commit to dev branch) | No |
| Staging | Pre-production testing | Yes (on commit to main) | No |
| Production | Live traffic | No | Yes (manual approval) |

### 10.2 CI/CD Pipeline

**GitHub Actions Workflow**:

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      - run: npm ci
      - run: npm run lint
  
  test:
    runs-on: ubuntu-latest
    needs: lint
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
      - run: npm ci
      - run: npm test
      - run: npm run test:coverage
      - uses: codecov/codecov-action@v3
  
  build:
    runs-on: ubuntu-latest
    needs: test
    steps:
      - uses: actions/checkout@v3
      - uses: docker/build-push-action@v4
        with:
          push: true
          tags: |
            ${{ secrets.ECR_REGISTRY }}/order-service:${{ github.sha }}
            ${{ secrets.ECR_REGISTRY }}/order-service:latest
  
  deploy-staging:
    runs-on: ubuntu-latest
    needs: build
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v3
      - uses: aws-actions/configure-aws-credentials@v2
      - run: |
          kubectl set image deployment/order-service \
            order-service=${{ secrets.ECR_REGISTRY }}/order-service:${{ github.sha }} \
            -n staging
  
  deploy-production:
    runs-on: ubuntu-latest
    needs: deploy-staging
    if: github.ref == 'refs/heads/main'
    environment: production
    steps:
      - uses: actions/checkout@v3
      - uses: aws-actions/configure-aws-credentials@v2
      - run: |
          kubectl set image deployment/order-service \
            order-service=${{ secrets.ECR_REGISTRY }}/order-service:${{ github.sha }} \
            -n production
```

**Deployment Strategy**: Rolling update with health checks

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: order-service
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1        # Max 1 extra pod during update
      maxUnavailable: 0  # Always maintain 3 pods
  template:
    spec:
      containers:
      - name: order-service
        image: order-service:latest
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
```

### 10.3 Monitoring & Key Metrics

**Monitoring Stack**: Datadog (or Prometheus + Grafana)

#### 10.3.1 Application Metrics

| Metric | Description | Alert Threshold |
|--------|-------------|-----------------|
| `http.requests.total` | Total HTTP requests | N/A |
| `http.requests.duration` | Request duration (P50, P95, P99) | P95 > 500ms |
| `http.requests.errors` | HTTP error count | Rate > 1% |
| `http.requests.rate` | Requests per second | N/A |
| `orders.created.total` | Orders created | N/A |
| `orders.failed.total` | Failed orders | Rate > 0.5% |
| `payment.authorization.duration` | Payment auth time | P95 > 2s |
| `inventory.reservation.failures` | Inventory failures | Rate > 0.1% |

#### 10.3.2 Infrastructure Metrics

| Metric | Description | Alert Threshold |
|--------|-------------|-----------------|
| `cpu.usage` | CPU utilization | > 80% |
| `memory.usage` | Memory utilization | > 85% |
| `disk.usage` | Disk utilization | > 80% |
| `network.bytes.in` | Network ingress | N/A |
| `network.bytes.out` | Network egress | N/A |
| `pod.restarts` | Pod restart count | > 3 in 5 min |

#### 10.3.3 Database Metrics

| Metric | Description | Alert Threshold |
|--------|-------------|-----------------|
| `db.connections.active` | Active connections | > 80% of max |
| `db.query.duration` | Query duration | P95 > 100ms |
| `db.deadlocks` | Deadlock count | > 0 |
| `db.replication.lag` | Replication lag | > 10 seconds |
| `db.cache.hit_rate` | Cache hit rate | < 90% |

**Dashboard Example**:

```
┌─────────────────────────────────────────────────────────────┐
│                   Order Service Dashboard                    │
├─────────────────────────────────────────────────────────────┤
│  Request Rate: 1,234 RPS    │  Error Rate: 0.05%           │
│  P95 Latency: 280ms         │  P99 Latency: 450ms          │
├─────────────────────────────────────────────────────────────┤
│  [Graph: Request Rate over time]                            │
│  [Graph: Latency percentiles over time]                     │
│  [Graph: Error rate over time]                              │
├─────────────────────────────────────────────────────────────┤
│  CPU: 65%  ████████░░  │  Memory: 72%  ███████░░░          │
│  Pods: 3/3 healthy     │  Database: Connected              │
└─────────────────────────────────────────────────────────────┘
```

### 10.4 Logging Strategy

**Logging Levels**:

| Level | Use Case | Example |
|-------|----------|---------|
| ERROR | System errors, exceptions | Payment gateway timeout |
| WARN | Potential issues | High latency detected |
| INFO | Important events | Order created, user logged in |
| DEBUG | Detailed debugging | Function entry/exit, variable values |

**Structured Logging**:

```javascript
const logger = require('winston');

logger.info('Order created', {
  order_id: 'order_123',
  user_id: 'user_456',
  total: 100.00,
  items_count: 3,
  timestamp: new Date().toISOString(),
  request_id: 'req_xyz789'
});

// Output (JSON):
{
  "level": "info",
  "message": "Order created",
  "order_id": "order_123",
  "user_id": "user_456",
  "total": 100.00,
  "items_count": 3,
  "timestamp": "2024-01-15T10:30:00.000Z",
  "request_id": "req_xyz789"
}
```

**Log Aggregation**:

```
Application Pods → FluentBit → CloudWatch Logs → Datadog
                                                 ↓
                                          Elasticsearch
                                                 ↓
                                             Kibana
```

**Log Retention**:
- Hot storage (Elasticsearch): 7 days
- Warm storage (S3): 90 days
- Cold storage (S3 Glacier): 1 year

### 10.5 Alerting Rules

**Alert Severity Levels**:

| Severity | Response Time | Notification | Example |
|----------|--------------|--------------|---------|
| P0 (Critical) | Immediate | PagerDuty + Slack + Email | Service down, database failure |
| P1 (High) | 15 minutes | Slack + Email | High error rate, slow response time |
| P2 (Medium) | 1 hour | Slack | Elevated latency, cache miss rate |
| P3 (Low) | Next business day | Email | Disk usage warning |

**Alert Rules**:

```yaml
# High error rate
- alert: HighErrorRate
  expr: rate(http_requests_errors[5m]) > 0.01
  for: 5m
  labels:
    severity: P1
  annotations:
    summary: "High error rate detected"
    description: "Error rate is {{ $value }}% (threshold: 1%)"

# Slow response time
- alert: SlowResponseTime
  expr: histogram_quantile(0.95, http_request_duration_seconds) > 0.5
  for: 5m
  labels:
    severity: P1
  annotations:
    summary: "Slow response time detected"
    description: "P95 latency is {{ $value }}s (threshold: 0.5s)"

# Database connection pool exhausted
- alert: DatabaseConnectionPoolExhausted
  expr: db_connections_active / db_connections_max > 0.9
  for: 2m
  labels:
    severity: P0
  annotations:
    summary: "Database connection pool nearly exhausted"
    description: "{{ $value }}% of connections in use"
```

### 10.6 Distributed Tracing

**Tool**: Jaeger, AWS X-Ray, Datadog APM

**Trace Example**:

```
Trace ID: abc123xyz789
Duration: 285ms

┌─ HTTP GET /api/v1/orders/order_123 (285ms)
│  ├─ Authenticate user (15ms)
│  ├─ Query database: SELECT * FROM orders (45ms)
│  ├─ Query database: SELECT * FROM order_items (30ms)
│  ├─ HTTP GET inventory-service/check (120ms)
│  │  ├─ Query database: SELECT inventory (40ms)
│  │  └─ Redis GET product:abc (5ms)
│  ├─ HTTP GET payment-service/status (50ms)
│  └─ Serialize response (25ms)
```

**Instrumentation**:

```javascript
const tracer = require('dd-trace').init();

app.get('/api/v1/orders/:id', async (req, res) => {
  const span = tracer.startSpan('get_order');
  span.setTag('order_id', req.params.id);
  
  try {
    const order = await orderService.getOrder(req.params.id);
    span.setTag('order_status', order.status);
    res.json(order);
  } catch (error) {
    span.setTag('error', true);
    span.log({ event: 'error', message: error.message });
    throw error;
  } finally {
    span.finish();
  }
});
```

### 10.7 Incident Response

**Incident Response Process**:

1. **Detection** (0-5 min)
   - Alert triggered
   - On-call engineer paged

2. **Triage** (5-15 min)
   - Assess severity
   - Create incident channel
   - Notify stakeholders

3. **Investigation** (15-60 min)
   - Check logs, metrics, traces
   - Identify root cause
   - Test hypothesis

4. **Mitigation** (60-120 min)
   - Apply fix or rollback
   - Verify resolution
   - Monitor for recurrence

5. **Post-Mortem** (1-3 days)
   - Document timeline
   - Identify root cause
   - Create action items

**Incident Severity**:

| Severity | Impact | Response Time | Example |
|----------|--------|---------------|---------|
| SEV-1 | Complete outage | Immediate | Database down, all requests failing |
| SEV-2 | Major degradation | 15 minutes | 50% error rate, payment failures |
| SEV-3 | Minor degradation | 1 hour | Slow response time, cache failures |
| SEV-4 | No user impact | Next business day | Monitoring alert, log errors |

### 10.8 Disaster Recovery & Backup

**Backup Strategy**:

| Data Type | Frequency | Retention | Recovery Time |
|-----------|-----------|-----------|---------------|
| Database | Every 6 hours | 30 days | 15 minutes |
| Database (point-in-time) | Continuous | 7 days | 5 minutes |
| S3 Objects | Continuous (versioning) | 90 days | Immediate |
| Configuration | On change | Indefinite (Git) | Immediate |

**Disaster Recovery Plan**:

| Scenario | RTO | RPO | Recovery Steps |
|----------|-----|-----|----------------|
| Database failure | 2 min | 5 min | Failover to standby |
| Region failure | 30 min | 15 min | Failover to backup region |
| Data corruption | 1 hour | 6 hours | Restore from backup |
| Complete data loss | 4 hours | 6 hours | Restore from backup + replay logs |

**Backup Verification**:
- Weekly: Restore test database from backup
- Monthly: Full disaster recovery drill
- Quarterly: Cross-region failover test

### 10.9 Operational Runbooks

**Common Operations**:

| Operation | Runbook Link | Frequency |
|-----------|-------------|-----------|
| Deploy new version | [Deploy Runbook](#) | Daily |
| Scale up/down | [Scaling Runbook](#) | As needed |
| Database maintenance | [DB Maintenance](#) | Weekly |
| Certificate renewal | [Cert Renewal](#) | Annually |
| Incident response | [Incident Runbook](#) | As needed |
| Backup restoration | [Restore Runbook](#) | As needed |

**Example Runbook - Deploy New Version**:

```markdown
# Deploy New Version

## Prerequisites
- [ ] Code reviewed and approved
- [ ] Tests passing (unit, integration, e2e)
- [ ] Staging deployment successful
- [ ] Change ticket created

## Steps
1. Create deployment branch: `git checkout -b deploy/v1.2.3`
2. Update version: `npm version 1.2.3`
3. Push to GitHub: `git push origin deploy/v1.2.3`
4. Create PR to main branch
5. Approve deployment in GitHub Actions
6. Monitor deployment:
   - Check pod status: `kubectl get pods -n production`
   - Check logs: `kubectl logs -f deployment/order-service -n production`
   - Check metrics: [Dashboard Link]
7. Verify health checks passing
8. Monitor error rate for 15 minutes
9. If issues detected, rollback: `kubectl rollout undo deployment/order-service -n production`

## Rollback
- Command: `kubectl rollout undo deployment/order-service -n production`
- Verify: `kubectl rollout status deployment/order-service -n production`
```


---

## 11. Migration & Rollout Plan

### 11.1 Migration Strategy

> 💡 **Note**: This section applies when replacing an existing system. Skip if building from scratch.

**Migration Approach**: Strangler Fig Pattern

```
Phase 1: Parallel Run          Phase 2: Gradual Migration      Phase 3: Complete
┌──────────────┐               ┌──────────────┐                ┌──────────────┐
│   Old        │               │   Old        │                │              │
│   System     │               │   System     │                │              │
│   (100%)     │               │   (20%)      │                │              │
└──────────────┘               └──────────────┘                └──────────────┘
                               ┌──────────────┐                ┌──────────────┐
                               │   New        │                │   New        │
                               │   System     │                │   System     │
                               │   (80%)      │                │   (100%)     │
                               └──────────────┘                └──────────────┘
```

**Migration Phases**:

| Phase | Duration | Traffic % | Rollback Plan |
|-------|----------|-----------|---------------|
| Phase 0: Setup | 2 weeks | 0% | N/A |
| Phase 1: Shadow Mode | 2 weeks | 0% (shadow only) | Stop shadow traffic |
| Phase 2: Canary | 1 week | 5% | Route 53 weighted routing |
| Phase 3: Gradual Rollout | 4 weeks | 5% → 25% → 50% → 100% | Route 53 weighted routing |
| Phase 4: Cleanup | 2 weeks | 100% | Keep old system for 2 weeks |

### 11.2 Phased Rollout Stages

#### Stage 0: Setup & Preparation (Week 1-2)

**Objectives**:
- Deploy new system to production (0% traffic)
- Set up monitoring and alerting
- Configure feature flags
- Prepare rollback procedures

**Tasks**:
- [ ] Deploy infrastructure (database, cache, services)
- [ ] Configure monitoring dashboards
- [ ] Set up alerting rules
- [ ] Create feature flags for gradual rollout
- [ ] Document rollback procedures
- [ ] Train support team on new system

**Success Criteria**:
- All services healthy (0 errors in logs)
- Monitoring dashboards showing data
- Feature flags working correctly
- Rollback tested successfully

#### Stage 1: Shadow Mode (Week 3-4)

**Objectives**:
- Send duplicate traffic to new system
- Compare results with old system
- Identify discrepancies

**Implementation**:
```javascript
// Proxy layer
async function handleRequest(req) {
  // Send to old system (primary)
  const oldResponse = await oldSystem.handle(req);
  
  // Send to new system (shadow, async)
  shadowTraffic(req).catch(err => {
    logger.warn('Shadow traffic failed', { error: err });
  });
  
  // Return old system response
  return oldResponse;
}

async function shadowTraffic(req) {
  const newResponse = await newSystem.handle(req);
  
  // Compare responses
  if (!deepEqual(oldResponse, newResponse)) {
    logger.warn('Response mismatch', {
      old: oldResponse,
      new: newResponse
    });
  }
}
```

**Success Criteria**:
- New system handles 100% of shadow traffic
- Error rate < 0.1%
- Response time < 500ms (P95)
- < 1% response mismatches

#### Stage 2: Canary Deployment (Week 5)

**Objectives**:
- Route 5% of real traffic to new system
- Monitor for issues
- Validate business metrics

**Implementation**:
```yaml
# Route 53 weighted routing
- Weight: 95, Target: old-system-lb
- Weight: 5, Target: new-system-lb
```

**Monitoring**:
- Error rate comparison (old vs new)
- Latency comparison
- Business metrics (orders created, revenue)
- User feedback

**Success Criteria**:
- Error rate ≤ old system
- P95 latency ≤ old system + 10%
- No increase in support tickets
- Business metrics stable

**Rollback Triggers**:
- Error rate > 1%
- P95 latency > 1s
- Critical bug discovered
- Business metrics drop > 5%

#### Stage 3: Gradual Rollout (Week 6-9)

**Week 6: 25% Traffic**

| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| Error Rate | < 0.1% | 0.08% | ✅ |
| P95 Latency | < 500ms | 420ms | ✅ |
| Orders/hour | 1,000 | 1,020 | ✅ |
| Support Tickets | < 50/day | 45/day | ✅ |

**Week 7: 50% Traffic**

| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| Error Rate | < 0.1% | 0.09% | ✅ |
| P95 Latency | < 500ms | 450ms | ✅ |
| Orders/hour | 1,000 | 1,015 | ✅ |
| Support Tickets | < 50/day | 48/day | ✅ |

**Week 8-9: 100% Traffic**

| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| Error Rate | < 0.1% | 0.07% | ✅ |
| P95 Latency | < 500ms | 380ms | ✅ |
| Orders/hour | 1,000 | 1,030 | ✅ |
| Support Tickets | < 50/day | 42/day | ✅ |

#### Stage 4: Cleanup (Week 10-11)

**Objectives**:
- Decommission old system
- Migrate remaining data
- Update documentation

**Tasks**:
- [ ] Route 100% traffic to new system for 2 weeks
- [ ] Monitor for any issues
- [ ] Migrate historical data (if needed)
- [ ] Decommission old infrastructure
- [ ] Update documentation
- [ ] Archive old code repository
- [ ] Celebrate success! 🎉

### 11.3 Success Criteria per Stage

| Stage | Success Criteria | Go/No-Go Decision |
|-------|-----------------|-------------------|
| **Setup** | All services healthy, monitoring working | Proceed if all green |
| **Shadow** | < 0.1% error rate, < 1% mismatches | Proceed if < 5% mismatches |
| **Canary** | Error rate ≤ old system, no critical bugs | Proceed if metrics stable |
| **25%** | Error rate < 0.1%, P95 < 500ms | Proceed if no degradation |
| **50%** | Error rate < 0.1%, P95 < 500ms | Proceed if no degradation |
| **100%** | Error rate < 0.1%, P95 < 500ms, business metrics stable | Proceed to cleanup |

### 11.4 Rollback Strategy & Triggers

**Rollback Methods**:

| Method | Speed | Use Case |
|--------|-------|----------|
| Route 53 weight change | 1 minute | Traffic routing issues |
| Kubernetes rollback | 2 minutes | Application bugs |
| Database restore | 15 minutes | Data corruption |
| Full infrastructure rollback | 1 hour | Major system failure |

**Automatic Rollback Triggers**:

```javascript
// Automated rollback logic
async function checkHealthMetrics() {
  const metrics = await getMetrics();
  
  if (metrics.errorRate > 0.01) {
    await rollback('High error rate detected');
  }
  
  if (metrics.p95Latency > 1000) {
    await rollback('High latency detected');
  }
  
  if (metrics.ordersPerHour < 800) {
    await rollback('Order rate dropped significantly');
  }
}

async function rollback(reason) {
  logger.error('Initiating automatic rollback', { reason });
  
  // 1. Update Route 53 weights
  await route53.updateWeights({
    oldSystem: 100,
    newSystem: 0
  });
  
  // 2. Notify team
  await slack.send(`🚨 Automatic rollback initiated: ${reason}`);
  await pagerduty.trigger('Rollback initiated');
  
  // 3. Create incident
  await createIncident({
    title: 'Automatic rollback triggered',
    severity: 'P1',
    reason: reason
  });
}
```

**Manual Rollback Procedure**:

```bash
# 1. Update Route 53 weights (immediate)
aws route53 change-resource-record-sets \
  --hosted-zone-id Z123456 \
  --change-batch file://rollback-weights.json

# 2. Rollback Kubernetes deployment (if needed)
kubectl rollout undo deployment/order-service -n production

# 3. Verify old system handling traffic
curl https://api.example.com/health

# 4. Monitor metrics
# Check dashboard: https://datadog.com/dashboard/rollback
```

### 11.5 Communication Plan

**Stakeholder Communication**:

| Stakeholder | Communication Method | Frequency | Content |
|-------------|---------------------|-----------|---------|
| Engineering Team | Slack + Email | Daily during rollout | Detailed metrics, issues |
| Product Team | Email | Weekly | High-level progress, business impact |
| Support Team | Slack + Training | Before each phase | New features, known issues |
| Executives | Email | Weekly | Executive summary, risks |
| Customers | Email + In-app | Major milestones | New features, improvements |

**Communication Templates**:

**Pre-Rollout Announcement**:
```
Subject: New Order System Rollout - Starting [Date]

Hi Team,

We're excited to announce the rollout of our new order processing system!

Timeline:
- Week 1-2: Shadow mode (no customer impact)
- Week 3: 5% of traffic
- Week 4-7: Gradual increase to 100%

What to expect:
- Faster order processing (500ms → 200ms)
- Better error handling
- Improved monitoring

Known issues:
- [List any known limitations]

Questions? Contact: [Team Email]
```

**Rollout Progress Update**:
```
Subject: Order System Rollout - Week 3 Update

Hi Team,

Week 3 Progress:
✅ 25% of traffic migrated
✅ Error rate: 0.08% (target: < 0.1%)
✅ P95 latency: 420ms (target: < 500ms)
✅ No increase in support tickets

Next Steps:
- Week 4: Increase to 50% traffic
- Continue monitoring metrics

Issues:
- None reported

Dashboard: [Link]
```

### 11.6 Risk Assessment & Mitigation

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Data loss during migration | Low | Critical | Backup before migration, test restore |
| Performance degradation | Medium | High | Load testing, gradual rollout |
| Integration failures | Medium | High | Integration tests, shadow mode |
| User confusion | Low | Medium | User communication, training |
| Rollback failure | Low | Critical | Test rollback procedure, keep old system |
| Database migration issues | Medium | Critical | Test migration, point-in-time recovery |

### 11.7 Post-Migration Checklist

**Week 1 After 100% Migration**:
- [ ] Monitor error rates daily
- [ ] Review support tickets for new issues
- [ ] Check business metrics (orders, revenue)
- [ ] Verify all integrations working
- [ ] Collect user feedback

**Week 2-4 After 100% Migration**:
- [ ] Continue monitoring (less frequent)
- [ ] Optimize based on production data
- [ ] Address any minor issues
- [ ] Plan old system decommission

**Decommission Old System**:
- [ ] Verify 100% traffic on new system for 2 weeks
- [ ] Export any remaining data
- [ ] Update documentation
- [ ] Shut down old infrastructure
- [ ] Archive old code
- [ ] Cancel old service subscriptions

---

## Appendix

### A. Glossary

| Term | Definition |
|------|------------|
| **API** | Application Programming Interface |
| **CDN** | Content Delivery Network |
| **CRUD** | Create, Read, Update, Delete |
| **DAU** | Daily Active Users |
| **JWT** | JSON Web Token |
| **MTBF** | Mean Time Between Failures |
| **MTTR** | Mean Time To Recovery |
| **P50/P95/P99** | 50th/95th/99th percentile |
| **RBAC** | Role-Based Access Control |
| **RPS** | Requests Per Second |
| **RPO** | Recovery Point Objective |
| **RTO** | Recovery Time Objective |
| **SLA** | Service Level Agreement |
| **TTL** | Time To Live |

### B. References

- [System Design Primer](https://github.com/donnemartin/system-design-primer)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Microservices Patterns](https://microservices.io/patterns/)
- [Database Indexing Best Practices](https://use-the-index-luke.com/)
- [API Design Guidelines](https://github.com/microsoft/api-guidelines)

### C. Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2024-01-15 | [Author] | Initial version |
| 1.1 | 2024-02-01 | [Author] | Added cost estimation section |
| 1.2 | 2024-02-15 | [Author] | Updated API endpoints |

---

## Document Review & Approval

| Role | Name | Signature | Date |
|------|------|-----------|------|
| **Author** | [Name] | | |
| **Tech Lead** | [Name] | | |
| **Architect** | [Name] | | |
| **Security Lead** | [Name] | | |
| **Product Owner** | [Name] | | |

---

**End of Document**

> 💡 **Tips for Using This Template**:
> - Delete sections that don't apply to your project
> - Replace all [placeholders] with actual values
> - Update examples to match your domain
> - Keep it concise - aim for 30-50 pages max
> - Review and update regularly as system evolves
> - Use this as a living document, not a one-time artifact
