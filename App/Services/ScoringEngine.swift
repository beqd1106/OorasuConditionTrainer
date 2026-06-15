import Foundation

/// 和了の種類
enum WinType: String, Codable, CaseIterable, Identifiable {
    case ron   // ロン
    case tsumo // ツモ
    var id: String { rawValue }
    var title: String { self == .ron ? "ロン" : "ツモ" }
}

/// 点数計算エンジン。
/// ロン/ツモ・親/子・本場・供託を考慮し、「対象を上回るのに必要な最低手」を求める。
///
/// 手の価値は実戦でよく使う代表的な点数（=候補）で表す。
/// ツモは「和了者が相手全員から得る合計点」で表す（各家の支払いは内部で分配）。
enum ScoringEngine {

    // MARK: - 代表的な点数候補（昇順）

    /// 子（非親）ロンの和了点
    static let childRon: [Int] = [
        1000, 1300, 1600, 2000, 2600, 3200, 3900,
        5200, 6400, 7700, 8000, 12000, 16000, 24000, 32000
    ]

    /// 親（ディーラー）ロンの和了点
    static let dealerRon: [Int] = [
        1500, 2000, 2400, 2900, 3400, 3900, 4800, 5800,
        7700, 8700, 9600, 11600, 12000, 18000, 24000, 36000, 48000
    ]

    /// 子ツモの合計点（子/親の支払いの合計）
    static let childTsumoTotal: [Int] = [
        1100, 1500, 2000, 2700, 3200, 4000, 5200, 6400, 7900,
        8000, 12000, 16000, 24000, 32000
    ]

    /// 親ツモの合計点（全員均等払いの合計）
    static let dealerTsumoTotal: [Int] = [
        1500, 2100, 3000, 3900, 4800, 6000, 7800, 9600, 11700,
        12000, 18000, 24000, 36000, 48000
    ]

    /// 状況に応じた和了点の候補リスト
    static func handCandidates(isDealer: Bool, winType: WinType) -> [Int] {
        switch (isDealer, winType) {
        case (false, .ron):   return childRon
        case (true,  .ron):   return dealerRon
        case (false, .tsumo): return childTsumoTotal
        case (true,  .tsumo): return dealerTsumoTotal
        }
    }

    // MARK: - 局面

    /// 1局面の入力。dealerIndex/userIndex は scores と同じ並びのインデックス。
    struct Situation {
        var scores: [Int]
        var dealerIndex: Int   // 親（東家）の席
        var userIndex: Int     // 自分の席
        var winType: WinType
        var honba: Int         // 本場の数
        var perHonba: Int      // 1本場あたりの点（ロンは放銃者が全額、ツモは1人あたり perHonba/3）
        var sticks: Int        // 供託（リーチ棒）の本数。1本=1000点、和了者総取り

        var userIsDealer: Bool { userIndex == dealerIndex }
        var honbaToWinner: Int { honba * perHonba }       // 本場で和了者が得る合計
        var sticksToWinner: Int { sticks * 1000 }
    }

    // MARK: - 逆転条件

    /// ある相手を上回る条件（最低手）の算出結果
    struct Requirement {
        let targetRank: Int
        let targetScore: Int
        let gap: Int
        /// ロン時：対象者以外からロンする場合の最低手（nil=候補内に無い）
        let ronOther: Int?
        /// ロン時：対象者から直撃する場合の最低手
        let ronDirect: Int?
        /// ツモ時：ツモ和了の最低合計点
        let tsumo: Int?
    }

    /// 和了者（自分）が手 `hand` で和了したときに得る合計点（本場・供託込み）
    static func winnerGain(hand: Int, situation s: Situation) -> Int {
        hand + s.honbaToWinner + s.sticksToWinner
    }

    /// ツモ時、対象者が支払う「手の分配割合」。
    /// 親が和了：全員 1/3。子が和了：親は 1/2、子は 1/4。
    private static func tsumoTargetShare(situation s: Situation, targetIsDealer: Bool) -> Double {
        if s.userIsDealer {
            return 1.0 / 3.0
        } else {
            return targetIsDealer ? 1.0 / 2.0 : 1.0 / 4.0
        }
    }

    /// 本場でツモのとき、対象者1人が払う本場分
    private static func tsumoHonbaPerPlayer(situation s: Situation) -> Double {
        Double(s.perHonba) / 3.0 * Double(s.honba)
    }

    /// 候補リストから、条件式を満たす最小の手を返す。
    private static func minHand(in candidates: [Int], satisfying: (Int) -> Bool) -> Int? {
        candidates.first(where: satisfying)
    }

    /// 自分が上回る必要のある相手ごとに、必要な最低手を算出する。
    static func requirements(for s: Situation) -> [Requirement] {
        guard s.scores.indices.contains(s.userIndex) else { return [] }
        let userScore = s.scores[s.userIndex]
        let isDealer = s.userIsDealer
        let candidates = handCandidates(isDealer: isDealer, winType: s.winType)

        var seen = Set<Int>()
        var results: [Requirement] = []

        for (i, targetScore) in s.scores.enumerated() where i != s.userIndex {
            guard targetScore >= userScore else { continue } // 既に自分が上
            guard !seen.contains(targetScore) else { continue }
            seen.insert(targetScore)

            let gap = targetScore - userScore
            let rank = 1 + s.scores.filter { $0 > targetScore }.count
            let targetIsDealer = (i == s.dealerIndex)

            var ronOther: Int? = nil
            var ronDirect: Int? = nil
            var tsumo: Int? = nil

            switch s.winType {
            case .ron:
                // 他家ロン：対象者は減らない。自分 + (hand + 本場 + 供託) > 相手
                ronOther = minHand(in: candidates) { hand in
                    userScore + winnerGain(hand: hand, situation: s) > targetScore
                }
                // 直撃：対象者が放銃。相手は hand + 本場 を失う（供託は場のもの）
                ronDirect = minHand(in: candidates) { hand in
                    let after = userScore + winnerGain(hand: hand, situation: s)
                    let targetAfter = targetScore - (hand + s.honbaToWinner)
                    return after > targetAfter
                }
            case .tsumo:
                let share = tsumoTargetShare(situation: s, targetIsDealer: targetIsDealer)
                let honbaLoss = tsumoHonbaPerPlayer(situation: s)
                tsumo = minHand(in: candidates) { hand in
                    let after = Double(userScore + winnerGain(hand: hand, situation: s))
                    let targetAfter = Double(targetScore) - (Double(hand) * share + honbaLoss)
                    return after > targetAfter
                }
            }

            results.append(
                Requirement(targetRank: rank, targetScore: targetScore, gap: gap,
                            ronOther: ronOther, ronDirect: ronDirect, tsumo: tsumo)
            )
        }
        return results.sorted { $0.targetScore > $1.targetScore }
    }
}
