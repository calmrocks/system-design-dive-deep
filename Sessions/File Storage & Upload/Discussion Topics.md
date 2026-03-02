# File Storage & Upload - Discussion Topics

## Architecture & Design

1. **When would you use pre-signed URLs vs proxying through your API server?**
   - Security considerations
   - Access control granularity
   - Client capability constraints

2. **How do you decide between chunked upload and single-request upload?**
   - File size thresholds
   - Network reliability
   - Client complexity trade-offs

3. **What's your strategy for choosing between object storage providers?**
   - S3 vs GCS vs Azure Blob vs self-hosted (MinIO)
   - Multi-cloud considerations
   - Vendor lock-in and egress costs

## Real-World Scenarios

4. **Design a file upload system for a medical imaging platform with 500MB+ DICOM files**
   - Resumable uploads over hospital networks
   - Compliance and encryption requirements
   - Processing pipeline for image analysis

5. **Your CDN bill doubled last month — how do you investigate and optimize?**
   - Identifying hot content vs long-tail
   - Cache hit ratio analysis
   - Storage tiering and lifecycle policies

6. **How would you handle a viral piece of content that suddenly gets 10M downloads in an hour?**
   - CDN capacity and origin shielding
   - Rate limiting per file
   - Cost implications

## Reliability & Performance

7. **A file processing job fails after transcoding 80% of a 2-hour video — what's your retry strategy?**
   - Checkpoint-based processing
   - Idempotent processing steps
   - Cost of reprocessing

8. **How do you ensure file durability (no data loss) across your storage system?**
   - Replication and erasure coding
   - Cross-region backup
   - Integrity verification (checksums)

## Advanced Topics

9. **When would you implement content-addressable storage for deduplication?**
   - Storage savings vs complexity
   - Reference counting challenges
   - Privacy implications of dedup

10. **How do you handle file versioning for a document collaboration tool?**
    - Storage cost of keeping all versions
    - Diff-based vs full-copy versioning
    - Version pruning policies
