import Foundation

/// 1問への回答結果。回答時間も記録し、平均回答時間の集計に使う。
struct AnswerResult: Identifiable, Codable, Hashable {
    let id: UUID
    let questionId: UUID
    let selectedAnswer: Int
    let correctAnswer: Int
    let isCorrect: Bool
    let responseTimeMs: Int

    init(id: UUID = UUID(),
         questionId: UUID,
         selectedAnswer: Int,
         correctAnswer: Int,
         responseTimeMs: Int) {
        self.id = id
        self.questionId = questionId
        self.selectedAnswer = selectedAnswer
        self.correctAnswer = correctAnswer
        self.isCorrect = selectedAnswer == correctAnswer
        self.responseTimeMs = responseTimeMs
    }
}
