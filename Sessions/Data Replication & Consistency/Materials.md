# Data Replication & Consistency - Learning Materials

## Articles & Blogs

- [Designing Data-Intensive Applications - Chapter 5: Replication](https://dataintensive.net/) - Martin Kleppmann's definitive guide on replication
- [Jepsen: Consistency Models](https://jepsen.io/consistency) - Visual guide to consistency models
- [How Amazon DynamoDB Handles Replication](https://www.allthingsdistributed.com/2007/10/amazons_dynamo.html) - Werner Vogels' Dynamo paper summary

## Videos

- [Replication and Consistency Explained](https://www.youtube.com/watch?v=nH4qjmP2ne4) - ByteByteGo visual explanation
- [CRDTs: The Hard Parts](https://www.youtube.com/watch?v=x7drE24geUw) - Martin Kleppmann on conflict-free data types
- [Database Replication Explained](https://www.youtube.com/watch?v=bI8Ry6GhMSE) - Hussein Nasser's deep dive

## Technical Documentation

- [PostgreSQL Streaming Replication](https://www.postgresql.org/docs/current/warm-standby.html) - Official PostgreSQL replication docs
- [MySQL Replication](https://dev.mysql.com/doc/refman/8.0/en/replication.html) - Official MySQL replication guide
- [Amazon Aurora Global Database](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-global-database.html) - Cross-region replication on AWS

## Key Concepts to Explore

- Single-leader, multi-leader, and leaderless replication
- Synchronous vs asynchronous replication trade-offs
- Consistency models (linearizable, causal, eventual)
- Conflict resolution strategies (LWW, merge, CRDTs)
- Failover mechanisms and split-brain prevention
