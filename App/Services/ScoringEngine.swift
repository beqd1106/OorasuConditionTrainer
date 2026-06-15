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
/// ツモの各家支払いは符翻ごとの実値テーブルで持つ（比例計算はしない）。
enum ScoringEngine {

    // MARK: - ロン点（合計＝放銃者の支払い）

    /// 子（非親）ロン
    static let childRon: [Int] = [
        1000, 1300, 1600, 2000, 2600, 3200, 3900,
        5200, 6400, 7700, 8000, 12000, 16000, 24000, 32000
    ]
    /// 親（ディーラー）ロン
    static let dealerRon: [Int] = [
        1500, 2000, 2400, 2900, 3400, 3900, 4800, 5800,
        7700, 8700, 9600, 11600, 12000, 18000, 24000, 36000, 48000
    ]

    // MARK: - ツモ点（合計＋各家支払いの実値）

    /// 子ツモ：child=子の支払い, dealer=親の支払い, total=合計
    struct ChildTsumo { let child: Int; let dealer: Int; let total: Int }
    static let childTsumoTable: [ChildTsumo] = [
        .init(child: 300,  dealer: 500,   total: 1100),
        .init(child: 400,  dealer: 700,   total: 1500),
        .init(child: 500,  dealer: 1000,  total: 2000),
        .init(child: 700,  dealer: 1300,  total: 2700),
        .init(child: 800,  dealer: 1600,  total: 3200),
        .init(child: 1000, dealer: 2000,  total: 4000),
        .init(child: 1300, dealer: 2600,  total: 5200),
        .init(child: 1600, dealer: 3200,  total: 6400),
        .init(child: 2000, dealer: 3900,  total: 7900),
        .init(child: 2000, dealer: 4000,  total: 8000),   // 満貫
        .init(child: 3000, dealer: 6000,  total: 12000),  // 跳満
        .init(child: 4000, dealer: 8000,  total: 16000),  // 倍満
        .init(child: 6000, dealer: 12000, total: 24000),  // 三倍満
        .init(child: 8000, dealer: 16000, total: 32000)   // 役満
    ]

    /// 親ツモ：each=全員の支払い, total=合計
    struct DealerTsumo { let each: Int; let total: Int }
    static let dealerTsumoTable: [DealerTsumo] = [
        .init(each: 500,   total: 1500),
        .init(each: 700,   total: 2100),
        .init(each: 1000,  total: 3000),
        .init(each: 1300,  total: 3900),
        .init(each: 1600,  total: 4800),
        .init(each: 2000,  total: 6000),
        .init(each: 2600,  total: 7800),
        .init(each: 3200,  total: 9600),
        .init(each: 3900,  total: 11700),
        .init(each: 4000,  total: 12000),  // 満貫
        .init(each: 6000,  total: 18000),  // 跳満
        .init(each: 8000,  total: 24000),  // 倍満
        .init(each: 12000, total: 36000),  // 三倍満
        .init(each: 16000, total: 48000)   // 役満
    ]

    /// 状況に応じた「答えとして選ぶ点（合計）」の候補リスト（昇順）
    static func handCandidates(isDealer: Bool, winType: WinType) -> [Int] {
        switch (isDealer, winType) {
        case (false, .ron):   return childRon
        case (true,  .ron):   return dealerRon
        case (false, .tsumo): return childTsumoTable.map(\.total)
        case (true,  .tsumo): return dealerTsumoTable.map(\.total)
        }
    }

    // MARK: - 局面

    struct Situation {
        var scores: [Int]
        var dealerIndex: Int
        var userIndex: Int
        var winType: WinType
        var honba: Int
        var perHonba: Int   // 1本場あたり（ロンは放銃者が全額、ツモは1人 perHonba/3）
        var sticks: Int

        var userIsDealer: Bool { userIndex == dealerIndex }
        var honbaToWinner: Int { honba * perHonba }
        var sticksToWinner: Int { sticks * 1000 }
        var honbaPerPlayer: Int { (perHonba / 3) * honba }  // ツモ時、相手1人が払う本場分
    }

    /// 逆転条件の算出結果
    struct Requirement {
        let targetRank: Int
        let targetScore: Int
        let gap: Int
        let ronOther: Int?
        let ronDirect: Int?
        let tsumo: Int?
    }

    /// 和了方法（内部判定用）
    enum Method { case ronOther, ronDirect, tsumo }

    // MARK: - 計算

    /// 和了者が得る合計点（本場・供託込み）
    static func winnerGain(hand: Int, situation s: Situation) -> Int {
        hand + s.honbaToWinner + s.sticksToWinner
    }

    /// ツモ時、対象者1人が失う点（手の支払い＋本場分）
    private static func tsumoTargetLoss(total: Int, situation s: Situation, targetIsDealer: Bool) -> Int {
        let hand: Int
        if s.userIsDealer {
            hand = dealerTsumoTable.first { $0.total == total }?.each ?? 0
        } else if let e = childTsumoTable.first(where: { $0.total == total }) {
            hand = targetIsDealer ? e.dealer : e.child
        } else {
            hand = 0
        }
        return hand + s.honbaPerPlayer
    }

    /// ある手 `hand`（合計）で対象を上回れるか
    static func overtakes(hand: Int, situation s: Situation, targetIndex: Int, method: Method) -> Bool {
        let (userAfter, targetAfter) = outcome(hand: hand, situation: s, targetIndex: targetIndex, method: method)
        return userAfter > targetAfter
    }

    /// 和了後の自分・対象者の点数
    static func outcome(hand: Int, situation s: Situation, targetIndex: Int, method: Method) -> (userAfter: Int, targetAfter: Int) {
        let userScore = s.scores[s.userIndex]
        let targetScore = s.scores[targetIndex]
        let targetIsDealer = targetIndex == s.dealerIndex
        let userAfter = userScore + winnerGain(hand: hand, situation: s)
        let targetAfter: Int
        switch method {
        case .ronOther:
            targetAfter = targetScore
        case .ronDirect:
            targetAfter = targetScore - (hand + s.honbaToWinner)
        case .tsumo:
            targetAfter = targetScore - tsumoTargetLoss(total: hand, situation: s, targetIsDealer: targetIsDealer)
        }
        return (userAfter, targetAfter)
    }

    /// 指定の相手・方法で上回る最低手（候補内に無ければ nil）
    static func minimumHand(situation s: Situation, targetIndex: Int, method: Method) -> Int? {
        let winType: WinType = (method == .tsumo) ? .tsumo : .ron
        var sit = s
        sit.winType = winType
        let candidates = handCandidates(isDealer: sit.userIsDealer, winType: winType)
        return candidates.first { overtakes(hand: $0, situation: sit, targetIndex: targetIndex, method: method) }
    }

    /// 自分が上回る必要のある相手ごとに、必要な最低手を算出する。
    static func requirements(for s: Situation) -> [Requirement] {
        guard s.scores.indices.contains(s.userIndex) else { return [] }
        let userScore = s.scores[s.userIndex]
        var seen = Set<Int>()
        var results: [Requirement] = []

        for (i, targetScore) in s.scores.enumerated() where i != s.userIndex {
            guard targetScore >= userScore else { continue }
            guard !seen.contains(targetScore) else { continue }
            seen.insert(targetScore)

            let gap = targetScore - userScore
            let rank = 1 + s.scores.filter { $0 > targetScore }.count

            var ronOther: Int? = nil
            var ronDirect: Int? = nil
            var tsumo: Int? = nil
            switch s.winType {
            case .ron:
                ronOther = minimumHand(situation: s, targetIndex: i, method: .ronOther)
                ronDirect = minimumHand(situation: s, targetIndex: i, method: .ronDirect)
            case .tsumo:
                tsumo = minimumHand(situation: s, targetIndex: i, method: .tsumo)
            }
            results.append(Requirement(targetRank: rank, targetScore: targetScore, gap: gap,
                                       ronOther: ronOther, ronDirect: ronDirect, tsumo: tsumo))
        }
        return results.sorted { $0.targetScore > $1.targetScore }
    }
}
