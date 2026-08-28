# Prompt Template: Chaos Test (SIGKILL Mid-Flow)

```
Generate a chaos test that:

1. Starts a [business flow, e.g., saga, payment, bid]
2. Waits until [specific step, e.g., funds held] completes
3. Sends SIGKILL to the [service] container/process
4. Restarts the service
5. Asserts:
   - No stuck / partial state
   - Flow either completes correctly or rolls back cleanly
   - No duplicate side effects

Use [Testcontainers / Docker Java client / ProcessBuilder] for process control.
Include the full test class with setup and teardown.
```
