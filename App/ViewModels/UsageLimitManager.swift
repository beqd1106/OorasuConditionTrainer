import Foundation

/// AI解説の利用回数を端末側で記録・表示し、1日のソフト上限を設ける。
/// （課金の最終防壁は OpenAI/Gemini 側の支出上限とサーバー側で担保する。これは補助的な抑制。）
@MainActor
final class UsageLimitManager: ObservableObject {
    @Published private(set) var todayCount: Int = 0
    @Published private(set) var monthCount: Int = 0

    /// 1日のソフト上限（これを超えたらAI解説を止め、無料のローカル解説に切替）
    let dailyLimit = 30

    private let defaults: UserDefaults
    private enum Keys {
        static let day = "ai_usage_day"
        static let dayCount = "ai_usage_day_count"
        static let month = "ai_usage_month"
        static let monthCount = "ai_usage_month_count"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        rolloverIfNeeded()
        todayCount = defaults.integer(forKey: Keys.dayCount)
        monthCount = defaults.integer(forKey: Keys.monthCount)
    }

    var canUseToday: Bool { todayCount < dailyLimit }
    var remainingToday: Int { max(0, dailyLimit - todayCount) }

    /// 1回利用を記録
    func record() {
        rolloverIfNeeded()
        todayCount = defaults.integer(forKey: Keys.dayCount) + 1
        monthCount = defaults.integer(forKey: Keys.monthCount) + 1
        defaults.set(todayCount, forKey: Keys.dayCount)
        defaults.set(monthCount, forKey: Keys.monthCount)
    }

    /// 日付・月が変わっていたらカウントをリセット
    private func rolloverIfNeeded() {
        let now = Date()
        let dayKey = Self.dayString(now)
        let monthKey = Self.monthString(now)
        if defaults.string(forKey: Keys.day) != dayKey {
            defaults.set(dayKey, forKey: Keys.day)
            defaults.set(0, forKey: Keys.dayCount)
        }
        if defaults.string(forKey: Keys.month) != monthKey {
            defaults.set(monthKey, forKey: Keys.month)
            defaults.set(0, forKey: Keys.monthCount)
        }
    }

    private static func dayString(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.locale = Locale(identifier: "en_US_POSIX")
        return f.string(from: d)
    }
    private static func monthString(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM"; f.locale = Locale(identifier: "en_US_POSIX")
        return f.string(from: d)
    }
}
