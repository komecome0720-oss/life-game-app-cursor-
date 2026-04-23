#!/usr/bin/env bash
set -euo pipefail

# iPhone実機のデバッグ実行を統一するためのスクリプト
# 使い方:
#   ./ios/run_on_device.sh
#   ./ios/run_on_device.sh "<device-id>"

if ! command -v flutter >/dev/null 2>&1; then
  echo "flutter コマンドが見つかりません。Flutter SDKをインストールしてください。"
  exit 1
fi

flutter pub get

if [[ $# -gt 0 ]]; then
  flutter run -d "$1"
else
  flutter devices
  echo ""
  echo "デバイスID未指定のため、接続済みデバイス一覧を表示しました。"
  echo "iPhoneのdevice-idを指定して再実行してください:"
  echo "./ios/run_on_device.sh \"<device-id>\""
fi
