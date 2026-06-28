import SwiftData
import Foundation

enum ItemCategory: String, Codable, CaseIterable {
    case food       = "食べ物"
    case recovery   = "回復"
    case training   = "強化"
    case rare       = "レア"
    case costume    = "着せ替え"
    case roomDeco   = "部屋デコ"
}

enum ItemEffect: Codable {
    case hunger(Int)        // お腹回復
    case stamina(Int)       // 体力回復
    case happiness(Int)     // 幸福度回復
    case experience(Int)    // 経験値付与
    case expBoostPercent(Int, hours: Int)  // 経験値ブースト（%、時間）
    case costume(String)    // 着せ替えID
    case roomDeco(String)   // 部屋デコID
}

@Model
final class Item {
    var id: UUID
    var name: String
    var category: ItemCategory
    var quantity: Int
    var iconName: String    // SF Symbols or asset name
    var descriptionText: String
    var effectData: Data    // ItemEffect を JSON エンコード

    init(name: String, category: ItemCategory, quantity: Int = 1,
         iconName: String, description: String) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.quantity = quantity
        self.iconName = iconName
        self.descriptionText = description
        self.effectData = Data()
    }
}

// MARK: - 定義済みアイテムカタログ

struct ItemCatalog {
    static let all: [ItemTemplate] = [
        ItemTemplate(id: "food_rice",      name: "ごはん粒",        category: .food,     icon: "🍚", description: "お腹を15回復する",      effect: .hunger(15)),
        ItemTemplate(id: "food_meat",      name: "おにく",          category: .food,     icon: "🍖", description: "お腹を30回復する",      effect: .hunger(30)),
        ItemTemplate(id: "recovery_sleep", name: "ぐっすりの実",    category: .recovery, icon: "💤", description: "体力を30回復する",      effect: .stamina(30)),
        ItemTemplate(id: "recovery_herb",  name: "げんきのはっぱ",  category: .recovery, icon: "🌿", description: "幸福度を20回復する",    effect: .happiness(20)),
        ItemTemplate(id: "training_iron",  name: "きんにくのかけら", category: .training, icon: "💪", description: "経験値を100獲得",       effect: .experience(100)),
        ItemTemplate(id: "boost_balance",  name: "バランスボーナス", category: .rare,     icon: "⭐", description: "経験値+50%（3時間）",   effect: .expBoostPercent(50, hours: 3)),
        ItemTemplate(id: "rare_leaf",      name: "ちからの葉っぱ",  category: .rare,     icon: "🍃", description: "経験値を200獲得",       effect: .experience(200)),
    ]

    static func template(id: String) -> ItemTemplate? {
        all.first { $0.id == id }
    }
}

struct ItemTemplate {
    let id: String
    let name: String
    let category: ItemCategory
    let icon: String
    let description: String
    let effect: ItemEffect
}
