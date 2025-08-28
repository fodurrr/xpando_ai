# Monitoring and Observability

## Monitoring Stack

- **Frontend Monitoring:** Browser console errors forwarded to Phoenix LiveView telemetry
- **Backend Monitoring:** Telemetry.Metrics with Prometheus export
- **Error Tracking:** Sentry integration for production errors
- **Performance Monitoring:** AppSignal for APM and custom metrics

## Key Metrics

**Frontend Metrics:**
- Core Web Vitals (LCP, FID, CLS)
- LiveView mount/patch/handle_event timing
- WebSocket connection stability
- Phoenix Channel join/leave rates

**Backend Metrics:**
- Request rate by endpoint
- Error rate by error type
- Response time percentiles (p50, p95, p99)
- Database query performance
- AI provider latency
- P2P network node count
- Knowledge validation rate
- XPD token transaction throughput