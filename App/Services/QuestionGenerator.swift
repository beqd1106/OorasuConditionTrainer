import Foundation

/// 問題の自動生成。
/// ランダムに点数状況を作り、モードに応じた「対象順位を上回る最低ロン点」が
/// 回答候補の範囲に収まるものだけを採用する（generate-and-check 方式）。
enum QuestionGenerator {

    /// 10問など、1セッション分の問題を生成する。
    static func generateSession(mode: QuestionMode, count: Int = 10) -> [Question] {
        var result: [Question] = []
        var attempts = 0
        let maxAttempts = count * 400

        while result.count < count && attempts < maxAttempts {
            attempts += 1
            if let q = generateOne(mode: mode) {
                result.append(q)
            }
        }
        // 念のための保険（通常ここには到達しない）
        while result.count < count {
            result.append(fallback(mode: mode))
        }
        return result
    }

    // MARK: - 1問生成

    private static func generateOne(mode: QuestionMode) -> Question? {
        let scores = randomScores()
        let winds = Wind.allCases.shuffled()

        // 席ごとにプレイヤーを作成（この時点では isUser=false）
        var players: [Player] = zip(winds, scores).map { wind, score in
            Player(name: wind.seatName, wind: wind, score: score, isUser: false)
        }

        // 点数の高い順 = 順位
        let ranked = players.sorted { $0.score > $1.score }

        // モードごとに自分の順位（0始まり）を決める
        let userRankIndex: Int
        switch mode {
        case .avoidLast:
            userRankIndex = 3                       // 4位
        case .top:
            userRankIndex = Int.random(in: 1...2)   // 2位 or 3位
        case .rankUp:
            userRankIndex = Int.random(in: 1...3)   // 2/3/4位
        }

        let userPlayer = ranked[userRankIndex]
        let targetRankIndex = (mode == .top) ? 0 : userRankIndex - 1
        let targetPlayer = ranked[targetRankIndex]

        let gap = targetPlayer.score - userPlayer.score
        guard gap > 0,
              let correct = ScoreCalculator.minimumRonToOvertake(gap: gap) else {
            return nil   // 点差が大きすぎる/不正 → 作り直し
        }

        // 自分のプレイヤーに isUser フラグを立てる
        players = players.map { p in
            Player(id: p.id, name: p.name, wind: p.wind, score: p.score, isUser: p.id == userPlayer.id)
        }

        let targetRank = targetRankIndex + 1
        let choices = ScoreCalculator.makeChoices(correct: correct)
        let qText = questionText(mode: mode, targetRank: targetRank)
        let explanation = explanationText(
            mode: mode,
            userScore: userPlayer.score,
            targetScore: targetPlayer.score,
            gap: gap,
            correct: correct,
            targetRank: targetRank
        )

        return Question(
            id: UUID(),
            mode: mode,
            round: "南4局",
            honba: 0,
            riichiSticks: 0,
            players: players,
            userPlayerId: userPlayer.id,
            targetRank: targetRank,
            questionText: qText,
            choices: choices,
            correctAnswer: correct,
            explanation: explanation
        )
    }

    // MARK: - 点数生成

    /// 合計100,000点（25,000×4）、すべて100点単位・正の値・重複なしの4スコアを返す。
    private static func randomScores() -> [Int] {
        while true {
            var s: [Int] = []
            for _ in 0..<3 {
                s.append(Int.random(in: 80...420) * 100) // 8,000〜42,000
            }
            let fourth = 100_000 - s.reduce(0, +)
            s.append(fourth)
            // トビなし(>0)、極端値を避ける、重複なし
            if fourth >= 3_000, fourth <= 60_000, Set(s).count == 4 {
                return s
            }
        }
    }

    // MARK: - 文言生成

    private static func questionText(mode: QuestionMode, targetRank: Int) -> String {
        switch mode {
        case .top:
            return "トップになる最低ロン点は？"
        case .avoidLast:
            return "ラスを回避して3位になる最低ロン点は？"
        case .rankUp:
            return "\(targetRank)位に上がる最低ロン点は？"
        }
    }

    private static func targetLabel(mode: QuestionMode, targetRank: Int) -> String {
        switch mode {
        case .top:       return "トップ"
        case .avoidLast: return "3位"
        case .rankUp:    return "\(targetRank)位"
        }
    }

    private static func explanationText(mode: QuestionMode,
                                        userScore: Int,
                                        targetScore: Int,
                                        gap: Int,
                                        correct: Int,
                                        targetRank: Int) -> String {
        let f = NumberFormatterUtility.scoreString
        let label = targetLabel(mode: mode, targetRank: targetRank)
        let afterUser = userScore + correct
        let lead = afterUser - targetScore

        var text = ""
        text += "正解：\(f(correct))点\n\n"
        text += "\(label)との差は\(f(gap))点です。\n"
        text += "対象者以外から\(f(correct))点をロンすると、\n\n"
        text += "あなた：\(f(userScore)) ＋ \(f(correct)) ＝ \(f(afterUser))\n"
        text += "\(label)：\(f(targetScore))\n\n"
        text += "となり、あなたが\(f(lead))点差で\(label)になります。\n\n"

        if let prev = ScoreCalculator.candidateBelow(correct) {
            let afterPrev = userScore + prev
            text += "\(f(prev))点ロンでは\(f(afterPrev))点までしか届かず、"
            text += (afterPrev == targetScore) ? "同点のため逆転できません。\n" : "逆転できません。\n"
        }
        text += "したがって最低条件は\(f(correct))点です。"
        return text
    }

    // MARK: - 保険用の決め打ち問題

    private static func fallback(mode: QuestionMode) -> Question {
        // 仕様の例（トップ条件）に準拠した安全な1問
        let east = Player(name: "東家", wind: .east, score: 34_200, isUser: false)
        let south = Player(name: "南家", wind: .south, score: 31_800, isUser: true)
        let west = Player(name: "西家", wind: .west, score: 22_500, isUser: false)
        let north = Player(name: "北家", wind: .north, score: 11_500, isUser: false)
        let players = [east, south, west, north]
        let correct = 2600
        let explanation = explanationText(
            mode: .top, userScore: 31_800, targetScore: 34_200,
            gap: 2_400, correct: correct, targetRank: 1
        )
        return Question(
            id: UUID(), mode: mode, round: "南4局", honba: 0, riichiSticks: 0,
            players: players, userPlayerId: south.id, targetRank: 1,
            questionText: questionText(mode: .top, targetRank: 1),
            choices: ScoreCalculator.makeChoices(correct: correct),
            correctAnswer: correct, explanation: explanation
        )
    }
}
