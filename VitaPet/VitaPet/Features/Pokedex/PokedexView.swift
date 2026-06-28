import SwiftUI

struct PokedexView: View {
    @State private var selectedSpecies: Species? = nil

    var body: some View {
        NavigationStack {
            List {
                ForEach(Species.allCases, id: \.self) { species in
                    Section(header: Text(species.displayName + "族")) {
                        SpeciesPokedexRow(species: species)
                    }
                }
            }
            .navigationTitle("図鑑")
        }
    }
}

struct SpeciesPokedexRow: View {
    let species: Species

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(GrowthStage.allCases, id: \.self) { stage in
                    PokedexCell(species: species, stage: stage, discovered: true)
                }
            }
            .padding(.vertical, 8)
        }
    }
}

struct PokedexCell: View {
    let species: Species
    let stage: GrowthStage
    let discovered: Bool  // 未実装：SwiftData から発見フラグを取得する

    private var emoji: String {
        guard discovered else { return "❓" }
        switch stage {
        case .egg:      return "🥚"
        case .baby:     return "🔮"
        case .child:    return "✨"
        case .teen:     return "⚡"
        case .mature:   return "🌟"
        case .ultimate: return "👑"
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(emoji)
                .font(.title)
                .frame(width: 60, height: 60)
                .background(discovered ? Color.orange.opacity(0.1) : Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            Text(stage.rawValue)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
    }
}
