import Foundation

/// 累計成績。UserDefaults に JSON で保存する。
struct UserStats: Codable {
    var totalQuestions: Int
    var totalCorrect: Int
    var totalResponseTimeMs: Int

    init(totalQuestions: Int = 0, totalCorrect: Int = 0, totalResponseTimeMs: Int = 0) {
        self.totalQuestions = totalQuestions
        self.totalCorrect = totalCorrect
        self.totalResponseTimeMs = totalResponseTimeMs
    }

    /// 通算正答率（0.0〜1.0）
    var accuracy: Double {
        totalQuestions == 0 ? 0 : Double(totalCorrect) / Double(totalQuestions)
    }

    /// 通算正答率（%表示の整数）
    var accuracyPercent: Int {
        Int((accuracy * 100).rounded())
    }

    /// 平均回答時間（秒）
    var averageResponseSeconds: Double {
        totalQuestions == 0 ? 0 : Double(totalResponseTimeMs) / 1000.0 / Double(totalQuestions)
    }
}
