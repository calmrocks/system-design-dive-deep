# System Design Dive Deep

A comprehensive system design learning repository with structured sessions, case studies, and hands-on materials.

## Using Obsidian with This Repository

This repository is designed to work seamlessly with [Obsidian](https://obsidian.md/), a powerful knowledge management tool.

### Setup

1. **Install Obsidian**: Download from [obsidian.md](https://obsidian.md/)

2. **Open as Vault**: 
   - Launch Obsidian
   - Click "Open folder as vault"
   - Navigate to: `system-design-dive-deep/SystemDesign/SystemDesign/`
   - This is your Obsidian vault root

3. **Recommended Plugins** (Optional):
   - **Mermaid** (built-in): Already supported for diagrams
   - **Dataview**: For dynamic content queries
   - **Excalidraw**: For hand-drawn diagrams
   - **Git**: For version control within Obsidian

### Repository Structure

```
SystemDesign/SystemDesign/
├── Sessions/              # Topic-based learning sessions
│   ├── Cache/
│   │   ├── Cache.md              # Main concepts and diagrams
│   │   ├── Materials.md          # Curated learning resources
│   │   ├── Discussion Topics.md  # Discussion questions
│   │   └── demos/                # Code examples and POCs
│   └── [Other Topics]/
│       └── ...
```

## 📚 Session Topics

| Topic                                                                                                                                                                                  | Duration | Level                 | Key Concepts                                                                                 | Discussion                                                                                                                                                               | Materials                                                                                                                                              |
| -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | --------------------- | -------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| [Cache](https://github.com/calmrocks/system-design-dive-deep/blob/main/SystemDesign/SystemDesign/Sessions/Cache/Cache.md)                                                              | 60 min   | Intermediate          | Cache layers, eviction policies (LRU/LFU), write strategies, cache invalidation              | [Discussion Topics](https://github.com/calmrocks/system-design-dive-deep/blob/main/SystemDesign/SystemDesign/Sessions/Cache/Discussion%20Topics.md)                      | [Materials](https://github.com/calmrocks/system-design-dive-deep/blob/main/SystemDesign/SystemDesign/Sessions/Cache/Materials.md)                      |
| [Load Balancer](https://github.com/calmrocks/system-design-dive-deep/blob/main/SystemDesign/SystemDesign/Sessions/Load%20Balancer/Load%20Balancer.md)                                  | 60 min   | Intermediate          | L4 vs L7 load balancing, algorithms (round-robin, least connections, IP hash), health checks | [Discussion Topics](https://github.com/calmrocks/system-design-dive-deep/blob/main/SystemDesign/SystemDesign/Sessions/Load%20Balancer/Discussion%20Topics.md)            | [Materials](https://github.com/calmrocks/system-design-dive-deep/blob/main/SystemDesign/SystemDesign/Sessions/Load%20Balancer/Materials.md)            |
| [Circuit Breaker](https://github.com/calmrocks/system-design-dive-deep/blob/main/SystemDesign/SystemDesign/Sessions/Circuit%20Breaker/Circuit%20Breaker.md)                            | 60 min   | Intermediate-Advanced | State machine (closed/open/half-open), bulkhead pattern, retry with backoff, timeouts        | [Discussion Topics](https://github.com/calmrocks/system-design-dive-deep/blob/main/SystemDesign/SystemDesign/Sessions/Circuit%20Breaker/Discussion%20Topics.md)          | [Materials](https://github.com/calmrocks/system-design-dive-deep/blob/main/SystemDesign/SystemDesign/Sessions/Circuit%20Breaker/Materials.md)          |
| [Consistent Hashing](https://github.com/calmrocks/system-design-dive-deep/blob/main/SystemDesign/SystemDesign/Sessions/Consistent%20Hashing/Consistent%20Hashing.md)                   | 60 min   | Intermediate          | Hash ring, virtual nodes, key redistribution, replication                                    | [Discussion Topics](https://github.com/calmrocks/system-design-dive-deep/blob/main/SystemDesign/SystemDesign/Sessions/Consistent%20Hashing/Discussion%20Topics.md)       | [Materials](https://github.com/calmrocks/system-design-dive-deep/blob/main/SystemDesign/SystemDesign/Sessions/Consistent%20Hashing/Materials.md)       |
| [Distributed Transactions](https://github.com/calmrocks/system-design-dive-deep/blob/main/SystemDesign/SystemDesign/Sessions/Distributed%20Transactions/Distributed%20Transactions.md) | 60 min   | Intermediate-Advanced | 2PC/3PC, Saga pattern, compensation, outbox pattern, eventual consistency                    | [Discussion Topics](https://github.com/calmrocks/system-design-dive-deep/blob/main/SystemDesign/SystemDesign/Sessions/Distributed%20Transactions/Discussion%20Topics.md) | [Materials](https://github.com/calmrocks/system-design-dive-deep/blob/main/SystemDesign/SystemDesign/Sessions/Distributed%20Transactions/Materials.md) |
| [Message Queue](https://github.com/calmrocks/system-design-dive-deep/blob/main/SystemDesign/SystemDesign/Sessions/Message%20Queue/Message%20Queue.md)                                  | 60 min   | Intermediate          | Kafka vs RabbitMQ vs SQS, pub/sub patterns, event-driven architecture                        | [Discussion Topics](https://github.com/calmrocks/system-design-dive-deep/blob/main/SystemDesign/SystemDesign/Sessions/Message%20Queue/Discussion%20Topics.md)            | [Materials](https://github.com/calmrocks/system-design-dive-deep/blob/main/SystemDesign/SystemDesign/Sessions/Message%20Queue/Materials.md)            |
| [Rate Limiter](https://github.com/calmrocks/system-design-dive-deep/blob/main/SystemDesign/SystemDesign/Sessions/Rate%20Limiter/Rate%20Limiter.md)                                     | 60 min   | Intermediate          | Token bucket, leaky bucket, sliding window, distributed rate limiting                        | [Discussion Topics](https://github.com/calmrocks/system-design-dive-deep/blob/main/SystemDesign/SystemDesign/Sessions/Rate%20Limiter/Discussion%20Topics.md)             | [Materials](https://github.com/calmrocks/system-design-dive-deep/blob/main/SystemDesign/SystemDesign/Sessions/Rate%20Limiter/Materials.md)             |
| [Service Discovery](https://github.com/calmrocks/system-design-dive-deep/blob/main/SystemDesign/SystemDesign/Sessions/Service%20Discovery/Service%20Discovery.md)                      | 60 min   | Intermediate          | Client-side vs server-side discovery, service registry, health checking, DNS-based discovery | [Discussion Topics](https://github.com/calmrocks/system-design-dive-deep/blob/main/SystemDesign/SystemDesign/Sessions/Service%20Discovery/Discussion%20Topics.md)        | [Materials](https://github.com/calmrocks/system-design-dive-deep/blob/main/SystemDesign/SystemDesign/Sessions/Service%20Discovery/Materials.md)        |

### Navigation Tips

- **Wiki Links**: Use `[[Topic Name]]` to link between notes
- **Backlinks**: See which notes reference the current note in the right sidebar
- **Graph View**: Visualize connections between topics (Ctrl/Cmd + G)
- **Quick Switcher**: Jump to any note quickly (Ctrl/Cmd + O)

### Working with Sessions

Each session topic follows a consistent structure:

1. **Main Document**: Core concepts with Mermaid diagrams
2. **Materials**: Curated articles, videos, and documentation (best of the best only)
3. **Discussion Topics**: Thought-provoking questions for deeper understanding
4. **Demos Folder**: Practical code examples and configurations

### Mermaid Diagrams

All diagrams use Mermaid syntax and render automatically in Obsidian:

```mermaid
graph LR
    Client --> LoadBalancer
    LoadBalancer --> Server1
    LoadBalancer --> Server2
```

### Best Practices

- **Link Liberally**: Create connections between related topics using `[[links]]`
- **Use Tags**: Add `#systemdesign`, `#architecture`, etc. for organization
- **Daily Notes**: Keep learning logs and insights in daily notes
- **Templates**: Create templates for new session topics (see existing structure)

### Contributing

When adding new topics:

1. Follow the existing folder structure
2. Use Obsidian markdown with Mermaid for diagrams
3. Curate only the best learning materials
4. Include practical discussion topics
5. Add code examples in the `demos/` folder

### Resources

- [Obsidian Documentation](https://help.obsidian.md/)
- [Mermaid Syntax](https://mermaid.js.org/intro/)
- [Markdown Guide](https://www.markdownguide.org/)

---

**Note**: This is a public-facing repository. For internal training materials, see the `system-design-internal` repository.
