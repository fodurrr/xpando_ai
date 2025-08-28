# Security and Performance

## Security Requirements

**Frontend Security:**
- CSP Headers: `default-src 'self'; script-src 'self' 'unsafe-eval'; style-src 'self' 'unsafe-inline'`
- XSS Prevention: Phoenix HTML escaping, LiveView sanitization
- Secure Storage: HTTPOnly cookies for sessions, no sensitive data in localStorage

**Backend Security:**
- Input Validation: Ash changesets with strict validation rules
- Rate Limiting: Plug rate limiter, 100 requests/minute per IP
- CORS Policy: Restrictive CORS, only allow registered node origins

**Authentication Security:**
- Token Storage: Secure HTTPOnly cookies, JWT for API
- Session Management: Redis-backed sessions with 24h expiry
- Password Policy: Minimum 12 characters, bcrypt hashing

## Performance Optimization

**Frontend Performance:**
- Bundle Size Target: < 200KB gzipped JavaScript
- Loading Strategy: LiveView server-side rendering, minimal JS
- Caching Strategy: ETag headers, 1-year cache for static assets

**Backend Performance:**
- Response Time Target: < 100ms p95 for reads, < 500ms for writes
- Database Optimization: Proper indexes, query optimization via Ash
- Caching Strategy: ETS for hot data, 5-minute TTL