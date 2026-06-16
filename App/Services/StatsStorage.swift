import Foundation

/// 成績の永続化（UserDefaults + JSON）。
/// 通信もアカウントも不要。端末内だけに保存する。
final class StatsStorage {
    static let shared = StatsStorage()

    private let key = "oorasu_user_stats_v1"
    private let modeKey = "oorasu_mode_stats_v1"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - 通算

    /// 保存済みの累計成績を読み込む。無ければ初期値。
    func load() -> UserStats {
        guard let data = defaults.data(forKey: key),
              let stats = try? JSONDecoder().decode(UserStats.self, from: data) else {
            return UserStats()
        }
        return stats
    }

    func save(_ stats: UserStats) {
        if let data = try? JSONEncoder().encode(stats) {
            defaults.set(data, forKey: key)
        }
    }

    // MARK: - モード別

    /// モード別の累計（rawValue → UserStats）
    func loadModeStats() -> [String: UserStats] {
        guard let data = defaults.data(forKey: modeKey),
              let dict = try? JSONDecoder().decode([String: UserStats].self, from: data) else {
            return [:]
        }
        return dict
    }

    private func saveModeStats(_ dict: [String: UserStats]) {
        if let data = try? JSONEncoder().encode(dict) {
            defaults.set(data, forKey: modeKey)
        }
    }

    // MARK: - 記録

    /// 1セッション分の結果を累計（と任意でモード別）へ反映する。
    /// - Parameter mode: 通常モードなら該当モード、復習など nil ならモード別は記録しない。
    func record(results: [AnswerResult], mode: QuestionMode? = nil) {
        let correct = results.filter { $0.isCorrect }.count
        let timeMs = results.reduce(0) { $0 + $1.responseTimeMs }

        // 通算
        var stats = load()
        stats.totalQuestions += results.count
        stats.totalCorrect += correct
        stats.totalResponseTimeMs += timeMs
        save(stats)

        // モード別
        if let mode {
            var dict = loadModeStats()
            var ms = dict[mode.rawValue] ?? UserStats()
            ms.totalQuestions += results.count
            ms.totalCorrect += correct
            ms.totalResponseTimeMs += timeMs
            dict[mode.rawValue] = ms
            saveModeStats(dict)
        }
    }

    /// 成績リセット（通算・モード別とも消す）。
    func reset() {
        defaults.removeObject(forKey: key)
        defaults.removeObject(forKey: modeKey)
    }
}
