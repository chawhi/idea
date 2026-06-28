# VitaPet — Xcode セットアップ手順

## 必要環境
- macOS 14 (Sonoma) 以上
- Xcode 16 以上
- iOS 17 以上対応デバイス / シミュレータ
- Apple Developer アカウント（HealthKit は実機必須）

---

## 1. Xcode プロジェクト作成

1. Xcode を起動 → **File > New > Project**
2. **iOS > App** を選択
3. 以下の設定で作成：

| 項目 | 値 |
|-----|---|
| Product Name | VitaPet |
| Bundle Identifier | com.yourname.vitapet |
| Interface | SwiftUI |
| Language | Swift |
| Storage | SwiftData |

4. **watchOS ターゲットを追加**：  
   File > New > Target > **watchOS > Watch App**  
   Product Name: `VitaPetWatch`

---

## 2. ソースファイルの配置

このリポジトリの `VitaPet/VitaPet/` 以下のファイルをすべてプロジェクトにドラッグ＆ドロップ。  
以下のグループ構成になるよう配置する：

```
VitaPet/
├── App/
│   ├── VitaPetApp.swift
│   └── ContentView.swift
├── Models/
│   ├── Pet.swift
│   ├── Item.swift
│   ├── FoodRecord.swift
│   └── Skill.swift
├── Services/
│   ├── HealthKitService.swift
│   └── PetEvolutionService.swift
└── Features/
    ├── Home/
    │   ├── HomeView.swift
    │   ├── PetStatusView.swift
    │   └── OnboardingView.swift
    ├── FoodLog/
    │   └── FoodLogView.swift
    ├── Battle/
    │   └── BattleMenuView.swift
    ├── Pokedex/
    │   └── PokedexView.swift
    ├── Social/
    │   └── FriendListView.swift
    └── Shop/
        └── ShopView.swift
```

---

## 3. HealthKit 権限設定

`Info.plist` に以下のキーを追加：

```xml
<key>NSHealthShareUsageDescription</key>
<string>歩数・睡眠・運動データをペットの育成に使用します</string>

<key>NSHealthUpdateUsageDescription</key>
<string>このアプリは健康データの書き込みは行いません</string>
```

Signing & Capabilities タブで **HealthKit** を追加。

---

## 4. SwiftData 確認

`VitaPetApp.swift` の `ModelContainer` に以下が含まれていることを確認：
```swift
ModelContainer(for: Pet.self, Item.self, FoodRecord.self)
```

---

## 5. ビルド & 実行

```
Cmd + R  →  シミュレータで起動
```

HealthKit はシミュレータでも動作するが、データは手動入力が必要。  
実際の歩数・睡眠データは実機でのみ取得できる。

---

## 現在の実装状況（Phase 1 MVP）

| 機能 | 状態 |
|-----|-----|
| オンボーディング（種族選択・命名） | ✅ 実装済み |
| ホーム画面（ペット表示・ステータスバー） | ✅ 実装済み |
| HealthKit 連携（歩数・睡眠・カロリー） | ✅ 実装済み |
| ペットへのアクション（ごはん・遊ぶ・話す） | ✅ 実装済み |
| ステータス詳細画面 | ✅ 実装済み |
| 食事記録（テキスト入力） | ✅ 実装済み |
| 食事記録（カメラ・バーコード） | 🔲 Phase 2 |
| 進化・転生システム | ✅ ロジック実装済み（演出は Phase 3）|
| 図鑑 | ✅ 基本実装済み |
| バトル | 🔲 Phase 4 |
| フレンド・ランキング | 🔲 Phase 4 |
| ショップ・課金 | 🔲 Phase 5 |
| Apple Watch アプリ | 🔲 Phase 3 |
