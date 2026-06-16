import Foundation

/// 累計成績をUIへ供給する。アプリ全体で1つ共有する（環境オブジェクト）。
@MainActor
final class StatsViewModel: ObservableObject {
    @Published private(set) var stats: UserStats
    @Published private(set) var modeStats: [QuestionMode: UserStats] = [:]

    private let storage: StatsStorage

    init(storage: StatsStorage = .shared) {
        self.storage = storage
        self.stats = storage.load()
        loadModeStats()
    }

    /// 保存値を再読込（セッション終了後やホーム再表示で呼ぶ）
    func refresh() {
        stats = storage.load()
        loadModeStats()
    }

    private func loadModeStats() {
        var m: [QuestionMode: UserStats] = [:]
        for (k, v) in storage.loadModeStats() {
            if let mode = QuestionMode(rawValue: k) { m[mode] = v }
        }
        modeStats = m
    }

    /// セッション結果を記録して反映（mode=nil は復習などモード別非記録）
    func record(_ results: [AnswerResult], mode: QuestionMode?) {
        storage.record(results: results, mode: mode)
        refresh()
    }

    func reset() {
        storage.reset()
        refresh()
    }
}
