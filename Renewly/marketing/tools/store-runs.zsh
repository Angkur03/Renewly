#
# store-runs.zsh
# Renewly
#
# Created by Md Mehedi Hasan Angkur on 2026-10-04.
# Copyright © 2026. All rights reserved.
#
# Shared by the capture scripts: one run per store language.
#

BUNDLE_ID="com.beleiveinAllahRenewly.Renewly"

# run-id | app language | region locale | main currency
RUNS=(
  "en-US|en|en_US|USD"
  "en-GB|en|en_GB|GBP"
  "de-DE|de|de_DE|EUR"
  "fr-FR|fr|fr_FR|EUR"
  "es-ES|es|es_ES|EUR"
  "es-MX|es|es_MX|MXN"
  "pt-BR|pt-BR|pt_BR|BRL"
  "ja|ja|ja_JP|JPY"
  "zh-Hans|zh-Hans|zh_CN|CNY"
  "bn-BD|bn|bn_IN|INR"
)

simulator_udid() {
  xcrun simctl list devices available | grep -F "$1 (" | head -1 | grep -oE '[0-9A-F-]{36}'
}

prepare_simulator() {
  xcrun simctl boot "$1" 2>/dev/null || true
  xcrun simctl bootstatus "$1" -b >/dev/null
  xcrun simctl status_bar "$1" override --time "9:41" --dataNetwork wifi --wifiMode active --wifiBars 3 \
    --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100
}
