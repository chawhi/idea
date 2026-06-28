import SwiftUI

struct BattleMenuView: View {
    let pet: Pet

    var body: some View {
        NavigationStack {
            List {
                Section("あなたのペット") {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(pet.name).font(.headline)
                            Text("ATK: \(pet.battleATK)  DEF: \(pet.battleDEF)  SPD: \(pet.battleSPD)")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(pet.stage == .ultimate ? "完全体" : pet.stage.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Color.orange.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }

                Section("バトルモード") {
                    battleRow(icon: "person.2.fill",    label: "フレンド対戦",    color: .blue,   note: "Coming Soon")
                    battleRow(icon: "shuffle",           label: "ランダム対戦",    color: .green,  note: "Coming Soon")
                    battleRow(icon: "trophy.fill",       label: "週次ランキング",  color: .orange, note: "Coming Soon")
                }

                Section("スキル設定") {
                    ForEach(Array(pet.inheritedSkillNames.prefix(3).enumerated()), id: \.offset) { idx, skillId in
                        if let skill = SkillCatalog.skill(id: skillId) {
                            HStack {
                                Text("スロット \(idx + 1)")
                                    .font(.caption).foregroundStyle(.secondary)
                                Text(skill.name).font(.subheadline)
                                Spacer()
                                Text(skill.category.rawValue)
                                    .font(.caption2)
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(Color.purple.opacity(0.2))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    if pet.inheritedSkillNames.isEmpty {
                        Text("スキルはペットが成長すると解放されます")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("バトル")
        }
    }

    private func battleRow(icon: String, label: String, color: Color, note: String) -> some View {
        HStack {
            Image(systemName: icon).foregroundStyle(color)
            Text(label)
            Spacer()
            Text(note).font(.caption).foregroundStyle(.secondary)
        }
    }
}
