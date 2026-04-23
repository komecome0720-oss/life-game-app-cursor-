#!/usr/bin/env bash
set -euo pipefail

# TestFlight (Internal Testing) 向けのビルドを固定化するスクリプト
# アップロード自体は Xcode Organizer または Transporter で実行する

if ! command -v flutter >/dev/null 2>&1; then
  echo "flutter コマンドが見つかりません。Flutter SDKをインストールしてください。"
  exit 1
fi

flutter clean
flutter pub get
flutter build ipa --release

echo ""
echo "IPAビルドが完了しました。"
echo "出力先: build/ios/ipa/"
echo "このIPAを App Store Connect の TestFlight (Internal) へアップロードしてください。"
