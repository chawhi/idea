import SwiftUI
import SwiftData

struct HomeView: View {
    @Bindable var pet: Pet
    @StateObject private var health = HealthKitService.shared
    @State private var showFoodLog  = false
    @State private var showStatus   = false
    @State private var actionMessage: String? = nil
    @State private var showMessage  = false

    private let evolution = PetEvolutionService.shared

    var body: some View {
        ZStack {
            // 背景
            StageBackground(stage: pet.stage)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 上部：歩数バー
                StepProgressBar(steps: health.todaySteps, goal: 8000)
                    .padding(.horizontal)
                    .padding(.top, 8)

                // ペット表示エリア
                PetDisplayArea(pet: pet, onTap: handleTap)
                    .frame(maxHeight: .infinity)

                // ステータスバー
                PetStatusBars(pet: pet)
                    .padding(.horizontal)

                // アクションボタン
                ActionButtons(
                    onFeed:  { feedPet()  },
                    onPlay:  { playPet()  },
                    onTalk:  { talkPet()  },
                    onFood:  { showFoodLog = true }
                )
                .padding()

                // 今日の入手アイテムプレビュー
                TodayItemsPreview(steps: health.todaySteps)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }

            // アクションフィードバック
            if showMessage, let msg = actionMessage {
                ActionFeedback(message: msg)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showFoodLog)  { FoodLogView() }
        .sheet(isPresented: $showStatus)   { PetStatusView(pet: pet) }
        .task {
            try? await health.requestAuthorization()
        }
        .onAppear {
            evolution.applyTimeDecay(to: pet)
        }
    }

    // MARK: - アクション

    private func handleTap() {
        evolution.talkToPet(pet)
        showFeedback("よしよし！ 😊")
    }

    private func feedPet() {
        evolution.feedPet(pet, itemEffect: 15)
        showFeedback("もぐもぐ… 🍚")
    }

    private func playPet() {
        evolution.playWithPet(pet)
        showFeedback("わーい！ 🎉")
    }

    private func talkPet() {
        evolution.talkToPet(pet)
        let phrases = ["クル〜♪", "げんき！", "あそぼ〜", "うれしいな"]
        showFeedback(phrases.randomElement()!)
    }

    private func showFeedback(_ message: String) {
        actionMessage = message
        withAnimation(.spring()) { showMessage = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { showMessage = false }
        }
    }
}

// MARK: - サブビュー

struct StepProgressBar: View {
    let steps: Int
    let goal: Int

    var progress: Double { min(Double(steps) / Double(goal), 1.0) }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "figure.walk")
                Text("\(steps.formatted()) 歩")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                Spacer()
                Text("目標 \(goal.formatted())")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 10)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(LinearGradient(colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * progress, height: 10)
                        .animation(.spring(), value: progress)
                }
            }
            .frame(height: 10)
        }
        .foregroundStyle(.white)
        .padding(10)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct PetDisplayArea: View {
    let pet: Pet
    let onTap: () -> Void
    @State private var isPressed = false

    var body: some View {
        VStack(spacing: 8) {
            // ペットアニメーション（Phase 1 ではプレースホルダー）
            ZStack {
                Circle()
                    .fill(speciesColor(pet.species).opacity(0.2))
                    .frame(width: 180, height: 180)

                Text(petEmoji(pet.species, stage: pet.stage))
                    .font(.system(size: 100))
                    .scaleEffect(isPressed ? 0.85 : 1.0)
                    .animation(.spring(response: 0.3), value: isPressed)
            }
            .onTapGesture {
                isPressed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { isPressed = false }
                onTap()
            }

            Text(pet.name)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(.white)

            Text("\(pet.species.displayName)族 / \(pet.stage.rawValue)")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(.white.opacity(0.15))
                .clipShape(Capsule())
        }
    }

    private func petEmoji(_ species: Species, stage: GrowthStage) -> String {
        switch stage {
        case .egg:     return "🥚"
        case .baby:    return species == .flare ? "🔥" : species == .marine ? "💧" : species == .terra ? "🌱" : species == .sylph ? "🌬️" : "⭐"
        case .child:   return species == .flare ? "🦊" : species == .marine ? "🐠" : species == .terra ? "🐻" : species == .sylph ? "🐦" : "🐱"
        case .teen:    return species == .flare ? "🦁" : species == .marine ? "🐬" : species == .terra ? "🐗" : species == .sylph ? "🦅" : "🦋"
        case .mature:  return species == .flare ? "🐲" : species == .marine ? "🧜" : species == .terra ? "🦣" : species == .sylph ? "🌪️" : "🌙"
        case .ultimate: return species == .flare ? "🦄" : species == .marine ? "🐉" : species == .terra ? "🗿" : species == .sylph ? "⚡" : "✨"
        }
    }

    private func speciesColor(_ species: Species) -> Color {
        switch species {
        case .flare:  return .orange
        case .marine: return .blue
        case .terra:  return .green
        case .sylph:  return .cyan
        case .luna:   return .purple
        }
    }
}

struct PetStatusBars: View {
    let pet: Pet

    var body: some View {
        VStack(spacing: 6) {
            StatusBar(label: "❤️ お腹", value: pet.hunger,   color: .red)
            StatusBar(label: "💤 体力", value: pet.stamina,  color: .blue)
            StatusBar(label: "😊 幸福", value: pet.happiness, color: .yellow)
        }
        .padding(10)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct StatusBar: View {
    let label: String
    let value: Int
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.white)
                .frame(width: 60, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.2))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geo.size.width * Double(value) / 100)
                        .animation(.spring(), value: value)
                }
            }
            .frame(height: 8)
            Text("\(value)")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 28, alignment: .trailing)
        }
    }
}

struct ActionButtons: View {
    let onFeed:  () -> Void
    let onPlay:  () -> Void
    let onTalk:  () -> Void
    let onFood:  () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ActionButton(icon: "fork.knife",    label: "ごはん",   action: onFeed)
            ActionButton(icon: "gamecontroller", label: "あそぶ",   action: onPlay)
            ActionButton(icon: "bubble.left",   label: "はなす",   action: onTalk)
            ActionButton(icon: "camera",         label: "きろく",   action: onFood)
        }
    }
}

struct ActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)
                Text(label)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(.white.opacity(0.15))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct TodayItemsPreview: View {
    let steps: Int

    var foodItems: Int { steps / 1000 }
    var nextItemIn: Int { 1000 - (steps % 1000) }

    var body: some View {
        HStack {
            Label("今日の入手: 🍚×\(foodItems)", systemImage: "gift")
                .font(.caption)
                .foregroundStyle(.white)
            Spacer()
            Text("あと \(nextItemIn) 歩で +1")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct StageBackground: View {
    let stage: GrowthStage

    var colors: [Color] {
        switch stage {
        case .egg:     return [.indigo, .purple]
        case .baby:    return [.teal, .green]
        case .child:   return [.green, .mint]
        case .teen:    return [.orange, .yellow]
        case .mature:  return [.red, .orange]
        case .ultimate: return [.purple, .indigo]
        }
    }

    var body: some View {
        LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

struct ActionFeedback: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.system(.title3, design: .rounded, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.6))
            .clipShape(Capsule())
            .padding(.top, 100)
            .frame(maxHeight: .infinity, alignment: .top)
    }
}
