#!/bin/zsh
#
# capture-promo-video.sh
# Renewly
#
# Created by Md Mehedi Hasan Angkur on 2026-10-04.
# Copyright © 2026. All rights reserved.
#
# Records the in-app demo tour (-demo_tour) on the iPhone simulator, one recording per store language.
# Needs a Debug build. ComposePromoVideo.swift turns the recordings into the finished videos.
#
# Usage:
#   capture-promo-video.sh <Renewly.app> <output-dir> [run-id ...]
# Example:
#   capture-promo-video.sh build/Renewly.app /tmp/renewly-video-raw en-US ja
#

set -euo pipefail

APP="$1"
OUT="$2"
shift 2
selected_runs=("$@")

source "${0:A:h}/store-runs.zsh"

DEVICE_NAME="iPhone 17 Pro Max"
# The tour itself runs 24 seconds; the rest covers a first launch, which can take several seconds.
RECORD_SECONDS=34

udid=$(simulator_udid "$DEVICE_NAME")
[[ -z "$udid" ]] && { echo "No simulator named $DEVICE_NAME" >&2; exit 1; }
prepare_simulator "$udid"
mkdir -p "$OUT"

for run in "${RUNS[@]}"; do
  IFS='|' read -r run_id language locale currency <<< "$run"
  if (( ${#selected_runs[@]} > 0 )) && (( ${selected_runs[(Ie)$run_id]} == 0 )); then
    continue
  fi

  xcrun simctl terminate "$udid" "$BUNDLE_ID" 2>/dev/null || true
  xcrun simctl uninstall "$udid" "$BUNDLE_ID" 2>/dev/null || true
  xcrun simctl install "$udid" "$APP"

  xcrun simctl io "$udid" recordVideo --codec=h264 --force "$OUT/$run_id.mov" >/dev/null 2>&1 &
  recorder=$!
  sleep 1
  xcrun simctl launch "$udid" "$BUNDLE_ID" \
    -AppleLanguages "($language)" -AppleLocale "$locale" \
    -primary_currency "$currency" -app_theme light -seed_demo starter -demo_reminders YES \
    -debug_pro_override YES -demo_tour YES >/dev/null
  sleep "$RECORD_SECONDS"
  kill -INT "$recorder"
  wait "$recorder" || true
  xcrun simctl terminate "$udid" "$BUNDLE_ID" 2>/dev/null || true
  echo "recorded $run_id"
done
