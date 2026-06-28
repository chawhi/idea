import SwiftData
import Foundation

enum MealType: String, Codable, CaseIterable {
    case breakfast = "朝食"
    case lunch     = "昼食"
    case dinner    = "夕食"
    case snack     = "間食"

    var icon: String {
        switch self {
        case .breakfast: return "🌅"
        case .lunch:     return "☀️"
        case .dinner:    return "🌙"
        case .snack:     return "🍬"
        }
    }
}

enum FoodLogMethod: String, Codable {
    case text    = "テキスト入力"
    case camera  = "写真撮影"
    case barcode = "バーコード"
    case ocr     = "栄養成分表スキャン"
}

@Model
final class FoodRecord {
    var id: UUID
    var mealType: MealType
    var foodName: String
    var logMethod: FoodLogMethod

    // 栄養素（100g あたりではなく実際の摂取量）
    var calories: Double
    var protein: Double      // g
    var fat: Double          // g
    var carbohydrate: Double // g
    var fiber: Double        // g

    // メタデータ
    var recordedAt: Date
    var photoPath: String?   // 写真保存パス
    var barcodeValue: String?

    init(
        mealType: MealType,
        foodName: String,
        logMethod: FoodLogMethod,
        calories: Double,
        protein: Double = 0,
        fat: Double = 0,
        carbohydrate: Double = 0,
        fiber: Double = 0
    ) {
        self.id = UUID()
        self.mealType = mealType
        self.foodName = foodName
        self.logMethod = logMethod
        self.calories = calories
        self.protein = protein
        self.fat = fat
        self.carbohydrate = carbohydrate
        self.fiber = fiber
        self.recordedAt = Date()
        self.photoPath = nil
        self.barcodeValue = nil
    }
}

// MARK: - 栄養バランス評価

extension [FoodRecord] {
    /// 今日の食事記録からバランススコアを算出（0.0〜1.0）
    func balanceScore(for date: Date = .now) -> Double {
        let todayRecords = filter { Calendar.current.isDate($0.recordedAt, inSameDayAs: date) }
        guard !todayRecords.isEmpty else { return 0 }

        let totalCalories    = todayRecords.reduce(0) { $0 + $1.calories }
        let totalProtein     = todayRecords.reduce(0) { $0 + $1.protein }
        let totalFat         = todayRecords.reduce(0) { $0 + $1.fat }
        let totalCarbs       = todayRecords.reduce(0) { $0 + $1.carbohydrate }

        guard totalCalories > 0 else { return 0 }

        // PFC 比率を評価（目標: P=20%, F=25%, C=55%）
        let pRatio = (totalProtein * 4) / totalCalories   // タンパク質カロリー比
        let fRatio = (totalFat * 9)    / totalCalories   // 脂質カロリー比
        let cRatio = (totalCarbs * 4)  / totalCalories   // 炭水化物カロリー比

        let pScore = 1.0 - abs(pRatio - 0.20) / 0.20
        let fScore = 1.0 - abs(fRatio - 0.25) / 0.25
        let cScore = 1.0 - abs(cRatio - 0.55) / 0.55

        // 記録食数ボーナス（3食記録で満点）
        let mealTypes = Set(todayRecords.map { $0.mealType }.filter { $0 != .snack })
        let mealBonus = Double(mealTypes.count) / 3.0

        return max(0, min(1, (pScore + fScore + cScore) / 3.0 * 0.7 + mealBonus * 0.3))
    }
}
