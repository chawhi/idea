import Foundation
import SwiftData

/// ペットの進化・ステータス更新・転生を管理するサービス
@MainActor
final class PetEvolutionService {
    static let shared = PetEvolutionService()
    private init() {}

    // MARK: - HealthKit データ → ペット反映

    /// 今日のヘルスデータをペットに反映（1時間ごとのバックグラウンド処理で呼ぶ）
    func applyHealthData(to pet: Pet, health: HealthKitService) {
        // 歩数 → お腹回復（1,000歩ごとに+5）
        let foodFromSteps = (health.todaySteps / 1000) * 5
        pet.hunger = min(100, pet.hunger + foodFromSteps)

        // 睡眠 → 体力回復
        if health.hasGoodSleep {
            pet.stamina = min(100, pet.stamina + 30)
        }

        // 運動 → 経験値ボーナス
        if health.hasWorkout {
            pet.experience += 50
        }

        // 心拍数が高すぎる（140以上）→ ストレスで幸福度低下
        if health.currentHeartRate > 140 {
            pet.happiness = max(0, pet.happiness - 5)
        }

        // 累計データ更新
        pet.totalSteps = max(pet.totalSteps, health.todaySteps)
        pet.totalActiveCalories += health.todayActiveCalories / 24  // 1時間分
        pet.totalSleepHours += health.todaySleepHours / 8            // 1時間分

        pet.lastCaredAt = Date()

        // 進化チェック
        checkEvolution(pet: pet, health: health)
    }

    // MARK: - 自然ステータス低下（時間経過）

    /// 時間経過でステータスが自然低下（1時間ごとに呼ぶ）
    func applyTimeDecay(to pet: Pet) {
        guard pet.stage != .egg else { return }
        pet.hunger    = max(0, pet.hunger    - 3)
        pet.stamina   = max(0, pet.stamina   - 1)
        pet.happiness = max(0, pet.happiness - 2)
    }

    // MARK: - ユーザーアクション

    func feedPet(_ pet: Pet, itemEffect: Int) {
        pet.hunger = min(100, pet.hunger + itemEffect)
        pet.experience += 5
    }

    func playWithPet(_ pet: Pet) {
        pet.happiness = min(100, pet.happiness + 15)
        pet.stamina   = max(0, pet.stamina - 5)
        pet.experience += 10
    }

    func talkToPet(_ pet: Pet) {
        pet.happiness = min(100, pet.happiness + 5)
        pet.experience += 3
    }

    // MARK: - 進化判定

    private func checkEvolution(pet: Pet, health: HealthKitService) {
        guard pet.experience >= pet.stage.experienceThreshold,
              pet.stage < .ultimate else { return }

        let nextStage: GrowthStage
        switch pet.stage {
        case .egg:    nextStage = .baby
        case .baby:   nextStage = .child
        case .child:  nextStage = .teen
        case .teen:   nextStage = .mature
        case .mature: nextStage = .ultimate
        case .ultimate: return
        }

        // 少年期→成熟 の分岐で進化タイプを確定
        if pet.stage == .teen {
            pet.evolutionType = evaluateEvolutionType(pet: pet)
        }

        pet.stage = nextStage
        pet.experience = 0
        pet.level += 1
    }

    func evaluateEvolutionType(pet: Pet) -> EvolutionType {
        guard pet.totalSteps > 0 else { return .neglected }

        // 7日間の平均目標歩数を 7,000 と仮定してスコア算出
        let stepScore    = min(1.0, Double(pet.totalSteps) / 49000.0)
        let sleepScore   = min(1.0, pet.totalSleepHours / 56.0)      // 7時間×7日
        let mealScore    = min(1.0, Double(pet.mealRecordCount) / 21.0) // 3食×7日
        let activeScore  = min(1.0, pet.totalActiveCalories / 2800.0)  // 400kcal×7日

        // 全て0.7以上 → バランス型
        if [stepScore, sleepScore, mealScore, activeScore].allSatisfy({ $0 >= 0.7 }) {
            return .balanced
        }
        // ステータスが全体的に低い → 放置型
        if [stepScore, sleepScore, mealScore, activeScore].filter({ $0 < 0.3 }).count >= 2 {
            return .neglected
        }

        // 最も高いスコアで分岐
        let scores: [(EvolutionType, Double)] = [
            (.active,       (stepScore + activeScore) / 2),
            (.sleepFocused, sleepScore),
            (.gourmet,      mealScore),
        ]
        return scores.max(by: { $0.1 < $1.1 })?.0 ?? .balanced
    }

    // MARK: - 転生

    struct ReincarnationResult {
        let inheritedSkills: [String]   // スキルID
        let newEggRarity: EggRarity
        let bonusCoins: Int
    }

    func reincarnate(pet: Pet) -> ReincarnationResult {
        guard pet.stage == .ultimate else {
            return ReincarnationResult(inheritedSkills: [], newEggRarity: .normal, bonusCoins: 0)
        }

        // 引き継ぎスキルを選定（最大2つ）
        let availableSkills = SkillCatalog.skills(for: pet.species)
        let inherited = Array(availableSkills.prefix(min(2, availableSkills.count))).map { $0.id }

        // たまごレア度を決定
        let rarity: EggRarity
        switch pet.reincarnationCount {
        case 0:     rarity = .silver
        case 1...2: rarity = .gold
        default:    rarity = pet.reincarnationCount >= 5 ? .rainbow : .gold
        }

        // 転生ボーナスコイン
        let coins = 200 + pet.reincarnationCount * 50

        // ペットリセット（転生回数とスキルのみ引き継ぎ）
        let newCount = pet.reincarnationCount + 1
        let allSkills = pet.inheritedSkillNames + inherited

        pet.stage               = .egg
        pet.evolutionType       = nil
        pet.eggRarity           = rarity
        pet.hunger              = 80
        pet.stamina             = 80
        pet.happiness           = 80
        pet.weight              = 50
        pet.experience          = 0
        pet.level               = 1
        pet.reincarnationCount  = newCount
        pet.inheritedSkillNames = Array(Set(allSkills))  // 重複排除
        pet.totalSteps          = 0
        pet.totalActiveCalories = 0
        pet.totalSleepHours     = 0
        pet.mealRecordCount     = 0
        pet.createdAt           = Date()

        return ReincarnationResult(
            inheritedSkills: inherited,
            newEggRarity: rarity,
            bonusCoins: coins
        )
    }
}
