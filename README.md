# Omarchy Hardware Stats

A compact hardware and network statistics widget for the Omarchy Shell bar.

```text
 12%    38%   󰢮 4%    1.2M    8.4M
```

It displays total CPU utilization, RAM utilization, available GPU utilization,
and live upload/download rates. GPU telemetry is detected automatically and is
hidden when unavailable.

## Install

```bash
omarchy plugin add https://github.com/leomoon-studios/omarchy-hw-stats --enable --yes
omarchy bar move leomoon-studios.omarchy-hw-stats --section center --after omarchy.weather
```

## Remove

```bash
omarchy plugin remove leomoon-studios.omarchy-hw-stats --yes
```

The plugin reads local counters from `/proc` and `/sys`. NVIDIA utilization is
queried through `nvidia-smi` when available. It does not require root access or
run a separate background daemon.

## Settings

- `refreshIntervalSec`: refresh interval from 1 to 60 seconds; default `2`.
- `networkInterface`: interface name or `auto`; default `auto`.

With automatic interface selection, the normal default-route interface is
used. This avoids counting VPN tunnel traffic and its physical transport twice.

## Requirements

- Omarchy 4
- Python 3
- Optional: `nvidia-smi` for NVIDIA utilization

## License

MIT
