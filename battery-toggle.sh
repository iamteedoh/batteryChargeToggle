#!/bin/bash

## Author: Tito Valentin
## Name of Program: battery-toggle.sh
## Date Created: 2026-02-26
## Description: Toggles battery charge thresholds between Longevity Mode (75-80%) and Full Charge Mode (0-100%)

BAT="/sys/class/power_supply/BAT0"
STOP_FILE="$BAT/charge_stop_threshold"
START_FILE="$BAT/charge_start_threshold"
HAS_THRESHOLDS=false
[[ -f "$STOP_FILE" && -f "$START_FILE" ]] && HAS_THRESHOLDS=true

status_only=false
for arg in "$@"; do
    case "$arg" in
        -s|--status) status_only=true ;;
    esac
done

if [[ "$status_only" = false ]]; then
    if [[ "$HAS_THRESHOLDS" = false ]]; then
        echo "  Error: Charge threshold control is not supported on this hardware."
        echo "  Use -s/--status to view battery stats."
        exit 1
    fi
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
fi

# Gather battery details
status=$(cat "$BAT/status")
capacity=$(cat "$BAT/capacity")
cycle_count=$(cat "$BAT/cycle_count")

# Try energy_* (µWh) first, fall back to charge_* (µAh)
energy_now=$(cat "$BAT/energy_now" 2>/dev/null)
energy_full=$(cat "$BAT/energy_full" 2>/dev/null)
energy_design=$(cat "$BAT/energy_full_design" 2>/dev/null)

if [[ -n "$energy_now" && -n "$energy_full" && -n "$energy_design" ]]; then
    cap_now=$(awk "BEGIN {printf \"%.2f\", $energy_now / 1000000}")
    cap_full=$(awk "BEGIN {printf \"%.2f\", $energy_full / 1000000}")
    cap_design=$(awk "BEGIN {printf \"%.2f\", $energy_design / 1000000}")
    cap_unit="Wh"
    health=$(awk "BEGIN {printf \"%.1f\", ($energy_full / $energy_design) * 100}")
else
    charge_now=$(cat "$BAT/charge_now" 2>/dev/null)
    charge_full=$(cat "$BAT/charge_full" 2>/dev/null)
    charge_design=$(cat "$BAT/charge_full_design" 2>/dev/null)

    if [[ -n "$charge_now" && -n "$charge_full" && -n "$charge_design" ]]; then
        cap_now=$(awk "BEGIN {printf \"%.0f\", $charge_now / 1000}")
        cap_full=$(awk "BEGIN {printf \"%.0f\", $charge_full / 1000}")
        cap_design=$(awk "BEGIN {printf \"%.0f\", $charge_design / 1000}")
        cap_unit="mAh"
        health=$(awk "BEGIN {printf \"%.1f\", ($charge_full / $charge_design) * 100}")
    fi
fi

if [[ "$status_only" = true ]]; then
    if [[ "$HAS_THRESHOLDS" = true ]]; then
        stop_thresh=$(cat "$STOP_FILE")
        start_thresh=$(cat "$START_FILE")
        if [[ "$stop_thresh" -eq 80 ]]; then
            mode="Longevity"
            mode_desc="Charging between 75%-80% — preserving battery health."
        else
            mode="Full Charge"
            mode_desc="Charging to 100% — plug in and top off!"
        fi
    fi
fi

echo ""
if [[ -n "$mode" ]]; then
    echo "  ==========================================="
    echo "  Mode: $mode"
    echo "  $mode_desc"
    echo "  ==========================================="
    echo ""
fi
echo "  Battery Report"
echo "  -------------------------------------------"
echo "  Status:            $status"
echo "  Charge:            ${capacity}%"
echo "  Charge cycles:     $cycle_count"
if [[ -n "$cap_now" ]]; then
    echo "  Current capacity:  ${cap_now} ${cap_unit}"
    echo "  Full capacity:     ${cap_full} ${cap_unit}"
    echo "  Design capacity:   ${cap_design} ${cap_unit}"
    echo "  Health:            ${health}%"
fi
if [[ "$HAS_THRESHOLDS" = true ]]; then
    start_thresh=$(cat "$START_FILE" 2>/dev/null)
    stop_thresh=$(cat "$STOP_FILE" 2>/dev/null)
    echo "  Start threshold:   ${start_thresh}%"
    echo "  Stop threshold:    ${stop_thresh}%"
fi
echo "  -------------------------------------------"
echo ""
