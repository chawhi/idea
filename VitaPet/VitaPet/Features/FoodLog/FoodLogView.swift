import SwiftUI
import SwiftData
import AVFoundation

struct FoodLogView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \FoodRecord.recordedAt, order: .reverse) private var records: [FoodRecord]

    @State private var showCamera   = false
    @State private var showBarcode  = false
    @State private var showText     = false
    @State private var selectedMeal: MealType = .lunch

    private var todayRecords: [FoodRecord] {
        records.filter { Calendar.current.isDateInToday($0.recordedAt) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 記録方法選択
                    inputMethodPicker

                    // 今日の記録
                    if !todayRecords.isEmpty {
                        todayLog
                    }

                    // 栄養バランス
                    if todayRecords.count >= 2 {
                        nutritionBalance
                    }
                }
                .padding()
            }
            .navigationTitle("食事記録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
            .sheet(isPresented: $showText)    { TextInputFoodView(mealType: selectedMeal) }
            .sheet(isPresented: $showBarcode) { BarcodeScanView(mealType: selectedMeal) }
            .sheet(isPresented: $showCamera)  { CameraFoodView(mealType: selectedMeal) }
        }
    }

    // MARK: - 入力方法ピッカー

    private var inputMethodPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("記録する食事")
                .font(.headline)

            // 食事タイプ選択
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(MealType.allCases, id: \.self) { meal in
                        Button {
                            selectedMeal = meal
                        } label: {
                            Label(meal.rawValue, systemImage: "")
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedMeal == meal ? Color.orange : Color.gray.opacity(0.2))
                                .foregroundStyle(selectedMeal == meal ? .white : .primary)
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            // 入力方法ボタン
            HStack(spacing: 12) {
                LogMethodButton(icon: "📷", label: "写真撮影", color: .blue) {
                    showCamera = true
                }
                LogMethodButton(icon: "📊", label: "バーコード", color: .green) {
                    showBarcode = true
                }
                LogMethodButton(icon: "✏️", label: "テキスト", color: .orange) {
                    showText = true
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 2)
    }

    // MARK: - 今日の記録リスト

    private var todayLog: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今日の記録")
                .font(.headline)

            ForEach(MealType.allCases, id: \.self) { meal in
                let mealRecords = todayRecords.filter { $0.mealType == meal }
                if !mealRecords.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Label(meal.rawValue, systemImage: "")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        ForEach(mealRecords) { record in
                            FoodRecordRow(record: record)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 2)
    }

    // MARK: - 栄養バランス

    private var nutritionBalance: some View {
        let score = todayRecords.balanceScore()
        let totalCal = todayRecords.reduce(0) { $0 + $1.calories }

        return VStack(alignment: .leading, spacing: 12) {
            Text("栄養バランス")
                .font(.headline)

            HStack {
                VStack(alignment: .leading) {
                    Text("合計カロリー")
                        .font(.caption).foregroundStyle(.secondary)
                    Text("\(Int(totalCal)) kcal")
                        .font(.title2).bold()
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("バランススコア")
                        .font(.caption).foregroundStyle(.secondary)
                    Text(String(format: "%.0f%%", score * 100))
                        .font(.title2).bold()
                        .foregroundStyle(score > 0.7 ? .green : score > 0.4 ? .orange : .red)
                }
            }

            if score >= 0.7 {
                Label("バランスボーナス発動中！経験値+50% 🎉", systemImage: "star.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 2)
    }
}

// MARK: - サブビュー

struct LogMethodButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(icon).font(.title2)
                Text(label).font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct FoodRecordRow: View {
    let record: FoodRecord

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(record.foodName).font(.subheadline)
                Text("\(Int(record.calories)) kcal  P:\(Int(record.protein))g  F:\(Int(record.fat))g  C:\(Int(record.carbohydrate))g")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: logMethodIcon(record.logMethod))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func logMethodIcon(_ method: FoodLogMethod) -> String {
        switch method {
        case .text:    return "text.cursor"
        case .camera:  return "camera"
        case .barcode: return "barcode"
        case .ocr:     return "doc.text.viewfinder"
        }
    }
}

// MARK: - テキスト入力ビュー

struct TextInputFoodView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let mealType: MealType

    @State private var foodName     = ""
    @State private var calories     = ""
    @State private var protein      = ""
    @State private var fat          = ""
    @State private var carbohydrate = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("食品名") {
                    TextField("例: 白米 200g", text: $foodName)
                }
                Section("栄養素") {
                    HStack { Text("カロリー"); Spacer(); TextField("kcal", text: $calories).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
                    HStack { Text("タンパク質"); Spacer(); TextField("g", text: $protein).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
                    HStack { Text("脂質");      Spacer(); TextField("g", text: $fat).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
                    HStack { Text("炭水化物");  Spacer(); TextField("g", text: $carbohydrate).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
                }
            }
            .navigationTitle("\(mealType.rawValue)を記録")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("キャンセル") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("登録") { save() }
                        .disabled(foodName.isEmpty || calories.isEmpty)
                }
            }
        }
    }

    private func save() {
        let record = FoodRecord(
            mealType: mealType,
            foodName: foodName,
            logMethod: .text,
            calories: Double(calories) ?? 0,
            protein: Double(protein) ?? 0,
            fat: Double(fat) ?? 0,
            carbohydrate: Double(carbohydrate) ?? 0
        )
        context.insert(record)
        dismiss()
    }
}

// MARK: - プレースホルダー（Phase 2 で実装）

struct BarcodeScanView: View {
    let mealType: MealType
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "barcode.viewfinder")
                    .font(.system(size: 80))
                    .foregroundStyle(.green)
                Text("バーコードスキャン")
                    .font(.title2.bold())
                Text("Phase 2 で実装予定")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("バーコード")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }
}

struct CameraFoodView: View {
    let mealType: MealType
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue)
                Text("料理写真で記録")
                    .font(.title2.bold())
                Text("Phase 2 で AI 認識を実装予定")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("写真撮影")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }
}
