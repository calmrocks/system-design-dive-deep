# RedNote Scale Estimates and Capacity Planning

## Overview

This document provides detailed scale estimates for the RedNote platform, including user metrics, traffic patterns, storage requirements, and capacity planning calculations. These estimates inform infrastructure decisions and help identify potential bottlenecks.

## 1. User and Traffic Estimates

### 1.1 User Base
- **Total Registered Users:** 200 million
- **Monthly Active Users (MAU):** 100 million (50% of registered)
- **Daily Active Users (DAU):** 50 million (50% of MAU)
- **Peak Concurrent Users:** 10 million (20% of DAU)
- **Average Session Duration:** 30 minutes
- **Sessions per DAU:** 3 sessions per day

### 1.2 User Growth Projections
| Year | Registered Users | MAU | DAU |
|------|-----------------|-----|-----|
| Current | 200M | 100M | 50M |
| Year 1 | 300M | 150M | 75M |
| Year 2 | 400M | 200M | 100M |
| Year 3 | 500M | 250M | 125M |

### 1.3 Geographic Distribution
- **China:** 80% (40M DAU)
- **Southeast Asia:** 12% (6M DAU)
- **Other Regions:** 8% (4M DAU)

## 2. Content Generation Estimates

### 2.1 Post Creation
- **Posts per Day:** 10 million
- **Posts per DAU:** 0.2 (20% of users post daily)
- **Active Content Creators:** 10 million users (20% of MAU)
- **Average Posts per Creator:** 1 post per day

### 2.2 Post Characteristics
- **Text-Only Posts:** 10%
- **Posts with Images:** 70% (average 4 images per post)
- **Posts with Videos:** 20% (average 1 video per post)
- **Average Post Size:**
  - Text: 500 bytes
  - Images: 2MB per image (after compression)
  - Videos: 50MB per video (before transcoding)

### 2.3 Content Interactions
- **Likes per Day:** 500 million (10 likes per DAU)
- **Comments per Day:** 100 million (2 comments per DAU)
- **Shares per Day:** 50 million (1 share per DAU)
- **Saves/Bookmarks per Day:** 25 million (0.5 per DAU)

## 3. Read Traffic Estimates

### 3.1 Feed Requests
- **Feed Refreshes per User per Session:** 10
- **Total Feed Requests per Day:** 1.5 billion (30 per DAU)
- **Posts per Feed Page:** 20
- **Average Feed Pages Viewed per Session:** 5

### 3.2 Search Queries
- **Search Queries per Day:** 100 million (2 per DAU)
- **Search Results per Query:** 50
- **Search Click-Through Rate:** 30%

### 3.3 Profile Views
- **Profile Views per Day:** 200 million (4 per DAU)
- **Own Profile Views:** 50 million
- **Other User Profile Views:** 150 million

## 4. Requests Per Second (RPS) Calculations

### 4.1 Peak vs. Average Traffic
- **Peak to Average Ratio:** 3x
- **Peak Hours:** 8 PM - 11 PM local time
- **Average RPS:** Based on daily totals / 86,400 seconds
- **Peak RPS:** Average RPS × 3

### 4.2 Read Operations RPS

| Operation | Daily Requests | Avg RPS | Peak RPS |
|-----------|---------------|---------|----------|
| Feed Generation | 1.5B | 17,361 | 52,083 |
| Post Detail View | 500M | 5,787 | 17,361 |
| Profile View | 200M | 2,315 | 6,945 |
| Search Query | 100M | 1,157 | 3,472 |
| Media Fetch (CDN) | 5B | 57,870 | 173,611 |
| **Total Reads** | **7.3B** | **84,490** | **253,472** |

### 4.3 Write Operations RPS

| Operation | Daily Requests | Avg RPS | Peak RPS |
|-----------|---------------|---------|----------|
| Post Creation | 10M | 116 | 347 |
| Like/Unlike | 500M | 5,787 | 17,361 |
| Comment | 100M | 1,157 | 3,472 |
| Follow/Unfollow | 10M | 116 | 347 |
| Share | 50M | 579 | 1,736 |
| **Total Writes** | **670M** | **7,755** | **23,263** |

### 4.4 Database Operations

**Read-Heavy Workload:**
- Read:Write Ratio = 10:1 (approximately)
- Total Database RPS (Peak): ~276,735
- Requires read replicas and caching strategy

## 5. Storage Estimates

### 5.1 User Data Storage
- **User Profiles:** 200M users × 10KB = 2TB
- **Social Graph (Followers):** 200M users × 500 followers × 16 bytes = 1.6TB
- **User Preferences:** 200M users × 5KB = 1TB
- **Total User Data:** ~5TB

### 5.2 Content Metadata Storage
- **Posts Metadata:** 10M posts/day × 365 days × 2KB = 7.3TB/year
- **Comments:** 100M comments/day × 365 days × 500 bytes = 18.25TB/year
- **Likes/Interactions:** 500M likes/day × 365 days × 32 bytes = 5.84TB/year
- **Total Metadata:** ~31TB/year

### 5.3 Media Storage
- **Images:**
  - 7M posts with images/day × 4 images × 2MB = 56TB/day
  - Annual: 56TB × 365 = 20.44PB/year
- **Videos:**
  - 2M posts with videos/day × 1 video × 50MB (original) = 100TB/day
  - Transcoded versions (3 resolutions): 100TB × 3 = 300TB/day
  - Annual: 300TB × 365 = 109.5PB/year
- **Total Media Storage:** ~130PB/year

### 5.4 Total Storage Requirements

| Data Type | Current | 1 Year | 3 Years |
|-----------|---------|--------|---------|
| User Data | 5TB | 10TB | 20TB |
| Metadata | 31TB | 62TB | 124TB |
| Media | 130PB | 260PB | 520PB |
| **Total** | **130PB** | **260PB** | **520PB** |

**Storage Growth:** ~130PB per year

## 6. Bandwidth Estimates

### 6.1 Upload Bandwidth
- **Post Creation:** 10M posts/day
  - Images: 7M × 4 × 2MB = 56TB/day
  - Videos: 2M × 50MB = 100TB/day
- **Total Upload:** 156TB/day = 1.8GB/second average, 5.4GB/s peak

### 6.2 Download Bandwidth (CDN)
- **Feed Image Loading:** 1.5B feed requests × 20 posts × 1 image × 200KB = 6PB/day
- **Video Streaming:** 500M video views/day × 50MB = 25PB/day
- **Total Download:** 31PB/day = 359GB/second average, 1.08TB/s peak

### 6.3 CDN Requirements
- **Cache Hit Ratio Target:** 95%
- **Origin Traffic:** 5% of 31PB = 1.55PB/day
- **CDN Edge Traffic:** 29.45PB/day

## 7. Database Capacity Planning

### 7.1 Primary Database (User & Metadata)
- **Total Data Size:** 36TB (current)
- **Working Set (Hot Data):** 20% = 7.2TB
- **Memory Required:** 10TB (with overhead)
- **IOPS Required:** 100,000 IOPS (peak)

### 7.2 Sharding Strategy
- **Shard by User ID:** 100 shards
- **Data per Shard:** 360GB
- **RPS per Shard:** ~2,767 peak RPS
- **Allows for horizontal scaling**

### 7.3 Read Replicas
- **Read:Write Ratio:** 10:1
- **Replicas per Shard:** 3-5 read replicas
- **Total Database Instances:** 100 shards × 4 (1 primary + 3 replicas) = 400 instances

## 8. Cache Layer Estimates

### 8.1 Cache Requirements
- **Feed Cache:** 10M concurrent users × 20 posts × 2KB = 400GB
- **User Profile Cache:** 10M concurrent users × 10KB = 100GB
- **Hot Content Cache:** 1M popular posts × 50KB = 50GB
- **Session Cache:** 10M sessions × 5KB = 50GB
- **Total Cache:** ~600GB

### 8.2 Cache Hit Ratio Targets
- **Feed Cache:** 80% hit ratio
- **User Profile Cache:** 90% hit ratio
- **Content Cache:** 95% hit ratio
- **Overall Cache Hit Ratio:** 85%

### 8.3 Cache Reduction Impact
- **Database Load Reduction:** 85% of reads served from cache
- **Effective Database RPS:** 253,472 × 0.15 = 38,021 RPS
- **Significant cost and performance improvement**

## 9. Compute Resource Estimates

### 9.1 Application Servers
- **RPS per Server:** 1,000 RPS (with caching)
- **Servers Required (Peak):** 277,000 / 1,000 = 277 servers
- **With Headroom (30%):** 360 servers
- **Instance Type:** 8 vCPU, 16GB RAM

### 9.2 Background Workers
- **Media Processing:** 50 workers (video transcoding)
- **Recommendation Engine:** 20 workers
- **Notification Service:** 30 workers
- **Analytics Pipeline:** 10 workers
- **Total Workers:** 110 instances

### 9.3 Total Compute
- **Application Servers:** 360 instances
- **Background Workers:** 110 instances
- **Database Instances:** 400 instances
- **Cache Instances:** 50 instances (Redis cluster)
- **Total Instances:** ~920 instances

## 10. Cost Estimates

### 10.1 Infrastructure Costs (Monthly)
- **Compute (EC2/VMs):** 920 instances × $200 = $184,000
- **Database (RDS/Managed):** 400 instances × $300 = $120,000
- **Cache (Redis/Memcached):** 50 instances × $150 = $7,500
- **Storage (S3/Object Storage):** 130PB × $0.02/GB = $2,660,000
- **CDN (CloudFront/CDN):** 31PB transfer × $0.02/GB = $620,000
- **Network Transfer:** $50,000
- **Total Monthly Cost:** ~$3,641,500

### 10.2 Cost per User
- **Cost per DAU:** $3,641,500 / 50M = $0.073 per DAU
- **Cost per MAU:** $3,641,500 / 100M = $0.036 per MAU
- **Within target of < $0.10 per DAU**

### 10.3 Cost Optimization Opportunities
- **Aggressive Caching:** Reduce database costs by 50%
- **Media Compression:** Reduce storage costs by 30%
- **CDN Optimization:** Reduce bandwidth costs by 20%
- **Spot Instances:** Reduce compute costs by 40% for batch jobs
- **Potential Savings:** ~$1M per month

## 11. Bottleneck Analysis

### 11.1 Potential Bottlenecks
1. **Media Storage Growth:** 130PB/year is expensive and challenging to manage
2. **Database Write Throughput:** 23,263 peak write RPS requires careful sharding
3. **CDN Bandwidth:** 1.08TB/s peak requires global CDN presence
4. **Real-time Feed Generation:** 52,083 peak RPS requires sophisticated caching

### 11.2 Mitigation Strategies
1. **Media Storage:**
   - Aggressive compression and deduplication
   - Tiered storage (hot/warm/cold)
   - Archive old content to cheaper storage
2. **Database Writes:**
   - Implement write-through caching
   - Batch non-critical writes
   - Use message queues for async processing
3. **CDN Bandwidth:**
   - Multi-CDN strategy
   - Adaptive bitrate streaming for videos
   - Image optimization and lazy loading
4. **Feed Generation:**
   - Pre-compute feeds for active users
   - Cache feed results aggressively
   - Use eventual consistency

## 12. Scalability Headroom

### 12.1 Current Capacity
- **Designed for:** 50M DAU
- **Can Handle:** 75M DAU (50% headroom)
- **Breaking Point:** 100M DAU (requires infrastructure expansion)

### 12.2 Scaling Triggers
- **CPU Utilization:** > 70% sustained
- **Database IOPS:** > 80% of provisioned
- **Cache Hit Ratio:** < 80%
- **API Latency:** P95 > 300ms

### 12.3 Scaling Actions
- **Horizontal Scaling:** Add more application servers (auto-scaling)
- **Database Scaling:** Add more read replicas or shards
- **Cache Scaling:** Increase cache cluster size
- **CDN Scaling:** Expand CDN coverage and capacity

## Summary

RedNote's scale requires a distributed, highly available architecture with:
- **50M DAU** generating **10M posts/day**
- **~277K peak RPS** (mostly reads)
- **130PB/year storage growth** (primarily media)
- **31PB/day CDN bandwidth**
- **~920 compute instances**
- **~$3.6M/month infrastructure cost** ($0.073 per DAU)

The platform must prioritize caching, CDN optimization, and efficient media storage to maintain performance and cost-effectiveness at scale.
