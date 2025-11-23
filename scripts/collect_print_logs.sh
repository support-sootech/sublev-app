#!/usr/bin/env zsh
# Helper to collect adb logcat lines relevant to printing and our app
# Usage: ./scripts/collect_print_logs.sh <device-id>
DEVICE_ID="$1"
if [[ -z "$DEVICE_ID" ]]; then
  echo "Usage: $0 <device-id>"
  echo "Get device id with: adb devices"
  exit 1
fi

# Filters: Flutter logs, our debug messages (FINAL IMPRESSAO, ERRO IMPRIMIR ETIQUETA, etc.), and plugin tag
adb -s "$DEVICE_ID" logcat -v time | grep --line-buffered -E "Flutter|FINAL IMPRESSAO|ERRO IMPRIMIR ETIQUETA|printEtiqueta returned false|NiimbotLabelPrinter|niimbot|PrintBluetooth" 
