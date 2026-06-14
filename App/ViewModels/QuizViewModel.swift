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

    @Published private(set) var questions: [Question]
    @Published private(set) var currentIndex: Int = 0
    @Published private(set) var phase: Phase = .question
    @Published private(set) var results: [AnswerResult] = []
    @Published private(set) var lastSelected: Int? = nil

    /// 現在の問題が表示された時刻（回答時間の計測・経過時間表示に使う）
    private(set) var questionStart: Date = Date()

    init(mode: QuestionMode) {
        self.mode = mode
        self.questions = QuestionGenerator.generateSession(mode: mode, count: 10)
    }

    // MARK: - 参照用

    var current: Question { questions[currentIndex] }
    var questionNumber: Int { currentIndex + 1 }
    var total: Int { questions.count }
    var correctCount: Int { results.filter { $0.isCorrect }.count }
    var isLastQuestion: Bool { currentIndex == questions.count - 1 }
    var lastResult: AnswerResult? { results.last }

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
        let result = AnswerResult(
            questionId: current.id,
            selectedAnswer: choice,
            correctAnswer: current.correctAnswer,
            responseTimeMs: max(0, elapsedMs)
        )
        results.append(result)
        lastSelected = choice
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

    /// 同じモードでもう一度（新しい問題を生成）
    func restart() {
        questions = QuestionGenerator.generateSession(mode: mode, count: 10)
        currentIndex = 0
        results = []
        lastSelected = nil
        phase = .question
    }
}
