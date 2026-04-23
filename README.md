# task_manager

Flutterで作るタスク管理アプリです。

## iPhone実機運用（推奨）

日常開発は **実機へ直接インストール**、節目確認は **TestFlight（Internal Testing）** を使う二段運用を標準にします。

### 1) 日常開発（最速ループ）

1. iPhoneをMacに接続し、Developer Modeを有効化
2. XcodeでSigning設定（Team/Bundle ID）を通す
3. 以下で実機起動

```bash
./ios/run_on_device.sh "<device-id>"
```

`device-id` は `flutter devices` で確認できます。

### 2) TestFlight Internal（配布経路確認）

以下でIPAを作成します。

```bash
./ios/build_for_testflight.sh
```

作成された `build/ios/ipa/` のIPAを、Xcode Organizer または Transporter で App Store Connect にアップロードしてください。

### 3) 運用チェックポイント

- 日次: 直接インストールのみで機能確認
- 週次 or マイルストーン: TestFlightビルドを作成して回帰確認
- リリース直前: TestFlightの最終ビルドで署名・権限・認証・通知を再確認
- 詳細チェックリスト: `ios/testflight_checkpoints.md`

## 参考リンク

- [Flutter documentation](https://docs.flutter.dev/)
- [TestFlight overview](https://developer.apple.com/testflight/)
