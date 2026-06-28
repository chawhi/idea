import SwiftUI

struct PetStatusView: View {
    @Bindable var pet: Pet
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // ペットサマリー
                    petHeader

                    // 基本ステータス
                    GroupBox("基本ステータス") {
                        VStack(spacing: 10) {
                            statRow(label: "お腹",   value: pet.hunger,    max: 100, color: .red)
                            statRow(label: "体力",   value: pet.stamina,   max: 100, color: .blue)
                            statRow(label: "幸福度", value: pet.happiness, max: 100, color: .yellow)
                            statRow(label: "体重",   value: pet.weight,    max: 100, color: .green)
                        }
                    }

                    // バトル能力値
                    GroupBox("バトル能力値") {
                        VStack(spacing: 10) {
                            abilityRow(label: "攻撃力 (ATK)", value: pet.battleATK)
                            abilityRow(label: "防御力 (DEF)", value: pet.battleDEF)
                            abilityRow(label: "素早さ (SPD)", value: pet.battleSPD)
                            abilityRow(label: "魔力  (MAG)", value: pet.battleMAG)
                            abilityRow(label: "最大 HP",     value: pet.maxHP)
                        }
                    }

                    // 遺産スキル
                    if !pet.inheritedSkillNames.isEmpty {
                        GroupBox("引き継ぎスキル") {
                            ForEach(pet.inheritedSkillNames, id: \.self) { skillId in
                                if let skill = SkillCatalog.skill(id: skillId) {
                                    HStack {
                                        Text(skill.name)
                                            .font(.subheadline)
                                        Spacer()
                                        Text(skill.category.rawValue)
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(Color.purple.opacity(0.2))
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    }

                    // 進化情報
                    GroupBox("進化情報") {
                        VStack(alignment: .leading, spacing: 8) {
                            if pet.stage < .ultimate {
                                let progress = Double(pet.experience) / Double(pet.stage.experienceThreshold)
                                Text("次の進化まで")
                                    .font(.subheadline)
                                ProgressView(value: progress)
                                    .tint(.orange)
                                Text("経験値 \(pet.experience) / \(pet.stage.experienceThreshold)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("完全体に到達しています！")
                                    .font(.subheadline)
                                    .foregroundStyle(.orange)
                                Button("転生する") { }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.purple)
                            }

                            if let evoType = pet.evolutionType {
                                Divider()
                                Label("進化タイプ: \(evoType.rawValue)", systemImage: "arrow.up.circle")
                                    .font(.subheadline)
                            }

                            Text("転生回数: \(pet.reincarnationCount) 回")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
            }
            .navigationTitle("\(pet.name) のステータス")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }

    private var petHeader: some View {
        VStack(spacing: 4) {
            Text(pet.name)
                .font(.system(.title, design: .rounded, weight: .bold))
            Text("Lv.\(pet.level)  \(pet.species.displayName)族  \(pet.stage.rawValue)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func statRow(label: String, value: Int, max: Int, color: Color) -> some View {
        HStack {
            Text(label)
                .frame(width: 56, alignment: .leading)
                .font(.subheadline)
            ProgressView(value: Double(value), total: Double(max))
                .tint(color)
            Text("\(value)/\(max)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 48, alignment: .trailing)
        }
    }

    private func abilityRow(label: String, value: Int) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
            Spacer()
            Text("\(value)")
                .font(.system(.subheadline, design: .monospaced, weight: .bold))
                .foregroundStyle(.orange)
        }
    }
}
