# eBPF monitor recovery and verification

## Behavior

- Build three separate ELF objects: `cpu`, `fps-ring`, and `fps-perf`. The CPU object creates no FPS map.
- Fall back to PerfEventArray when RingBuf creation returns `EINVAL`, `EOPNOTSUPP`, or `ENOSYS`. Keep the full error chain for permission or memory failures.
- Report FPS initialization after registering the event buffer. Retry failed PID attachments every two seconds and reset the sample baseline on a PID switch.
- Attach libgui probes in this order: the Android 16 and earlier `Surface::queueBuffer(ANativeWindowBuffer*, int[, SurfaceQueueBufferOutput*])` overload, the Android 16 backported `sp<GraphicBuffer>&&` overload, the Android 17 `sp<GraphicBuffer>` and `sp<Fence>` overload, and finally the stable `ANativeWindow` entry point `hook_queueBuffer`. Preserve this order because Android 16 can expose the Android 17 overload outside the active rendering path. Log each failed candidate in full and report attachment failure only when all candidates fail.
- RingBuf and perf share the same 16-byte event format with explicitly initialized padding. The perf reader handles records spanning buffers, timestamp ordering across CPUs, lost events, and CPUs coming online or going offline.
- Emit only new frame intervals. Index CPU samples by CPU ID and calculate foreground load from the busiest thread using deltas between complete cumulative snapshots.
- Start CLG after the first valid CPU sample. FAS also needs a valid frame from the target PID. Release frequency control when the monitor exits or goes more than two seconds without a valid sample.
- Restore the previous governor and frequency limits before handing control to another controller. Keep failed snapshots for retry. FAS also attempts to restore perfmgr settings on exit.
- Log the kernel version, page size, and errno for failed memlock setup. Include full error chains for monitor failures and report frequencies in kHz.

## Automated checks

Use Linux with nightly Rust, rust-src, and bpf-linker. CI verifies the pinned SHA-256 of the official Linux x86_64 musl bpf-linker 0.11.1 binary and adds it to the PATH for tests and Android packaging. For local builds, install it using the [upstream instructions](https://github.com/aya-rs/bpf-linker#installation) and add it to PATH.

```sh
cargo test -p yumi --bin yumi --locked
```

Tests cover frame decoding, duplicate, out-of-order, and stale frames, baseline resets on PID switches, CPU pending-time deltas, monitor timeout recovery, RingBuf fallback errors, and program and map isolation in the real ELF files.

The original Windows validation checked all three `bpfel-unknown-none` release targets and type-checked the Android userspace code and tests with placeholder BPF bytes. Six platform-independent sampling and monitor-health tests passed, along with the build script compilation and `git diff --check`. Full ELF linking, module packaging, loading, and execution of the fallback and real-ELF isolation tests require the Linux tooling or a device.

## On-device verification

1. On a device with RingBuf support, check that CPU and FPS initialize independently and that FPS selects RingBuf.
2. On a device with perf/uprobe support but no RingBuf, check that FPS logs the RingBuf errno and selects PerfEventArray. The CPU monitor should produce no RingBuf errors.
3. Start without a foreground PID, then open an app. Verify attachment and continued frame delivery. Confirm that an attachment can retry against the same PID.
4. Switch games, restart a process with the same package name, and turn the screen off and on. Verify that PID, app profile, and frequency controller stay synchronized.
5. Stop rendering for more than two seconds. Verify that FAS releases control and stops emitting cached frames. Resume rendering and check that monitoring establishes a new baseline.
6. Inject a CPU map read error or stop CPU samples. Verify that CLG and any FAS controller relying on CPU data release control. Compare the governor, `scaling_min_freq`, and `scaling_max_freq` for every policy against the original snapshot.
7. Confirm that frequency logs use kHz. Check sample logs and live sysfs values alongside initialization messages.

These device checks verify kernel verifier behavior, SELinux, perf permissions, libgui symbols, and sysfs write restrictions. Preserve the full error chain if a check fails.
