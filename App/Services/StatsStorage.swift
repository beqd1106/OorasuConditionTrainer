import Foundation

/// 成績の永続化（UserDefaults + JSON）。
/// 通信もアカウントも不要。端末内だけに保存する。
final class StatsStorage {
    static let shared = StatsStorage()

    private let key = "oorasu_user_stats_v1"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

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

    /// 1セッション分の回答結果を累計へ反映する。
    func record(results: [AnswerResult]) {
        var stats = load()
        stats.totalQuestions += results.count
        stats.totalCorrect += results.filter { $0.isCorrect }.count
        stats.totalResponseTimeMs += results.reduce(0) { $0 + $1.responseTimeMs }
        save(stats)
    }

    /// 成績リセット（設定などから呼べるよう用意）。
    func reset() {
        defaults.removeObject(forKey: key)
    }
}
