import HealthKit
import Foundation

/// HealthKit からデータを取得してゲームへ反映するサービス
@MainActor
final class HealthKitService: ObservableObject {
    static let shared = HealthKitService()
    private let store = HKHealthStore()

    @Published var todaySteps: Int = 0
    @Published var todaySleepHours: Double = 0
    @Published var todayActiveCalories: Double = 0
    @Published var currentHeartRate: Double = 0
    @Published var isAuthorized: Bool = false

    private init() {}

    // MARK: - 認可リクエスト

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        let readTypes: Set<HKObjectType> = [
            HKQuantityType(.stepCount),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.heartRate),
            HKCategoryType(.sleepAnalysis),
        ]

        try await store.requestAuthorization(toShare: [], read: readTypes)
        isAuthorized = true
        await fetchAll()
        setupBackgroundDelivery()
    }

    // MARK: - 全データ取得

    func fetchAll() async {
        async let steps    = fetchTodaySteps()
        async let sleep    = fetchLastNightSleep()
        async let calories = fetchTodayActiveCalories()
        async let hr       = fetchLatestHeartRate()

        todaySteps         = await steps
        todaySleepHours    = await sleep
        todayActiveCalories = await calories
        currentHeartRate   = await hr
    }

    // MARK: - 歩数

    func fetchTodaySteps() async -> Int {
        let type = HKQuantityType(.stepCount)
        let predicate = HKQuery.predicateForSamples(
            withStart: Calendar.current.startOfDay(for: .now),
            end: .now
        )
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                let steps = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                continuation.resume(returning: Int(steps))
            }
            store.execute(query)
        }
    }

    // MARK: - 睡眠時間

    func fetchLastNightSleep() async -> Double {
        let type = HKCategoryType(.sleepAnalysis)
        // 昨日22:00〜今日の現在時刻を対象
        let yesterday = Calendar.current.date(byAdding: .hour, value: -10, to: .now)!
        let predicate = HKQuery.predicateForSamples(withStart: yesterday, end: .now)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, _ in
                let total = (samples as? [HKCategorySample])?.reduce(0.0) { acc, sample in
                    guard sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
                          sample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                          sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                          sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue
                    else { return acc }
                    return acc + sample.endDate.timeIntervalSince(sample.startDate) / 3600
                } ?? 0
                continuation.resume(returning: total)
            }
            store.execute(query)
        }
    }

    // MARK: - アクティブカロリー

    func fetchTodayActiveCalories() async -> Double {
        let type = HKQuantityType(.activeEnergyBurned)
        let predicate = HKQuery.predicateForSamples(
            withStart: Calendar.current.startOfDay(for: .now),
            end: .now
        )
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                let cal = result?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                continuation.resume(returning: cal)
            }
            store.execute(query)
        }
    }

    // MARK: - 心拍数

    func fetchLatestHeartRate() async -> Double {
        let type = HKQuantityType(.heartRate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in
                let bpm = (samples?.first as? HKQuantitySample)?
                    .quantity.doubleValue(for: HKUnit(from: "count/min")) ?? 0
                continuation.resume(returning: bpm)
            }
            store.execute(query)
        }
    }

    // MARK: - バックグラウンドデリバリー

    private func setupBackgroundDelivery() {
        let types: [HKQuantityTypeIdentifier] = [.stepCount, .activeEnergyBurned]
        for typeId in types {
            let type = HKQuantityType(typeId)
            store.enableBackgroundDelivery(for: type, frequency: .hourly) { _, _ in }
        }
    }

    // MARK: - ゲーム変換

    /// 歩数をごはんアイテム数に変換（1,000 歩 = 1 個）
    func stepsToFoodItems(_ steps: Int) -> Int { steps / 1000 }

    /// 睡眠時間が 7 時間以上かどうか
    var hasGoodSleep: Bool { todaySleepHours >= 7.0 }

    /// 運動 30 分以上（カロリー 200kcal 以上を目安）
    var hasWorkout: Bool { todayActiveCalories >= 200 }
}

enum HealthKitError: LocalizedError {
    case notAvailable
    var errorDescription: String? {
        switch self {
        case .notAvailable: return "このデバイスでは HealthKit を使用できません"
        }
    }
}
