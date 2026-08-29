# JFR Hypothesis-Driven Diagnosis Report

> **Principle:** This report does not deliver a single "verdict."
> It presents multiple competing hypotheses, rates confidence from evidence,
> and prescribes the next experiment to strengthen or falsify each one.

---

## Recording Metadata


 Version: 2.1
 Chunks: 1
 Start: 2026-08-29 10:04:11 (UTC)
 Duration: 105 s

 Event Type                              Count  Size (bytes) 
=============================================================
 jdk.JavaMonitorEnter                    71738       1886945
 jdk.ObjectAllocationSample              24428        400470
 jdk.GCPhaseParallel                     13788        381772
 jdk.ThreadPark                           3796        144066
 jdk.NativeMethodSample                   2567         30086
 jdk.ExecutionSample                      1667         20406
 jdk.ThreadCPULoad                        1566         27311
 jdk.ModuleExport                         1538         16789
 jdk.PromoteObjectInNewPLAB               1444         26249
 jdk.Checkpoint                            622       4858533
 jdk.BooleanFlag                           505         15365
 jdk.TenuringDistribution                  390          4501
 jdk.Deoptimization                        372          9855
 jdk.ActiveSetting                         360         10391
 jdk.ThreadAllocationStatistics            235          3092
 jdk.ThreadStart                           223          3000
 jdk.OldObjectSample                       205          7118
 jdk.ExecuteVMOperation                    193          3125
 jdk.Compilation                           189          5481
 jdk.JavaErrorThrow                        185          9474
 jdk.LongFlag                              161          5220
 jdk.SocketWrite                           155          5296
 jdk.SafepointBegin                        136          2096
 jdk.UnsignedLongFlag                      132          4484
 jdk.MetaspaceChunkFreeListSummary         120          2216
 jdk.GCReferenceStatistics                 120          1295
 jdk.GCPhasePauseLevel1                    117          4719
 jdk.ResidentSetSize                       100          1758
 jdk.CPULoad                               100          1968
 jdk.JavaThreadStatistics                  100          1440
 jdk.ClassLoadingStatistics                100          1157
 jdk.CompilerStatistics                    100          3068
 jdk.ExceptionStatistics                   100          1449
 jdk.ModuleRequire                          89           890
 jdk.GCHeapSummary                          60          2324
 jdk.MetaspaceSummary                       60          3084
 jdk.G1HeapSummary                          60          1599
 jdk.GCPhasePauseLevel2                     54          1791
 jdk.PromoteObjectOutsidePLAB               52           821
 jdk.InitialSecurityProperty                49          2572
 jdk.NetworkUtilization                     35           494
 jdk.G1MMU                                  34           458
 jdk.GCCPUTime                              34           611
 jdk.GCPhasePause                           34           828
 jdk.NativeLibrary                          33          1837
 jdk.GarbageCollection                      30           705
 jdk.StringFlag                             28           957
 jdk.YoungGarbageCollection                 26           351
 jdk.G1GarbageCollection                    26           351
 jdk.EvacuationInformation                  26           741
 jdk.G1EvacuationYoungStatistics            26           724
 jdk.G1EvacuationOldStatistics              26           586
 jdk.G1BasicIHOP                            26          1046
 jdk.G1AdaptiveIHOP                         26          1089
 jdk.IntFlag                                25           931
 jdk.GCPhaseConcurrent                      24          1105
 jdk.DirectBufferStatistics                 20           488
 jdk.ThreadEnd                              18           172
 jdk.ThreadSleep                            18           366
 jdk.GCPhaseConcurrentLevel1                16           602
 jdk.InitialSystemProperty                  16           745
 jdk.DoubleFlag                             15           605
 jdk.UnsignedIntFlag                        14           473
 jdk.InitialEnvironmentVariable             12           645
 jdk.MetaspaceGCThreshold                   10           161
 jdk.ThreadContextSwitchRate                10           117
 jdk.SymbolTableStatistics                  10           387
 jdk.StringTableStatistics                  10           387
 jdk.ClassLoaderStatistics                   9           249
 jdk.SocketRead                              9           319
 jdk.CompilationFailure                      8           337
 jdk.GCHeapMemoryPoolUsage                   6           228
 jdk.MetaspaceAllocationFailure              6            88
 jdk.CodeCacheStatistics                     6           195
 jdk.OldGarbageCollection                    4            50
 jdk.ContainerCPUUsage                       3            86
 jdk.ContainerCPUThrottling                  3            64
 jdk.ContainerMemoryUsage                    3            68
 jdk.ContainerIOUsage                        3            50
 jdk.JavaMonitorWait                         2            52
 jdk.GCHeapMemoryUsage                       2            44
 jdk.PhysicalMemory                          2            34
 jdk.GCConfiguration                         2            51
 jdk.FileRead                                2            64
 jdk.Metadata                                1        103219
 jdk.ContainerConfiguration                  1            57
 jdk.Shutdown                                1            42
 jdk.JVMInformation                          1           435
 jdk.OSInformation                           1           250
 jdk.VirtualizationInformation               1            31
 jdk.SystemProcess                           1           278
 jdk.CPUInformation                          1          1487
 jdk.CPUTimeStampCounter                     1            19
 jdk.ThreadDump                              1       1954383
 jdk.CompilerConfiguration                   1            10
 jdk.CodeCacheConfiguration                  1            45
 jdk.GCSurvivorConfiguration                 1            10
 jdk.GCTLABConfiguration                     1            12
 jdk.GCHeapConfiguration                     1            27
 jdk.YoungGenerationConfiguration            1            17
 jdk.ActiveRecording                         1            96
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
| JFR File | `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/spring-petclinic/profile.jfr` |
| Analysis Output | `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/spring-petclinic/jfr` |
| JVM+System CPU |  |

## Evidence Summary

| Event Type | Count | p50 | p95 | p99 | Max | Severity |
|------------|-------|-----|-----|-----|-----|----------|
| ThreadPark           |   3796 |     83.5ms |     1000ms |     5110ms |    30000ms | CRITICAL   |
| SocketRead           |      9 |     71.7ms |      105ms |      105ms |      105ms | CRITICAL   |
| JavaMonitorEnter     |  71738 |      119ms |      407ms |      698ms |     1490ms | CRITICAL   |
| GC Pause             |     34 |     17.9ms |      114ms |      137ms |      137ms | CONCERNING |

| Event Type | Count | Note | Severity |
|------------|-------|------|----------|
| ExecutionSample      |   1667 | CPU execution samples (not ms)                 | N/A        |
| ObjectAllocation     |  24428 | Allocation samples (not ms)                    | N/A        |
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

**Severity:** CRITICAL (SocketRead p95 = 105ms)

**Evidence:**
- SocketRead events: 9
- SocketRead p95: 105ms, p99: 105ms, max: 105ms
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
- ThreadPark events: 3796
- ThreadPark p95: 1000ms, p99: 5110ms, max: 30000ms
- ExecutionSample events: 1667 (low CPU work suggests threads wait more than compute)
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

**Severity:** CONCERNING (GC Pause p99 = 137ms)

**Evidence:**
- GC Pause events: 34
- GC Pause p95: 114ms, p99: 137ms, max: 137ms
- Total GC pause time: 1251.4ms

**Interpretation:**
GC pauses are elevated. This may contribute to tail latency and should be monitored.

**Next experiment:**
- If allocation rate is high (>20000 samples), monitor GC overhead % during longer runs.
- Otherwise: no GC experiment needed until higher confidence in H1/H2.

### [H4] CPU is NOT proven to be the bottleneck

**Confidence:** LOW (not proven)

**Severity:** N/A (JVM+System CPU = )

**Evidence:**
- ExecutionSample events: 1667
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

**Severity:** CRITICAL (JavaMonitorEnter p95 = 407ms)

**Evidence:**
- JavaMonitorEnter events: 71738
- Monitor wait p95: 407ms, max: 1490ms
- Most contended monitors:
  - org.springframework.boot.loader.net.protocol.jar.UrlJarFiles$Cache: 71193 events
  - org.springframework.boot.loader.net.protocol.jar.UrlNestedJarFile: 207 events
  - java.util.Hashtable: 173 events
  - jdk.internal.loader.URLClassPath: 128 events
  - java.lang.Object: 16 events

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
- ObjectAllocationSample events: 24428
- Top allocating classes:
  - byte[]: 10441 samples
  - java.lang.String: 3934 samples
  - java.net.URL: 3843 samples
  - org.springframework.boot.loader.net.protocol.jar.JarFileUrlKey: 2306 samples
  - java.lang.Object[]: 388 samples

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
|    2369 | org.apache.catalina.core.ApplicationFilterChain.doFilter |
|    1377 | ... |
|    1129 | jakarta.servlet.http.HttpServlet.service |
|    1073 | org.springframework.web.filter.OncePerRequestFilter.doFilter |
|     964 | org.thymeleaf.engine.ProcessorTemplateHandler.handleOpenElement |
|     960 | org.thymeleaf.engine.OpenElementTag.beHandled |
|     870 | org.thymeleaf.TemplateEngine.process |
|     860 | org.thymeleaf.engine.Model.process |
|     760 | org.springframework.web.servlet.resource.DefaultResourceResolverChain.resolveUrlPath |
|     760 | org.springframework.web.servlet.resource.AbstractResourceResolver.resolveUrlPath |
|     632 | org.springframework.web.servlet.DispatcherServlet.doDispatch |
|     623 | org.springframework.web.servlet.FrameworkServlet.processRequest |
|     622 | org.springframework.web.servlet.DispatcherServlet.doService |
|     572 | org.springframework.web.servlet.FrameworkServlet.service |
|     555 | org.springframework.web.servlet.FrameworkServlet.doGet |

### Longest ThreadParks with Business Frame

| Duration | Thread | First Business Frame |
|---------:|--------|---------------------|
| 30000.00 ms | HikariPool-1:housekeeper | java.lang.Thread.run |
| 30000.00 ms | HikariPool-1:housekeeper | java.lang.Thread.run |
| 30000.00 ms | HikariPool-1:housekeeper | java.lang.Thread.run |
|  9980.00 ms | Common-Cleaner | jdk.internal.misc.InnocuousThread.run |
|  9980.00 ms | Cleaner-0 | jdk.internal.misc.InnocuousThread.run |
|  8100.00 ms | Common-Cleaner | jdk.internal.misc.InnocuousThread.run |
|  8100.00 ms | Cleaner-0 | jdk.internal.misc.InnocuousThread.run |
|  7040.00 ms | Catalina-utility-2 | org.apache.tomcat.util.threads.TaskThread$WrappingRunnable.run |
|  7040.00 ms | Catalina-utility-1 | org.apache.tomcat.util.threads.TaskThread$WrappingRunnable.run |
|  6400.00 ms | http-nio-8080-exec-9 | org.apache.tomcat.util.threads.TaskQueue.take |

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
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/spring-petclinic/jfr/cpu.txt` | ExecutionSample stack traces |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/spring-petclinic/jfr/alloc.txt` | ObjectAllocationSample events |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/spring-petclinic/jfr/io.txt` | SocketRead events |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/spring-petclinic/jfr/io_write.txt` | SocketWrite events |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/spring-petclinic/jfr/park.txt` | ThreadPark events |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/spring-petclinic/jfr/locks.txt` | JavaMonitorEnter events |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/spring-petclinic/jfr/gc.txt` | GCPhasePause events |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/spring-petclinic/jfr/exceptions.txt` | JavaErrorThrow events |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/spring-petclinic/jfr/exceptions2.txt` | ExceptionThrow events |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/spring-petclinic/jfr/cpu_load.txt` | CPULoad events |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/spring-petclinic/jfr/io_write.txt` | SocketWrite events (manual inspection) |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/spring-petclinic/jfr/jvm_info.txt` | JVMInformation events |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/spring-petclinic/jfr/os_info.txt` | OSInformation events |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/spring-petclinic/jfr/cpu_info.txt` | CPUInformation events |

---
Report complete. Full report saved to: `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/spring-petclinic/jfr/diagnosis-report.md`
