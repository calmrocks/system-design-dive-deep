# Social Media System Design - Progressive Stages

## Stage 1: Basic CRUD Operations

### Architecture Overview
Simple monolithic architecture with basic CRUD operations for users and posts.

~~~mermaid
graph TB
    subgraph "Stage 1: Basic CRUD"
        Client[Client/Browser]
        API[API Server<br/>User CRUD<br/>Post CRUD]
        DB[(Relational Database<br/>PostgreSQL/MySQL)]
        
        Client -->|HTTP Requests| API
        API -->|SQL Queries| DB
        DB -->|Query Results| API
        API -->|HTTP Response| Client
    end
    
    style API fill:#4A90E2
    style DB fill:#50C878
~~~

### Data Flow

~~~mermaid
sequenceDiagram
    participant C as Client
    participant A as API Server
    participant D as Database
    
    Note over C,D: Create Post Flow
    C->>A: POST /api/posts
    A->>D: INSERT INTO posts
    D-->>A: Success
    A-->>C: 201 Created
    
    Note over C,D: Get Posts Flow
    C->>A: GET /api/posts
    A->>D: SELECT * FROM posts
    D-->>A: Posts Data
    A-->>C: 200 OK + Posts
~~~

### Database Schema

~~~mermaid
erDiagram
    USERS ||--o{ POSTS : creates
    USERS {
        int id PK
        string username
        string email
        string password_hash
        timestamp created_at
        timestamp updated_at
    }
    POSTS {
        int id PK
        int user_id FK
        string title
        text content
        int votes
        timestamp created_at
        timestamp updated_at
    }
~~~

---
