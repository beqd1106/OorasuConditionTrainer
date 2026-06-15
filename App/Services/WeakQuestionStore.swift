import Foundation

/// 苦手問題（間違えた問題）の保存。復習モードで再出題する。
/// UserDefaults に最新を優先して保存し、上限件数で打ち切る。
final class WeakQuestionStore {
    static let shared = WeakQuestionStore()

    private let key = "oorasu_weak_questions_v1"
    private let maxCount = 60
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> [Question] {
        guard let data = defaults.data(forKey: key),
              let items = try? JSONDecoder().decode([Question].self, from: data) else {
            return []
        }
        return items
    }

    var count: Int { load().count }

    private func save(_ items: [Question]) {
        if let data = try? JSONEncoder().encode(items) {
            defaults.set(data, forKey: key)
        }
    }

    /// 間違えた問題を追加（先頭に積み、上限で打ち切り）。同一IDは重複させない。
    func add(_ question: Question) {
        var items = load().filter { $0.id != question.id }
        items.insert(question, at: 0)
        if items.count > maxCount { items = Array(items.prefix(maxCount)) }
        save(items)
    }

    /// 復習で正解した問題を苦手リストから外す。
    func remove(id: UUID) {
        let items = load().filter { $0.id != id }
        save(items)
    }

    func clear() {
        defaults.removeObject(forKey: key)
    }
}
