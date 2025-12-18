# Circuit Breaker & Resilience Patterns

## Session Overview

| Attribute | Details |
|-----------|---------|
| Duration | 60 minutes |
| Level | Intermediate to Advanced |
| Prerequisites | Microservices basics, distributed systems concepts |

## Agenda

| Time | Topic |
|------|-------|
| 0-5 min | Introduction & Why Resilience Matters |
| 5-20 min | Circuit Breaker Pattern Deep Dive |
| 20-35 min | Bulkhead, Retry & Timeout Patterns |
| 35-50 min | Fallback Strategies & Graceful Degradation |
| 50-60 min | Practical Exercise & Discussion |

## Learning Objectives

By the end of this session, you will be able to:
- Understand the circuit breaker state machine and transitions
- Implement bulkhead pattern for fault isolation
- Design effective retry strategies with exponential backoff
- Configure appropriate timeouts for different scenarios
- Build fallback mechanisms for graceful degradation

---

## 1. Why Resilience Matters

### The Cascading Failure Problem

```
┌─────────────────────────────────────────────────────────────────┐
│                    Cascading Failure Example                     │
│                                                                  │
│  Normal Operation:                                              │
│  ┌────────┐    ┌────────┐    ┌────────┐    ┌────────┐         │
│  │  API   │───▶│ Order  │───▶│Payment │───▶│  DB    │         │
│  │Gateway │    │Service │    │Service │    │        │         │
│  └────────┘    └────────┘    └────────┘    └────────┘         │
│                                                                  │
│  Database Slowdown → Cascading Failure:                         │
│  ┌────────┐    ┌────────┐    ┌────────┐    ┌────────┐         │
│  │  API   │    │ Order  │    │Payment │    │  DB    │         │
│  │Gateway │    │Service │    │Service │    │ SLOW   │         │
│  │TIMEOUT │◀───│BLOCKED │◀───│WAITING │◀───│        │         │
│  │  ✗     │    │  ✗     │    │  ✗     │    │  ⚠️    │         │
│  └────────┘    └────────┘    └────────┘    └────────┘         │
│                                                                  │
│  Thread pools exhausted → All services fail!                    │
└─────────────────────────────────────────────────────────────────┘
```

### Resilience Patterns Overview

| Pattern | Purpose | When to Use |
|---------|---------|-------------|
| Circuit Breaker | Fail fast, prevent cascade | Downstream service failures |
| Bulkhead | Isolate failures | Resource contention |
| Retry | Handle transient failures | Network glitches, timeouts |
| Timeout | Bound wait time | Slow dependencies |
| Fallback | Graceful degradation | Any failure scenario |

---

## 2. Circuit Breaker Pattern

### State Machine

```
┌─────────────────────────────────────────────────────────────────┐
│                   Circuit Breaker States                         │
│                                                                  │
│                    Success                                       │
│                 ┌──────────┐                                    │
│                 │          │                                    │
│                 ▼          │                                    │
│  ┌──────────────────────────────┐                              │
│  │           CLOSED             │                              │
│  │   (Normal Operation)         │                              │
│  │   - Requests pass through    │                              │
│  │   - Track failure count      │                              │
│  └──────────────────────────────┘                              │
│                 │                                               │
│                 │ Failure threshold exceeded                    │
│                 ▼                                               │
│  ┌──────────────────────────────┐                              │
│  │            OPEN              │                              │
│  │   (Fail Fast)                │                              │
│  │   - Reject all requests      │                              │
│  │   - Return error immediately │                              │
│  └──────────────────────────────┘                              │
│                 │                                               │
│                 │ Timeout expires                               │
│                 ▼                                               │
│  ┌──────────────────────────────┐                              │
│  │         HALF-OPEN            │                              │
│  │   (Testing Recovery)         │◀─────┐                       │
│  │   - Allow limited requests   │      │                       │
│  │   - Test if service healthy  │      │ Failure              │
│  └──────────────────────────────┘      │                       │
│                 │                       │                       │
│                 │ Success              │                       │
│                 └───────────────────────┘                       │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Circuit Breaker Implementation

```java
public class CircuitBreaker {
    private final String name;
    private final int failureThreshold;
    private final long openTimeoutMs;
    private final int halfOpenMaxCalls;
    
    private CircuitState state = CircuitState.CLOSED;
    private int failureCount = 0;
    private int successCount = 0;
    private long lastFailureTime = 0;
    private int halfOpenCallCount = 0;
    
    public CircuitBreaker(String name, int failureThreshold, 
                          long openTimeoutMs, int halfOpenMaxCalls) {
        this.name = name;
        this.failureThreshold = failureThreshold;
        this.openTimeoutMs = openTimeoutMs;
        this.halfOpenMaxCalls = halfOpenMaxCalls;
    }
    
    public <T> T execute(Supplier<T> action, Supplier<T> fallback) {
        if (!allowRequest()) {
            return fallback.get();
        }
        
        try {
            T result = action.get();
            recordSuccess();
            return result;
        } catch (Exception e) {
            recordFailure();
            return fallback.get();
        }
    }
    
    private synchronized boolean allowRequest() {
        switch (state) {
            case CLOSED:
                return true;
                
            case OPEN:
                if (System.currentTimeMillis() - lastFailureTime > openTimeoutMs) {
                    transitionTo(CircuitState.HALF_OPEN);
                    return true;
                }
                return false;
                
            case HALF_OPEN:
                if (halfOpenCallCount < halfOpenMaxCalls) {
                    halfOpenCallCount++;
                    return true;
                }
                return false;
                
            default:
                return false;
        }
    }
    
    private synchronized void recordSuccess() {
        switch (state) {
            case CLOSED:
                failureCount = 0;
                break;
                
            case HALF_OPEN:
                successCount++;
                if (successCount >= halfOpenMaxCalls) {
                    transitionTo(CircuitState.CLOSED);
                }
                break;
        }
    }
    
    private synchronized void recordFailure() {
        lastFailureTime = System.currentTimeMillis();
        
        switch (state) {
            case CLOSED:
                failureCount++;
                if (failureCount >= failureThreshold) {
                    transitionTo(CircuitState.OPEN);
                }
                break;
                
            case HALF_OPEN:
                transitionTo(CircuitState.OPEN);
                break;
        }
    }
    
    private void transitionTo(CircuitState newState) {
        CircuitState oldState = this.state;
        this.state = newState;
        this.failureCount = 0;
        this.successCount = 0;
        this.halfOpenCallCount = 0;
        
        log.info("Circuit breaker '{}' transitioned: {} -> {}", 
                 name, oldState, newState);
    }
}

enum CircuitState {
    CLOSED, OPEN, HALF_OPEN
}
```

### Using Resilience4j

```java
// Configuration
CircuitBreakerConfig config = CircuitBreakerConfig.custom()
    .failureRateThreshold(50)                    // 50% failure rate
    .waitDurationInOpenState(Duration.ofSeconds(30))
    .slidingWindowType(SlidingWindowType.COUNT_BASED)
    .slidingWindowSize(10)                       // Last 10 calls
    .minimumNumberOfCalls(5)                     // Min calls before calculating
    .permittedNumberOfCallsInHalfOpenState(3)
    .automaticTransitionFromOpenToHalfOpenEnabled(true)
    .build();

CircuitBreaker circuitBreaker = CircuitBreaker.of("paymentService", config);

// Usage with decorator
Supplier<Payment> decoratedSupplier = CircuitBreaker
    .decorateSupplier(circuitBreaker, () -> paymentService.process(order));

Try<Payment> result = Try.ofSupplier(decoratedSupplier)
    .recover(CallNotPermittedException.class, e -> fallbackPayment());
```

---

## 3. Bulkhead Pattern

### Thread Pool Isolation

```
┌─────────────────────────────────────────────────────────────────┐
│                    Bulkhead Pattern                              │
│                                                                  │
│  Without Bulkhead (Shared Thread Pool):                         │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              Shared Thread Pool (100 threads)            │   │
│  │  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐      │   │
│  │  │ A   │ │ B   │ │ C   │ │ A   │ │ B   │ │ C   │ ...  │   │
│  │  └─────┘ └─────┘ └─────┘ └─────┘ └─────┘ └─────┘      │   │
│  └─────────────────────────────────────────────────────────┘   │
│  If Service C is slow → All threads blocked → A & B fail!      │
│                                                                  │
│  With Bulkhead (Isolated Thread Pools):                         │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐   │
│  │ Service A Pool  │ │ Service B Pool  │ │ Service C Pool  │   │
│  │   (30 threads)  │ │   (30 threads)  │ │   (40 threads)  │   │
│  │ ┌───┐┌───┐┌───┐│ │ ┌───┐┌───┐┌───┐│ │ ┌───┐┌───┐┌───┐│   │
│  │ │ A ││ A ││ A ││ │ │ B ││ B ││ B ││ │ │ C ││ C ││ C ││   │
│  │ └───┘└───┘└───┘│ │ └───┘└───┘└───┘│ │ └───┘└───┘└───┘│   │
│  └─────────────────┘ └─────────────────┘ └─────────────────┘   │
│  If Service C is slow → Only C's pool affected → A & B OK!     │
└─────────────────────────────────────────────────────────────────┘
```

### Bulkhead Implementation

```java
// Resilience4j Bulkhead Configuration
BulkheadConfig bulkheadConfig = BulkheadConfig.custom()
    .maxConcurrentCalls(25)           // Max concurrent calls
    .maxWaitDuration(Duration.ofMillis(500))  // Wait time for permit
    .build();

Bulkhead bulkhead = Bulkhead.of("paymentService", bulkheadConfig);

// Thread Pool Bulkhead (for async operations)
ThreadPoolBulkheadConfig threadPoolConfig = ThreadPoolBulkheadConfig.custom()
    .maxThreadPoolSize(10)
    .coreThreadPoolSize(5)
    .queueCapacity(100)
    .keepAliveDuration(Duration.ofMillis(100))
    .build();

ThreadPoolBulkhead threadPoolBulkhead = 
    ThreadPoolBulkhead.of("paymentService", threadPoolConfig);

// Usage
Supplier<Payment> decoratedSupplier = Bulkhead
    .decorateSupplier(bulkhead, () -> paymentService.process(order));
```

### Semaphore-Based Bulkhead

```java
public class SemaphoreBulkhead {
    private final Semaphore semaphore;
    private final String name;
    private final long maxWaitMs;
    
    public SemaphoreBulkhead(String name, int maxConcurrent, long maxWaitMs) {
        this.name = name;
        this.semaphore = new Semaphore(maxConcurrent);
        this.maxWaitMs = maxWaitMs;
    }
    
    public <T> T execute(Supplier<T> action) throws BulkheadFullException {
        boolean acquired = false;
        try {
            acquired = semaphore.tryAcquire(maxWaitMs, TimeUnit.MILLISECONDS);
            if (!acquired) {
                throw new BulkheadFullException(
                    "Bulkhead '" + name + "' is full"
                );
            }
            return action.get();
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new BulkheadFullException("Interrupted waiting for bulkhead");
        } finally {
            if (acquired) {
                semaphore.release();
            }
        }
    }
}
```
