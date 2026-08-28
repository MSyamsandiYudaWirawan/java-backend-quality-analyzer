# Prompt Template: Idempotency Key + Deduplication

```
Generate an idempotency filter for [endpoint].

Flow:
1. Client sends Idempotency-Key header (UUID)
2. Check Redis/cache for cached response
   - Hit: return cached response immediately
   - Miss: proceed with processing
3. After processing succeeds, store response in Redis with TTL [24h]
4. If processing fails, do NOT cache — allow retry

Requirements:
- Cache key: idempotency:{key}
- TTL: 24 hours
- Thread-safe: two requests with same key must not both process
- Use [Redis / in-memory] for cache
- Include test: send duplicate request, assert same response, assert processing runs once

Output the interceptor/filter, service wrapper, and test.
```
