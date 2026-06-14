import Foundation

/// 累計成績をUIへ供給する。アプリ全体で1つ共有する（環境オブジェクト）。
@MainActor
final class StatsViewModel: ObservableObject {
    @Published private(set) var stats: UserStats

    private let storage: StatsStorage

    init(storage: StatsStorage = .shared) {
        self.storage = storage
        self.stats = storage.load()
    }

    /// 保存値を再読込（セッション終了後やホーム再表示で呼ぶ）
    func refresh() {
        stats = storage.load()
    }

    /// セッション結果を記録して反映
    func record(_ results: [AnswerResult]) {
        storage.record(results: results)
        refresh()
    }

    func reset() {
        storage.reset()
        refresh()
    }
}
