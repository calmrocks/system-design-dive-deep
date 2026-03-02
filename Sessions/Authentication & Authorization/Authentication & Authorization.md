# Authentication & Authorization: Architecture Guide

## Overview

| Attribute | Details |
|-----------|---------|
| Duration | 60 minutes |
| Level | Intermediate to Advanced |
| Prerequisites | Cache session, basic web security knowledge |

## Learning Objectives

- Distinguish authentication (who are you?) from authorization (what can you do?)
- Design token-based auth systems with JWT and refresh tokens
- Understand OAuth 2.0 and SSO flows for third-party integration
- Implement role-based and attribute-based access control at scale
- Reason about session management, token revocation, and security trade-offs

---

## 1. Authentication vs Authorization

### The Two Questions

~~~
Authentication (AuthN): "Who are you?"
  → Verify identity
  → Input: credentials (password, token, biometric)
  → Output: identity (user_id, email)

Authorization (AuthZ): "What can you do?"
  → Check permissions
  → Input: identity + requested action + resource
  → Output: allow or deny

Example:
  AuthN: "I'm user alice@example.com" (verified via password)
  AuthZ: "Can alice delete project-X?" (checked via RBAC)
  
  Both are required. Neither is sufficient alone.
~~~

---

## 2. Authentication Patterns

### Session-Based Authentication

~~~mermaid
sequenceDiagram
    participant C as Client
    participant API as API Server
    participant DB as Database
    participant SS as Session Store (Redis)
    
    C->>API: POST /login {email, password}
    API->>DB: Verify credentials
    DB-->>API: User found, password matches
    API->>SS: Create session {userId, roles, expiresAt}
    SS-->>API: sessionId: "sess-abc123"
    API-->>C: Set-Cookie: session_id=sess-abc123; HttpOnly; Secure
    
    Note over C: Subsequent requests...
    C->>API: GET /profile (Cookie: session_id=sess-abc123)
    API->>SS: Get session "sess-abc123"
    SS-->>API: {userId: "user-1", roles: ["admin"]}
    API-->>C: 200 OK {profile data}
~~~

~~~
Pros:
  ✅ Server controls session (easy revocation)
  ✅ Small cookie (just session ID)
  ✅ HttpOnly cookie prevents XSS token theft

Cons:
  ❌ Requires session store (stateful)
  ❌ Session store is a single point of failure
  ❌ Harder to scale across services (sticky sessions or shared store)
~~~

### Token-Based Authentication (JWT)

~~~mermaid
sequenceDiagram
    participant C as Client
    participant API as Auth Service
    participant RS as Resource Service
    
    C->>API: POST /login {email, password}
    API->>API: Verify credentials
    API->>API: Generate JWT (signed with secret)
    API-->>C: {accessToken: "eyJ...", refreshToken: "ref-xyz", expiresIn: 900}
    
    Note over C: Subsequent requests...
    C->>RS: GET /api/data (Authorization: Bearer eyJ...)
    RS->>RS: Verify JWT signature
    RS->>RS: Check expiry, extract claims
    RS-->>C: 200 OK {data}
    
    Note over C: Access token expired...
    C->>API: POST /token/refresh {refreshToken: "ref-xyz"}
    API->>API: Validate refresh token
    API-->>C: {accessToken: "eyJ...(new)", expiresIn: 900}
~~~

~~~
JWT structure:
  Header:  {"alg": "RS256", "typ": "JWT"}
  Payload: {"sub": "user-1", "roles": ["admin"], 
            "iat": 1709312400, "exp": 1709313300}
  Signature: RS256(header + payload, private_key)

  Encoded: eyJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJ1c2VyLTEi...

Pros:
  ✅ Stateless (no session store needed)
  ✅ Self-contained (carries user info)
  ✅ Works across services (any service can verify)
  ✅ Scales horizontally

Cons:
  ❌ Can't revoke until expiry (without blocklist)
  ❌ Larger than session cookie
  ❌ Token theft = full access until expiry
~~~

### Token Lifecycle

~~~
Access Token:
  - Short-lived (5-15 minutes)
  - Used for API requests
  - Contains user claims (id, roles)
  - Stateless verification (signature check only)

Refresh Token:
  - Long-lived (7-30 days)
  - Used only to get new access tokens
  - Stored server-side (database)
  - Can be revoked (delete from DB)
  - Rotated on each use (one-time use)

Why two tokens?
  Access token: fast, stateless, but can't revoke
  Refresh token: slower, stateful, but revocable
  → Compromise: short access window + revocable refresh
~~~

---

## 3. OAuth 2.0 and SSO

### OAuth 2.0 Authorization Code Flow

~~~mermaid
sequenceDiagram
    participant U as User
    participant App as Your App
    participant AS as Auth Server (Google)
    participant RS as Resource Server (Google API)
    
    U->>App: Click "Login with Google"
    App->>AS: Redirect to /authorize?client_id=...&redirect_uri=...&scope=email
    AS->>U: Google login page
    U->>AS: Enter credentials + consent
    AS->>App: Redirect to callback?code=AUTH_CODE
    
    App->>AS: POST /token {code, client_id, client_secret}
    AS-->>App: {access_token, refresh_token, id_token}
    
    App->>RS: GET /userinfo (Bearer access_token)
    RS-->>App: {email, name, picture}
    
    App->>App: Create local user session
    App-->>U: Logged in!
~~~

### Single Sign-On (SSO)

~~~
SSO flow:
  User logs into Identity Provider (IdP) once
  → Automatically authenticated across all connected apps

  User → App A → "Not logged in" → Redirect to IdP
  IdP → "Enter credentials" → User logs in
  IdP → Redirect back to App A with token → Logged in

  User → App B → "Not logged in" → Redirect to IdP
  IdP → "Already authenticated" (session exists)
  IdP → Redirect back to App B with token → Logged in (no password!)

Protocols:
  SAML 2.0: XML-based, enterprise (Okta, Azure AD)
  OIDC: JSON-based, modern (Google, Auth0, Cognito)
  
  OIDC = OAuth 2.0 + identity layer (id_token with user info)
~~~

---

## 4. Authorization Models

### Role-Based Access Control (RBAC)

~~~
Roles define what groups of users can do:

  Roles:
    admin:   [create, read, update, delete, manage_users]
    editor:  [create, read, update]
    viewer:  [read]

  Assignment:
    alice → admin
    bob   → editor
    carol → viewer

  Check:
    Can bob delete post-123?
    bob.roles = [editor]
    editor.permissions = [create, read, update]
    "delete" not in permissions → DENY
~~~

~~~mermaid
flowchart TB
    USER[User: Bob] --> ROLE[Role: Editor]
    ROLE --> P1[Permission: Create]
    ROLE --> P2[Permission: Read]
    ROLE --> P3[Permission: Update]
    
    USER2[User: Alice] --> ROLE2[Role: Admin]
    ROLE2 --> P4[Permission: All]
    
    USER3[User: Carol] --> ROLE3[Role: Viewer]
    ROLE3 --> P5[Permission: Read]
~~~

### Attribute-Based Access Control (ABAC)

~~~
Policies based on attributes of user, resource, and environment:

  Policy: "Users can edit documents they own"
    Subject attributes: user.id, user.department, user.role
    Resource attributes: doc.owner_id, doc.classification
    Environment: time_of_day, ip_address, device_type

  Evaluation:
    Can bob edit doc-456?
    → bob.id == doc-456.owner_id? → YES → ALLOW
    → bob.department == doc-456.department? → check further...

  More flexible than RBAC but more complex:
    "Managers can approve expenses under $10K in their department
     during business hours from a corporate device"
~~~

### Resource-Based Policies

~~~
Common in multi-tenant systems:

  Organization → Teams → Projects → Resources

  Permission check:
    1. Is user a member of the organization?
    2. Does user's team have access to this project?
    3. Does user's role allow this action on this resource?

  Example (GitHub-like):
    org:acme / team:backend / repo:api-service
    
    alice: org:acme, team:backend, role:maintainer
    → Can push to api-service? YES (maintainer on team with access)
    
    bob: org:acme, team:frontend, role:member
    → Can push to api-service? NO (team doesn't have access)
~~~

---

## 5. Token Revocation

### The Revocation Problem

~~~
JWT is stateless → can't "delete" a token
Token is valid until it expires

Scenarios requiring revocation:
  - User logs out
  - Password changed
  - Account compromised
  - User role changed
  - User deleted

Solutions:
┌─────────────────────────────────────────────────────┐
│ 1. Short-lived access tokens (5 min)                │
│    → Acceptable delay: max 5 min of stale access    │
│    → Revoke refresh token for immediate effect      │
│                                                     │
│ 2. Token blocklist (Redis)                          │
│    → On revocation: add token ID to blocklist       │
│    → On each request: check blocklist               │
│    → TTL = token remaining lifetime                 │
│    → Trade-off: adds a stateful check               │
│                                                     │
│ 3. Token versioning                                 │
│    → Store token_version per user in DB/cache       │
│    → JWT includes version claim                     │
│    → If JWT version < current version → reject      │
│    → Increment version to revoke all tokens         │
└─────────────────────────────────────────────────────┘
~~~

---

## 6. Security Considerations

### Common Attack Vectors

~~~
1. Credential Stuffing
   Attacker uses leaked passwords from other sites
   Fix: Rate limiting, CAPTCHA, breach detection, MFA

2. Token Theft (XSS)
   JavaScript steals token from localStorage
   Fix: HttpOnly cookies, Content Security Policy
        Never store tokens in localStorage for sensitive apps

3. CSRF (Cross-Site Request Forgery)
   Malicious site triggers authenticated request
   Fix: CSRF tokens, SameSite cookies, check Origin header

4. Session Fixation
   Attacker sets session ID before user logs in
   Fix: Regenerate session ID after login

5. Brute Force
   Attacker tries many passwords
   Fix: Account lockout, progressive delays, MFA
~~~

### Multi-Factor Authentication (MFA)

~~~mermaid
sequenceDiagram
    participant U as User
    participant API as Auth Service
    participant MFA as MFA Service
    
    U->>API: POST /login {email, password}
    API->>API: Verify password ✓
    API-->>U: {mfaRequired: true, mfaToken: "temp-xyz"}
    
    U->>U: Open authenticator app, get code
    U->>API: POST /login/mfa {mfaToken: "temp-xyz", code: "123456"}
    API->>MFA: Verify TOTP code
    MFA-->>API: Valid ✓
    API-->>U: {accessToken: "eyJ...", refreshToken: "ref-abc"}
~~~

~~~
MFA methods (by security level):
  Hardware key (FIDO2/WebAuthn): strongest, phishing-resistant
  Authenticator app (TOTP):     strong, widely supported
  SMS code:                     moderate, vulnerable to SIM swap
  Email code:                   weakest MFA, better than nothing
~~~

---

## 7. Auth at Scale

### Centralized Auth Service

~~~mermaid
flowchart TB
    C[Client] --> GW[API Gateway]
    GW --> AUTH[Auth Service]
    AUTH --> |Verify token| GW
    
    GW --> S1[Service A]
    GW --> S2[Service B]
    GW --> S3[Service C]
    
    AUTH --> DB[(User DB)]
    AUTH --> CACHE[(Token Cache)]
~~~

~~~
Pattern: API Gateway handles auth, services trust internal requests

  1. Client sends request with token to API Gateway
  2. Gateway validates token (signature, expiry, blocklist)
  3. Gateway adds user context headers (X-User-Id, X-Roles)
  4. Internal services trust these headers
  5. Services do their own authorization (permission checks)

Benefits:
  ✅ Auth logic in one place
  ✅ Services don't need auth libraries
  ✅ Easy to add new auth methods (MFA, SSO)
  
Risks:
  ❌ Gateway is a single point of failure
  ❌ Internal services must validate headers aren't spoofed
  ❌ Service-to-service auth still needed
~~~

### Service-to-Service Authentication

~~~
Internal services also need auth:

  1. Mutual TLS (mTLS)
     Each service has a certificate
     Both sides verify each other
     ✅ Strong, no tokens to manage
     ❌ Certificate rotation complexity

  2. Service tokens (JWT)
     Services get their own tokens with service identity
     Short-lived, auto-rotated
     ✅ Familiar pattern, carries claims
     ❌ Token management overhead

  3. Service mesh (Istio, Linkerd)
     Sidecar proxy handles mTLS transparently
     ✅ Zero code changes in services
     ❌ Infrastructure complexity
~~~

---

## 8. Key Takeaways

| # | Takeaway |
|---|----------|
| 1 | AuthN (who) and AuthZ (what) are separate concerns — design them independently |
| 2 | Short-lived access tokens + revocable refresh tokens is the standard pattern |
| 3 | JWT is stateless but revocation requires a blocklist or version check |
| 4 | OAuth 2.0 / OIDC for third-party login, not for your own auth |
| 5 | RBAC for simple permission models, ABAC when you need attribute-based policies |
| 6 | Never store tokens in localStorage — use HttpOnly cookies for web apps |
| 7 | MFA is not optional for sensitive systems — hardware keys are strongest |
| 8 | Centralize auth at the gateway, but each service owns its authorization |

---

## 9. Practical Exercise

### Design Challenge

Design an authentication and authorization system for a multi-tenant SaaS platform:

**Requirements:**
- Organizations with teams and projects
- SSO via Google and Microsoft (OIDC)
- Username/password with MFA for non-SSO users
- Roles: Owner, Admin, Member, Guest (per organization)
- Fine-grained permissions: project-level access control
- API keys for programmatic access (CI/CD pipelines)
- Audit log of all auth events
- 10,000 organizations, 1 million users

**Discussion Questions:**
1. How do you handle a user who belongs to multiple organizations with different roles?
2. What's your token strategy for a user switching between organizations?
3. How do you implement "invite user to project" with proper permission scoping?
4. What happens when an organization admin revokes a user's access mid-session?
5. How do you design API key permissions to be more restrictive than the user who created them?
