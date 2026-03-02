# Authentication & Authorization - Discussion Topics

## Architecture & Design

1. **When would you choose session-based auth over JWT tokens?**
   - Revocation requirements
   - Infrastructure constraints
   - Single-page app vs server-rendered

2. **How do you design a permission model that supports both RBAC and fine-grained resource-level access?**
   - Role hierarchy vs flat roles
   - Permission inheritance across org/team/project
   - Performance of permission checks at scale

3. **What are the trade-offs of centralizing auth at the API gateway vs each service handling its own?**
   - Single point of failure
   - Service-to-service trust boundaries
   - Latency of auth checks

## Real-World Scenarios

4. **Design an auth system for a healthcare platform with strict compliance requirements**
   - HIPAA audit logging
   - Break-the-glass emergency access
   - Consent-based data sharing between providers

5. **A user reports their account was compromised — what's your incident response flow?**
   - Immediate token revocation
   - Session invalidation across devices
   - Audit log review and notification

6. **How would you migrate from a homegrown auth system to an identity provider like Auth0 or Cognito?**
   - Credential migration strategy
   - Dual-running during transition
   - Handling users who haven't logged in since migration

## Security

7. **How do you protect against token theft in a single-page application?**
   - localStorage vs HttpOnly cookies
   - Token binding and fingerprinting
   - Short-lived tokens and refresh rotation

8. **What's your strategy for rate limiting login attempts without locking out legitimate users?**
   - Per-IP vs per-account limiting
   - Progressive delays vs CAPTCHA
   - Distributed rate limiting across regions

## Advanced Topics

9. **How do you implement impersonation (admin acting as another user) safely?**
   - Audit trail requirements
   - Permission scoping during impersonation
   - Time-limited impersonation tokens

10. **How do you handle authorization for real-time features (WebSocket, SSE)?**
    - Auth at connection time vs per-message
    - Permission changes during active connections
    - Token refresh for long-lived connections
