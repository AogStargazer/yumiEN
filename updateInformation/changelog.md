# Changelog

## v2.0.2

### New features

- **CLG** adds eight settings for frequency scaling.
  - `headroom_ramp` sets the headroom transition width near `up_threshold` (default 0.15).
  - `up_jump_threshold` sets the minimum jump for fast upscaling (default 0.35).
  - `slow_up_scale` sets the minimum upscaling rate within the hysteresis band (default 0.02).
  - `slow_down_scale` scales downclocking within the hysteresis band (default 0.5).
  - `down_fast_threshold` and `down_fast_mult` set the load threshold and multiplier for rapid downclocking.
  - `spike_jump_threshold` and `spike_decay` set the threshold and attenuation for single-tick spikes.

### Improvements

- **CLG** can downclock when the target falls below the current frequency inside the hysteresis band, using slow, normal, and fast rates.
- **CLG** ramps headroom linearly near `up_threshold` to avoid frequency oscillation.
- **CLG** upscales faster as utilization approaches `up_threshold`.
- **CLG** attenuates single-tick load spikes above the threshold. Sustained load takes full effect on the next tick.
- **CLG** downclocks immediately below `down_fast_threshold`, bypassing the confirmation delay.
- **CLG** reloads configuration in place when modes change or the screen turns off or on.
- **AppDetect** suppresses redundant mode-change events such as `balance -> balance` after configuration reloads and screen wake.

### Fixes

- **CLG** now applies YAML `cpu_load_governor` settings, including `enabled`, after fixing a deserialization mismatch.
- **CLG** normalizes invalid bounds and NaN or infinite values to prevent `f32::clamp` panics.
- **CLG** snapshots and restores the previous governor and frequency limits on release. Failed reads skip fallback writes, and failed restores are retried.
- **Scheduler** logs IPC panics and releases CPU control. The configuration watcher backs off after failures.
- **Scheduler** leaves CLG disabled for unknown or empty mode names.
- **i18n** falls back to English when the language tag is invalid.
- **FAS** normalizes invalid performance bounds and fast-decay step limits to prevent clamp panics.
- **FAS** lets floor rescue bypass `max_inc` to recover from `perf_floor`.
- **FAS** filters zero, negative, or NaN frame-rate targets before they can affect PID coefficients.

## v2.0.1

### New features

- **FPS monitoring** uses one eBPF probe instance with multiple PID attachments so PID switches avoid delays and lost frames.

### Improvements

- **CLG** adds `up_rate_limit_ticks` to require consecutive high-load ticks before upscaling (default 2).
- **CLG** raises the jump threshold from 0.20 to 0.35 to reduce reactions to brief spikes.
- **CLG** reduces the creep coefficient from 0.05 to 0.02 to limit upscaling during low-load fluctuations.
- **CLG** applies headroom only when utilization is at or above `up_threshold`.
