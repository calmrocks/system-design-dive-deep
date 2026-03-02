# Distributed Locking - Learning Materials

## Articles & Blogs

- [How to do distributed locking](https://martin.kleppmann.com/2016/02/08/how-to-do-distributed-locking.html) - Martin Kleppmann's analysis of Redlock and fencing tokens
- [Is Redlock safe?](http://antirez.com/news/101) - Antirez's response to Kleppmann's critique
- [Distributed Locks with Redis](https://redis.io/docs/manual/patterns/distributed-locks/) - Official Redis distributed lock documentation

## Videos

- [Distributed Locks Explained](https://www.youtube.com/watch?v=v7x75aN9liM) - ByteByteGo visual walkthrough
- [Martin Kleppmann - How to do distributed locking](https://www.youtube.com/watch?v=fFUZiczUMkA) - Talk on correctness of distributed locks
- [Redisson Distributed Locks](https://www.youtube.com/watch?v=AnikT1bg4oo) - Practical Redis lock implementation with watchdog

## Technical Documentation

- [Apache ZooKeeper Recipes: Locks](https://zookeeper.apache.org/doc/current/recipes.html#sc_recipes_Locks) - Official ZooKeeper lock recipe
- [etcd Concurrency API](https://etcd.io/docs/v3.5/dev-guide/api_concurrency_ref_v3/) - etcd distributed lock primitives
- [Redisson Lock Documentation](https://github.com/redisson/redisson/wiki/8.-Distributed-locks-and-synchronizers) - Production-grade Redis lock library

## Key Concepts to Explore

- Redis SET NX vs ZooKeeper ephemeral sequential nodes
- Fencing tokens for correctness guarantees
- Redlock algorithm and its trade-offs
- Lock renewal / watchdog pattern
- Optimistic concurrency as an alternative to locking
