#!/bin/bash

BAT="/sys/class/power_supply/BAT0"
STOP_FILE="$BAT/charge_stop_threshold"
START_FILE="$BAT/charge_start_threshold"

if [[ $EUID -ne 0 ]]; then
    echo "This script needs root. Re-running with sudo..."
    exec sudo "$0" "$@"
fi

current_stop=$(cat "$STOP_FILE")

if [[ "$current_stop" -eq 80 ]]; then
    echo 0 > "$START_FILE"
    echo 100 > "$STOP_FILE"
    mode="Full Charge"
    mode_desc="Charging to 100% — plug in and top off!"
else
    echo 75 > "$START_FILE"
    echo 80 > "$STOP_FILE"
    mode="Longevity"
    mode_desc="Charging between 75%-80% — preserving battery health."
fi

# Gather battery details
status=$(cat "$BAT/status")
capacity=$(cat "$BAT/capacity")
cycle_count=$(cat "$BAT/cycle_count")
energy_now=$(cat "$BAT/energy_now" 2>/dev/null)
energy_full=$(cat "$BAT/energy_full" 2>/dev/null)
energy_design=$(cat "$BAT/energy_full_design" 2>/dev/null)

# Convert from microwatt-hours to Wh
if [[ -n "$energy_now" && -n "$energy_full" && -n "$energy_design" ]]; then
    energy_now_wh=$(awk "BEGIN {printf \"%.2f\", $energy_now / 1000000}")
    energy_full_wh=$(awk "BEGIN {printf \"%.2f\", $energy_full / 1000000}")
    energy_design_wh=$(awk "BEGIN {printf \"%.2f\", $energy_design / 1000000}")
    health=$(awk "BEGIN {printf \"%.1f\", ($energy_full / $energy_design) * 100}")
fi

start_thresh=$(cat "$START_FILE")
stop_thresh=$(cat "$STOP_FILE")

echo ""
echo "  ==========================================="
echo "  Mode: $mode"
echo "  $mode_desc"
echo "  ==========================================="
echo ""
echo "  Battery Report"
echo "  -------------------------------------------"
echo "  Status:            $status"
echo "  Charge:            ${capacity}%"
echo "  Charge cycles:     $cycle_count"
if [[ -n "$energy_now_wh" ]]; then
    echo "  Energy now:        ${energy_now_wh} Wh"
    echo "  Full capacity:     ${energy_full_wh} Wh"
    echo "  Design capacity:   ${energy_design_wh} Wh"
    echo "  Health:            ${health}%"
fi
echo "  Start threshold:   ${start_thresh}%"
echo "  Stop threshold:    ${stop_thresh}%"
echo "  -------------------------------------------"
echo ""
