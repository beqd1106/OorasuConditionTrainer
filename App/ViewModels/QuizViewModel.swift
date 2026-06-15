import Foundation

/// 10問1セッションの進行を管理する。
/// 出題 → 回答 → 解説 → 次の問題 … → 結果、というフェーズ遷移を持つ。
@MainActor
final class QuizViewModel: ObservableObject {

    enum Phase {
        case question     // 出題中（回答待ち）
        case explanation  // 解説表示中
        case finished     // 全問終了（結果画面）
    }

    let mode: QuestionMode
    let difficulty: Difficulty
    /// 苦手復習セッションかどうか（true のとき正解した問題を苦手リストから外す）
    let isReview: Bool

    @Published private(set) var questions: [Question]
    @Published private(set) var currentIndex: Int = 0
    @Published private(set) var phase: Phase = .question
    @Published private(set) var results: [AnswerResult] = []
    @Published private(set) var lastSelected: Int? = nil

    /// 現在の問題が表示された時刻（回答時間の計測・経過時間表示に使う）
    private(set) var questionStart: Date = Date()

    private let weakStore = WeakQuestionStore.shared

    /// 通常モード（自動生成）
    init(mode: QuestionMode, difficulty: Difficulty) {
        self.mode = mode
        self.difficulty = difficulty
        self.isReview = false
        self.questions = QuestionGenerator.generateSession(mode: mode, difficulty: difficulty, count: 10)
    }

    /// 苦手復習モード（保存済みの問題を出題）
    init(reviewQuestions: [Question]) {
        let qs = Array(reviewQuestions.prefix(10))
        self.mode = qs.first?.mode ?? .rankUp
        self.difficulty = .normal
        // 万一空なら通常出題にフォールバック（クラッシュ防止）
        self.isReview = !qs.isEmpty
        self.questions = qs.isEmpty
            ? QuestionGenerator.generateSession(mode: .rankUp, difficulty: .normal, count: 10)
            : qs
    }

    // MARK: - 参照用

    var current: Question { questions[currentIndex] }
    var questionNumber: Int { currentIndex + 1 }
    var total: Int { questions.count }
    var correctCount: Int { results.filter { $0.isCorrect }.count }
    var isLastQuestion: Bool { currentIndex == questions.count - 1 }
    var lastResult: AnswerResult? { results.last }

    /// 画面タイトル
    var sessionTitle: String { isReview ? "苦手復習" : mode.title }

    /// 今セッションの平均回答時間（秒）
    var averageResponseSeconds: Double {
        guard !results.isEmpty else { return 0 }
        let total = results.reduce(0) { $0 + $1.responseTimeMs }
        return Double(total) / 1000.0 / Double(results.count)
    }

    // MARK: - 操作

    /// 問題表示時にタイマーを開始（QuestionView の onAppear から呼ぶ）
    func startQuestionTimer() {
        questionStart = Date()
    }

    /// 選択肢を回答する
    func submit(_ choice: Int) {
        guard phase == .question else { return }
        let elapsedMs = Int(Date().timeIntervalSince(questionStart) * 1000)
        let q = current
        let result = AnswerResult(
            questionId: q.id,
            selectedAnswer: choice,
            correctAnswer: q.correctAnswer,
            responseTimeMs: max(0, elapsedMs)
        )
        results.append(result)
        lastSelected = choice

        // 苦手リストの更新
        if isReview {
            // 復習で正解したら苦手リストから外す
            if result.isCorrect { weakStore.remove(id: q.id) }
        } else if !result.isCorrect {
            // 通常モードで間違えたら苦手リストに追加
            weakStore.add(q)
        }

        phase = .explanation
    }

    /// 次の問題へ。最終問なら結果へ。
    func advance() {
        if currentIndex + 1 < questions.count {
            currentIndex += 1
            lastSelected = nil
            phase = .question
        } else {
            phase = .finished
        }
    }

    /// もう一度（通常モードは新規生成、復習は同じ問題を再挑戦）
    func restart() {
        if !isReview {
            questions = QuestionGenerator.generateSession(mode: mode, difficulty: difficulty, count: 10)
        }
        currentIndex = 0
        results = []
        lastSelected = nil
        phase = .question
    }
}
