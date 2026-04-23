# CLAUDE.md — タスク管理アプリ（時間単価ご褒美システム）

## プロジェクト概要

ゲーミフィケーションの考え方を取り入れたタスク管理アプリ。
ユーザーが「月のお小遣い ÷ 月の目標時間 = 時間単価」を設定し、
タスクをこなすごとにその単価分の仮想報酬が得られる仕組み。

**例：** 月3万円 ÷ 月10時間 = 1時間あたり3,000円

---

## ターゲット・公開方針

- プラットフォーム：iOS（将来的にAndroidも検討）
- 公開対象：将来的に多くのユーザーに公開予定
- ログイン：必須（複数端末で同期）

---

## 技術スタック

- フレームワーク：Flutter
- データベース：Firebase Firestore
- 認証：Firebase Authentication
  - Appleでログイン（App Store要件のため必須）
  - Googleでログイン
  - メールアドレス＋パスワード
- アーキテクチャ：Riverpod + MVVM パターン
- 開発ツール：Cursor / Claude Code

---

## コーディングルール

- 言語：Dart（Flutter標準）
- 状態管理：Riverpod を使うこと（Provider・GetXは使わない）
- ファイル構成：機能ごとにフォルダを分ける（feature-first構成）
- コメント：日本語で書いてよい
- 命名規則：Dartの標準に従う（クラス名はUpperCamelCase、変数はlowerCamelCase）

---

## 画面構成

### 1. ホーム画面（実装済み）

画面を上下 3:7 に分割。

**上部エリア（3割）**
- 左上：ユーザーステータス（取得済み報酬残高、レベルなど）
- 右上：健康管理（実装済み）

**下部エリア（7割）**
- カレンダー：タスクをカレンダー形式で表示
  - Googleカレンダー / Appleカレンダーと連携（ベース）
  - 手動でのタスク追加も可能

---

### 2. 欲しいものリスト画面

| 機能 | 詳細 |
|---|---|
| アイテム追加 | 名前を手入力で追加 |
| 価格入力 | 金額を入力すると「あと何時間分のタスクで買えるか」を自動計算・表示 |
| 購入済みチェック | チェックを入れると購入済みとしてマーク |
| 画像・URL登録 | 商品画像またはURLを紐づけて登録できる |

---

### 3. 設定画面（未実装）

- 月のお小遣い（円）を入力
- 月の目標時間（時間）を入力
- → 時間単価を自動計算して保存

---

## データモデル（Firestore）

```
users/{userId}
  - monthlyBudget: number        // 月のお小遣い（円）
  - monthlyTargetHours: number   // 月の目標時間
  - hourlyRate: number           // 時間単価（自動計算）
  - totalEarned: number          // 累計獲得報酬
  - createdAt: timestamp

users/{userId}/tasks/{taskId}
  - title: string                // タスク名
  - durationMinutes: number      // 所要時間（分）
  - reward: number               // 報酬額（時間単価×時間）
  - isCompleted: boolean         // 完了フラグ
  - completedAt: timestamp
  - scheduledDate: timestamp     // カレンダー表示用
  - externalCalendarId: string   // 外部カレンダー連携ID（任意）

users/{userId}/wishlist/{itemId}
  - name: string                 // 欲しいもの名
  - price: number                // 価格（円）
  - imageUrl: string             // 商品画像URL（任意）
  - shopUrl: string              // 購入先URL（任意）
  - isPurchased: boolean         // 購入済みフラグ
  - createdAt: timestamp
```

---

## 主要ビジネスロジック

```
// 時間単価の計算
hourlyRate = monthlyBudget / monthlyTargetHours

// タスク完了時の報酬
reward = hourlyRate × (durationMinutes / 60)

// 欲しいものを買うために必要な時間
requiredHours = itemPrice / hourlyRate
```

---

## 現在の実装状況

- [x] ホーム画面（UI）
- [x] 健康管理パート
- [ ] カレンダー機能（タスク表示・手動追加）
- [ ] 外部カレンダー連携
- [ ] 欲しいものリスト画面
- [ ] 設定画面
- [ ] Firebase セットアップ
- [ ] ログイン機能

---

## 注意事項

- Firebase の API キーや秘密鍵は絶対にコードに直書きしない（`.env` または `firebase_options.dart` を使う）
- App Store 申請のため、Apple ログインは必ず実装すること
- Firestore のセキュリティルールを必ず設定すること（認証済みユーザーのみ自分のデータにアクセス可）
