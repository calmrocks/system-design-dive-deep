# Rate Limiter - 1 Hour Session

**Duration:** 60 minutes
**Level:** Intermediate

---

## 📋 Session Agenda

- [ ] Introduction to Rate Limiting (10 min)
- [ ] Rate Limiting Algorithms (15 min)
- [ ] Distributed Rate Limiting (15 min)
- [ ] Implementation Patterns (10 min)
- [ ] Best Practices & Real-World Examples (10 min)

---

## 🎯 Learning Objectives

By the end of this session, you will understand:
- What rate limiting is and why it's essential
- Different rate limiting algorithms and their trade-offs
- How to implement distributed rate limiting
- Common patterns and best practices
- How to choose the right algorithm for your use case

---

## 1. Introduction to Rate Limiting (10 min)

### What is Rate Limiting?

**Rate limiting** is a technique to control the rate of requests a client can make to a service within a specified time window.

> [!quote] Fundamental Principle
> "Rate limiting is the first line of defense against abuse and the last line of defense for availability."

### Why Rate Limit?

**Protection & Control:**
- 🛡️ **DDoS Protection:** Prevent denial-of-service attacks
- 💰 **Cost Control:** Limit expensive API calls
- ⚖️ **Fair Usage:** Ensure equitable resource distribution
- 🔧 **System Stability:** Prevent cascading failures
- 📊 **Predictable Performance:** Maintain SLAs

### Rate Limiting Dimensions

~~~
Rate Limit Dimensions:

1. By User/API Key
   └─ 1000 requests/hour per user

2. By IP Address
   └─ 100 requests/minute per IP

3. By Endpoint
   └─ /api/search: 10 req/sec
   └─ /api/upload: 5 req/min

4. By Service Tier
   └─ Free: 100 req/day
   └─ Pro: 10,000 req/day
   └─ Enterprise: Unlimited
~~~

### Key Metrics

| Metric | Description | Example |
|--------|-------------|---------|
| **Rate** | Requests allowed per time unit | 100 req/sec |
| **Burst** | Maximum requests in short burst | 150 req |
| **Window** | Time period for rate calculation | 1 minute |
| **Quota** | Total requests in longer period | 10,000/day |

---

## 2. Rate Limiting Algorithms (15 min)

### 1. Token Bucket Algorithm

**Concept:** Tokens are added to a bucket at a fixed rate. Each request consumes a token.

~~~
Token Bucket Visualization:

Bucket Capacity: 10 tokens
Refill Rate: 2 tokens/second

Time 0s:  [🪙🪙🪙🪙🪙🪙🪙🪙🪙🪙] 10 tokens
Request:  [🪙🪙🪙🪙🪙🪙🪙🪙🪙⬜] 9 tokens (1 consumed)
Time 1s:  [🪙🪙🪙🪙🪙🪙🪙🪙🪙🪙] 10 tokens (refilled, capped)
Burst 5:  [🪙🪙🪙🪙🪙⬜⬜⬜⬜⬜] 5 tokens (5 consumed)
Time 2s:  [🪙🪙🪙🪙🪙🪙🪙⬜⬜⬜] 7 tokens (+2 refilled)
~~~

**Implementation:**

~~~python
import time
from threading import Lock

class TokenBucket:
    def __init__(self, capacity: int, refill_rate: float):
        self.capacity = capacity
        self.tokens = capacity
        self.refill_rate = refill_rate  # tokens per second
        self.last_refill = time.time()
        self.lock = Lock()
    
    def _refill(self):
        now = time.time()
        elapsed = now - self.last_refill
        tokens_to_add = elapsed * self.refill_rate
        self.tokens = min(self.capacity, self.tokens + tokens_to_add)
        self.last_refill = now
    
    def consume(self, tokens: int = 1) -> bool:
        with self.lock:
            self._refill()
            if self.tokens >= tokens:
                self.tokens -= tokens
                return True
            return False

# Usage
bucket = TokenBucket(capacity=10, refill_rate=2)

for i in range(15):
    if bucket.consume():
        print(f"Request {i+1}: Allowed")
    else:
        print(f"Request {i+1}: Rate limited")
~~~

**Pros:**
- ✅ Allows bursts up to bucket capacity
- ✅ Smooth rate limiting over time
- ✅ Memory efficient (O(1) per client)

**Cons:**
- ❌ Burst can overwhelm downstream services
- ❌ Requires careful capacity tuning

---

### 2. Leaky Bucket Algorithm

**Concept:** Requests enter a queue (bucket) and are processed at a fixed rate. Overflow is rejected.

~~~
Leaky Bucket Visualization:

        Incoming Requests
              │
              ▼
    ┌─────────────────┐
    │  🔵 🔵 🔵 🔵 🔵  │  ← Queue (bucket)
    │  🔵 🔵 🔵       │
    └────────┬────────┘
             │ Fixed outflow rate
             ▼
        Processed at constant rate
~~~

**Implementation:**

~~~python
import time
from collections import deque
from threading import Lock

class LeakyBucket:
    def __init__(self, capacity: int, leak_rate: float):
        self.capacity = capacity
        self.leak_rate = leak_rate  # requests per second
        self.queue = deque()
        self.last_leak = time.time()
        self.lock = Lock()
    
    def _leak(self):
        now = time.time()
        elapsed = now - self.last_leak
        leaks = int(elapsed * self.leak_rate)
        
        for _ in range(min(leaks, len(self.queue))):
            self.queue.popleft()
        
        if leaks > 0:
            self.last_leak = now
    
    def allow(self) -> bool:
        with self.lock:
            self._leak()
            if len(self.queue) < self.capacity:
                self.queue.append(time.time())
                return True
            return False

# Usage
bucket = LeakyBucket(capacity=5, leak_rate=1)
~~~

**Pros:**
- ✅ Constant output rate (no bursts)
- ✅ Predictable downstream load
- ✅ Good for APIs with strict rate requirements

**Cons:**
- ❌ No burst allowance
- ❌ Recent requests may wait behind old ones

---

### 3. Fixed Window Counter

**Concept:** Count requests in fixed time windows. Reset counter at window boundary.

~~~
Fixed Window Counter:

Window: 1 minute, Limit: 100 requests

12:00:00 - 12:00:59  │  12:01:00 - 12:01:59
     Window 1        │       Window 2
                     │
[████████░░] 80 req  │  [██░░░░░░░░] 20 req
                     │
     ↑ Counter resets at boundary
~~~

**Implementation:**

~~~python
import time
from threading import Lock

class FixedWindowCounter:
    def __init__(self, limit: int, window_seconds: int):
        self.limit = limit
        self.window_seconds = window_seconds
        self.counters = {}  # client_id -> (window_start, count)
        self.lock = Lock()
    
    def _get_window_start(self) -> int:
        return int(time.time() // self.window_seconds) * self.window_seconds
    
    def allow(self, client_id: str) -> bool:
        with self.lock:
            window_start = self._get_window_start()
            
            if client_id not in self.counters:
                self.counters[client_id] = (window_start, 0)
            
            stored_window, count = self.counters[client_id]
            
            # New window - reset counter
            if stored_window != window_start:
                self.counters[client_id] = (window_start, 1)
                return True
            
            # Same window - check limit
            if count < self.limit:
                self.counters[client_id] = (window_start, count + 1)
                return True
            
            return False

# Usage
limiter = FixedWindowCounter(limit=100, window_seconds=60)
~~~

**Pros:**
- ✅ Simple to implement
- ✅ Memory efficient
- ✅ Easy to understand

**Cons:**
- ❌ Boundary burst problem (2x limit at window edges)

~~~
Boundary Burst Problem:

12:00:30 - 12:00:59: 100 requests (allowed)
12:01:00 - 12:01:30: 100 requests (allowed)
                     ↓
Result: 200 requests in 1 minute! (2x limit)
~~~

---

### 4. Sliding Window Log

**Concept:** Store timestamp of each request. Count requests within sliding window.

~~~
Sliding Window Log:

Current time: 12:01:30
Window: 1 minute
Limit: 5 requests

Timestamps: [12:00:45, 12:01:00, 12:01:15, 12:01:20, 12:01:25]
            └─────────────────────────────────────────────────┘
                    All within last 60 seconds = 5 requests
                    
New request at 12:01:30 → REJECTED (limit reached)
~~~

**Implementation:**

~~~python
import time
from collections import deque
from threading import Lock

class SlidingWindowLog:
    def __init__(self, limit: int, window_seconds: int):
        self.limit = limit
        self.window_seconds = window_seconds
        self.logs = {}  # client_id -> deque of timestamps
        self.lock = Lock()
    
    def allow(self, client_id: str) -> bool:
        with self.lock:
            now = time.time()
            window_start = now - self.window_seconds
            
            if client_id not in self.logs:
                self.logs[client_id] = deque()
            
            # Remove expired timestamps
            while self.logs[client_id] and self.logs[client_id][0] < window_start:
                self.logs[client_id].popleft()
            
            # Check limit
            if len(self.logs[client_id]) < self.limit:
                self.logs[client_id].append(now)
                return True
            
            return False

# Usage
limiter = SlidingWindowLog(limit=100, window_seconds=60)
~~~

**Pros:**
- ✅ Accurate rate limiting
- ✅ No boundary burst problem
- ✅ Smooth rate enforcement

**Cons:**
- ❌ High memory usage (stores all timestamps)
- ❌ O(n) cleanup operation

---

### 5. Sliding Window Counter

**Concept:** Hybrid of fixed window and sliding window. Weighted average of current and previous window.

~~~
Sliding Window Counter:

Previous Window (12:00-12:01): 84 requests
Current Window (12:01-12:02):  36 requests
Current time: 12:01:15 (25% into current window)

Weighted count = 84 * (1 - 0.25) + 36 * 0.25
               = 84 * 0.75 + 36 * 0.25
               = 63 + 9
               = 72 requests

If limit = 100, new request is ALLOWED
~~~

**Implementation:**

~~~python
import time
from threading import Lock

class SlidingWindowCounter:
    def __init__(self, limit: int, window_seconds: int):
        self.limit = limit
        self.window_seconds = window_seconds
        self.windows = {}  # client_id -> {prev_count, curr_count, curr_window}
        self.lock = Lock()
    
    def _get_window_start(self) -> int:
        return int(time.time() // self.window_seconds) * self.window_seconds
    
    def allow(self, client_id: str) -> bool:
        with self.lock:
            now = time.time()
            window_start = self._get_window_start()
            window_progress = (now - window_start) / self.window_seconds
            
            if client_id not in self.windows:
                self.windows[client_id] = {
                    'prev_count': 0,
                    'curr_count': 0,
                    'curr_window': window_start
                }
            
            w = self.windows[client_id]
            
            # Check if we moved to a new window
            if w['curr_window'] != window_start:
                if w['curr_window'] == window_start - self.window_seconds:
                    w['prev_count'] = w['curr_count']
                else:
                    w['prev_count'] = 0
                w['curr_count'] = 0
                w['curr_window'] = window_start
            
            # Calculate weighted count
            weighted_count = (w['prev_count'] * (1 - window_progress) + 
                            w['curr_count'])
            
            if weighted_count < self.limit:
                w['curr_count'] += 1
                return True
            
            return False

# Usage
limiter = SlidingWindowCounter(limit=100, window_seconds=60)
~~~

**Pros:**
- ✅ Smooths boundary burst problem
- ✅ Memory efficient (O(1) per client)
- ✅ Good balance of accuracy and efficiency

**Cons:**
- ❌ Approximation (not 100% accurate)
- ❌ Slightly more complex than fixed window

---

### Algorithm Comparison

| Algorithm | Memory | Accuracy | Burst Handling | Complexity |
|-----------|--------|----------|----------------|------------|
| Token Bucket | O(1) | High | Allows bursts | Low |
| Leaky Bucket | O(n) | High | No bursts | Medium |
| Fixed Window | O(1) | Low | Boundary burst | Low |
| Sliding Log | O(n) | Highest | Smooth | Medium |
| Sliding Counter | O(1) | High | Smooth | Medium |

