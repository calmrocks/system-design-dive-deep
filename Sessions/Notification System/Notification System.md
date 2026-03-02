# Notification System: Architecture Guide

## Overview

| Attribute | Details |
|-----------|---------|
| Duration | 60 minutes |
| Level | Intermediate to Advanced |
| Prerequisites | Message Queue session, Event-Driven Architecture session |

## Learning Objectives

- Design a multi-channel notification system (push, email, SMS, in-app)
- Handle fan-out, delivery guarantees, and user preferences
- Reason about rate limiting, deduplication, and priority
- Build notification pipelines that scale to millions of users
- Evaluate trade-offs between delivery speed and reliability

---

## 1. Why Notification Systems Are Complex

### The Problem

~~~
Simple version:
  Event happens → send email
  Done? Not even close.

Real-world requirements:
  ✅ Multiple channels (push, email, SMS, in-app, webhook)
  ✅ User preferences (opt-in/out per channel per type)
  ✅ Rate limiting (don't spam users)
  ✅ Deduplication (don't send the same notification twice)
  ✅ Priority (security alert > marketing email)
  ✅ Templating (localized, personalized content)
  ✅ Delivery tracking (sent, delivered, opened, clicked)
  ✅ Retry with backoff (provider failures)
  ✅ Regulatory compliance (GDPR, CAN-SPAM, quiet hours)
~~~

---

## 2. High-Level Architecture

### System Overview

~~~mermaid
flowchart TB
    subgraph sources["Event Sources"]
        S1[Order Service]
        S2[Auth Service]
        S3[Marketing Service]
        S4[Scheduled Jobs]
    end
    
    subgraph core["Notification Service"]
        API[Notification API]
        PREF[Preference Engine]
        TMPL[Template Engine]
        ROUTER[Channel Router]
        DEDUP[Dedup & Rate Limiter]
        QUEUE[Priority Queues]
    end
    
    subgraph channels["Channel Workers"]
        PUSH[Push Worker]
        EMAIL[Email Worker]
        SMS[SMS Worker]
        INAPP[In-App Worker]
    end
    
    subgraph providers["External Providers"]
        APNS[APNs / FCM]
        SES[Email Provider]
        TWILIO[SMS Provider]
        WS[WebSocket Server]
    end
    
    S1 & S2 & S3 & S4 --> API
    API --> DEDUP --> PREF --> TMPL --> ROUTER
    ROUTER --> QUEUE
    QUEUE --> PUSH & EMAIL & SMS & INAPP
    PUSH --> APNS
    EMAIL --> SES
    SMS --> TWILIO
    INAPP --> WS
~~~

### Request Flow

~~~mermaid
sequenceDiagram
    participant Src as Event Source
    participant API as Notification API
    participant DD as Dedup/Rate Limit
    participant Pref as Preference Engine
    participant Tmpl as Template Engine
    participant Q as Priority Queue
    participant W as Channel Worker
    participant P as Provider (APNs/SES)
    
    Src->>API: Send notification request
    API->>DD: Check dedup key + rate limit
    DD-->>API: OK (not duplicate, within limit)
    API->>Pref: Get user preferences
    Pref-->>API: Channels: [push, email], quiet hours: 10pm-8am
    API->>Tmpl: Render template (locale: ja-JP)
    Tmpl-->>API: Rendered content per channel
    API->>Q: Enqueue (priority: high)
    Q->>W: Dequeue
    W->>P: Deliver notification
    P-->>W: Delivery receipt
    W->>W: Update delivery status
~~~

---

## 3. Core Components

### User Preferences

~~~
Preference model:
┌─────────────────────────────────────────────────────┐
│ user_id: "user-123"                                 │
│ channels:                                           │
│   push:  { enabled: true,  device_tokens: [...] }   │
│   email: { enabled: true,  address: "..." }         │
│   sms:   { enabled: false, phone: "..." }           │
│ notification_types:                                  │
│   order_update:    { push: true, email: true }      │
│   marketing:       { push: false, email: true }     │
│   security_alert:  { push: true, email: true,       │
│                      sms: true }  ← override        │
│ quiet_hours:                                        │
│   timezone: "Asia/Tokyo"                            │
│   start: "22:00", end: "08:00"                      │
│   exceptions: ["security_alert"]                    │
└─────────────────────────────────────────────────────┘

Resolution order:
  1. Regulatory (unsubscribed = never send)
  2. Type-level preference (user opted out of marketing push)
  3. Channel-level preference (user disabled SMS)
  4. Quiet hours (defer unless exception)
  5. Global defaults
~~~

### Priority Queues

~~~
Priority levels:
  P0 - Critical:  Security alerts, 2FA codes
                   → Process immediately, bypass rate limits
  P1 - High:      Order confirmations, payment receipts
                   → Process within seconds
  P2 - Medium:    Social interactions (likes, comments)
                   → Process within minutes
  P3 - Low:       Marketing, recommendations, digests
                   → Process within hours, batch-friendly

Implementation:
  Separate queue per priority level
  Workers poll P0 first, then P1, etc.
  Or: weighted fair queuing (P0 gets 50% capacity, P1 30%, etc.)
~~~

### Rate Limiting

~~~
Rate limit layers:

  Per-user rate limits:
    Max 5 push notifications per hour
    Max 1 email per notification type per day
    Max 1 SMS per day (cost control)

  Per-type rate limits:
    Marketing: max 2 per week per user
    Social: max 20 per hour per user

  Global rate limits:
    Email provider: 100,000/hour (SES limit)
    SMS provider: 10,000/hour (Twilio limit)
    Push: 500,000/hour (FCM limit)

  When rate limited:
    P0-P1: queue and retry (don't drop)
    P2-P3: aggregate into digest or drop
~~~

### Deduplication

~~~
Problem: Same event triggers notification twice

  Order service retries → two "order confirmed" emails

Solution: Idempotency key
  Key = hash(user_id + notification_type + entity_id + time_window)
  
  Check Redis: EXISTS dedup:{key}
    Yes → skip (already sent)
    No  → SET dedup:{key} EX 3600 (1 hour TTL)
         → proceed with sending
~~~

---

## 4. Channel-Specific Design

### Push Notifications (APNs / FCM)

~~~mermaid
flowchart TB
    W[Push Worker] --> LOOKUP[Device Token Lookup]
    LOOKUP --> BATCH[Batch by Platform]
    BATCH --> APNS[APNs<br/>iOS devices]
    BATCH --> FCM[FCM<br/>Android devices]
    APNS --> FEEDBACK[Process Feedback]
    FCM --> FEEDBACK
    FEEDBACK --> INVALID{Invalid Token?}
    INVALID -->|Yes| REMOVE[Remove token<br/>from user profile]
    INVALID -->|No| LOG[Log delivery status]
~~~

~~~
Key challenges:
  - Device token management (tokens change, expire, become invalid)
  - Platform differences (APNs vs FCM payload formats)
  - Silent push vs alert push
  - Badge count management
  - Token feedback loop (remove invalid tokens)
~~~

### Email

~~~
Delivery pipeline:
  1. Render HTML + plain text from template
  2. Personalize (name, order details, locale)
  3. Add tracking pixel + link tracking
  4. Send via provider (SES, SendGrid, Mailgun)
  5. Handle bounces and complaints
  
Reputation management:
  - Warm up new sending domains gradually
  - Monitor bounce rate (< 2%) and complaint rate (< 0.1%)
  - Implement List-Unsubscribe header
  - Separate transactional and marketing sending domains
~~~

### In-App Notifications

~~~mermaid
flowchart LR
    W[In-App Worker] --> DB[(Notification Store)]
    W --> WS[WebSocket Server]
    WS --> CLIENT[Client App]
    CLIENT --> DB
    
    DB --> |Pull: GET /notifications| CLIENT
    WS --> |Push: real-time| CLIENT
~~~

~~~
Dual delivery:
  1. Write to notification store (persistent)
  2. Push via WebSocket (real-time)
  
  If user is online → WebSocket delivers instantly
  If user is offline → they see it when they open the app (pull from store)

Storage schema:
  notification_id, user_id, type, title, body, 
  data (JSON), read (boolean), created_at
  
  Index on (user_id, read, created_at DESC)
  TTL: 90 days (auto-delete old notifications)
~~~

---

## 5. Fan-Out Patterns

### Small Fan-Out (Targeted)

~~~
"Your order has shipped" → 1 user, 2-3 channels
  Simple: process inline or single queue message

"New comment on your post" → 1 user + N followers watching
  Medium: fan-out to ~100-1000 users
  Process in batches
~~~

### Large Fan-Out (Broadcast)

~~~
"New feature announcement" → 10 million users

  Naive: 10M queue messages → overwhelms everything

  Better approach:
  1. Create notification campaign record
  2. Segment users (active in last 30 days, opted in)
  3. Batch into chunks of 1000 users
  4. Enqueue chunks as low-priority jobs
  5. Workers process chunks, respecting rate limits
  6. Track progress (sent: 4.2M / 10M)
  
  Timeline: hours, not seconds (and that's fine)
~~~

~~~mermaid
flowchart TB
    CAMPAIGN[Campaign: 10M users] --> SEGMENT[Segment & Filter]
    SEGMENT --> CHUNK1[Chunk 1<br/>1000 users]
    SEGMENT --> CHUNK2[Chunk 2<br/>1000 users]
    SEGMENT --> DOTS[...]
    SEGMENT --> CHUNKN[Chunk 10000<br/>1000 users]
    
    CHUNK1 & CHUNK2 & DOTS & CHUNKN --> QUEUE[Low Priority Queue]
    QUEUE --> W1[Worker 1]
    QUEUE --> W2[Worker 2]
    QUEUE --> W3[Worker N]
    
    W1 & W2 & W3 --> PROVIDERS[Email/Push/SMS Providers]
~~~

---

## 6. Delivery Tracking

### Status Flow

~~~mermaid
stateDiagram-v2
    [*] --> Queued
    Queued --> Sending
    Sending --> Delivered
    Sending --> Failed
    Failed --> Retrying
    Retrying --> Sending
    Retrying --> Dead: Max retries exceeded
    Delivered --> Opened: Email/Push opened
    Opened --> Clicked: Link clicked
~~~

~~~
Tracking mechanisms:
  Email:
    - Delivery: provider webhook (SES notification)
    - Open: tracking pixel (1x1 image)
    - Click: redirect link through tracking service
    - Bounce/Complaint: provider feedback loop
  
  Push:
    - Delivery: APNs/FCM delivery receipt
    - Open: app reports notification tap
    - Dismiss: app reports notification dismiss
  
  SMS:
    - Delivery: provider delivery report
    - No open/click tracking (unless short URL)
  
  In-App:
    - Delivery: written to store (always succeeds)
    - Read: client marks as read via API
    - Click: client reports action
~~~

---

## 7. Anti-Patterns

### Notification Spam

~~~
Problem: Every micro-event triggers a notification

  "User A liked your post"     (10:01)
  "User B liked your post"     (10:02)
  "User C liked your post"     (10:03)
  → 3 push notifications in 2 minutes

Fix: Aggregate and batch
  "User A, B, C and 5 others liked your post" (10:15)
  
  Implementation:
    Buffer notifications by (user, type, entity) for N minutes
    Collapse into single notification with count
~~~

### Fire and Forget

~~~
Problem: Send notification, never check if it arrived

  → Users complain they never got the 2FA code
  → No way to diagnose

Fix: Track delivery status for every notification
     Alert on delivery failure rate spikes
     Provide fallback channels (push failed → try SMS)
~~~

### Synchronous Sending

~~~
Problem: API call blocks until notification is sent

  POST /orders → process order → send email → respond
  
  If email provider is slow (3s) → API response is slow
  If email provider is down → API call fails

Fix: Always enqueue, never send inline
     Return 202 Accepted, process async
     Exception: 2FA codes (use sync with timeout + fallback)
~~~

---

## 8. Key Takeaways

| # | Takeaway |
|---|----------|
| 1 | Always async — enqueue notifications, never send inline |
| 2 | User preferences are first-class — respect opt-outs and quiet hours |
| 3 | Priority queues prevent marketing from blocking security alerts |
| 4 | Dedup with idempotency keys — at-least-once delivery means duplicates happen |
| 5 | Rate limit per user, per type, and per provider |
| 6 | Aggregate similar notifications — don't spam |
| 7 | Track delivery end-to-end — you can't fix what you can't measure |
| 8 | Plan for large fan-out separately from targeted notifications |

---

## 9. Practical Exercise

### Design Challenge

Design a notification system for a food delivery app:

**Channels:** Push, SMS, email, in-app

**Notification types:**
- Order confirmed, preparing, out for delivery, delivered
- Driver assigned, driver location updates
- Payment receipt
- Promotional offers (weekly)
- Account security (password change, new login)

**Requirements:**
- 5 million active users, 500K orders per day
- Order status updates must arrive within 10 seconds
- Users can configure preferences per notification type
- Support 15 languages
- Promotional notifications respect quiet hours

**Discussion Questions:**
1. How do you ensure order status push notifications arrive within 10 seconds?
2. What's your fallback strategy if push delivery fails for a delivery update?
3. How do you handle driver location updates without overwhelming the user?
4. What's your approach to promotional notification batching and scheduling?
5. How do you handle a user who has push disabled but needs to know their food arrived?
