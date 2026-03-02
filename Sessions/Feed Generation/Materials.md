# Feed Generation - Learning Materials

## Articles & Blogs

- [Designing a News Feed System](https://bytebytego.com/courses/system-design-interview/design-a-news-feed-system) - ByteByteGo's comprehensive walkthrough
- [How Twitter's Timeline Works](https://blog.twitter.com/engineering/en_us/topics/infrastructure/2017/the-infrastructure-behind-twitter-scale) - Twitter's fan-out architecture
- [Instagram Feed Ranking](https://about.instagram.com/blog/announcements/shedding-more-light-on-how-instagram-works) - How Instagram ranks feed content

## Videos

- [Design a News Feed - System Design Interview](https://www.youtube.com/watch?v=hykjbT5Z0oE) - ByteByteGo visual walkthrough
- [Twitter System Design](https://www.youtube.com/watch?v=wYk0xPP_P_8) - Fan-out on write vs read explained
- [Facebook News Feed Architecture](https://www.youtube.com/watch?v=Xpx5RYNTQvg) - Real-world feed system at scale

## Technical Documentation

- [Redis Sorted Sets](https://redis.io/docs/data-types/sorted-sets/) - Data structure commonly used for feed caches
- [Apache Kafka for Event Streaming](https://kafka.apache.org/documentation/) - Event backbone for fan-out pipelines
- [Cursor-Based Pagination](https://relay.dev/graphql/connections.htm) - Relay connection specification for pagination

## Key Concepts to Explore

- Fan-out on write vs fan-out on read vs hybrid approach
- Celebrity/hotspot problem and threshold-based strategies
- Feed ranking signals and two-phase ranking
- Cursor-based pagination for infinite scroll
- Real-time feed updates via WebSocket
