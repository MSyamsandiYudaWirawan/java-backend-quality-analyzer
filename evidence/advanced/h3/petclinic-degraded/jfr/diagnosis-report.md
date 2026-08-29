# JFR Hypothesis-Driven Diagnosis Report

> **Principle:** This report does not deliver a single "verdict."
> It presents multiple competing hypotheses, rates confidence from evidence,
> and prescribes the next experiment to strengthen or falsify each one.

---

## Recording Metadata


 Version: 2.1
 Chunks: 1
 Start: 2026-08-29 10:11:40 (UTC)
 Duration: 102 s

 Event Type                              Count  Size (bytes) 
=============================================================
 jdk.JavaMonitorEnter                    74682       1962185
 jdk.ObjectAllocationSample              24345        397565
 jdk.GCPhaseParallel                     14809        410534
 jdk.ThreadPark                           3955        150147
 jdk.NativeMethodSample                   2418         28375
 jdk.ExecutionSample                      2081         25442
 jdk.PromoteObjectInNewPLAB               1801         32701
 jdk.ModuleExport                         1538         16770
 jdk.ThreadCPULoad                        1406         24437
 jdk.Checkpoint                            640       4943686
 jdk.BooleanFlag                           505         15365
 jdk.TenuringDistribution                  405          4720
 jdk.Deoptimization                        369          9811
 jdk.ActiveSetting                         360         10391
 jdk.PromoteObjectOutsidePLAB              301          4832
 jdk.ThreadAllocationStatistics            234          3080
 jdk.ThreadStart                           222          2937
 jdk.ExecuteVMOperation                    196          3171
 jdk.Compilation                           194          5620
 jdk.JavaErrorThrow                        185          9472
 jdk.SocketWrite                           170          5796
 jdk.LongFlag                              161          5220
 jdk.SafepointBegin                        135          2064
 jdk.OldObjectSample                       135          4541
 jdk.UnsignedLongFlag                      132          4484
 jdk.MetaspaceChunkFreeListSummary         124          2292
 jdk.GCReferenceStatistics                 124          1349
 jdk.GCPhasePauseLevel1                    120          4853
 jdk.ResidentSetSize                        98          1722
 jdk.CPULoad                                98          1928
 jdk.JavaThreadStatistics                   98          1416
 jdk.ClassLoadingStatistics                 98          1133
 jdk.CompilerStatistics                     98          3042
 jdk.ExceptionStatistics                    98          1421
 jdk.ModuleRequire                          89           890
 jdk.GCHeapSummary                          62          2400
 jdk.MetaspaceSummary                       62          3188
 jdk.G1HeapSummary                          62          1650
 jdk.GCPhasePauseLevel2                     57          1880
 jdk.InitialSecurityProperty                49          2572
 jdk.G1MMU                                  35           472
 jdk.GCCPUTime                              35           644
 jdk.GCPhasePause                           35           852
 jdk.NetworkUtilization                     33           468
 jdk.NativeLibrary                          33          1837
 jdk.GarbageCollection                      31           729
 jdk.StringFlag                             28           959
 jdk.YoungGarbageCollection                 27           365
 jdk.G1GarbageCollection                    27           365
 jdk.EvacuationInformation                  27           765
 jdk.G1EvacuationYoungStatistics            27           760
 jdk.G1EvacuationOldStatistics              27           602
 jdk.G1BasicIHOP                            27          1086
 jdk.G1AdaptiveIHOP                         27          1132
 jdk.IntFlag                                25           931
 jdk.GCPhaseConcurrent                      24          1105
 jdk.DirectBufferStatistics                 19           463
 jdk.ThreadEnd                              18           172
 jdk.ThreadSleep                            18           366
 jdk.GCPhaseConcurrentLevel1                16           602
 jdk.InitialSystemProperty                  16           745
 jdk.DoubleFlag                             15           605
 jdk.UnsignedIntFlag                        14           473
 jdk.InitialEnvironmentVariable             12           647
 jdk.MetaspaceGCThreshold                   10           161
 jdk.CompilationFailure                      9           380
 jdk.ThreadContextSwitchRate                 9           105
 jdk.ClassLoaderStatistics                   9           249
 jdk.SymbolTableStatistics                   9           348
 jdk.StringTableStatistics                   9           348
 jdk.SocketRead                              8           285
 jdk.GCHeapMemoryPoolUsage                   6           228
 jdk.MetaspaceAllocationFailure              6            89
 jdk.CodeCacheStatistics                     6           195
 jdk.OldGarbageCollection                    4            50
 jdk.JavaMonitorWait                         3            78
 jdk.ContainerCPUUsage                       3            86
 jdk.ContainerCPUThrottling                  3            65
 jdk.ContainerMemoryUsage                    3            68
 jdk.ContainerIOUsage                        3            50
 jdk.GCHeapMemoryUsage                       2            44
 jdk.PhysicalMemory                          2            34
 jdk.GCConfiguration                         2            51
 jdk.Metadata                                1        103219
 jdk.ContainerConfiguration                  1            57
 jdk.Shutdown                                1            42
 jdk.JVMInformation                          1           437
 jdk.OSInformation                           1           250
 jdk.VirtualizationInformation               1            31
 jdk.SystemProcess                           1           280
 jdk.CPUInformation                          1          1487
 jdk.CPUTimeStampCounter                     1            19
 jdk.ThreadDump                              1       1967228
 jdk.CompilerConfiguration                   1            10
 jdk.CodeCacheConfiguration                  1            45
 jdk.GCSurvivorConfiguration                 1            10
 jdk.GCTLABConfiguration                     1            12
 jdk.GCHeapConfiguration                     1            27
 jdk.YoungGenerationConfiguration            1            17
 jdk.FileRead                                1            36
 jdk.ActiveRecording                         1            98
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
| JFR File | `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/petclinic-degraded/profile.jfr` |
| Analysis Output | `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/petclinic-degraded/jfr` |
| JVM+System CPU |  |

## Evidence Summary

| Event Type | Count | p50 | p95 | p99 | Max | Severity |
|------------|-------|-----|-----|-----|-----|----------|
| ThreadPark           |   3955 |     83.8ms |     1000ms |     5000ms |    30000ms | CRITICAL   |
| SocketRead           |      8 |     75.6ms |       80ms |       80ms |       80ms | CRITICAL   |
| JavaMonitorEnter     |  74682 |      120ms |      397ms |      599ms |      903ms | CRITICAL   |
| GC Pause             |     35 |     30.1ms |      107ms |      146ms |      146ms | CONCERNING |

| Event Type | Count | Note | Severity |
|------------|-------|------|----------|
| ExecutionSample      |   2081 | CPU execution samples (not ms)                 | N/A        |
| ObjectAllocation     |  24345 | Allocation samples (not ms)                    | N/A        |
| Exception/Error      |    185 | Total exception events                         | CONCERNING |

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

**Confidence:** NOT PROVEN

**Severity:** CRITICAL (SocketRead p95 = 80ms)

**Evidence:**
- SocketRead events: 8
- SocketRead p95: 80ms, p99: 80ms, max: 80ms
- Top destinations:

**Interpretation:**
Socket reads are either infrequent or fast. External I/O is not strongly
implicated in this recording.

**Next experiment:**
1. Measure query / downstream call latency from application metrics.
2. Compare throughput with a stubbed/cached response path.
3. Check for N+1 calls, missing indexes, or oversized payloads.

### [H2] Blocking wait patterns may limit concurrency

**Confidence:** NOT PROVEN

**Severity:** CRITICAL (ThreadPark p95 = 1000ms)

**Evidence:**
- ThreadPark events: 3955
- ThreadPark p95: 1000ms, p99: 5000ms, max: 30000ms
- ExecutionSample events: 2081 (low CPU work suggests threads wait more than compute)
- Most parked class: java.util.concurrent.locks.AbstractQueuedSynchronizer$ConditionObject

**Interpretation:**
Thread parking is not dominant in this recording. The blocking wait model is
not strongly implicated as the primary bottleneck.

**Next experiment:**
1. Capture active/max thread counts and request queue depth during load.
2. Vary thread pool sizes and measure throughput + tail latency.
3. If using a blocking stack, compare against a non-blocking alternative ONLY
   after confirming the wait cause (e.g., blocking I/O driver + reactive framework
   is NOT a valid experiment — it tests the framework, not non-blocking I/O).

### [H3] GC is NOT currently a primary bottleneck

**Confidence:** MEDIUM

**Severity:** CONCERNING (GC Pause p99 = 146ms)

**Evidence:**
- GC Pause events: 35
- GC Pause p95: 107ms, p99: 146ms, max: 146ms
- Total GC pause time: 1291.5ms

**Interpretation:**
GC pauses are elevated. This may contribute to tail latency and should be monitored.

**Next experiment:**
- If allocation rate is high (>20000 samples), monitor GC overhead % during longer runs.
- Otherwise: no GC experiment needed until higher confidence in H1/H2.

### [H4] CPU is NOT proven to be the bottleneck

**Confidence:** LOW (not proven)

**Severity:** N/A (JVM+System CPU = )

**Evidence:**
- ExecutionSample events: 2081
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

**Severity:** CRITICAL (JavaMonitorEnter p95 = 397ms)

**Evidence:**
- JavaMonitorEnter events: 74682
- Monitor wait p95: 397ms, max: 903ms
- Most contended monitors:
  - org.springframework.boot.loader.net.protocol.jar.UrlJarFiles$Cache: 72527 events
  - jdk.internal.loader.URLClassPath: 1698 events
  - org.springframework.boot.loader.net.protocol.jar.UrlNestedJarFile: 213 events
  - java.util.Hashtable: 193 events
  - java.lang.Object: 18 events

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
- ObjectAllocationSample events: 24345
- Top allocating classes:
  - byte[]: 10325 samples
  - java.net.URL: 3929 samples
  - java.lang.String: 3860 samples
  - org.springframework.boot.loader.net.protocol.jar.JarFileUrlKey: 2287 samples
  - java.lang.Object[]: 358 samples

**Interpretation:**
High allocation rate detected. This often correlates with GC pressure,
especially if temporary objects dominate (JSON parsing, DTO mapping, String concat).

**Next experiment:**
1. Profile allocation rate vs GC pause frequency over a longer run.
2. If correlated, reduce allocations (object pooling, reuse buffers, avoid autoboxing).

### [H7] Exception rate may indicate errors or control-flow abuse

**Confidence:** MEDIUM

**Severity:** CONCERNING (total exceptions = 185)

**Evidence:**
- Exception/Error events: 185
- Top thrown types (errors):
  - java.lang.NoSuchMethodError: 146 events
  - java.lang.IncompatibleClassChangeError: 38 events
  - java.lang.NoClassDefFoundError: 1 events

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
|    2301 | org.apache.catalina.core.ApplicationFilterChain.doFilter |
|    1890 | org.springframework.web.servlet.resource.AbstractResourceResolver.resolveUrlPath |
|    1880 | org.springframework.web.servlet.resource.DefaultResourceResolverChain.resolveUrlPath |
|    1757 | ... |
|    1292 | org.springframework.web.servlet.resource.PathResourceResolver.getResource |
|    1248 | java.net.URLClassLoader$2.run |
|    1085 | org.springframework.web.filter.OncePerRequestFilter.doFilter |
|    1080 | jakarta.servlet.http.HttpServlet.service |
|     888 | org.thymeleaf.engine.ProcessorTemplateHandler.handleOpenElement |
|     879 | org.thymeleaf.engine.OpenElementTag.beHandled |
|     828 | org.thymeleaf.TemplateEngine.process |
|     795 | java.net.URL.<init> |
|     747 | org.thymeleaf.engine.Model.process |
|     714 | java.security.AccessController.doPrivileged |
|     664 | java.lang.ClassLoader.getResource |

### Longest ThreadParks with Business Frame

| Duration | Thread | First Business Frame |
|---------:|--------|---------------------|
| 30000.00 ms | HikariPool-1:housekeeper | java.lang.Thread.run |
| 30000.00 ms | HikariPool-1:housekeeper | java.lang.Thread.run |
| 30000.00 ms | HikariPool-1:housekeeper | java.lang.Thread.run |
|  9670.00 ms | Common-Cleaner | jdk.internal.misc.InnocuousThread.run |
|  9670.00 ms | Cleaner-0 | jdk.internal.misc.InnocuousThread.run |
|  8660.00 ms | Common-Cleaner | jdk.internal.misc.InnocuousThread.run |
|  8660.00 ms | Cleaner-0 | jdk.internal.misc.InnocuousThread.run |
|  7580.00 ms | Common-Cleaner | jdk.internal.misc.InnocuousThread.run |
|  7580.00 ms | Cleaner-0 | jdk.internal.misc.InnocuousThread.run |
|  6690.00 ms | Catalina-utility-2 | org.apache.tomcat.util.threads.TaskThread$WrappingRunnable.run |

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
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/petclinic-degraded/jfr/cpu.txt` | ExecutionSample stack traces |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/petclinic-degraded/jfr/alloc.txt` | ObjectAllocationSample events |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/petclinic-degraded/jfr/io.txt` | SocketRead events |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/petclinic-degraded/jfr/io_write.txt` | SocketWrite events |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/petclinic-degraded/jfr/park.txt` | ThreadPark events |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/petclinic-degraded/jfr/locks.txt` | JavaMonitorEnter events |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/petclinic-degraded/jfr/gc.txt` | GCPhasePause events |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/petclinic-degraded/jfr/exceptions.txt` | JavaErrorThrow events |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/petclinic-degraded/jfr/exceptions2.txt` | ExceptionThrow events |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/petclinic-degraded/jfr/cpu_load.txt` | CPULoad events |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/petclinic-degraded/jfr/io_write.txt` | SocketWrite events (manual inspection) |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/petclinic-degraded/jfr/jvm_info.txt` | JVMInformation events |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/petclinic-degraded/jfr/os_info.txt` | OSInformation events |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/petclinic-degraded/jfr/cpu_info.txt` | CPUInformation events |

---
Report complete. Full report saved to: `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/petclinic-degraded/jfr/diagnosis-report.md`
