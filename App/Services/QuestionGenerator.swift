import Foundation

/// 問題の自動生成。
/// ランダムな局面に、ロン/ツモ・親子・本場・供託を加えて、
/// ScoringEngine で「対象を上回る最低手」を求め、その値を正解にする。
enum QuestionGenerator {

    static func generateSession(mode: QuestionMode,
                                difficulty: Difficulty = .normal,
                                count: Int = 10) -> [Question] {
        var result: [Question] = []
        var attempts = 0
        while result.count < count && attempts < count * 500 {
            attempts += 1
            if let q = generateOne(mode: mode, difficulty: difficulty) {
                result.append(q)
            }
        }
        while result.count < count {
            result.append(fallback(mode: mode))
        }
        return result
    }

    // MARK: - 1問生成

    private static func generateOne(mode: QuestionMode, difficulty: Difficulty) -> Question? {
        let rawScores = randomScores()
        let winds = Wind.allCases.shuffled()
        var players = zip(winds, rawScores).map {
            Player(name: $0.0.seatName, wind: $0.0, score: $0.1, isUser: false)
        }
        let ranked = players.sorted { $0.score > $1.score }

        // 自分・対象の順位
        let userRankIndex: Int
        switch mode {
        case .avoidLast:          userRankIndex = 3
        case .top:                userRankIndex = Int.random(in: 1...2)
        case .rankUp, .directHit: userRankIndex = Int.random(in: 1...3)
        }
        let userPlayer = ranked[userRankIndex]
        let targetRankIndex = (mode == .top) ? 0 : userRankIndex - 1
        let targetPlayer = ranked[targetRankIndex]

        // 和了種別と方法
        let winType: WinType = (mode == .directHit) ? .ron : chooseWinType(difficulty)
        let method: ScoringEngine.Method = (mode == .directHit)
            ? .ronDirect
            : (winType == .tsumo ? .tsumo : .ronOther)

        // 本場・供託
        let (honba, sticks) = bonuses(difficulty)
        let perHonba = 300

        // 自分フラグ
        players = players.map {
            Player(id: $0.id, name: $0.name, wind: $0.wind, score: $0.score, isUser: $0.id == userPlayer.id)
        }

        let scores = players.map(\.score)
        guard let userIndex = players.firstIndex(where: { $0.isUser }),
              let dealerIndex = players.firstIndex(where: { $0.wind == .east }),
              let targetIndex = players.firstIndex(where: { $0.id == targetPlayer.id }) else { return nil }

        let sit = ScoringEngine.Situation(
            scores: scores, dealerIndex: dealerIndex, userIndex: userIndex,
            winType: winType, honba: honba, perHonba: perHonba, sticks: sticks
        )
        guard let correct = ScoringEngine.minimumHand(situation: sit, targetIndex: targetIndex, method: method) else {
            return nil
        }

        let candidates = ScoringEngine.handCandidates(isDealer: sit.userIsDealer, winType: winType)
        let choices = ScoringEngine.makeChoices(correct: correct, candidates: candidates, difficulty: difficulty)
        let targetRank = targetRankIndex + 1
        let qText = questionText(mode: mode, winType: winType, targetRank: targetRank)
        let explanation = explanationText(
            sit: sit, targetIndex: targetIndex, method: method,
            correct: correct, candidates: candidates, mode: mode, targetRank: targetRank
        )

        return Question(
            id: UUID(), mode: mode, round: "南4局", honba: honba, riichiSticks: sticks,
            players: players, userPlayerId: userPlayer.id, targetRank: targetRank,
            questionText: qText, choices: choices, correctAnswer: correct, explanation: explanation,
            winType: winType, dealerWind: .east, perHonba: perHonba
        )
    }

    // MARK: - パラメータ選択

    private static func chooseWinType(_ d: Difficulty) -> WinType {
        let tsumoProbability: Double
        switch d {
        case .easy:   tsumoProbability = 0.0
        case .normal: tsumoProbability = 0.3
        case .hard:   tsumoProbability = 0.5
        case .oni:    tsumoProbability = 0.5
        }
        return Double.random(in: 0...1) < tsumoProbability ? .tsumo : .ron
    }

    /// 難易度に応じた本場・供託（やさしいほど 0 が多い）
    private static func bonuses(_ d: Difficulty) -> (honba: Int, sticks: Int) {
        switch d {
        case .easy:   return (0, 0)
        case .normal: return (Int.random(in: 0...1), Bool.random() ? 0 : Int.random(in: 0...1))
        case .hard:   return (Int.random(in: 0...2), Int.random(in: 0...1))
        case .oni:    return (Int.random(in: 0...3), Int.random(in: 0...2))
        }
    }

    // MARK: - 点数生成

    private static func randomScores() -> [Int] {
        while true {
            var s: [Int] = []
            for _ in 0..<3 { s.append(Int.random(in: 80...420) * 100) }
            let fourth = 100_000 - s.reduce(0, +)
            s.append(fourth)
            if fourth >= 3_000, fourth <= 60_000, Set(s).count == 4 { return s }
        }
    }

    // MARK: - 文言

    private static func targetLabel(mode: QuestionMode, targetRank: Int) -> String {
        switch mode {
        case .top:                  return "トップ"
        case .avoidLast:            return "3位"
        case .rankUp, .directHit:   return "\(targetRank)位"
        }
    }

    private static func questionText(mode: QuestionMode, winType: WinType, targetRank: Int) -> String {
        let label = targetLabel(mode: mode, targetRank: targetRank)
        switch mode {
        case .directHit:
            return "\(label)から直撃して上がる最低ロン点は？"
        case .top, .rankUp, .avoidLast:
            let goal = (mode == .avoidLast) ? "ラスを回避して3位になる" : "\(label)になる"
            if winType == .tsumo {
                return "ツモで\(goal)最低点は？"
            } else {
                return "\(goal)最低ロン点は？"
            }
        }
    }

    private static func methodPhrase(_ method: ScoringEngine.Method, label: String) -> String {
        switch method {
        case .ronOther:  return "対象者以外から\(label)をロン"
        case .ronDirect: return "\(label)から直撃でロン"
        case .tsumo:     return "ツモ和了"
        }
    }

    private static func explanationText(sit: ScoringEngine.Situation,
                                        targetIndex: Int,
                                        method: ScoringEngine.Method,
                                        correct: Int,
                                        candidates: [Int],
                                        mode: QuestionMode,
                                        targetRank: Int) -> String {
        let f = NumberFormatterUtility.scoreString
        let label = targetLabel(mode: mode, targetRank: targetRank)
        let userScore = sit.scores[sit.userIndex]
        let targetScore = sit.scores[targetIndex]
        let gap = targetScore - userScore
        let bonus = sit.honbaToWinner + sit.sticksToWinner

        let (userAfter, targetAfter) = ScoringEngine.outcome(hand: correct, situation: sit, targetIndex: targetIndex, method: method)
        let lead = userAfter - targetAfter

        var text = "正解：\(f(correct))点\n\n"
        text += "\(label)との差は\(f(gap))点です。\n"
        if bonus > 0 {
            text += "本場\(sit.honba)・供託\(sit.sticks)本で +\(f(bonus))点 が無料で乗ります。\n"
        }
        text += "\(methodPhrase(method, label: label))で\(f(correct))点を和了すると、\n\n"
        text += "あなた：\(f(userAfter))\n"
        text += "\(label)：\(f(targetAfter))\n\n"
        text += "となり、\(f(lead))点差で逆転します。\n\n"

        if let prev = ScoringEngine.candidateBelow(correct, in: candidates) {
            let (pu, pt) = ScoringEngine.outcome(hand: prev, situation: sit, targetIndex: targetIndex, method: method)
            text += "\(f(prev))点では あなた\(f(pu)) ／ \(label)\(f(pt)) となり"
            text += (pu == pt) ? "、同点で逆転できません。\n" : "届きません。\n"
        }
        text += "したがって最低条件は\(f(correct))点です。"
        return text
    }

    // MARK: - 保険用の固定問題

    private static func fallback(mode: QuestionMode) -> Question {
        let east  = Player(name: "東家", wind: .east,  score: 34_200, isUser: false)
        let south = Player(name: "南家", wind: .south, score: 31_800, isUser: true)
        let west  = Player(name: "西家", wind: .west,  score: 22_500, isUser: false)
        let north = Player(name: "北家", wind: .north, score: 11_500, isUser: false)
        let players = [east, south, west, north]
        let sit = ScoringEngine.Situation(
            scores: players.map(\.score), dealerIndex: 0, userIndex: 1,
            winType: .ron, honba: 0, perHonba: 300, sticks: 0
        )
        let correct = ScoringEngine.minimumHand(situation: sit, targetIndex: 0, method: .ronOther) ?? 2600
        let candidates = ScoringEngine.handCandidates(isDealer: false, winType: .ron)
        let explanation = explanationText(
            sit: sit, targetIndex: 0, method: .ronOther,
            correct: correct, candidates: candidates, mode: .top, targetRank: 1
        )
        return Question(
            id: UUID(), mode: mode, round: "南4局", honba: 0, riichiSticks: 0,
            players: players, userPlayerId: south.id, targetRank: 1,
            questionText: questionText(mode: .top, winType: .ron, targetRank: 1),
            choices: ScoringEngine.makeChoices(correct: correct, candidates: candidates, difficulty: .normal),
            correctAnswer: correct, explanation: explanation,
            winType: .ron, dealerWind: .east, perHonba: 300
        )
    }
}
