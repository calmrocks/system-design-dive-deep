# File Storage & Upload: Architecture Guide

## Overview

| Attribute | Details |
|-----------|---------|
| Duration | 60 minutes |
| Level | Intermediate to Advanced |
| Prerequisites | Cache session, Message Queue session |

## Learning Objectives

- Design file upload and storage systems that handle large files reliably
- Understand chunked uploads, resumable uploads, and multipart strategies
- Reason about storage tiers, CDN distribution, and cost optimization
- Build processing pipelines for images, videos, and documents
- Evaluate trade-offs between storage backends and delivery methods

---

## 1. Why File Storage Is Its Own Problem

### Beyond Simple Upload

~~~
Naive approach:
  POST /upload → receive entire file → save to disk → return URL
  
  Problems at scale:
  ❌ 2GB video upload fails at 95% → user starts over
  ❌ Single server disk fills up
  ❌ Files served from app server → blocks request threads
  ❌ No processing (thumbnails, transcoding, virus scan)
  ❌ No geographic distribution → slow for distant users
  ❌ Storage costs grow linearly forever
~~~

---

## 2. Upload Architecture

### Pre-Signed URL Pattern

~~~mermaid
sequenceDiagram
    participant C as Client
    participant API as API Server
    participant S3 as Object Storage
    
    C->>API: POST /uploads/initiate {filename, size, type}
    API->>API: Validate (size limit, file type, auth)
    API->>S3: Generate pre-signed upload URL
    S3-->>API: Pre-signed URL (expires in 15 min)
    API-->>C: {uploadUrl, uploadId}
    
    C->>S3: PUT file directly to pre-signed URL
    S3-->>C: 200 OK
    
    C->>API: POST /uploads/{uploadId}/complete
    API->>API: Verify upload, trigger processing
    API-->>C: {fileUrl, status: "processing"}
~~~

~~~
Why pre-signed URLs?
  ✅ File goes directly to storage (bypasses API server)
  ✅ API server handles only metadata (lightweight)
  ✅ No proxy bottleneck for large files
  ✅ Storage provider handles bandwidth and reliability
  ✅ Temporary URL = secure (expires, scoped permissions)
~~~

### Chunked / Resumable Upload

~~~mermaid
sequenceDiagram
    participant C as Client
    participant API as API Server
    participant S3 as Object Storage
    
    C->>API: POST /uploads/initiate {filename, size: 2GB}
    API-->>C: {uploadId, chunkSize: 10MB, totalChunks: 200}
    
    loop For each chunk
        C->>S3: PUT chunk N (10MB)
        S3-->>C: OK {etag}
        C->>C: Track progress (N/200)
    end
    
    Note over C: Network drops at chunk 150...
    Note over C: Resume later...
    
    C->>API: GET /uploads/{uploadId}/status
    API-->>C: {completedChunks: [1-150], remaining: [151-200]}
    
    loop Resume from chunk 151
        C->>S3: PUT chunk N
        S3-->>C: OK
    end
    
    C->>API: POST /uploads/{uploadId}/complete
    API->>S3: Complete multipart upload
    S3->>S3: Assemble chunks into final file
    S3-->>API: OK
    API-->>C: {fileUrl}
~~~

~~~
Chunked upload benefits:
  ✅ Resumable (don't restart on failure)
  ✅ Parallel chunk uploads (faster)
  ✅ Progress tracking per chunk
  ✅ Memory efficient (don't buffer entire file)
  
Chunk size trade-offs:
  Small chunks (1MB):  more requests, better resume granularity
  Large chunks (100MB): fewer requests, less overhead
  Sweet spot: 5-10MB for most use cases
~~~

---

## 3. Storage Architecture

### Storage Tiers

~~~mermaid
flowchart LR
    UPLOAD[New Upload] --> HOT[Hot Storage<br/>SSD / S3 Standard<br/>Frequently accessed]
    
    HOT -->|30 days| WARM[Warm Storage<br/>S3 IA<br/>Occasional access]
    
    WARM -->|90 days| COLD[Cold Storage<br/>S3 Glacier<br/>Rare access]
    
    COLD -->|365 days| ARCHIVE[Archive<br/>Glacier Deep Archive<br/>Compliance only]
~~~

~~~
Cost optimization:
  Hot:     $0.023/GB/month  (profile pics, recent uploads)
  Warm:    $0.0125/GB/month (older content, still accessible)
  Cold:    $0.004/GB/month  (backups, rarely accessed)
  Archive: $0.00099/GB/month (legal compliance, never accessed)

Lifecycle rules:
  - Move to warm after 30 days of no access
  - Move to cold after 90 days
  - Delete or archive after 1 year
  - Exception: profile pictures stay hot forever
~~~

### Metadata Storage

~~~
File metadata (database):
┌─────────────────────────────────────────────────────┐
│ file_id:        "file-uuid-123"                     │
│ owner_id:       "user-456"                          │
│ original_name:  "vacation-photo.jpg"                │
│ storage_key:    "uploads/2025/03/file-uuid-123.jpg" │
│ content_type:   "image/jpeg"                        │
│ size_bytes:     4_500_000                           │
│ checksum:       "sha256:abc123..."                  │
│ status:         "ready" | "processing" | "failed"   │
│ variants:       {                                   │
│   "thumbnail": "thumbs/file-uuid-123_200x200.jpg", │
│   "medium":    "thumbs/file-uuid-123_800x600.jpg"  │
│ }                                                   │
│ created_at:     "2025-03-01T10:00:00Z"              │
│ accessed_at:    "2025-03-01T12:00:00Z"              │
│ storage_tier:   "hot"                               │
└─────────────────────────────────────────────────────┘

Separation of concerns:
  Object storage: file bytes (cheap, scalable, durable)
  Database: metadata (queryable, relational, small)
~~~

---

## 4. File Processing Pipeline

### Image Processing

~~~mermaid
flowchart TB
    UPLOAD[Upload Complete] --> QUEUE[Processing Queue]
    QUEUE --> SCAN[Virus Scan]
    SCAN -->|Clean| VALIDATE[Validate Image]
    SCAN -->|Infected| QUARANTINE[Quarantine & Alert]
    VALIDATE --> STRIP[Strip EXIF<br/>metadata/GPS]
    STRIP --> VARIANTS[Generate Variants]
    
    VARIANTS --> THUMB[Thumbnail<br/>200x200]
    VARIANTS --> MED[Medium<br/>800x600]
    VARIANTS --> LARGE[Large<br/>1920x1080]
    VARIANTS --> WEBP[WebP conversion]
    
    THUMB & MED & LARGE & WEBP --> STORE[Store to Object Storage]
    STORE --> CDN[Push to CDN]
    STORE --> UPDATE[Update metadata<br/>status: ready]
~~~

### Video Processing

~~~
Video pipeline (more complex):
  1. Upload original to storage
  2. Virus scan
  3. Extract metadata (duration, resolution, codec)
  4. Transcode to multiple resolutions:
     - 1080p (H.264, 5 Mbps)
     - 720p  (H.264, 2.5 Mbps)
     - 480p  (H.264, 1 Mbps)
     - 360p  (H.264, 0.5 Mbps)
  5. Generate HLS/DASH segments for adaptive streaming
  6. Extract thumbnail at multiple timestamps
  7. Generate preview GIF (optional)
  8. Update metadata with all variant URLs

Processing time:
  1 minute video ≈ 2-5 minutes processing
  1 hour video ≈ 2-6 hours processing
  → Must be async, with progress tracking
~~~

---

## 5. Content Delivery

### CDN Architecture

~~~mermaid
flowchart TB
    USER_US[User US] --> EDGE_US[CDN Edge US]
    USER_EU[User EU] --> EDGE_EU[CDN Edge EU]
    USER_ASIA[User Asia] --> EDGE_ASIA[CDN Edge Asia]
    
    EDGE_US -->|Cache Miss| ORIGIN[Origin Storage]
    EDGE_EU -->|Cache Miss| ORIGIN
    EDGE_ASIA -->|Cache Miss| ORIGIN
    
    EDGE_US -->|Cache Hit| USER_US
    EDGE_EU -->|Cache Hit| USER_EU
    EDGE_ASIA -->|Cache Hit| USER_ASIA
~~~

~~~
CDN strategy:
  Static content (images, videos):
    - Long cache TTL (1 year)
    - Cache-bust via URL versioning (file-uuid-v2.jpg)
    - Serve from nearest edge location
  
  User-generated content:
    - Medium cache TTL (1 hour to 1 day)
    - Invalidate on update/delete
    - Consider signed URLs for private content

  Adaptive content (video streaming):
    - Cache HLS/DASH segments at edge
    - Different quality segments cached independently
    - Manifest files: short TTL (for live content)
~~~

### Signed URLs for Private Content

~~~mermaid
sequenceDiagram
    participant C as Client
    participant API as API Server
    participant CDN as CDN Edge
    participant S3 as Origin Storage
    
    C->>API: GET /files/{fileId}/url
    API->>API: Check authorization
    API->>API: Generate signed CDN URL (expires 1h)
    API-->>C: {url: "https://cdn.example.com/file?sig=...&exp=..."}
    
    C->>CDN: GET file with signature
    CDN->>CDN: Validate signature & expiry
    CDN-->CDN: Cache hit? Serve from cache
    CDN->>S3: Cache miss? Fetch from origin
    S3-->>CDN: File bytes
    CDN-->>C: File bytes
~~~

---

## 6. Deduplication

### Content-Addressable Storage

~~~
Problem: 1000 users upload the same meme → 1000 copies stored

Solution: Hash-based deduplication
  1. Client computes SHA-256 of file before upload
  2. Server checks: does this hash already exist?
     Yes → reference existing file, skip upload
     No  → proceed with upload
  3. Store file with hash as key
  
  Storage key: sha256/{first-2-chars}/{hash}.{ext}
  Example:     sha256/ab/abc123def456...jpg

  Reference counting:
    file_hash → {ref_count: 47, storage_key: "..."}
    When ref_count reaches 0 → delete file

Savings: 30-60% storage reduction for social platforms
~~~

---

## 7. Anti-Patterns

### Storing Files in the Database

~~~
Problem: BLOBs in PostgreSQL/MySQL

  INSERT INTO files (id, data) VALUES (1, <2GB binary>)
  
  → Database backups become enormous
  → Replication lag spikes
  → Query performance degrades
  → Can't use CDN for delivery

Fix: Store files in object storage
     Store only metadata in database
     Exception: tiny files (<256KB) where simplicity matters
~~~

### No Size or Type Validation

~~~
Problem: Accept any upload without validation

  → User uploads 50GB file (fills storage)
  → User uploads .exe disguised as .jpg (security risk)
  → User uploads malformed file (crashes processor)

Fix: Validate before upload:
  - File size limits per type (images: 20MB, videos: 5GB)
  - Content-type validation (check magic bytes, not just extension)
  - Virus scan before making available
  - Rate limit uploads per user
~~~

### Serving Files Through the App Server

~~~
Problem: App server proxies every file download

  Client → App Server → Storage → App Server → Client
  
  → App server becomes bottleneck
  → Wastes compute on byte shuffling
  → Can't leverage CDN caching

Fix: Pre-signed URLs or CDN
     App server only handles auth and URL generation
     File bytes flow directly from storage/CDN to client
~~~

---

## 8. Key Takeaways

| # | Takeaway |
|---|----------|
| 1 | Use pre-signed URLs — never proxy file bytes through your API server |
| 2 | Chunked uploads are essential for large files and unreliable networks |
| 3 | Separate file bytes (object storage) from metadata (database) |
| 4 | Process files async — virus scan, resize, transcode in a pipeline |
| 5 | Storage tiering saves significant cost as data grows |
| 6 | CDN for delivery — serve from the edge, not the origin |
| 7 | Content-addressable storage deduplicates at the storage layer |
| 8 | Validate everything — size, type, content — before accepting uploads |

---

## 9. Practical Exercise

### Design Challenge

Design a file storage system for a team collaboration platform (like Slack/Teams):

**Requirements:**
- Users upload documents, images, videos, and code snippets
- Max file size: 1GB for paid plans, 100MB for free
- Files shared in channels visible to all channel members
- Full-text search across document contents
- Preview generation (PDF thumbnails, code syntax highlighting)
- 50 million files, 500K uploads per day
- Files must be available across all regions within 5 minutes

**Discussion Questions:**
1. How would you handle a user uploading a 1GB video on a flaky mobile connection?
2. What's your storage strategy for a mix of tiny text files and large videos?
3. How do you implement access control when a user is removed from a channel?
4. What's your approach to generating previews for 50+ file types?
5. How do you handle the cost of storing 50M files that are rarely accessed after the first week?
