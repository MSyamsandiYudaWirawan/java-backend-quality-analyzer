# Prompt Template: Outbox + Polling Publisher

```
Generate an outbox pattern implementation:

1. Outbox table: [service]_outbox
   - id, aggregate_id, aggregate_type, event_type, payload (JSON), processed (bool), created_at
2. Business service writes to DB + outbox in SAME transaction
3. PollingPublisher runs every 100ms:
   - SELECT unprocessed rows
   - Publish each to Kafka/topic
   - UPDATE processed = true
4. Handle publish failures: retry with backoff, dead-letter after N tries

Requirements:
- Reactive / non-blocking
- At-least-once delivery (idempotent consumers handle dupes)
- Include the outbox repository, publisher class, and integration test
```
