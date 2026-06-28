import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @State private var selectedSpecies: Species = .flare
    @State private var petName: String = ""
    @State private var step: OnboardingStep = .welcome
    @State private var isCreating = false

    enum OnboardingStep {
        case welcome, healthPermission, speciesSelect, naming, done
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [.indigo, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            switch step {
            case .welcome:
                WelcomeStep(onNext: { step = .healthPermission })
            case .healthPermission:
                HealthPermissionStep(onNext: { step = .speciesSelect })
            case .speciesSelect:
                SpeciesSelectStep(selected: $selectedSpecies, onNext: { step = .naming })
            case .naming:
                NamingStep(
                    species: selectedSpecies,
                    name: $petName,
                    onNext: { createPet() }
                )
            case .done:
                EmptyView()  // ContentView が自動で切り替わる
            }
        }
        .animation(.easeInOut, value: step)
    }

    private func createPet() {
        guard !petName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isCreating = true
        let pet = Pet(name: petName, species: selectedSpecies)
        context.insert(pet)
        step = .done
    }
}

// MARK: - ステップビュー群

struct WelcomeStep: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            Text("✨ VitaPet ✨")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("あなたの毎日の健康が\nペットを育てる")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
            Spacer()
            Button("はじめる") { onNext() }
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.purple)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
        }
    }
}

struct HealthPermissionStep: View {
    let onNext: () -> Void
    @StateObject private var health = HealthKitService.shared

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "heart.fill")
                .font(.system(size: 64))
                .foregroundStyle(.pink)
            Text("ヘルスケアと連携する")
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
            Text("歩数・睡眠・運動のデータを使って\nペットに影響を与えます。\nデータはあなたのデバイスに保存されます。")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
            Button("ヘルスケアを許可する") {
                Task {
                    try? await health.requestAuthorization()
                    onNext()
                }
            }
            .font(.system(.headline, design: .rounded))
            .foregroundStyle(.purple)
            .frame(maxWidth: .infinity)
            .padding()
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 40)

            Button("スキップ") { onNext() }
                .foregroundStyle(.white.opacity(0.7))
                .padding(.bottom, 60)
        }
    }
}

struct SpeciesSelectStep: View {
    @Binding var selected: Species
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("なかまを えらぼう！")
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
                .padding(.top, 60)

            TabView(selection: $selected) {
                ForEach(Species.allCases, id: \.self) { species in
                    SpeciesCard(species: species)
                        .tag(species)
                }
            }
            .tabViewStyle(.page)
            .frame(height: 360)

            Button("このこにする！") { onNext() }
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.purple)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
        }
    }
}

struct SpeciesCard: View {
    let species: Species

    private var emoji: String {
        switch species {
        case .flare:  return "🔥"
        case .marine: return "💧"
        case .terra:  return "🌿"
        case .sylph:  return "🌬️"
        case .luna:   return "⭐"
        }
    }

    private var description: String {
        switch species {
        case .flare:  return "情熱的で元気いっぱい。\n運動が好きなあなたにぴったり！"
        case .marine: return "穏やかで癒し系。\n睡眠をしっかりとるあなたに。"
        case .terra:  return "安定感があって頼もしい。\nバランスよく生活したいあなたに。"
        case .sylph:  return "すばしっこくて自由奔放。\nたくさん歩くあなたにぴったり！"
        case .luna:   return "ミステリアスで知的。\n食事に気を使うあなたに。"
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(emoji)
                .font(.system(size: 80))
            Text(species.displayName + "族")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
            Text("属性: \(species.attributeName)")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
                .background(.white.opacity(0.15))
                .clipShape(Capsule())
            Text(description)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(24)
        .background(.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal, 32)
    }
}

struct NamingStep: View {
    let species: Species
    @Binding var name: String
    let onNext: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("なまえを つけよう！")
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundStyle(.white)

            Text(species == .flare ? "🥚🔥" : species == .marine ? "🥚💧" : species == .terra ? "🥚🌿" : species == .sylph ? "🥚🌬️" : "🥚⭐")
                .font(.system(size: 80))

            TextField("なまえを入力", text: $name)
                .font(.system(.title2, design: .rounded))
                .multilineTextAlignment(.center)
                .padding()
                .background(.white.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 40)
                .focused($isFocused)
                .onSubmit { if !name.isEmpty { onNext() } }

            Spacer()

            Button("たまごを もらう！") { onNext() }
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.purple)
                .frame(maxWidth: .infinity)
                .padding()
                .background(name.isEmpty ? Color.gray : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .onAppear { isFocused = true }
    }
}
