# JFR Hypothesis-Driven Diagnosis Report

> **Principle:** This report does not deliver a single "verdict."
> It presents multiple competing hypotheses, rates confidence from evidence,
> and prescribes the next experiment to strengthen or falsify each one.

---

## Recording Metadata


 Version: 2.1
 Chunks: 1
 Start: 2026-08-29 10:26:10 (UTC)
 Duration: 102 s

 Event Type                              Count  Size (bytes) 
=============================================================
 jdk.ThreadPark                          28408       1061534
 jdk.ObjectAllocationSample              22421        374889
 jdk.JavaMonitorEnter                     5018        135721
 jdk.GCPhaseParallel                      4699        128690
 jdk.SocketWrite                          1784         60994
 jdk.ExecutionSample                      1537         18691
 jdk.ThreadCPULoad                        1426         24970
 jdk.ModuleExport                         1383         15104
 jdk.NativeMethodSample                   1103         12715
 jdk.PromoteObjectInNewPLAB                835         14768
 jdk.Checkpoint                            628       4444896
 jdk.BooleanFlag                           505         15365
 jdk.ActiveSetting                         360         10391
 jdk.SocketRead                            281         10030
 jdk.Deoptimization                        255          6715
 jdk.ThreadStart                           253          3385
 jdk.TenuringDistribution                  240          2630
 jdk.ThreadAllocationStatistics            234          3111
 jdk.OldObjectSample                       201          7135
 jdk.ExecuteVMOperation                    166          2646
 jdk.JavaErrorThrow                        164          9139
 jdk.LongFlag                              161          5220
 jdk.Compilation                           143          4062
 jdk.UnsignedLongFlag                      132          4484
 jdk.SafepointBegin                        111          1704
 jdk.ResidentSetSize                        91          1596
 jdk.CPULoad                                91          1788
 jdk.JavaThreadStatistics                   91          1306
 jdk.ClassLoadingStatistics                 91          1044
 jdk.CompilerStatistics                     91          2752
 jdk.ExceptionStatistics                    91          1242
 jdk.ModuleRequire                          89           890
 jdk.PromoteObjectOutsidePLAB               82          1264
 jdk.ThreadEnd                              78           704
 jdk.GCPhasePauseLevel1                     78          3134
 jdk.MetaspaceChunkFreeListSummary          76          1388
 jdk.GCReferenceStatistics                  76           808
 jdk.InitialSecurityProperty                49          2572
 jdk.GCPhasePauseLevel2                     40          1320
 jdk.GCHeapSummary                          38          1460
 jdk.MetaspaceSummary                       38          1944
 jdk.G1HeapSummary                          38           990
 jdk.NativeLibrary                          34          1895
 jdk.NetworkUtilization                     31           452
 jdk.StringFlag                             28           965
 jdk.IntFlag                                25           931
 jdk.G1MMU                                  22           291
 jdk.GCCPUTime                              22           394
 jdk.GCPhasePause                           22           535
 jdk.GarbageCollection                      19           442
 jdk.DirectBufferStatistics                 18           438
 jdk.GCPhaseConcurrent                      18           825
 jdk.ThreadSleep                            18           366
 jdk.YoungGarbageCollection                 16           213
 jdk.G1GarbageCollection                    16           213
 jdk.EvacuationInformation                  16           442
 jdk.G1EvacuationYoungStatistics            16           445
 jdk.G1EvacuationOldStatistics              16           370
 jdk.G1BasicIHOP                            16           656
 jdk.G1AdaptiveIHOP                         16           663
 jdk.InitialSystemProperty                  16           745
 jdk.DoubleFlag                             15           605
 jdk.UnsignedIntFlag                        14           473
 jdk.GCPhaseConcurrentLevel1                12           448
 jdk.InitialEnvironmentVariable             12           653
 jdk.CompilationFailure                     10           413
 jdk.ThreadContextSwitchRate                 9           105
 jdk.ClassLoaderStatistics                   9           247
 jdk.SymbolTableStatistics                   9           348
 jdk.StringTableStatistics                   9           348
 jdk.MetaspaceGCThreshold                    7           112
 jdk.GCHeapMemoryPoolUsage                   6           228
 jdk.CodeCacheStatistics                     6           195
 jdk.MetaspaceAllocationFailure              4            57
 jdk.OldGarbageCollection                    3            36
 jdk.ContainerCPUUsage                       3            86
 jdk.ContainerCPUThrottling                  3            65
 jdk.ContainerMemoryUsage                    3            68
 jdk.ContainerIOUsage                        3            50
 jdk.FileRead                                3            94
 jdk.GCHeapMemoryUsage                       2            44
 jdk.PhysicalMemory                          2            34
 jdk.GCConfiguration                         2            51
 jdk.Metadata                                1        103219
 jdk.ContainerConfiguration                  1            57
 jdk.Shutdown                                1            42
 jdk.JVMInformation                          1           443
 jdk.OSInformation                           1           250
 jdk.VirtualizationInformation               1            31
 jdk.SystemProcess                           1           286
 jdk.CPUInformation                          1          1487
 jdk.CPUTimeStampCounter                     1            19
 jdk.ThreadDump                              1        651516
 jdk.CompilerConfiguration                   1            10
 jdk.CodeCacheConfiguration                  1            45
 jdk.GCSurvivorConfiguration                 1            10
 jdk.GCTLABConfiguration                     1            12
 jdk.GCHeapConfiguration                     1            27
 jdk.YoungGenerationConfiguration            1            17
 jdk.ActiveRecording                         1           104
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
| JFR File | `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/REST-With-Spring-module6/profile.jfr` |
| Analysis Output | `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/REST-With-Spring-module6/jfr` |
| JVM+System CPU |  |

## Evidence Summary

| Event Type | Count | p50 | p95 | p99 | Max | Severity |
|------------|-------|-----|-----|-----|-----|----------|
| ThreadPark           |  28408 |     90.8ms |     1510ms |     2400ms |    39700ms | CRITICAL   |
| SocketRead           |    281 |     84.1ms |      118ms |      200ms |      204ms | CRITICAL   |
| JavaMonitorEnter     |   5018 |      379ms |     1310ms |     1790ms |     2000ms | CRITICAL   |
| GC Pause             |     22 |     21.6ms |      106ms |      109ms |      109ms | CONCERNING |

| Event Type | Count | Note | Severity |
|------------|-------|------|----------|
| ExecutionSample      |   1537 | CPU execution samples (not ms)                 | N/A        |
| ObjectAllocation     |  22421 | Allocation samples (not ms)                    | N/A        |
| Exception/Error      |    164 | Total exception events                         | CONCERNING |

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

**Severity:** CRITICAL (SocketRead p95 = 118ms)

**Evidence:**
- SocketRead events: 281
- SocketRead p95: 118ms, p99: 200ms, max: 204ms
- Top destinations:

**Interpretation:**
Socket reads are either infrequent or fast. External I/O is not strongly
implicated in this recording.

**Next experiment:**
1. Measure query / downstream call latency from application metrics.
2. Compare throughput with a stubbed/cached response path.
3. Check for N+1 calls, missing indexes, or oversized payloads.

### [H2] Blocking wait patterns may limit concurrency

**Confidence:** MEDIUM

**Severity:** CRITICAL (ThreadPark p95 = 1510ms)

**Evidence:**
- ThreadPark events: 28408
- ThreadPark p95: 1510ms, p99: 2400ms, max: 39700ms
- ExecutionSample events: 1537 (low CPU work suggests threads wait more than compute)
- Most parked class: java.util.concurrent.SynchronousQueue$Transferer

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

**Severity:** CONCERNING (GC Pause p99 = 109ms)

**Evidence:**
- GC Pause events: 22
- GC Pause p95: 106ms, p99: 109ms, max: 109ms
- Total GC pause time: 757.9ms

**Interpretation:**
GC pauses are elevated. This may contribute to tail latency and should be monitored.

**Next experiment:**
- If allocation rate is high (>20000 samples), monitor GC overhead % during longer runs.
- Otherwise: no GC experiment needed until higher confidence in H1/H2.

### [H4] CPU is NOT proven to be the bottleneck

**Confidence:** LOW (not proven)

**Severity:** N/A (JVM+System CPU = )

**Evidence:**
- ExecutionSample events: 1537
- JVM+System CPU load: 
- Hottest method: org.apache.catalina.core.ApplicationFilterChain.internalDoFilter

**Interpretation:**
Execution samples are relatively low. The JVM is not spending most of its time
on-CPU. This is consistent with an I/O-waiting or thread-parked state.

**Next experiment:**
1. Correlate ExecutionSample count with OS-level CPU % (already in JFR via CPULoad).
2. If CPU % is high and ExecutionSample is high -> profile hot methods (already done above).
3. If CPU % is low and ExecutionSample is low -> bottleneck is elsewhere (H1 or H2).

### [H5] Lock contention may be causing serial execution

**Confidence:** MEDIUM

**Severity:** CRITICAL (JavaMonitorEnter p95 = 1310ms)

**Evidence:**
- JavaMonitorEnter events: 5018
- Monitor wait p95: 1310ms, max: 2000ms
- Most contended monitors:
  - org.apache.coyote.AbstractProtocol$RecycledProcessors: 2353 events
  - java.util.HashMap: 1722 events
  - java.lang.Object: 665 events
  - org.apache.tomcat.util.collections.SynchronizedQueue: 135 events
  - sun.security.provider.HashDrbg: 121 events

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
- ObjectAllocationSample events: 22421
- Top allocating classes:
  - byte[]: 1901 samples
  - java.lang.Object[]: 1361 samples
  - java.util.HashMap: 1007 samples
  - java.util.HashMap$Node[]: 816 samples
  - java.util.ArrayList$Itr: 727 samples

**Interpretation:**
High allocation rate detected. This often correlates with GC pressure,
especially if temporary objects dominate (JSON parsing, DTO mapping, String concat).

**Next experiment:**
1. Profile allocation rate vs GC pause frequency over a longer run.
2. If correlated, reduce allocations (object pooling, reuse buffers, avoid autoboxing).

### [H7] Exception rate may indicate errors or control-flow abuse

**Confidence:** MEDIUM

**Severity:** CONCERNING (total exceptions = 164)

**Evidence:**
- Exception/Error events: 164
- Top thrown types (errors):
  - java.lang.NoSuchMethodError: 130 events
  - java.lang.IncompatibleClassChangeError: 19 events
  - java.lang.UnsatisfiedLinkError: 8 events
  - java.lang.NoClassDefFoundError: 6 events
  - org.apache.tomcat.jni.LibraryNotFoundError: 1 events

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
|    1796 | org.apache.catalina.core.ApplicationFilterChain.internalDoFilter |
|    1682 | org.apache.catalina.core.ApplicationFilterChain.doFilter |
|    1021 | jakarta.servlet.http.HttpServlet.service |
|    1019 | ... |
|     948 | org.springframework.web.filter.OncePerRequestFilter.doFilter |
|     921 | org.springframework.aop.framework.ReflectiveMethodInvocation.proceed |
|     588 | nonapi.io.github.classgraph.concurrency.SingletonMap.get |
|     548 | org.springframework.web.servlet.FrameworkServlet.processRequest |
|     523 | org.springframework.web.servlet.DispatcherServlet.doService |
|     517 | org.springframework.web.servlet.DispatcherServlet.doDispatch |
|     512 | org.springframework.web.servlet.FrameworkServlet.service |
|     464 | org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerAdapter.handleInternal |
|     460 | org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerAdapter.invokeHandlerMethod |
|     453 | org.springframework.web.servlet.mvc.method.AbstractHandlerMethodAdapter.handle |
|     446 | org.antlr.v4.runtime.atn.ParserATNSimulator.closure_ |

### Longest ThreadParks with Business Frame

| Duration | Thread | First Business Frame |
|---------:|--------|---------------------|
| 39700.00 ms | Common-Cleaner | jdk.internal.misc.InnocuousThread.run |
| 30100.00 ms | HikariPool-1 housekeeper | java.lang.Thread.run |
| 30000.00 ms | HikariPool-1 housekeeper | java.lang.Thread.run |
| 30000.00 ms | HikariPool-1 housekeeper | java.lang.Thread.run |
| 17300.00 ms | Cleaner-0 | jdk.internal.misc.InnocuousThread.run |
| 13500.00 ms | Cleaner-0 | jdk.internal.misc.InnocuousThread.run |
|  8820.00 ms | Cleaner-0 | jdk.internal.misc.InnocuousThread.run |
|  8520.00 ms | Catalina-utility-2 | org.apache.tomcat.util.threads.TaskThread$WrappingRunnable.run |
|  8520.00 ms | Catalina-utility-1 | org.apache.tomcat.util.threads.TaskThread$WrappingRunnable.run |
|  5000.00 ms | HikariPool-1 connection adder | java.lang.Thread.run |

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
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/REST-With-Spring-module6/jfr/cpu.txt` | ExecutionSample stack traces |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/REST-With-Spring-module6/jfr/alloc.txt` | ObjectAllocationSample events |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/REST-With-Spring-module6/jfr/io.txt` | SocketRead events |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/REST-With-Spring-module6/jfr/io_write.txt` | SocketWrite events |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/REST-With-Spring-module6/jfr/park.txt` | ThreadPark events |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/REST-With-Spring-module6/jfr/locks.txt` | JavaMonitorEnter events |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/REST-With-Spring-module6/jfr/gc.txt` | GCPhasePause events |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/REST-With-Spring-module6/jfr/exceptions.txt` | JavaErrorThrow events |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/REST-With-Spring-module6/jfr/exceptions2.txt` | ExceptionThrow events |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/REST-With-Spring-module6/jfr/cpu_load.txt` | CPULoad events |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/REST-With-Spring-module6/jfr/io_write.txt` | SocketWrite events (manual inspection) |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/REST-With-Spring-module6/jfr/jvm_info.txt` | JVMInformation events |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/REST-With-Spring-module6/jfr/os_info.txt` | OSInformation events |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/REST-With-Spring-module6/jfr/cpu_info.txt` | CPUInformation events |

---
Report complete. Full report saved to: `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/REST-With-Spring-module6/jfr/diagnosis-report.md`
