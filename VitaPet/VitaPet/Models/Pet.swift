import SwiftData
import Foundation

// MARK: - 列挙型

enum Species: String, Codable, CaseIterable {
    case flare  = "フレア"
    case marine = "マリン"
    case terra  = "テラ"
    case sylph  = "シルフ"
    case luna   = "ルナ"

    var displayName: String { rawValue }

    /// 種族ごとのステータス倍率
    var statMultipliers: StatMultipliers {
        switch self {
        case .flare:  return StatMultipliers(atk: 1.3, def: 0.9, spd: 1.1, mag: 0.8)
        case .marine: return StatMultipliers(atk: 0.8, def: 1.2, spd: 0.9, mag: 1.3)
        case .terra:  return StatMultipliers(atk: 1.0, def: 1.4, spd: 0.8, mag: 1.0)
        case .sylph:  return StatMultipliers(atk: 0.9, def: 0.8, spd: 1.5, mag: 1.0)
        case .luna:   return StatMultipliers(atk: 0.9, def: 1.0, spd: 1.0, mag: 1.4)
        }
    }

    var attributeName: String {
        switch self {
        case .flare:  return "炎"
        case .marine: return "水"
        case .terra:  return "大地"
        case .sylph:  return "風"
        case .luna:   return "月"
        }
    }
}

struct StatMultipliers {
    let atk: Double
    let def: Double
    let spd: Double
    let mag: Double
}

enum GrowthStage: String, Codable, CaseIterable, Comparable {
    case egg      = "たまご"
    case baby     = "赤ちゃん"
    case child    = "子供"
    case teen     = "少年/少女"
    case mature   = "成熟"
    case ultimate = "完全体"

    private var order: Int {
        switch self {
        case .egg: return 0; case .baby: return 1; case .child: return 2
        case .teen: return 3; case .mature: return 4; case .ultimate: return 5
        }
    }

    static func < (lhs: GrowthStage, rhs: GrowthStage) -> Bool {
        lhs.order < rhs.order
    }

    /// 全ステータスへの成長補正倍率
    var stageMultiplier: Double {
        switch self {
        case .egg: return 0.1; case .baby: return 0.3; case .child: return 0.5
        case .teen: return 0.7; case .mature: return 0.9; case .ultimate: return 1.0
        }
    }

    /// 次のステージへの経験値しきい値
    var experienceThreshold: Int {
        switch self {
        case .egg: return 100; case .baby: return 300; case .child: return 700
        case .teen: return 1500; case .mature: return 3000; case .ultimate: return Int.max
        }
    }
}

enum EvolutionType: String, Codable {
    case balanced     = "バランス型"
    case active       = "アクティブ型"
    case sleepFocused = "安眠型"
    case gourmet      = "グルメ型"
    case neglected    = "放置型"
}

enum EggRarity: String, Codable {
    case normal   = "ノーマル"
    case silver   = "シルバー"
    case gold     = "ゴールド"
    case rainbow  = "レインボー"
}

// MARK: - ペットモデル

@Model
final class Pet {
    var id: UUID
    var name: String
    var species: Species
    var stage: GrowthStage
    var evolutionType: EvolutionType?
    var eggRarity: EggRarity

    // ステータス（0〜100）
    var hunger: Int     // お腹
    var stamina: Int    // 体力
    var happiness: Int  // 幸福度
    var weight: Int     // 体重

    // 成長
    var experience: Int
    var level: Int
    var reincarnationCount: Int

    // 遺産スキル（スキル名の配列として保持）
    var inheritedSkillNames: [String]

    // ヘルスデータ累計（ステータス計算用）
    var totalSteps: Int
    var totalActiveCalories: Double
    var totalSleepHours: Double
    var mealRecordCount: Int
    var foodBalanceScore: Double  // 0.0〜1.0の食事バランス評価

    // 日付
    var createdAt: Date
    var lastCaredAt: Date

    // カスタマイズ
    var equippedCostumeId: String?
    var equippedRoomDecoId: String?

    init(
        name: String,
        species: Species,
        eggRarity: EggRarity = .normal
    ) {
        self.id = UUID()
        self.name = name
        self.species = species
        self.stage = .egg
        self.evolutionType = nil
        self.eggRarity = eggRarity
        self.hunger = 80
        self.stamina = 80
        self.happiness = 80
        self.weight = 50
        self.experience = 0
        self.level = 1
        self.reincarnationCount = 0
        self.inheritedSkillNames = []
        self.totalSteps = 0
        self.totalActiveCalories = 0
        self.totalSleepHours = 0
        self.mealRecordCount = 0
        self.foodBalanceScore = 0.5
        self.createdAt = Date()
        self.lastCaredAt = Date()
    }
}

// MARK: - ステータス計算

extension Pet {
    /// 転生ボーナス倍率（上限 1.2）
    var reincarnationBonus: Double {
        min(1.0 + Double(reincarnationCount) * 0.05, 1.2)
    }

    /// バトル用 ATK
    var battleATK: Int {
        let base = Double(totalActiveCalories) / 100.0 + 5
        return Int(base * species.statMultipliers.atk * stage.stageMultiplier * reincarnationBonus)
    }

    /// バトル用 DEF
    var battleDEF: Int {
        let base = totalSleepHours / 50.0 + 5
        return Int(base * species.statMultipliers.def * stage.stageMultiplier * reincarnationBonus)
    }

    /// バトル用 SPD
    var battleSPD: Int {
        let base = Double(totalSteps) / 5000.0 + 5
        return Int(base * species.statMultipliers.spd * stage.stageMultiplier * reincarnationBonus)
    }

    /// バトル用 MAG
    var battleMAG: Int {
        let base = foodBalanceScore * Double(mealRecordCount) / 30.0 + 5
        return Int(base * species.statMultipliers.mag * stage.stageMultiplier * reincarnationBonus)
    }

    /// 最大 HP
    var maxHP: Int {
        level * 10 + stamina * 2
    }

    /// ステータスが全体的に低下しているか（世話不足）
    var isNeglected: Bool {
        hunger < 20 || stamina < 20 || happiness < 20
    }
}
