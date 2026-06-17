import Foundation

/// 着順アップ条件の「実現率（概算）」を、麻雀統計に接地して推定する。
/// 厳密な実戦確率ではないが、AIの主観ではなく次の統計（MahjongStats）を組み合わせる：
///   ・1局の和了率   ・ロン/ツモ比率   ・打点別の出現率(P(打点>=X|和了))
///   ・必要な和了方法（他家ロン/直撃限定/ツモ）
/// 「この手1回でその条件を満たして和了できる確率」を表す（局の途中でもオーラスでも同じ指標）。
/// 後で実データ/AIモデルへ差し替えられるよう関数として独立。
enum ProbabilityEstimator {

    struct Input {
        var requiredHand: Int?    // 必要な手（候補内の値。nil = 候補超＝役満超）
        var winType: WinType
        var isDealer: Bool
        var isDirectOnly: Bool    // 直撃しか手段がない（他家ロン不可）
    }

    /// 0〜100 の概算実現率（%）
    static func feasibility(_ input: Input) -> Int {
        Int((realization(input) * 100).rounded())
    }

    /// 0.0〜1.0 の概算実現率
    static func realization(_ input: Input) -> Double {
        guard let hand = input.requiredHand else { return 0.005 } // 役満超はほぼ不可能

        // 必要打点を「子ロン換算の代表点」に正規化し、その打点以上で和了する割合を見る。
        let tierPoints = childRonEquivalent(hand: hand, isDealer: input.isDealer, winType: input.winType)
        let survival = MahjongStats.valueSurvival(childRonEquivalent: tierPoints) // P(打点>=必要 | 和了)

        // 和了方法の係数
        let winRate = input.isDealer ? MahjongStats.winRateDealer : MahjongStats.winRate
        let methodFactor: Double
        switch input.winType {
        case .tsumo:
            methodFactor = MahjongStats.tsumoShare
        case .ron:
            methodFactor = input.isDirectOnly
                ? MahjongStats.ronShare * (1.0 / 3.0)  // 特定の相手からの直撃
                : MahjongStats.ronShare                // 他家3人いずれかからロン
        }

        // この手1回で「必要な方法＋必要な打点以上」で和了できる確率。
        let perHand = winRate * methodFactor * survival
        return min(0.95, max(0.005, perHand))
    }

    /// 必要な手（合計点）を「子ロン換算の代表点」に正規化する。
    /// 親満貫(12000)も子満貫(8000)も“手の作りにくさ”は同じなので、候補内の位置で揃える。
    static func childRonEquivalent(hand: Int, isDealer: Bool, winType: WinType) -> Int {
        let candidates = ScoringEngine.handCandidates(isDealer: isDealer, winType: winType)
        let childRon = ScoringEngine.childRon
        if let idx = candidates.firstIndex(of: hand) {
            return childRon[min(idx, childRon.count - 1)]
        }
        return hand
    }

    /// 「その打点以上で和了する割合」(%)。解説の出現率表示に使う（実現率と同じ統計を共有）。
    static func valueRarityPercent(requiredHand: Int?, isDealer: Bool, winType: WinType) -> Int? {
        guard let hand = requiredHand else { return nil }
        let eq = childRonEquivalent(hand: hand, isDealer: isDealer, winType: winType)
        return Int((MahjongStats.valueSurvival(childRonEquivalent: eq) * 100).rounded())
    }

    // MARK: - 打点ティア判定（コメント用）

    static func isManganOrAbove(hand: Int, isDealer: Bool, winType: WinType) -> Bool {
        hand >= threshold(.mangan, isDealer: isDealer, winType: winType)
    }
    static func isHaneOrAbove(hand: Int, isDealer: Bool, winType: WinType) -> Bool {
        hand >= threshold(.hane, isDealer: isDealer, winType: winType)
    }

    private enum Tier { case mangan, hane }
    private static func threshold(_ t: Tier, isDealer: Bool, winType: WinType) -> Int {
        switch t {
        case .mangan: return isDealer ? 12000 : 8000
        case .hane:   return isDealer ? 18000 : 12000
        }
    }
}
