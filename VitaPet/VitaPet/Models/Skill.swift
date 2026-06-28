import Foundation

enum SkillCategory: String, Codable {
    case attack  = "攻撃"
    case defense = "防御"
    case support = "補助"
}

enum SkillStatRef: String, Codable {
    case atk, def, spd, mag, hp
}

struct SkillEffect: Codable {
    enum EffectType: String, Codable {
        case damage         // ダメージ
        case damageMultiHit // 複数ヒット
        case heal           // HP 回復
        case buffSelf       // 自己強化
        case debuffEnemy    // 相手弱体
        case barrier        // ダメージ無効
        case dodge          // 回避率UP
    }

    let type: EffectType
    let statRef: SkillStatRef?  // 参照するステータス（ダメージ計算用）
    let multiplier: Double      // 倍率
    let hitCount: Int           // ヒット数（複数ヒット用）
    let turns: Int              // 効果持続ターン
    let selfCostHP: Double      // 自己コスト（HP%消費）

    init(
        type: EffectType,
        statRef: SkillStatRef? = .atk,
        multiplier: Double = 1.0,
        hitCount: Int = 1,
        turns: Int = 1,
        selfCostHP: Double = 0
    ) {
        self.type = type
        self.statRef = statRef
        self.multiplier = multiplier
        self.hitCount = hitCount
        self.turns = turns
        self.selfCostHP = selfCostHP
    }
}

struct Skill: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let species: Species
    let category: SkillCategory
    let effect: SkillEffect
    let description: String
    let unlockCondition: String  // 解放条件テキスト

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Skill, rhs: Skill) -> Bool { lhs.id == rhs.id }
}

// MARK: - 全スキル定義

struct SkillCatalog {
    static let all: [Skill] = flareSkills + marineSkills + terraSkills + sylphSkills + lunaSkills

    static func skills(for species: Species) -> [Skill] {
        all.filter { $0.species == species }
    }

    static func skill(id: String) -> Skill? {
        all.first { $0.id == id }
    }

    // MARK: フレア族
    static let flareSkills: [Skill] = [
        Skill(id: "flare_punch",    name: "フレアパンチ",    species: .flare, category: .attack,
              effect: SkillEffect(type: .damage, multiplier: 1.2),
              description: "ATK×1.2のダメージ", unlockCondition: "子供期到達"),
        Skill(id: "flame_wall",     name: "ほのおのかべ",    species: .flare, category: .defense,
              effect: SkillEffect(type: .buffSelf, statRef: .def, multiplier: 1.5, turns: 1),
              description: "1ターンDEF+50%", unlockCondition: "少年期到達"),
        Skill(id: "flamethrower",   name: "かえんほうしゃ",  species: .flare, category: .attack,
              effect: SkillEffect(type: .damage, multiplier: 0.8),
              description: "ATK×0.8の全体攻撃", unlockCondition: "成熟期到達"),
        Skill(id: "phoenix_rise",   name: "フェニックスライズ", species: .flare, category: .support,
              effect: SkillEffect(type: .heal, statRef: .hp, multiplier: 0.3),
              description: "HP30%回復（1回限り）", unlockCondition: "完全体（バランス型）"),
        Skill(id: "blaze_rush",     name: "ブレイズラッシュ", species: .flare, category: .attack,
              effect: SkillEffect(type: .damage, multiplier: 2.0, selfCostHP: 0.1),
              description: "ATK×2.0だが次ターンATK-20%", unlockCondition: "完全体（アクティブ型）"),
        Skill(id: "warm_heart",     name: "ウォームハート",  species: .flare, category: .support,
              effect: SkillEffect(type: .debuffEnemy, statRef: .atk, multiplier: 0.8, turns: 1),
              description: "相手のATKを1ターン-20%", unlockCondition: "転生後解放"),
    ]

    // MARK: マリン族
    static let marineSkills: [Skill] = [
        Skill(id: "aqua_shot",      name: "アクアショット",  species: .marine, category: .attack,
              effect: SkillEffect(type: .damage, multiplier: 1.1),
              description: "ATK×1.1のダメージ", unlockCondition: "子供期到達"),
        Skill(id: "bubble_shield",  name: "バブルシールド",  species: .marine, category: .defense,
              effect: SkillEffect(type: .barrier),
              description: "ダメージを1回完全無効化", unlockCondition: "少年期到達"),
        Skill(id: "tidal_wave",     name: "タイダルウェーブ", species: .marine, category: .attack,
              effect: SkillEffect(type: .damage, multiplier: 1.5),
              description: "ATK×1.5＋相手SPD-10%", unlockCondition: "成熟期到達"),
        Skill(id: "ocean_heal",     name: "オーシャンヒール", species: .marine, category: .support,
              effect: SkillEffect(type: .heal, statRef: .hp, multiplier: 0.2),
              description: "HP20%回復", unlockCondition: "完全体（安眠型）"),
        Skill(id: "deep_current",   name: "ディープカレント", species: .marine, category: .attack,
              effect: SkillEffect(type: .damage, statRef: .mag, multiplier: 1.8),
              description: "MAG×1.8のダメージ", unlockCondition: "完全体（バランス型）"),
        Skill(id: "mist_veil",      name: "ミストヴェール",  species: .marine, category: .defense,
              effect: SkillEffect(type: .dodge, turns: 2),
              description: "2ターン相手の命中率-30%", unlockCondition: "転生後解放"),
    ]

    // MARK: テラ族
    static let terraSkills: [Skill] = [
        Skill(id: "rock_smash",     name: "ロックスマッシュ", species: .terra, category: .attack,
              effect: SkillEffect(type: .damage, multiplier: 1.3),
              description: "ATK×1.3のダメージ", unlockCondition: "子供期到達"),
        Skill(id: "granite_armor",  name: "グラニットアーマー", species: .terra, category: .defense,
              effect: SkillEffect(type: .buffSelf, statRef: .def, multiplier: 1.3, turns: 3),
              description: "3ターンDEF+30%", unlockCondition: "少年期到達"),
        Skill(id: "earthquake",     name: "アースクエイク",  species: .terra, category: .attack,
              effect: SkillEffect(type: .damage, multiplier: 1.4),
              description: "ATK×1.4＋相手DEF-10%", unlockCondition: "成熟期到達"),
        Skill(id: "terra_regen",    name: "テラリジェネ",    species: .terra, category: .support,
              effect: SkillEffect(type: .heal, statRef: .hp, multiplier: 0.1, turns: 3),
              description: "3ターン毎ターンHP+10回復", unlockCondition: "完全体（バランス型）"),
        Skill(id: "mountain_crush", name: "マウンテンクラッシュ", species: .terra, category: .attack,
              effect: SkillEffect(type: .damage, multiplier: 2.5, selfCostHP: 0.1),
              description: "ATK×2.5（自分もHP10%消費）", unlockCondition: "完全体（アクティブ型）"),
        Skill(id: "anchor_body",    name: "アンカーボディ",  species: .terra, category: .defense,
              effect: SkillEffect(type: .barrier, turns: 1),
              description: "1ターン完全無敵", unlockCondition: "転生後解放"),
    ]

    // MARK: シルフ族
    static let sylphSkills: [Skill] = [
        Skill(id: "wind_slash",     name: "ウィンドスラッシュ", species: .sylph, category: .attack,
              effect: SkillEffect(type: .damage, statRef: .spd, multiplier: 1.1),
              description: "ATK×1.1（SPDが高いほど威力UP）", unlockCondition: "子供期到達"),
        Skill(id: "air_raid",       name: "エアイレイド",    species: .sylph, category: .attack,
              effect: SkillEffect(type: .damageMultiHit, multiplier: 0.7, hitCount: 2),
              description: "ATK×0.7を2回ヒット", unlockCondition: "少年期到達"),
        Skill(id: "storm_dodge",    name: "ストームダッジ",  species: .sylph, category: .defense,
              effect: SkillEffect(type: .dodge, multiplier: 0.6, turns: 1),
              description: "1ターン回避率+60%", unlockCondition: "成熟期到達"),
        Skill(id: "gale_charge",    name: "ゲイルチャージ",  species: .sylph, category: .support,
              effect: SkillEffect(type: .buffSelf, statRef: .spd, multiplier: 1.3, turns: 2),
              description: "自分のSPD+30%（2ターン）", unlockCondition: "完全体（アクティブ型）"),
        Skill(id: "thunderbolt",    name: "サンダーボルト",  species: .sylph, category: .attack,
              effect: SkillEffect(type: .damage, statRef: .mag, multiplier: 2.0),
              description: "MAG×2.0のダメージ", unlockCondition: "完全体（バランス型）"),
        Skill(id: "speed_steal",    name: "スピードスティール", species: .sylph, category: .support,
              effect: SkillEffect(type: .debuffEnemy, statRef: .spd, multiplier: 0.0, turns: 1),
              description: "相手のSPDを奪って自分に加算", unlockCondition: "転生後解放"),
    ]

    // MARK: ルナ族
    static let lunaSkills: [Skill] = [
        Skill(id: "stardust",       name: "スターダスト",   species: .luna, category: .attack,
              effect: SkillEffect(type: .damage, statRef: .mag, multiplier: 1.2),
              description: "MAG×1.2のダメージ", unlockCondition: "子供期到達"),
        Skill(id: "moon_shield",    name: "ムーンシールド",  species: .luna, category: .defense,
              effect: SkillEffect(type: .barrier, statRef: .mag, multiplier: 0.5),
              description: "ダメージをMAG×0.5軽減", unlockCondition: "少年期到達"),
        Skill(id: "lunatic_beam",   name: "ルナティックビーム", species: .luna, category: .attack,
              effect: SkillEffect(type: .damage, statRef: .mag, multiplier: 1.8),
              description: "MAG×1.8のダメージ", unlockCondition: "成熟期到達"),
        Skill(id: "star_fall",      name: "スターフォール",  species: .luna, category: .attack,
              effect: SkillEffect(type: .damageMultiHit, statRef: .mag, multiplier: 1.0, hitCount: 3),
              description: "MAG×1.0を3回ヒット", unlockCondition: "完全体（バランス型）"),
        Skill(id: "cosmic_curse",   name: "コスミックカース", species: .luna, category: .support,
              effect: SkillEffect(type: .debuffEnemy, multiplier: 0.85, turns: 2),
              description: "相手の全ステータス-15%（2ターン）", unlockCondition: "完全体（グルメ型）"),
        Skill(id: "eclipse",        name: "エクリプス",     species: .luna, category: .attack,
              effect: SkillEffect(type: .damage, multiplier: 1.5),
              description: "ATK×1.5＋自分HP20%回復", unlockCondition: "転生後解放"),
    ]
}
