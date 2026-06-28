import SwiftUI

struct ShopView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "cart.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.orange)
                Text("ショップ")
                    .font(.title2.bold())
                Text("Phase 5 で StoreKit 2 と共に実装予定")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .navigationTitle("ショップ")
        }
    }
}
