import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var pets: [Pet]
    @State private var selectedTab: Tab = .home

    enum Tab { case home, pokedex, battle, social, shop }

    var body: some View {
        if pets.isEmpty {
            OnboardingView()
        } else {
            TabView(selection: $selectedTab) {
                HomeView(pet: pets[0])
                    .tabItem { Label("ホーム", systemImage: "house.fill") }
                    .tag(Tab.home)

                PokedexView()
                    .tabItem { Label("図鑑", systemImage: "books.vertical.fill") }
                    .tag(Tab.pokedex)

                BattleMenuView(pet: pets[0])
                    .tabItem { Label("バトル", systemImage: "bolt.fill") }
                    .tag(Tab.battle)

                FriendListView()
                    .tabItem { Label("フレンド", systemImage: "person.2.fill") }
                    .tag(Tab.social)

                ShopView()
                    .tabItem { Label("ショップ", systemImage: "cart.fill") }
                    .tag(Tab.shop)
            }
            .tint(.orange)
        }
    }
}
