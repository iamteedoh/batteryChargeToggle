# Laptop Battery Charge Toggle (Linux)

[![CI](https://github.com/iamteedoh/batteryChargeToggle/actions/workflows/ci.yml/badge.svg)](https://github.com/iamteedoh/batteryChargeToggle/actions/workflows/ci.yml)
![License](https://img.shields.io/badge/license-GPL--3.0-blue)
[![GitHub Sponsors](https://img.shields.io/badge/GitHub%20Sponsors-%E2%9D%A4-ea4aaa?logo=githubsponsors)](https://github.com/sponsors/iamteedoh)
[![Patreon](https://img.shields.io/badge/Patreon-support-f96854?logo=patreon)](https://patreon.com/iamteedoh)
[![Buy Me a Coffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-support-ffdd00?logo=buymeacoffee&logoColor=black)](https://buymeacoffee.com/iamteedoh)

A Bash tool for Linux laptops that switches between battery charging modes and
displays a detailed, colorful battery report — complete with an ASCII title
banner and a live charge gauge. It runs both interactively (a menu) and
non-interactively (flags), so it fits scripts, keybindings, and casual use
alike.

Charging modes:

- **Longevity Mode** — Limits charging between 75%-80% to preserve long-term battery health.
- **Balanced Mode** — Charges between 60%-80%, an everyday middle ground between health and runtime.
- **Full Charge Mode** — Allows charging up to 100% for when you need maximum battery life on the go.
- **Status Mode** — View battery stats without changing anything (works on all hardware).

## How It Works

The script reads and writes to the Linux kernel's battery charge threshold files located at:

```
/sys/class/power_supply/BAT0/charge_start_threshold
/sys/class/power_supply/BAT0/charge_stop_threshold
```

When run with no options, the script toggles based on the current
`charge_stop_threshold`:

- If the stop threshold is **80** (Longevity Mode is active), it switches to **Full Charge Mode** by setting the start threshold to 0 and the stop threshold to 100.
- Otherwise, it switches to **Longevity Mode** by setting the start threshold to 75 and the stop threshold to 80.

To reach a specific mode directly (including Balanced), use `--mode`, or open
the interactive menu with `-i`/`--interactive` and pick one. After changing the
thresholds, the script prints a detailed battery report including:

- Current charging status (Charging, Discharging, Full, etc.)
- Current charge percentage
- Charge cycle count
- Capacity levels in Wh or mAh (current, full capacity, design capacity)
- Battery health percentage (full capacity vs. design capacity)
- Active charge start/stop thresholds (when supported)

You can also run the script with `-s` or `--status` to view the battery report without toggling. This works on all Linux hardware, including laptops that don't support charge thresholds.

## Requirements

- **Linux** with a battery that exposes sysfs battery info (`/sys/class/power_supply/BAT0/`)
- **Root privileges** — Required for toggling charge thresholds (not needed for `--status`). The script automatically re-runs itself with `sudo` if not already root
- **Bash** shell
- **awk** (for unit conversion calculations)

### Compatible Hardware

#### Battery Status (`--status`)

The status report works on any Linux laptop with a `/sys/class/power_supply/BAT0/` directory, including:

- **MacBooks running Linux** — tested on Fedora on a MacBook Pro
- ThinkPad, ASUS, Huawei, Dell, HP, and other PC laptops

The script automatically detects whether capacity is reported in energy (µWh) or charge (µAh) units and displays values in Wh or mAh accordingly.

#### Charge Threshold Toggling

Toggling between Longevity and Full Charge modes requires kernel-level charge threshold support. Common supported brands include:

- ThinkPad (via `thinkpad_acpi` or `natacpi`)
- ASUS (via `asus-nb-wmi` or `asus_wmi`)
- Huawei (via `huawei-wmi`)
- Other laptops with kernel-level charge threshold support

> **Note:** MacBooks running Linux do not support charge threshold toggling. The T2/Apple SMC chip controls charging and does not expose threshold files to the Linux kernel. You can still use `--status` to view battery stats.

You can verify threshold support by checking if these files exist:

```bash
ls /sys/class/power_supply/BAT0/charge_start_threshold
ls /sys/class/power_supply/BAT0/charge_stop_threshold
```

If these files are not present, the script will still work in `--status` mode but will display an error if you attempt to toggle.

## Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/iamteedoh/batteryChargeToggle.git
   cd batteryChargeToggle
   ```

2. Make the script executable:

   ```bash
   chmod +x battery-toggle.sh
   ```

3. (Optional) Copy it to a directory in your PATH for easy access:

   ```bash
   sudo cp battery-toggle.sh /usr/local/bin/battery-toggle
   ```

## Usage

```bash
./battery-toggle.sh              # toggle Longevity <-> Full Charge, then report
./battery-toggle.sh -s           # show the battery report without changing anything
./battery-toggle.sh --status     # (same as -s)
./battery-toggle.sh -i           # open the interactive menu
./battery-toggle.sh --mode balanced   # set a specific mode: longevity | balanced | full
./battery-toggle.sh --no-color   # disable colored output (also honors NO_COLOR)
./battery-toggle.sh --help       # show usage and exit
```

### Options

| Option | Description |
| --- | --- |
| _(none)_ | Toggle between Longevity and Full Charge, then print the report |
| `-s`, `--status` | Show the battery report without changing anything (no root needed) |
| `-i`, `--interactive` | Open the interactive menu to choose a mode |
| `-m`, `--mode MODE` | Set a specific mode: `longevity`, `balanced`, or `full` |
| `--no-color` | Disable colored output |
| `-h`, `--help` | Show help and exit |

Changing modes (toggle, `--mode`, or picking a mode in the menu) requires root
access to write to sysfs files. If not run as root, the script automatically
re-runs itself with `sudo` and prompts for your password. Colored output is
enabled on a terminal and automatically disabled when output is piped, when
`--no-color` is passed, or when the `NO_COLOR` environment variable is set.

### Example Output

Running the script shows a title banner, the active mode, and a battery report
with a colored charge gauge. For example, when switching to Longevity Mode:

```
   ____    _  _____ _____ _____ ______   __
  | __ )  / \|_   _|_   _| ____|  _ \ \ / /
  |  _ \ / _ \ | |   | | |  _| | |_) \ V /
  | |_) / ___ \| |   | | | |___|  _ < | |
  |____/_/   \_\_|   |_| |_____|_| \_\|_|
  Toggle laptop charge thresholds and view a battery report.

  ▸ Mode: Longevity
  Charging between 75%-80% — preserving battery health.

  Battery Report
  ────────────────────────────────────────────
  Status:            Charging
  Charge:            [███████████████░░░░░░░] 72%
  Charge cycles:     145
  Current capacity:  38.50 Wh
  Full capacity:     51.20 Wh
  Design capacity:   57.00 Wh
  Health:            89.8%
  Start threshold:   75%
  Stop threshold:    80%
  ────────────────────────────────────────────
```

### Interactive Menu

Run `./battery-toggle.sh -i` for a menu that shows the current battery report
and lets you pick a mode, refresh the report, or quit:

```
  Select an option:
    1) Longevity    (75-80%)   preserve battery health
    2) Balanced     (60-80%)   everyday middle ground
    3) Full Charge  (0-100%)   maximum runtime
    4) Refresh battery report
    5) Quit
  Choice:
```

On hardware without charge threshold support (e.g., a MacBook running Linux),
the menu still shows the battery report and refresh/quit options, and `--status`
works everywhere:

```
  Battery Report
  ────────────────────────────────────────────
  Status:            Full
  Charge:            [███████████████████░░░] 90%
  Charge cycles:     328
  Current capacity:  4800 mAh
  Full capacity:     5210 mAh
  Design capacity:   5765 mAh
  Health:            90.4%
  ────────────────────────────────────────────
```

### Tips

- **Daily use**: Keep Longevity Mode enabled to extend your battery's lifespan. Lithium-ion batteries degrade faster when kept at high charge levels.
- **Before travel**: Switch to Full Charge Mode and plug in to get a full 100% charge before unplugging.
- **Automation**: You can bind the script to a keyboard shortcut or create a desktop launcher for quick toggling.
- **Thresholds are not persistent**: These sysfs values reset on reboot. To make Longevity Mode the default at boot, add the script to your startup routine or use a systemd service/udev rule.

## Battery Recalibration

If you notice your battery percentage behaving erratically — such as suddenly jumping from ~50% down to single digits — your battery's fuel gauge has likely drifted. The fuel gauge is a chip inside the battery that estimates remaining capacity based on a learned voltage curve. Over time, as the battery ages and internal resistance increases, that curve becomes inaccurate, and the reported percentage no longer reflects reality.

To fix this, you can perform a full recalibration using TLP:

```bash
sudo tlp recalibrate BAT0
```

This command performs a complete discharge-recharge cycle to reset the fuel gauge:

1. Sets charge thresholds to 100% so the battery charges fully
2. Waits for the battery to reach 100% (laptop must be plugged in)
3. Force-discharges the battery via the ThinkPad's ACPI interface while still on AC power (so you don't lose power during the process)
4. Recharges back to 100%

By cycling from full to empty and back, the embedded controller re-learns the actual voltage-to-percentage mapping, which corrects the reporting drift.

### Recalibration Requirements

- **TLP** must be installed: `sudo dnf install tlp`
- **acpi_call kernel module** (for ThinkPads): `sudo dnf install akmod-acpi_call`
- The laptop must stay **plugged in** for the entire process
- The process takes **several hours** — avoid heavy use during recalibration
- On newer ThinkPad Gen 4+ models, the force-discharge ACPI call may not be supported

### When to Recalibrate

- When battery percentage jumps or drops unexpectedly
- When the reported capacity seems inconsistent with actual usage time
- As a general maintenance step every few months

A kernel or firmware update (e.g., upgrading Fedora) can also improve battery reporting accuracy, as newer kernels include fixes to the `power_supply` ACPI subsystem that improve how charge levels are read and interpolated.

## Notes

- The charge thresholds are applied at the kernel/firmware level and take effect immediately.
- The thresholds reset to defaults (usually 0/100) on reboot unless persisted via a startup script or tool like TLP.
- The `BAT0` path may differ on some systems (e.g., `BAT1`). Adjust the `BAT` variable in the script if needed.

## Contributing

Contributions are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for local
setup, the validation suite, and the pull request process.

## Security

Please report vulnerabilities privately as described in
[SECURITY.md](SECURITY.md) — not through public GitHub issues.

## License

This project is licensed under the GNU General Public License v3.0. See below for details.

```
Copyright (C) 2026 Tito Valentin

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <https://www.gnu.org/licenses/>.
```
