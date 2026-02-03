# Circuit Breaker & Resilience - Learning Materials

## Articles & Blogs

- [Circuit Breaker Pattern](https://martinfowler.com/bliki/CircuitBreaker.html) - Martin Fowler's original explanation of the pattern
- [Release It! Design Patterns](https://pragprog.com/titles/mnee2/release-it-second-edition/) - Michael Nygard's stability patterns (Chapter 5)
- [Netflix Hystrix: How It Works](https://github.com/Netflix/Hystrix/wiki/How-it-Works) - Deep dive into Netflix's circuit breaker implementation
- [Resilience4j User Guide](https://resilience4j.readme.io/docs) - Comprehensive guide to modern Java resilience library
- [Exponential Backoff and Jitter](https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/) - AWS Architecture Blog on retry strategies

## Videos

- [Resilience Engineering with Resilience4j](https://www.youtube.com/watch?v=kR2sm1zelI4) - Spring I/O conference talk
- [Circuit Breaker Pattern Explained](https://www.youtube.com/watch?v=ADHcBxEXvFA) - ByteByteGo visual explanation
- [Building Resilient Microservices](https://www.youtube.com/watch?v=RpfQ8AHwEvg) - QCon talk on resilience patterns
- [Chaos Engineering at Netflix](https://www.youtube.com/watch?v=CZ3wIuvmHeM) - How Netflix tests resilience

## Technical Documentation

- [Resilience4j GitHub](https://github.com/resilience4j/resilience4j) - Source code and examples
- [Spring Cloud Circuit Breaker](https://spring.io/projects/spring-cloud-circuitbreaker) - Spring's abstraction over circuit breaker implementations
- [Polly .NET Resilience Library](https://github.com/App-vNext/Polly) - .NET equivalent with excellent documentation
- [Istio Circuit Breaking](https://istio.io/latest/docs/tasks/traffic-management/circuit-breaking/) - Service mesh approach to resilience

## Key Concepts to Explore

- Circuit breaker state machine (Closed → Open → Half-Open)
- Bulkhead pattern and thread pool isolation
- Exponential backoff with decorrelated jitter
- Timeout configuration strategies
- Fallback and graceful degradation patterns
- Chaos engineering and failure injection testing
