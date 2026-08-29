# JFR Hypothesis-Driven Diagnosis Report

> **Principle:** This report does not deliver a single "verdict."
> It presents multiple competing hypotheses, rates confidence from evidence,
> and prescribes the next experiment to strengthen or falsify each one.

---

## Recording Metadata


 Version: 2.1
 Chunks: 1
 Start: 2026-08-29 10:21:06 (UTC)
 Duration: 99 s

 Event Type                              Count  Size (bytes) 
=============================================================
 jdk.ObjectAllocationSample               9453        148712
 jdk.GCPhaseParallel                      5362        147692
 jdk.NativeMethodSample                   3396         39624
 jdk.ExecutionSample                      1603         18854
 jdk.ModuleExport                         1041         11332
 jdk.PromoteObjectInNewPLAB                559          9590
 jdk.Checkpoint                            543       4970408
 jdk.BooleanFlag                           505         15365
 jdk.ActiveSetting                         372         10751
 jdk.Deoptimization                        234          6134
 jdk.TenuringDistribution                  195          2142
 jdk.JavaErrorThrow                        173          9638
 jdk.ExecuteVMOperation                    167          2646
 jdk.LongFlag                              161          5220
 jdk.Compilation                           146          4153
 jdk.UnsignedLongFlag                      132          4484
 jdk.SafepointBegin                        127          1843
 jdk.ThreadCPULoad                         119          1976
 jdk.ResidentSetSize                        97          1703
 jdk.CPULoad                                97          1907
 jdk.JavaThreadStatistics                   97          1131
 jdk.ClassLoadingStatistics                 97          1034
 jdk.CompilerStatistics                     97          2862
 jdk.ExceptionStatistics                    97          1398
 jdk.ModuleRequire                          86           860
 jdk.PromoteObjectOutsidePLAB               64           984
 jdk.MetaspaceChunkFreeListSummary          60          1096
 jdk.GCReferenceStatistics                  60           637
 jdk.GCPhasePauseLevel1                     57          2260
 jdk.InitialSecurityProperty                49          2572
 jdk.OldObjectSample                        41          1385
 jdk.ThreadAllocationStatistics             39           435
 jdk.NetworkUtilization                     36           522
 jdk.NativeLibrary                          33          1869
 jdk.GCHeapSummary                          30          1152
 jdk.MetaspaceSummary                       30          1534
 jdk.G1HeapSummary                          30           779
 jdk.StringFlag                             28           957
 jdk.ThreadPark                             27          1025
 jdk.GCPhasePauseLevel2                     27           891
 jdk.IntFlag                                25           931
 jdk.ThreadStart                            23           277
 jdk.DirectBufferStatistics                 19           486
 jdk.G1MMU                                  17           225
 jdk.GCCPUTime                              17           302
 jdk.GCPhasePause                           17           409
 jdk.InitialSystemProperty                  16           745
 jdk.GarbageCollection                      15           349
 jdk.InitialEnvironmentVariable             15           798
 jdk.DoubleFlag                             15           605
 jdk.UnsignedIntFlag                        14           473
 jdk.YoungGarbageCollection                 13           173
 jdk.G1GarbageCollection                    13           173
 jdk.EvacuationInformation                  13           357
 jdk.G1EvacuationYoungStatistics            13           366
 jdk.G1EvacuationOldStatistics              13           269
 jdk.G1BasicIHOP                            13           506
 jdk.G1AdaptiveIHOP                         13           530
 jdk.GCPhaseConcurrent                      12           548
 jdk.ThreadEnd                              10            94
 jdk.ThreadContextSwitchRate                 9           105
 jdk.SymbolTableStatistics                   9           348
 jdk.StringTableStatistics                   9           348
 jdk.GCPhaseConcurrentLevel1                 8           300
 jdk.GCHeapMemoryPoolUsage                   6           227
 jdk.CompilationFailure                      6           248
 jdk.ClassLoaderStatistics                   6           176
 jdk.CodeCacheStatistics                     6           195
 jdk.MetaspaceGCThreshold                    5            80
 jdk.MetaspaceAllocationFailure              4            58
 jdk.ContainerCPUUsage                       3            86
 jdk.ContainerCPUThrottling                  3            65
 jdk.ContainerMemoryUsage                    3            68
 jdk.ContainerIOUsage                        3            50
 jdk.Metadata                                2        209587
 jdk.JavaMonitorEnter                        2            48
 jdk.GCHeapMemoryUsage                       2            43
 jdk.OldGarbageCollection                    2            24
 jdk.PhysicalMemory                          2            34
 jdk.GCConfiguration                         2            51
 jdk.FileRead                                2            64
 jdk.ContainerConfiguration                  1            57
 jdk.Shutdown                                1            41
 jdk.JVMInformation                          1           435
 jdk.OSInformation                           1           250
 jdk.VirtualizationInformation               1            31
 jdk.SystemProcess                           1           278
 jdk.CPUInformation                          1          1487
 jdk.CPUTimeStampCounter                     1            19
 jdk.ThreadDump                              1         62973
 jdk.CompilerConfiguration                   1            10
 jdk.CodeCacheConfiguration                  1            45
 jdk.GCSurvivorConfiguration                 1            10
 jdk.GCTLABConfiguration                     1            12
 jdk.GCHeapConfiguration                     1            27
 jdk.YoungGenerationConfiguration            1            17
 jdk.FinalizerStatistics                     1            17
 jdk.ActiveRecording                         1            96
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
 io.netty.AllocateChunk                      0             0
 jdk.ClassLoad                               0             0
 jdk.ClassDefine                             0             0
 jdk.ClassRedefinition                       0             0
 jdk.RedefineClasses                         0             0
 jdk.RetransformClasses                      0             0
 jdk.ClassUnload                             0             0
 jdk.IntFlagChanged                          0             0
 jdk.UnsignedIntFlagChanged                  0             0
 jdk.LongFlagChanged                         0             0
 io.netty.AllocateBuffer                     0             0
 jdk.UnsignedLongFlagChanged                 0             0
 jdk.DoubleFlagChanged                       0             0
 jdk.BooleanFlagChanged                      0             0
 jdk.StringFlagChanged                       0             0
 jdk.MetaspaceOOM                            0             0
 io.netty.FreeBuffer                         0             0
 io.netty.ReallocateBuffer                   0             0
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
 jdk.JavaAgent                               0             0
 jdk.NativeAgent                             0             0
 jdk.FileForce                               0             0
 jdk.FileWrite                               0             0
 jdk.SocketRead                              0             0
 jdk.SocketWrite                             0             0
 jdk.JavaExceptionThrow                      0             0
 jdk.Deserialization                         0             0
 jdk.ProcessStart                            0             0
 jdk.SecurityPropertyModification            0             0
 jdk.SecurityProviderService                 0             0
 jdk.ThreadSleep                             0             0
 jdk.TLSHandshake                            0             0
 jdk.VirtualThreadStart                      0             0
 jdk.VirtualThreadEnd                        0             0
 jdk.VirtualThreadPinned                     0             0
 jdk.VirtualThreadSubmitFailed               0             0
 jdk.X509Certificate                         0             0
 jdk.X509Validation                          0             0

| Metric | Value |
|--------|-------|
| JFR File | `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/practice-webflux/profile.jfr` |
| Analysis Output | `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/practice-webflux/jfr` |
| JVM+System CPU |  |

## Evidence Summary

| Event Type | Count | p50 | p95 | p99 | Max | Severity |
|------------|-------|-----|-----|-----|-----|----------|
| ThreadPark           |     27 |      877ms |    27700ms |    38100ms |    38100ms | CRITICAL   |
| JavaMonitorEnter     |      2 |     38.6ms |     38.6ms |     38.6ms |     38.6ms | CRITICAL   |
| GC Pause             |     17 |     26.3ms |     90.9ms |     90.9ms |     90.9ms | CONCERNING |

| Event Type | Count | Note | Severity |
|------------|-------|------|----------|
| ExecutionSample      |   1603 | CPU execution samples (not ms)                 | N/A        |
| ObjectAllocation     |   9453 | Allocation samples (not ms)                    | N/A        |
| Exception/Error      |    173 | Total exception events                         | CONCERNING |

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

**Severity:** N/A (SocketRead p95 = 0ms)

**Evidence:**
- SocketRead events: 0
- SocketRead p95: 0ms, p99: 0ms, max: 0ms

**Interpretation:**
Socket reads are either infrequent or fast. External I/O is not strongly
implicated in this recording.

**Next experiment:**
1. Measure query / downstream call latency from application metrics.
2. Compare throughput with a stubbed/cached response path.
3. Check for N+1 calls, missing indexes, or oversized payloads.

### [H2] Blocking wait patterns may limit concurrency

**Confidence:** NOT PROVEN

**Severity:** CRITICAL (ThreadPark p95 = 27700ms)

**Evidence:**
- ThreadPark events: 27
- ThreadPark p95: 27700ms, p99: 38100ms, max: 38100ms
- ExecutionSample events: 1603 (low CPU work suggests threads wait more than compute)
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

**Severity:** CONCERNING (GC Pause p99 = 90.9ms)

**Evidence:**
- GC Pause events: 17
- GC Pause p95: 90.9ms, p99: 90.9ms, max: 90.9ms
- Total GC pause time: 593.5ms

**Interpretation:**
GC pauses are elevated. This may contribute to tail latency and should be monitored.

**Next experiment:**
- If allocation rate is high (>20000 samples), monitor GC overhead % during longer runs.
- Otherwise: no GC experiment needed until higher confidence in H1/H2.

### [H4] CPU is NOT proven to be the bottleneck

**Confidence:** LOW (not proven)

**Severity:** N/A (JVM+System CPU = )

**Evidence:**
- ExecutionSample events: 1603
- JVM+System CPU load: 
- Hottest method: ...

**Interpretation:**
Execution samples are relatively low. The JVM is not spending most of its time
on-CPU. This is consistent with an I/O-waiting or thread-parked state.

**Next experiment:**
1. Correlate ExecutionSample count with OS-level CPU % (already in JFR via CPULoad).
2. If CPU % is high and ExecutionSample is high -> profile hot methods (already done above).
3. If CPU % is low and ExecutionSample is low -> bottleneck is elsewhere (H1 or H2).

### [H5] Lock contention may be causing serial execution

**Confidence:** NOT PROVEN

**Severity:** CRITICAL (JavaMonitorEnter p95 = 38.6ms)

**Evidence:**
- JavaMonitorEnter events: 2
- Monitor wait p95: 38.6ms, max: 38.6ms
- Most contended monitors:
  - java.lang.Object: 2 events

**Interpretation:**
Lock contention is not dominant in this recording.

**Next experiment:**
1. Identify which business methods acquire the contended monitors.
2. Replace synchronized blocks with java.util.concurrent primitives if possible.
3. Measure throughput before/after.

### [H6] Allocation pressure may be causing GC churn

**Confidence:** LOW

**Evidence:**
- ObjectAllocationSample events: 9453
- Top allocating classes:
  - byte[]: 1252 samples
  - java.lang.Object[]: 859 samples
  - java.lang.String: 418 samples
  - java.util.concurrent.ConcurrentHashMap$Node[]: 355 samples
  - long[]: 169 samples

**Interpretation:**
Allocation rate is moderate. Not a primary concern unless GC pauses grow.

**Next experiment:**
1. Profile allocation rate vs GC pause frequency over a longer run.
2. If correlated, reduce allocations (object pooling, reuse buffers, avoid autoboxing).

### [H7] Exception rate may indicate errors or control-flow abuse

**Confidence:** MEDIUM

**Severity:** CONCERNING (total exceptions = 173)

**Evidence:**
- Exception/Error events: 173
- Top thrown types (errors):
  - java.lang.NoSuchMethodError: 141 events
  - java.lang.IncompatibleClassChangeError: 26 events
  - java.lang.UnsatisfiedLinkError: 3 events
  - io.netty.util.Signal: 2 events
  - reactor.core.Exceptions$StaticThrowable: 1 events

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
|    1090 | ... |
|    1058 | reactor.core.publisher.MonoFlatMap$FlatMapMain.onNext |
|     933 | reactor.core.publisher.Mono.subscribe |
|     927 | io.netty.channel.AbstractChannelHandlerContext.fireChannelRead |
|     791 | reactor.core.publisher.InternalMonoOperator.subscribe |
|     760 | reactor.core.publisher.Operators$MultiSubscriptionSubscriber.onComplete |
|     703 | reactor.core.publisher.FluxMap$MapSubscriber.onNext |
|     617 | reactor.core.publisher.FluxOnErrorResume$ResumeSubscriber.onNext |
|     589 | reactor.core.publisher.MonoIgnoreThen$ThenIgnoreMain.subscribeNext |
|     570 | reactor.core.publisher.Operators.complete |
|     543 | reactor.core.publisher.MonoIgnoreThen$ThenIgnoreMain.onComplete |
|     527 | reactor.core.publisher.MonoFlatMap$FlatMapMain.secondComplete |
|     507 | reactor.core.publisher.Operators$ScalarSubscription.request |
|     488 | reactor.core.publisher.MonoEmpty.subscribe |
|     412 | io.netty.handler.codec.ByteToMessageDecoder.fireChannelRead |

### Longest ThreadParks with Business Frame

| Duration | Thread | First Business Frame |
|---------:|--------|---------------------|
| 38100.00 ms | Common-Cleaner | jdk.internal.misc.InnocuousThread.run |
| 27700.00 ms | Cleaner-0 | jdk.internal.misc.InnocuousThread.run |
| 26300.00 ms | Common-Cleaner | jdk.internal.misc.InnocuousThread.run |
| 18500.00 ms | Common-Cleaner | jdk.internal.misc.InnocuousThread.run |
| 17200.00 ms | Cleaner-0 | jdk.internal.misc.InnocuousThread.run |
| 14300.00 ms | Cleaner-0 | jdk.internal.misc.InnocuousThread.run |
| 12000.00 ms | Cleaner-0 | jdk.internal.misc.InnocuousThread.run |
| 11700.00 ms | Cleaner-0 | jdk.internal.misc.InnocuousThread.run |
|  7160.00 ms | Cleaner-0 | jdk.internal.misc.InnocuousThread.run |
|  1560.00 ms | Cleaner-0 | jdk.internal.misc.InnocuousThread.run |

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
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/practice-webflux/jfr/cpu.txt` | ExecutionSample stack traces |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/practice-webflux/jfr/alloc.txt` | ObjectAllocationSample events |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/practice-webflux/jfr/io.txt` | SocketRead events |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/practice-webflux/jfr/io_write.txt` | SocketWrite events |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/practice-webflux/jfr/park.txt` | ThreadPark events |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/practice-webflux/jfr/locks.txt` | JavaMonitorEnter events |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/practice-webflux/jfr/gc.txt` | GCPhasePause events |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/practice-webflux/jfr/exceptions.txt` | JavaErrorThrow events |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/practice-webflux/jfr/exceptions2.txt` | ExceptionThrow events |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/practice-webflux/jfr/cpu_load.txt` | CPULoad events |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/practice-webflux/jfr/io_write.txt` | SocketWrite events (manual inspection) |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/practice-webflux/jfr/jvm_info.txt` | JVMInformation events |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/practice-webflux/jfr/os_info.txt` | OSInformation events |
| `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/practice-webflux/jfr/cpu_info.txt` | CPUInformation events |

---
Report complete. Full report saved to: `/c/study/java-backend-quality-analyzer/evidence/advanced/h3/practice-webflux/jfr/diagnosis-report.md`
