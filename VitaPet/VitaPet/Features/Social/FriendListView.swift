import SwiftUI

struct FriendListView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.blue)
                Text("フレンド機能")
                    .font(.title2.bold())
                Text("Phase 4 で Firebase 連携と共に実装予定")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .navigationTitle("フレンド")
        }
    }
}
