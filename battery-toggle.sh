#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later

## Author: Tito Valentin
## Name of Program: battery-toggle.sh
## Date Created: 2026-02-26
## Description: Interactive/non-interactive laptop battery tool — toggles or selects charge modes (Longevity 75-80%, Balanced 60-80%, Full Charge 0-100%) and prints a colorful battery report with a charge gauge.

BAT="/sys/class/power_supply/BAT0"
STOP_FILE="$BAT/charge_stop_threshold"
START_FILE="$BAT/charge_start_threshold"
HAS_THRESHOLDS=false
[[ -f "$STOP_FILE" && -f "$START_FILE" ]] && HAS_THRESHOLDS=true

RULE="────────────────────────────────────────────"

# --- Presentation helpers ---------------------------------------------------

setup_colors() {
    local use_color=1
    [[ -n "${NO_COLOR:-}" ]] && use_color=0
    [[ "$color_opt" == "off" ]] && use_color=0
    [[ ! -t 1 ]] && use_color=0
    if [[ "$use_color" -eq 1 ]]; then
        RESET=$'\e[0m'; BOLD=$'\e[1m'; DIM=$'\e[2m'
        RED=$'\e[31m'; GREEN=$'\e[32m'; YELLOW=$'\e[33m'; CYAN=$'\e[36m'
    else
        RESET=''; BOLD=''; DIM=''
        RED=''; GREEN=''; YELLOW=''; CYAN=''
    fi
}

print_banner() {
    printf '\n%s%s' "$CYAN" "$BOLD"
    cat <<'BANNER'
   ____    _  _____ _____ _____ ______   __
  | __ )  / \|_   _|_   _| ____|  _ \ \ / /
  |  _ \ / _ \ | |   | | |  _| | |_) \ V /
  | |_) / ___ \| |   | | | |___|  _ < | |
  |____/_/   \_\_|   |_| |_____|_| \_\|_|
BANNER
    printf '%s' "$RESET"
    printf '  %sToggle laptop charge thresholds and view a battery report.%s\n\n' \
        "$DIM" "$RESET"
}

show_help() {
    print_banner
    cat <<EOF
  Usage: battery-toggle.sh [OPTION]

  Options:
    (no option)          Toggle between Longevity and Full Charge, then report
    -s, --status         Show the battery report without changing anything
    -i, --interactive    Open the interactive menu to pick a mode
    -m, --mode MODE      Set a specific mode: longevity | balanced | full
        --no-color       Disable colored output
    -h, --help           Show this help and exit

  Modes:
    longevity   75-80%   preserve long-term battery health
    balanced    60-80%   everyday middle ground
    full        0-100%   maximum runtime on the go

  Status works on any Linux laptop; changing modes needs kernel charge
  threshold support and root (the script re-runs itself with sudo).
EOF
    printf '\n'
}

# Render a colored charge gauge, e.g. [██████░░░░]
render_gauge() {
    local pct="$1" width=22 filled empty color i fill_str="" empty_str=""
    if ! [[ "$pct" =~ ^[0-9]+$ ]]; then
        printf 'n/a'
        return
    fi
    filled=$(( pct * width / 100 ))
    (( filled > width )) && filled=$width
    (( filled < 0 )) && filled=0
    empty=$(( width - filled ))
    if (( pct >= 60 )); then color="$GREEN"
    elif (( pct >= 25 )); then color="$YELLOW"
    else color="$RED"; fi
    for (( i = 0; i < filled; i++ )); do fill_str+="█"; done
    for (( i = 0; i < empty; i++ )); do empty_str+="░"; done
    printf '[%s%s%s%s%s]' "$color" "$fill_str" "${RESET}${DIM}" "$empty_str" "$RESET"
}

row() {
    printf '  %-18s %s\n' "$1" "$2"
}

# --- Mode metadata ----------------------------------------------------------

display_name_for() {
    case "$1" in
        longevity) printf 'Longevity' ;;
        balanced)  printf 'Balanced' ;;
        full)      printf 'Full Charge' ;;
    esac
}

desc_for_name() {
    case "$1" in
        Longevity)     printf 'Charging between 75%%-80%% — preserving battery health.' ;;
        Balanced)      printf 'Charging between 60%%-80%% — balanced longevity and runtime.' ;;
        "Full Charge") printf 'Charging to 100%% — plug in and top off!' ;;
        *)             printf 'Custom charge thresholds in effect.' ;;
    esac
}

detect_mode() {
    case "$1/$2" in
        75/80)  printf 'Longevity' ;;
        60/80)  printf 'Balanced' ;;
        0/100)  printf 'Full Charge' ;;
        *)      printf 'Custom' ;;
    esac
}

validate_mode() {
    case "$1" in
        longevity|balanced|full) return 0 ;;
        *) return 1 ;;
    esac
}

apply_mode() {
    case "$1" in
        longevity) echo 75 > "$START_FILE"; echo 80  > "$STOP_FILE" ;;
        balanced)  echo 60 > "$START_FILE"; echo 80  > "$STOP_FILE" ;;
        full)      echo 0  > "$START_FILE"; echo 100 > "$STOP_FILE" ;;
    esac
}

# --- Battery report ---------------------------------------------------------

gather_battery() {
    status=$(cat "$BAT/status" 2>/dev/null)
    capacity=$(cat "$BAT/capacity" 2>/dev/null)
    cycle_count=$(cat "$BAT/cycle_count" 2>/dev/null)

    cap_now=""; cap_full=""; cap_design=""; cap_unit=""; health=""; health_color=""

    # Try energy_* (µWh) first, fall back to charge_* (µAh)
    local energy_now energy_full energy_design charge_now charge_full charge_design
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

    if [[ -n "$health" ]]; then
        local h_int="${health%.*}"
        if (( h_int >= 80 )); then health_color="$GREEN"
        elif (( h_int >= 60 )); then health_color="$YELLOW"
        else health_color="$RED"; fi
    fi
}

print_report() {
    local mode_name="$1" mode_desc="$2"
    gather_battery

    if [[ -n "$mode_name" ]]; then
        printf '  %s%s▸ Mode: %s%s\n' "$BOLD" "$CYAN" "$mode_name" "$RESET"
        printf '  %s%s%s\n\n' "$DIM" "$mode_desc" "$RESET"
    fi

    printf '  %s%sBattery Report%s\n' "$BOLD" "$CYAN" "$RESET"
    printf '  %s%s%s\n' "$DIM" "$RULE" "$RESET"
    row "Status:" "$status"
    if [[ -n "$capacity" ]]; then
        printf '  %-18s %s %s%s%%%s\n' \
            "Charge:" "$(render_gauge "$capacity")" "$BOLD" "$capacity" "$RESET"
    fi
    row "Charge cycles:" "$cycle_count"
    if [[ -n "$cap_now" ]]; then
        row "Current capacity:" "$cap_now $cap_unit"
        row "Full capacity:" "$cap_full $cap_unit"
        row "Design capacity:" "$cap_design $cap_unit"
        printf '  %-18s %s%s%%%s\n' "Health:" "$health_color" "$health" "$RESET"
    fi
    if [[ "$HAS_THRESHOLDS" == true ]]; then
        row "Start threshold:" "$(cat "$START_FILE" 2>/dev/null)%"
        row "Stop threshold:" "$(cat "$STOP_FILE" 2>/dev/null)%"
    fi
    printf '  %s%s%s\n\n' "$DIM" "$RULE" "$RESET"
}

# Report the currently active mode (used by --status and the interactive menu).
report_current() {
    local name="" desc="" s e
    if [[ "$HAS_THRESHOLDS" == true ]]; then
        s=$(cat "$START_FILE" 2>/dev/null)
        e=$(cat "$STOP_FILE" 2>/dev/null)
        name=$(detect_mode "$s" "$e")
        desc=$(desc_for_name "$name")
    fi
    print_report "$name" "$desc"
}

apply_and_report() {
    local key="$1" name desc
    apply_mode "$key"
    name=$(display_name_for "$key")
    desc=$(desc_for_name "$name")
    print_report "$name" "$desc"
}

# --- Interactive menu -------------------------------------------------------

run_interactive() {
    if [[ ! -t 0 ]]; then
        printf '  %sError:%s interactive mode requires a terminal.\n\n' "$RED$BOLD" "$RESET"
        exit 1
    fi

    report_current

    local choice
    while true; do
        printf '  %sSelect an option:%s\n' "$BOLD" "$RESET"
        if [[ "$HAS_THRESHOLDS" == true ]]; then
            printf '    %s1%s) Longevity    (75-80%%)   preserve battery health\n' "$CYAN" "$RESET"
            printf '    %s2%s) Balanced     (60-80%%)   everyday middle ground\n' "$CYAN" "$RESET"
            printf '    %s3%s) Full Charge  (0-100%%)   maximum runtime\n' "$CYAN" "$RESET"
        else
            printf '    %s(charge threshold changes are not supported on this hardware)%s\n' \
                "$DIM" "$RESET"
        fi
        printf '    %s4%s) Refresh battery report\n' "$CYAN" "$RESET"
        printf '    %s5%s) Quit\n' "$CYAN" "$RESET"
        printf '  Choice: '
        read -r choice || break
        printf '\n'
        case "$choice" in
            1) if [[ "$HAS_THRESHOLDS" == true ]]; then apply_and_report longevity
               else printf '  %sNot supported on this hardware.%s\n\n' "$YELLOW" "$RESET"; fi ;;
            2) if [[ "$HAS_THRESHOLDS" == true ]]; then apply_and_report balanced
               else printf '  %sNot supported on this hardware.%s\n\n' "$YELLOW" "$RESET"; fi ;;
            3) if [[ "$HAS_THRESHOLDS" == true ]]; then apply_and_report full
               else printf '  %sNot supported on this hardware.%s\n\n' "$YELLOW" "$RESET"; fi ;;
            4) report_current ;;
            5|q|Q) printf '  Goodbye!\n\n'; break ;;
            *) printf '  %sInvalid choice — pick 1-5.%s\n\n' "$YELLOW" "$RESET" ;;
        esac
    done
}

# --- Argument parsing -------------------------------------------------------

action="toggle"
mode_arg=""
color_opt="auto"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--status)      action="status" ;;
        -i|--interactive) action="interactive" ;;
        -m|--mode)        action="mode"; shift; mode_arg="${1:-}" ;;
        --mode=*)         action="mode"; mode_arg="${1#*=}" ;;
        --no-color)       color_opt="off" ;;
        -h|--help)        action="help" ;;
        *) printf 'Error: unknown option %s (use --help).\n' "$1" >&2; exit 1 ;;
    esac
    shift
done

setup_colors

if [[ "$action" == "help" ]]; then
    show_help
    exit 0
fi

if [[ "$action" == "mode" ]]; then
    mode_arg=$(printf '%s' "$mode_arg" | tr '[:upper:]' '[:lower:]')
    if ! validate_mode "$mode_arg"; then
        printf 'Error: invalid mode "%s" (use longevity|balanced|full).\n' "$mode_arg" >&2
        exit 1
    fi
fi

# --- Root / hardware guards for actions that write thresholds ---------------

if [[ "$action" == "toggle" || "$action" == "mode" ]] && [[ "$HAS_THRESHOLDS" == false ]]; then
    print_banner
    printf '  %sError:%s Charge threshold control is not supported on this hardware.\n' \
        "$RED$BOLD" "$RESET"
    printf '  Use %s-s/--status%s to view battery stats, or %s-i%s for the menu.\n\n' \
        "$BOLD" "$RESET" "$BOLD" "$RESET"
    exit 1
fi

if [[ "$action" == "toggle" || "$action" == "mode" || "$action" == "interactive" ]]; then
    if [[ "$HAS_THRESHOLDS" == true && $EUID -ne 0 ]]; then
        echo "This script needs root to change charge thresholds. Re-running with sudo..."
        exec sudo "$0" "$@"
    fi
fi

# --- Dispatch ---------------------------------------------------------------

case "$action" in
    interactive)
        print_banner
        run_interactive
        ;;
    status)
        print_banner
        report_current
        ;;
    mode)
        print_banner
        apply_and_report "$mode_arg"
        ;;
    toggle)
        print_banner
        current_stop=$(cat "$STOP_FILE")
        if [[ "$current_stop" -eq 80 ]]; then
            apply_and_report full
        else
            apply_and_report longevity
        fi
        ;;
esac
