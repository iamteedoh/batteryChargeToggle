# Laptop Battery Charge Toggle (Linux)

A Bash utility for Linux laptops that toggles between two battery charging modes:

- **Longevity Mode** — Limits charging between 75%-80% to preserve long-term battery health.
- **Full Charge Mode** — Allows charging up to 100% for when you need maximum battery life on the go.

## How It Works

The script reads and writes to the Linux kernel's battery charge threshold files located at:

```
/sys/class/power_supply/BAT0/charge_start_threshold
/sys/class/power_supply/BAT0/charge_stop_threshold
```

Each time you run it, the script checks the current `charge_stop_threshold`:

- If the stop threshold is **80** (Longevity Mode is active), it switches to **Full Charge Mode** by setting the start threshold to 0 and the stop threshold to 100.
- Otherwise, it switches to **Longevity Mode** by setting the start threshold to 75 and the stop threshold to 80.

After toggling, the script prints a detailed battery report including:

- Current charging status (Charging, Discharging, Full, etc.)
- Current charge percentage
- Charge cycle count
- Energy levels in Wh (current, full capacity, design capacity)
- Battery health percentage (full capacity vs. design capacity)
- Active charge start/stop thresholds

## Requirements

- **Linux** with a battery that exposes sysfs charge threshold controls (`/sys/class/power_supply/BAT0/`)
- **Root privileges** — The script automatically re-runs itself with `sudo` if not already root
- **Bash** shell
- **awk** (for unit conversion calculations)

### Compatible Hardware

Most modern laptops with supported battery drivers expose these threshold files. Common supported brands include:

- ThinkPad (via `thinkpad_acpi` or `natacpi`)
- ASUS (via `asus-nb-wmi` or `asus_wmi`)
- Huawei (via `huawei-wmi`)
- Other laptops with kernel-level charge threshold support

You can verify compatibility by checking if these files exist:

```bash
ls /sys/class/power_supply/BAT0/charge_start_threshold
ls /sys/class/power_supply/BAT0/charge_stop_threshold
```

## Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/your-username/batteryChargeToggle.git
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

Run the script directly:

```bash
./battery-toggle.sh
```

The script requires root access to write to sysfs files. If not run as root, it will automatically prompt for your sudo password.

### Example Output

When switching to Longevity Mode:

```
  ===========================================
  Mode: Longevity
  Charging between 75%-80% — preserving battery health.
  ===========================================

  Battery Report
  -------------------------------------------
  Status:            Charging
  Charge:            72%
  Charge cycles:     145
  Energy now:        38.50 Wh
  Full capacity:     51.20 Wh
  Design capacity:   57.00 Wh
  Health:            89.8%
  Start threshold:   75%
  Stop threshold:    80%
  -------------------------------------------
```

When switching to Full Charge Mode:

```
  ===========================================
  Mode: Full Charge
  Charging to 100% — plug in and top off!
  ===========================================

  Battery Report
  -------------------------------------------
  Status:            Charging
  Charge:            80%
  Charge cycles:     145
  Energy now:        42.10 Wh
  Full capacity:     51.20 Wh
  Design capacity:   57.00 Wh
  Health:            89.8%
  Start threshold:   0%
  Stop threshold:    100%
  -------------------------------------------
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
