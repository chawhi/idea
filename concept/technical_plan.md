# 技術実装計画書

## 技術スタック確定版

| レイヤー | 技術選定 | 理由 |
|--------|---------|-----|
| iOS UI | SwiftUI | Apple 標準・アニメーション豊富 |
| watchOS UI | SwiftUI (watchOS) | iPhone と共通コンポーネント |
| ゲームアニメーション | SpriteKit | キャラクターの 2D アニメに最適 |
| ヘルスデータ | HealthKit | 歩数・睡眠・カロリー・心拍数 |
| ローカル DB | SwiftData | iOS17+ 標準、Core Data より簡潔 |
| クラウド同期 | CloudKit | Apple ID 連携、無料枠が十分 |
| オンライン機能 | Firebase (Firestore + Auth) | バトル・フレンド・ランキング |
| 食品 DB | Open Food Facts API + 自社 DB | バーコードスキャン対応 |
| バーコードスキャン | AVFoundation | Apple 標準、追加ライブラリ不要 |
| 栄養成分表 OCR | Vision Framework | Apple 製、精度高い |
| 料理画像認識 | Core ML + カスタムモデル | オンデバイス推論でプライバシー保護 |
| プッシュ通知 | APNs + Firebase Messaging | ペット通知・バトル通知 |
| アナリティクス | Firebase Analytics | 無料・Apple 対応 |
| 課金 | StoreKit 2 | サブスク・買い切り両対応 |

---

## 開発フェーズ

### Phase 0 — 環境構築（1 週間）

- [ ] Xcode プロジェクト作成（iOS + watchOS マルチターゲット）
- [ ] SwiftData スキーマ設計・モデル定義
- [ ] Firebase プロジェクト作成・設定
- [ ] HealthKit パーミッション設定
- [ ] CI/CD 設定（Xcode Cloud or GitHub Actions）

---

### Phase 1 — コア育成ループ MVP（4〜6 週間）

**目標**: ペットが育てられる最小限の動くプロトタイプ

#### 実装内容

**ペットモデル**
```swift
// SwiftData モデル（概略）
@Model class Pet {
    var id: UUID
    var name: String
    var species: Species        // フレア/マリン/テラ/シルフ/ルナ
    var stage: GrowthStage      // たまご〜完全体
    var hunger: Int             // 0〜100
    var stamina: Int            // 0〜100
    var happiness: Int          // 0〜100
    var experience: Int
    var level: Int
    var evolutionType: EvolutionType?  // バランス/アクティブ/etc
    var reincarnationCount: Int
    var inheritedSkills: [Skill]
    var createdAt: Date
}
```

**HealthKit 連携**
```
取得するデータ:
  - HKQuantityTypeIdentifier.stepCount（歩数）
  - HKCategoryTypeIdentifier.sleepAnalysis（睡眠）
  - HKQuantityTypeIdentifier.activeEnergyBurned（カロリー）
  - HKQuantityTypeIdentifier.heartRate（心拍数）

取得タイミング:
  - アプリ起動時にバックグラウンドデリバリー登録
  - 1 時間ごとのバックグラウンド処理でペットに反映
```

**画面実装**
- [ ] ホーム画面（SpriteKit でペットアニメーション）
- [ ] ステータス画面
- [ ] ごはん / なでる / 話しかけるアクション
- [ ] HealthKit データ → アイテム変換処理
- [ ] アイテム使用画面

**watchOS**
- [ ] 文字盤コンプリケーション（ペット顔 + 歩数）
- [ ] Watch メイン画面（ステータス確認 + ごはんアクション）

**マイルストーン**: 実機で歩いたらペットが育つ体験ができる状態

---

### Phase 2 — 食事記録システム（3〜4 週間）

**目標**: 3 種類の食事入力が動作する

- [ ] 食品マスター DB 設計・初期データ投入（1,000 品目〜）
- [ ] テキスト入力 + 食品名サジェスト
- [ ] バーコードスキャン（AVFoundation + Open Food Facts API）
- [ ] 栄養成分表 OCR スキャン（Vision Framework）
- [ ] 料理写真 AI 認識（Core ML モデル訓練 or Food101 ベースモデル）
- [ ] 栄養バランス計算 → ゲーム反映
- [ ] 食事記録画面 UI

**Core ML モデル方針**
```
初期リリース: 料理カテゴリ分類のみ（和食/洋食/中華/ファスト等）
→ カテゴリから平均カロリーを推計
精度改善版（v2）: Food101 ファインチューニング → 具体的な料理名認識
```

---

### Phase 3 — 進化・転生システム（2〜3 週間）

**目標**: 分岐進化と転生が動作する

- [ ] 進化条件判定ロジック（日次バッチで評価）
- [ ] 進化演出アニメーション（SpriteKit パーティクル）
- [ ] 転生フロー（引き継ぎスキル選択 → 新たまご生成）
- [ ] たまごレア度決定ロジック
- [ ] 図鑑（発見済みキャラクター管理）
- [ ] 全キャラクターイラスト素材の統合

**進化判定ロジック（概略）**
```swift
func evaluateEvolutionType(pet: Pet, healthData: HealthSummary) -> EvolutionType {
    let stepScore = healthData.avgDailySteps / 10000.0      // 0〜1
    let sleepScore = healthData.avgSleepHours / 8.0         // 0〜1
    let mealScore = healthData.mealRecordRate               // 0〜1（3食記録率）
    let activeScore = healthData.avgActiveCalories / 400.0  // 0〜1

    // 各スコアが 0.7 以上なら「バランス型」
    if [stepScore, sleepScore, mealScore, activeScore].allSatisfy({ $0 >= 0.7 }) {
        return .balanced
    }
    // 最も高いスコアに応じて分岐
    let scores = [
        EvolutionType.active: (stepScore + activeScore) / 2,
        EvolutionType.sleepFocused: sleepScore,
        EvolutionType.gourmet: mealScore,
    ]
    return scores.max(by: { $0.value < $1.value })?.key ?? .neglected
}
```

---

### Phase 4 — オンライン機能（4〜5 週間）

**目標**: フレンド・バトル・ランキングが動作する

**Firebase 設計**
```
Firestore コレクション構造:
  /users/{userId}
    - displayName
    - friendCode
    - currentPet: { species, stage, stats }  ← バトル用スナップショット
    - weeklyBP: number
    - lastSynced: timestamp

  /battles/{battleId}
    - player1: userId
    - player2: userId
    - result: { winner, turns, log }
    - createdAt

  /rankings/weekly
    - entries: [{ userId, displayName, bp, petSnapshot }]
    - weekStart: timestamp

  /friends/{userId}/list
    - [{ friendId, addedAt }]
```

- [ ] Firebase Auth（Apple Sign In 連携）
- [ ] フレンドコード生成・検索・追加
- [ ] フレンドリスト画面
- [ ] バトルオートシミュレーターエンジン
- [ ] バトルデッキ設定画面
- [ ] バトルアニメーション画面
- [ ] 週次ランキング集計（Cloud Functions）
- [ ] フレンドへ応援アイテム送信

---

### Phase 5 — ショップ・課金（2〜3 週間）

- [ ] StoreKit 2 統合
- [ ] ジェム購入フロー
- [ ] サブスクリプション（VitaPet プレミアム）購入・管理
- [ ] レシート検証（サーバーサイド or StoreKit 2 の JWS 検証）
- [ ] ショップ UI
- [ ] 着せ替え適用システム
- [ ] 部屋デコ適用システム

---

### Phase 6 — 仕上げ・リリース準備（3〜4 週間）

- [ ] 通知設計・実装（ペットのお腹空き通知、進化通知など）
- [ ] オンボーディングフロー完成
- [ ] App Store Connect 設定（スクリーンショット・説明文）
- [ ] プライバシーポリシー・利用規約
- [ ] HealthKit プライバシーノート（Apple 審査で必須）
- [ ] TestFlight ベータテスト
- [ ] パフォーマンス最適化（SpriteKit の FPS 管理）
- [ ] App Store 申請

---

## 開発スケジュール概算

```
Phase 0:  1 週間
Phase 1:  6 週間  ← MVP、ここで最初に触れる
Phase 2:  4 週間
Phase 3:  3 週間
Phase 4:  5 週間
Phase 5:  3 週間
Phase 6:  4 週間
─────────────────
合計: 約 26 週間（6〜7 ヶ月）
```

> ※1 人開発の場合。デザイナーと分業できれば 4〜5 ヶ月に短縮可能。

---

## ディレクトリ構成（案）

```
VitaPet/
├── App/
│   ├── VitaPetApp.swift
│   └── AppDelegate.swift
├── Models/                    # SwiftData モデル
│   ├── Pet.swift
│   ├── Item.swift
│   ├── FoodRecord.swift
│   └── Skill.swift
├── Features/                  # 機能ごとのモジュール
│   ├── Home/
│   │   ├── HomeView.swift
│   │   └── PetSpriteScene.swift   # SpriteKit
│   ├── FoodLog/
│   │   ├── FoodLogView.swift
│   │   ├── BarcodeScanner.swift
│   │   ├── NutritionOCR.swift
│   │   └── FoodPhotoAI.swift
│   ├── Battle/
│   │   ├── BattleView.swift
│   │   └── BattleEngine.swift
│   ├── Social/
│   │   ├── FriendListView.swift
│   │   └── RankingView.swift
│   ├── Shop/
│   │   └── ShopView.swift
│   └── Pokedex/              # 図鑑
│       └── PokedexView.swift
├── Services/
│   ├── HealthKitService.swift
│   ├── FirebaseService.swift
│   ├── StoreKitService.swift
│   └── PetEvolutionService.swift
├── Assets.xcassets/
└── WatchApp/                  # watchOS ターゲット
    ├── WatchHomeView.swift
    └── ComplicationProvider.swift
```

---

## リスクと対策

| リスク | 対策 |
|-------|-----|
| HealthKit のバックグラウンド更新遅延 | BGTaskScheduler でバックグラウンド処理を確実に起動 |
| 料理 AI の精度不足 | v1 はカテゴリ分類のみ。精度ラベルを明示して誤認識を許容 |
| Apple 審査（HealthKit 利用理由） | 利用目的を明確に記述。ゲームへの連携であることを説明 |
| Firebase コスト増大 | バトルログ・ランキングの保存期間を制限（週次リセット） |
| SpriteKit のパフォーマンス | アニメーションの FPS を 30 に制限、テクスチャアトラス使用 |

---

## 最初に作るべきもの（優先順）

1. **ペットモデル + HealthKit 連携** — ゲームの心臓部
2. **ホーム画面 + SpriteKit キャラ** — ユーザーが最も長く見る画面
3. **進化判定ロジック** — コアゲームループの完結
4. **食事記録（テキストのみ）** — カメラは後回し
5. **バトル** — オンラインは最後

---

*作成日: 2026-06-27*
