import SwiftUI
import SwiftData

@main
struct VitaPetApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Pet.self, Item.self, FoodRecord.self)
        } catch {
            fatalError("SwiftData の初期化に失敗: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
        }
    }
}
