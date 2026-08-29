# JFR Hypothesis-Driven Diagnosis Report

> **Principle:** This report does not deliver a single "verdict."
> It presents multiple competing hypotheses, rates confidence from evidence,
> and prescribes the next experiment to strengthen or falsify each one.

---

## Recording Metadata


 Version: 2.1
 Chunks: 1
 Start: 2026-08-29 10:17:48 (UTC)
 Duration: 104 s

 Event Type                              Count  Size (bytes) 
=============================================================
 jdk.ThreadPark                          74961       2820550
 jdk.ObjectAllocationSample              20510        343804
 jdk.SocketRead                           5524        238757
 jdk.GCPhaseParallel                      4657        127783
 jdk.NativeMethodSample                   2661         31819
 jdk.ModuleExport                         1456         15910
 jdk.ThreadCPULoad                        1368         23819
 jdk.ExecutionSample                      1331         16506
 jdk.SocketWrite                          1252         45172
 jdk.JavaMonitorEnter                      895         23576
 jdk.Checkpoint                            670       5699207
 jdk.PromoteObjectInNewPLAB                648         11243
 jdk.BooleanFlag                           505         15365
 jdk.ActiveSetting                         360         10391
 jdk.Deoptimization                        291          7717
 jdk.ThreadAllocationStatistics            236          3102
 jdk.ThreadStart                           221          2971
 jdk.TenuringDistribution                  210          2289
 jdk.Compilation                           186          5248
 jdk.JavaErrorThrow                        186          9657
 jdk.ExecuteVMOperation                    166          2651
 jdk.LongFlag                              161          5220
 jdk.OldObjectSample                       134          4656
 jdk.UnsignedLongFlag                      132          4484
 jdk.SafepointBegin                        118          1814
 jdk.ResidentSetSize                        99          1740
 jdk.CPULoad                                99          1948
 jdk.JavaThreadStatistics                   99          1424
 jdk.ClassLoadingStatistics                 99          1145
 jdk.CompilerStatistics                     99          2920
 jdk.ExceptionStatistics                    99          1354
 jdk.ModuleRequire                          89           890
 jdk.GCPhasePauseLevel1                     72          2889
 jdk.MetaspaceChunkFreeListSummary          68          1240
 jdk.GCReferenceStatistics                  68           720
 jdk.InitialSecurityProperty                49          2572
 jdk.GCPhasePauseLevel2                     38          1265
 jdk.GCHeapSummary                          34          1303
 jdk.MetaspaceSummary                       34          1738
 jdk.G1HeapSummary                          34           881
 jdk.NetworkUtilization                     34           494
 jdk.NativeLibrary                          33          1837
 jdk.PromoteObjectOutsidePLAB               32           497
 jdk.StringFlag                             28           962
 jdk.IntFlag                                25           931
 jdk.G1MMU                                  20           264
 jdk.GCCPUTime                              20           356
 jdk.GCPhasePause                           20           488
 jdk.DirectBufferStatistics                 19           463
 jdk.GCPhaseConcurrent                      18           825
 jdk.ThreadSleep                            18           366
 jdk.GarbageCollection                      17           395
 jdk.InitialSystemProperty                  16           745
 jdk.InitialEnvironmentVariable             15           817
 jdk.DoubleFlag                             15           605
 jdk.YoungGarbageCollection                 14           186
 jdk.G1GarbageCollection                    14           186
 jdk.EvacuationInformation                  14           395
 jdk.G1EvacuationYoungStatistics            14           377
 jdk.G1EvacuationOldStatistics              14           315
 jdk.G1BasicIHOP                            14           569
 jdk.G1AdaptiveIHOP                         14           577
 jdk.UnsignedIntFlag                        14           473
 jdk.ThreadEnd                              12           110
 jdk.GCPhaseConcurrentLevel1                12           449
 jdk.ClassLoaderStatistics                  10           273
 jdk.ThreadContextSwitchRate                 9           105
 jdk.SymbolTableStatistics                   9           348
 jdk.StringTableStatistics                   9           348
 jdk.MetaspaceGCThreshold                    7           112
 jdk.GCHeapMemoryPoolUsage                   6           227
 jdk.CompilationFailure                      6           243
 jdk.CodeCacheStatistics                     6           195
 jdk.MetaspaceAllocationFailure              4            57
 jdk.OldGarbageCollection                    3            36
 jdk.ContainerCPUUsage                       3            87
 jdk.ContainerCPUThrottling                  3            64
 jdk.ContainerMemoryUsage                    3            68
 jdk.ContainerIOUsage                        3            50
 jdk.GCHeapMemoryUsage                       2            43
 jdk.PhysicalMemory                          2            34
 jdk.GCConfiguration                         2            51
 jdk.FileRead                                2            64
 jdk.Metadata                                1        103219
 jdk.ContainerConfiguration                  1            57
 jdk.Shutdown                                1            43
 jdk.JVMInformation                          1           440
 jdk.OSInformation                           1           250
 jdk.VirtualizationInformation               1            31
 jdk.SystemProcess                           1           283
 jdk.CPUInformation                          1          1487
 jdk.CPUTimeStampCounter                     1            19
 jdk.ThreadDump                              1        601671
 jdk.CompilerConfiguration                   1            10
 jdk.CodeCacheConfiguration                  1            45
 jdk.GCSurvivorConfiguration                 1            10
 jdk.GCTLABConfiguration                     1            12
 jdk.GCHeapConfiguration                     1            27
 jdk.YoungGenerationConfiguration            1            17
 jdk.ActiveRecording                         1           101
 jdk.JavaMonitorWait                         0             0
 jdk.JavaMonitorInflate                      0             0
 jdk.SyncOnValueBasedClass                   0             0
 jdk.ContinuationFreeze                      0             0
 jdk.ContinuationThaw                        0             0
 jdk.ContinuationFreezeFast                  0             0
 jdk.ContinuationFreezeSlow                  0             0
 jdk.ContinuationThawFast                    0             0
 jdk.ContinuationThawSlow                    0             0
 jdk.ReservedStackActivation                 0             0
 jdk.ClassLoad                               0             0
 jdk.ClassDefine                             0             0
 jdk.ClassRedefinition                       0             0
 jdk.RedefineClasses                         0             0
 jdk.RetransformClasses                      0             0
 jdk.ClassUnload                             0             0
 jdk.IntFlagChanged                          0             0
 jdk.UnsignedIntFlagChanged                  0             0
 jdk.LongFlagChanged                         0             0
 jdk.UnsignedLongFlagChanged                 0             0
 jdk.DoubleFlagChanged                       0             0
 jdk.BooleanFlagChanged                      0             0
 jdk.StringFlagChanged                       0             0
 jdk.MetaspaceOOM                            0             0
 jdk.PSHeapSummary                           0             0
 jdk.SystemGC                                0             0
 jdk.ParallelOldGarbageCollection            0             0
 jdk.ObjectCountAfterGC                      0             0
 jdk.PromotionFailed                         0             0
 jdk.EvacuationFailed                        0             0
 jdk.ConcurrentModeFailure                   0             0
 jdk.GCPhasePauseLevel3                      0             0
 jdk.GCPhasePauseLevel4                      0             0
 jdk.GCPhaseConcurrentLevel2                 0             0
 jdk.AllocationRequiringGC                   0             0
 jdk.G1HeapRegionTypeChange                  0             0
 jdk.JITRestart                              0             0
 jdk.CompilerPhase                           0             0
 jdk.CompilerInlining                        0             0
 jdk.CodeCacheFull                           0             0
 jdk.SafepointStateSynchronization           0             0
 jdk.SafepointCleanup                        0             0
 jdk.SafepointCleanupTask                    0             0
 jdk.SafepointEnd                            0             0
 jdk.ObjectAllocationInNewTLAB               0             0
 jdk.ObjectAllocationOutsideTLAB             0             0
 jdk.NativeMemoryUsage                       0             0
 jdk.NativeMemoryUsageTotal                  0             0
 jdk.DumpReason                              0             0
 jdk.DataLoss                                0             0
 jdk.ObjectCount                             0             0
 jdk.G1HeapRegionInformation                 0             0
 jdk.ZYoungGarbageCollection                 0             0
 jdk.ZOldGarbageCollection                   0             0
 jdk.ZAllocationStall                        0             0
 jdk.ZPageAllocation                         0             0
 jdk.ZRelocationSet                          0             0
 jdk.ZRelocationSetGroup                     0             0
 jdk.ZStatisticsCounter                      0             0
 jdk.ZStatisticsSampler                      0             0
 jdk.ZThreadPhase                            0             0
 jdk.ZUncommit                               0             0
 jdk.ZUnmap                                  0             0
 jdk.ShenandoahHeapRegionStateChange         0             0
 jdk.ShenandoahHeapRegionInformation         0             0
 jdk.Flush                                   0             0
 jdk.HeapDump                                0             0
 jdk.GCLocker                                0             0
 jdk.FinalizerStatistics                     0             0
 jdk.JavaAgent                               0             0
 jdk.NativeAgent                             0             0
 jdk.FileForce                               0             0
 jdk.FileWrite                               0             0
 jdk.JavaExceptionThrow                      0             0
 jdk.Deserialization                         0             0
 jdk.ProcessStart                            0             0
 jdk.SecurityPropertyModification            0             0
 jdk.SecurityProviderService                 0             0
 jdk.TLSHandshake                            0             0
 jdk.VirtualThreadStart                      0             0
 jdk.VirtualThreadEnd                        0             0
 jdk.VirtualThreadPinned                     0             0
 jdk.VirtualThreadSubmitFailed               0             0
 jdk.X509Certificate                         0             0
 jdk.X509Validation                          0             0

| Metric | Value |
|--------|-------|
| JFR File | `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/practice-mvc-caffeine/profile.jfr` |
| Analysis Output | `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/practice-mvc-caffeine/jfr` |
| JVM+System CPU |  |

## Evidence Summary

| Event Type | Count | p50 | p95 | p99 | Max | Severity |
|------------|-------|-----|-----|-----|-----|----------|
| ThreadPark           |  74961 |      103ms |      599ms |     1110ms |    59800ms | CRITICAL   |
| SocketRead           |   5524 |     72.2ms |     88.9ms |     99.5ms |      193ms | CRITICAL   |
| JavaMonitorEnter     |    895 |     97.8ms |      470ms |      607ms |      807ms | CRITICAL   |
| GC Pause             |     20 |     17.6ms |     94.4ms |     94.4ms |     94.4ms | CONCERNING |

| Event Type | Count | Note | Severity |
|------------|-------|------|----------|
| ExecutionSample      |   1331 | CPU execution samples (not ms)                 | N/A        |
| ObjectAllocation     |  20510 | Allocation samples (not ms)                    | N/A        |
| Exception/Error      |    186 | Total exception events                         | CONCERNING |

## Hypotheses

| Confidence | Meaning |
|------------|---------|
| HIGH | Evidence strongly supports; next step is optimization + measurement |
| MEDIUM | Evidence suggests; next step is targeted experiment to confirm |
| LOW | Evidence weak or indirect; next step is collect missing metrics |
| NOT PROVEN | No supporting evidence in this recording |

*Thresholds used (override via env vars):*
- IO count > 500, p95 > 20ms
- Park count > 5000, CPU count < 5000
- Lock count > 100, p95 > 10ms
- Alloc count > 20000
- GC p99 < 50ms (for 'not a bottleneck')

### [H1] External I/O (network/DB) may be limiting throughput

**Confidence:** MEDIUM

**Severity:** CRITICAL (SocketRead p95 = 88.9ms)

**Evidence:**
- SocketRead events: 5524
- SocketRead p95: 88.9ms, p99: 99.5ms, max: 193ms
- Top destinations:
  - postgres:5432: 5323 events

**Interpretation:**
Socket reads are frequent and slow under load. This is consistent with an
external I/O bottleneck (database, cache, or downstream service), but it
could also be network latency, large payloads, or inefficient queries.

**Next experiment:**
1. Measure query / downstream call latency from application metrics.
2. Compare throughput with a stubbed/cached response path.
3. Check for N+1 calls, missing indexes, or oversized payloads.

### [H2] Blocking wait patterns may limit concurrency

**Confidence:** MEDIUM

**Severity:** CRITICAL (ThreadPark p95 = 599ms)

**Evidence:**
- ThreadPark events: 74961
- ThreadPark p95: 599ms, p99: 1110ms, max: 59800ms
- ExecutionSample events: 1331 (low CPU work suggests threads wait more than compute)
- Most parked class: java.util.concurrent.locks.AbstractQueuedSynchronizer$ConditionObject

**Interpretation:**
Threads park frequently while CPU samples are low. This is consistent with a
blocking I/O or synchronization model where worker threads spend most of their
lifecycle waiting. However, ThreadPark alone does NOT prove thread starvation
— it could be normal pool behavior under moderate load.

**Next experiment:**
1. Capture active/max thread counts and request queue depth during load.
2. Vary thread pool sizes and measure throughput + tail latency.
3. If using a blocking stack, compare against a non-blocking alternative ONLY
   after confirming the wait cause (e.g., blocking I/O driver + reactive framework
   is NOT a valid experiment — it tests the framework, not non-blocking I/O).

### [H3] GC is NOT currently a primary bottleneck

**Confidence:** MEDIUM

**Severity:** CONCERNING (GC Pause p99 = 94.4ms)

**Evidence:**
- GC Pause events: 20
- GC Pause p95: 94.4ms, p99: 94.4ms, max: 94.4ms
- Total GC pause time: 535.7ms

**Interpretation:**
GC pauses are elevated. This may contribute to tail latency and should be monitored.

**Next experiment:**
- If allocation rate is high (>20000 samples), monitor GC overhead % during longer runs.
- Otherwise: no GC experiment needed until higher confidence in H1/H2.

### [H4] CPU is NOT proven to be the bottleneck

**Confidence:** LOW (not proven)

**Severity:** N/A (JVM+System CPU = )

**Evidence:**
- ExecutionSample events: 1331
- JVM+System CPU load: 
- Hottest method: org.apache.catalina.core.ApplicationFilterChain.doFilter

**Interpretation:**
Execution samples are relatively low. The JVM is not spending most of its time
on-CPU. This is consistent with an I/O-waiting or thread-parked state.

**Next experiment:**
1. Correlate ExecutionSample count with OS-level CPU % (already in JFR via CPULoad).
2. If CPU % is high and ExecutionSample is high -> profile hot methods (already done above).
3. If CPU % is low and ExecutionSample is low -> bottleneck is elsewhere (H1 or H2).

### [H5] Lock contention may be causing serial execution

**Confidence:** MEDIUM

**Severity:** CRITICAL (JavaMonitorEnter p95 = 470ms)

**Evidence:**
- JavaMonitorEnter events: 895
- Monitor wait p95: 470ms, max: 807ms
- Most contended monitors:
  - org.apache.coyote.AbstractProtocol$RecycledProcessors: 478 events
  - java.lang.Object: 176 events
  - org.apache.tomcat.util.collections.SynchronizedQueue: 133 events
  - java.util.HashMap: 67 events
  - sun.security.provider.HashDrbg: 35 events

**Interpretation:**
Monitor entry waits are frequent and slow. Some code paths may be serializing
concurrent requests unnecessarily.

**Next experiment:**
1. Identify which business methods acquire the contended monitors.
2. Replace synchronized blocks with java.util.concurrent primitives if possible.
3. Measure throughput before/after.

### [H6] Allocation pressure may be causing GC churn

**Confidence:** MEDIUM

**Evidence:**
- ObjectAllocationSample events: 20510
- Top allocating classes:
  - byte[]: 2278 samples
  - java.lang.Object[]: 1719 samples
  - java.util.concurrent.ConcurrentHashMap$Node: 1069 samples
  - java.util.ArrayList: 801 samples
  - java.util.LinkedHashMap: 767 samples

**Interpretation:**
High allocation rate detected. This often correlates with GC pressure,
especially if temporary objects dominate (JSON parsing, DTO mapping, String concat).

**Next experiment:**
1. Profile allocation rate vs GC pause frequency over a longer run.
2. If correlated, reduce allocations (object pooling, reuse buffers, avoid autoboxing).

### [H7] Exception rate may indicate errors or control-flow abuse

**Confidence:** MEDIUM

**Severity:** CONCERNING (total exceptions = 186)

**Evidence:**
- Exception/Error events: 186
- Top thrown types (errors):
  - java.lang.NoSuchMethodError: 151 events
  - java.lang.IncompatibleClassChangeError: 35 events

**Interpretation:**
High exception rate detected. Exceptions are expensive in Java (stack trace
capture, unwinding). If used for control flow, this is a known anti-pattern.

**Next experiment:**
1. Check logs for repeated error patterns at the times of the recording.
2. If control-flow exceptions (e.g., FlowControlException), refactor to return codes.
3. Measure throughput before/after.

## Hotspot Detail

> These are the raw hotspots. Use them to support or refute hypotheses above,
> not to declare a verdict.

### Top Methods by ExecutionSample

| Samples | Method |
|--------:|--------|
|    3068 | org.apache.catalina.core.ApplicationFilterChain.doFilter |
|    2027 | org.springframework.web.filter.OncePerRequestFilter.doFilter |
|    1251 | jakarta.servlet.http.HttpServlet.service |
|     853 | ... |
|     650 | org.springframework.web.servlet.FrameworkServlet.processRequest |
|     636 | org.springframework.web.servlet.DispatcherServlet.doService |
|     629 | org.springframework.web.servlet.FrameworkServlet.service |
|     608 | org.springframework.web.servlet.DispatcherServlet.doDispatch |
|     579 | org.apache.tomcat.websocket.server.WsFilter.doFilter |
|     571 | org.springframework.web.filter.RequestContextFilter.doFilterInternal |
|     564 | org.springframework.web.filter.ServerHttpObservationFilter.doFilterInternal |
|     526 | org.springframework.web.servlet.FrameworkServlet.doGet |
|     517 | org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerAdapter.invokeHandlerMethod |
|     516 | org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerAdapter.handleInternal |
|     508 | org.springframework.web.servlet.mvc.method.AbstractHandlerMethodAdapter.handle |

### Longest ThreadParks with Business Frame

| Duration | Thread | First Business Frame |
|---------:|--------|---------------------|
| 59800.00 ms | ForkJoinPool.commonPool-worker-1 | java.util.concurrent.ForkJoinWorkerThread.run |
| 44900.00 ms | Common-Cleaner | jdk.internal.misc.InnocuousThread.run |
| 30000.00 ms | HikariPool-1:housekeeper | java.lang.Thread.run |
| 30000.00 ms | HikariPool-1:housekeeper | java.lang.Thread.run |
| 30000.00 ms | HikariPool-1:housekeeper | java.lang.Thread.run |
| 24800.00 ms | Cleaner-0 | jdk.internal.misc.InnocuousThread.run |
| 23700.00 ms | Common-Cleaner | jdk.internal.misc.InnocuousThread.run |
| 20200.00 ms | Common-Cleaner | jdk.internal.misc.InnocuousThread.run |
| 20200.00 ms | Cleaner-0 | jdk.internal.misc.InnocuousThread.run |
| 16900.00 ms | Cleaner-0 | jdk.internal.misc.InnocuousThread.run |

## Measurement Reference

> Default severity thresholds. Override any via environment variables.
> Example: `SEV_IO_CONCERNING_MS=30 jfr-diagnose.sh recording.jfr`

### ThreadPark (blocking wait)

| Severity | p95 Threshold | What it means |
|----------|---------------|---------------|
| HEALTHY    | <= 1 ms    | Normal parking (LockSupport, brief pool waits) |
| MODERATE   | <= 10 ms   | Some blocking; may be connection pool or mild I/O wait |
| CONCERNING | <= 50 ms | Threads stuck waiting; likely I/O or lock bottleneck |
| CRITICAL   | > 50 ms  | Severe blocking; check thread dumps and pool sizing |

### SocketRead (network / DB I/O)

| Severity | p95 Threshold | What it means |
|----------|---------------|---------------|
| HEALTHY    | <= 1 ms    | Fast local network or in-memory store |
| MODERATE   | <= 5 ms   | Acceptable for remote calls |
| CONCERNING | <= 20 ms | Slow queries, large payloads, or network latency |
| CRITICAL   | > 20 ms  | DB bottleneck, N+1 queries, or downstream failure |

### JavaMonitorEnter (lock contention)

| Severity | p95 Threshold | What it means |
|----------|---------------|---------------|
| HEALTHY    | <= 1 ms    | Light synchronization, normal concurrency |
| MODERATE   | <= 5 ms   | Some contention; review synchronized blocks |
| CONCERNING | <= 20 ms | Serializing execution; consider j.u.c locks |
| CRITICAL   | > 20 ms  | Severe contention; likely throughput killer |

### GC Pause

| Severity | p99 Threshold | What it means |
|----------|---------------|---------------|
| HEALTHY    | <= 10 ms    | Modern GC (G1/ZGC/Shenandoah) doing its job |
| MODERATE   | <= 50 ms   | Tunable; monitor allocation rate |
| CONCERNING | <= 200 ms | Tail latency impact; review heap size / GC algo |
| CRITICAL   | > 200 ms  | Stop-the-world dominates; urgent tuning needed |

### CPU Load (JVM User + System)

| Severity | Threshold | What it means |
|----------|-----------|---------------|
| HEALTHY    | < 50%       | Plenty of headroom |
| MODERATE   | < 80%      | Approaching saturation |
| CONCERNING | < 95%    | Near saturation; scaling may help |
| CRITICAL   | >= 95%   | CPU-bound; profile hot methods |

### Exception Rate

| Severity | Total Count | What it means |
|----------|-------------|---------------|
| HEALTHY    | <= 10     | Normal operational noise |
| MODERATE   | <= 100    | Elevated; check for repeated patterns |
| CONCERNING | <= 1000  | Likely control-flow abuse or real errors |
| CRITICAL   | > 1000   | Exception storm; massive overhead |

### Notes on Interpreting Counts

- **ExecutionSample count** depends on recording duration and sampling rate.
  Correlate with CPU load % rather than judging the raw number alone.
- **ObjectAllocationSample count** also depends on duration. Look at the
  ratio to GC events: high alloc + high GC = pressure; high alloc + low GC = fine.
- **SocketWrite** is not severity-graded because write latency is usually
  buffered; focus on **SocketRead** for I/O bottlenecks.

## Experiment Tracker

> Copy this table into a new file and fill it in as you run each experiment.
> Never change two variables at once.

### Experiment Template

\`\`\`markdown
### Experiment: [describe change]

| Metric | Baseline | This Run | Delta |
|--------|----------|----------|-------|
| RPS (req/s) | ? | ? | ? |
| p50 latency (ms) | ? | ? | ? |
| p95 latency (ms) | ? | ? | ? |
| p99 latency (ms) | ? | ? | ? |
| max latency (ms) | ? | ? | ? |
| CPU % | ? | ? | ? |
| GC overhead % | ? | ? | ? |
| alloc/sec | ? | ? | ? |
| active threads | ? | ? | ? |
| external call p95 (ms) | ? | ? | ? |
| errors | ? | ? | ? |

**Hypothesis tested:** [H1 | H2 | H3 | ...]

**Conclusion:**
- Did the data strengthen or weaken the hypothesis?
- What is the next experiment?
\`\`\`

### Suggested Experiment Order

1. **Baseline confirmation** — run the same load test 3x and verify RPS variance is <5%.
   This is your control. If variance is high, your test harness is the bottleneck.

2. **Experiment A — Stub external I/O** (tests H1):
   - Setup: same app, but stub/cache the external call (DB, cache, HTTP client).
   - Expected if H1 is true: large throughput gain, lower SocketRead p95.
   - If no gain: external I/O is not the bottleneck -> look at H2 or H5.

3. **Experiment B — Scale concurrency** (tests H2):
   - Setup: increase thread pool / connection pool / event-loop count.
   - Expected if H2 is true: throughput rises with concurrency until saturation.
   - If flat: blocking wait model is not the bottleneck -> look at H1 or H4.

4. **Experiment C — Reduce allocations** (tests H6):
   - Setup: target the top allocating classes from the hotspot list above.
   - Expected if H6 is true: lower GC overhead, better tail latency.

> **Rule:** Change one variable per experiment. Otherwise you cannot attribute wins.

## Raw Evidence Files

| File | Description |
|------|-------------|
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/practice-mvc-caffeine/jfr/cpu.txt` | ExecutionSample stack traces |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/practice-mvc-caffeine/jfr/alloc.txt` | ObjectAllocationSample events |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/practice-mvc-caffeine/jfr/io.txt` | SocketRead events |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/practice-mvc-caffeine/jfr/io_write.txt` | SocketWrite events |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/practice-mvc-caffeine/jfr/park.txt` | ThreadPark events |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/practice-mvc-caffeine/jfr/locks.txt` | JavaMonitorEnter events |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/practice-mvc-caffeine/jfr/gc.txt` | GCPhasePause events |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/practice-mvc-caffeine/jfr/exceptions.txt` | JavaErrorThrow events |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/practice-mvc-caffeine/jfr/exceptions2.txt` | ExceptionThrow events |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/practice-mvc-caffeine/jfr/cpu_load.txt` | CPULoad events |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/practice-mvc-caffeine/jfr/io_write.txt` | SocketWrite events (manual inspection) |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/practice-mvc-caffeine/jfr/jvm_info.txt` | JVMInformation events |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/practice-mvc-caffeine/jfr/os_info.txt` | OSInformation events |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/practice-mvc-caffeine/jfr/cpu_info.txt` | CPUInformation events |

---
Report complete. Full report saved to: `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/practice-mvc-caffeine/jfr/diagnosis-report.md`
