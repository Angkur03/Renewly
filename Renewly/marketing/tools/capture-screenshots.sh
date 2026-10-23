#!/bin/zsh
#
# capture-screenshots.sh
# Renewly
#
# Created by Md Mehedi Hasan Angkur on 2026-10-04.
# Copyright © 2026. All rights reserved.
#
# Captures raw App Store screenshots from the simulator for every store language.
# Needs a Debug build, because it relies on the debug-only launch options
# (-seed_demo, -demo_reminders, -open_route, -demo_plans, -debug_pro_override).
#
# Usage:
#   capture-screenshots.sh <Renewly.app> <output-dir> [iphone|ipad ...] [-- run-id ...]
# Example:
#   capture-screenshots.sh build/Renewly.app marketing/raw iphone ipad -- en-US ja
#   CAPTURE_SHOTS="01_dashboard" capture-screenshots.sh build/Renewly.app marketing/raw
#

set -euo pipefail

APP="$1"
OUT="$2"
shift 2

source "${0:A:h}/store-runs.zsh"

WAIT_SECONDS=6

typeset -A DEVICE_NAMES=(
  iphone "iPhone 17 Pro Max"
  ipad "iPad Pro 13-inch (M5)"
)

ALL_SHOTS=(01_dashboard 02_trial 03_add 04_insights 05_warranty 06_reminders 07_paywall)
# CAPTURE_SHOTS="01_dashboard 05_warranty" re-captures only those screens.
SHOTS=(${=CAPTURE_SHOTS:-${ALL_SHOTS[*]}})

shot_arguments() {
  case "$1" in
    01_dashboard) reply=() ;;
    02_trial) reply=(-open_route "item:YouTube Premium") ;;
    03_add) reply=(-open_route services) ;;
    04_insights) reply=(-open_route insights -debug_pro_override YES) ;;
    05_warranty) reply=(-open_route "item:LG C3 OLED 65\"") ;;
    06_reminders) reply=(-open_route settings -debug_pro_override YES) ;;
    07_paywall) reply=(-open_route paywall -demo_plans YES) ;;
  esac
}

devices=()
selected_runs=()
while (( $# > 0 )); do
  if [[ "$1" == "--" ]]; then
    shift
    selected_runs=("$@")
    break
  fi
  devices+=("$1")
  shift
done
(( ${#devices[@]} == 0 )) && devices=(iphone ipad)

capture_device() {
  local device="$1"
  local udid
  udid=$(simulator_udid "${DEVICE_NAMES[$device]}")
  [[ -z "$udid" ]] && { echo "No simulator named ${DEVICE_NAMES[$device]}" >&2; return 1; }
  prepare_simulator "$udid"

  local run run_id language locale currency shot
  for run in "${RUNS[@]}"; do
    IFS='|' read -r run_id language locale currency <<< "$run"
    if (( ${#selected_runs[@]} > 0 )) && (( ${selected_runs[(Ie)$run_id]} == 0 )); then
      continue
    fi
    local dir="$OUT/$device/$run_id"
    mkdir -p "$dir"

    # A fresh install empties the store, so demo data is seeded again in this run's currency.
    xcrun simctl uninstall "$udid" "$BUNDLE_ID" 2>/dev/null || true
    xcrun simctl install "$udid" "$APP"

    for shot in "${SHOTS[@]}"; do
      # The iPad paywall is a small form sheet, so it is left out of the iPad set.
      [[ "$device" == ipad && "$shot" == 07_paywall ]] && continue
      shot_arguments "$shot"
      xcrun simctl terminate "$udid" "$BUNDLE_ID" 2>/dev/null || true
      xcrun simctl launch "$udid" "$BUNDLE_ID" \
        -AppleLanguages "($language)" -AppleLocale "$locale" \
        -primary_currency "$currency" -app_theme light -seed_demo starter -demo_reminders YES \
        "${reply[@]}" >/dev/null
      sleep "$WAIT_SECONDS"
      xcrun simctl io "$udid" screenshot "$dir/$shot.png" >/dev/null 2>&1
      echo "$device $run_id $shot"
    done
    xcrun simctl terminate "$udid" "$BUNDLE_ID" 2>/dev/null || true
  done
}

for device in "${devices[@]}"; do
  capture_device "$device" &
done
wait
