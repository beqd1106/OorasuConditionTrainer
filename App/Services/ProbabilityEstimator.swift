import Foundation

/// 着順アップ条件の「概算」実現可能性スコア（0〜100）。
/// 厳密な実戦確率ではなく、必要打点・親番・残り局数・和了方法から推定する目安。
/// 後から実データ/AIモデルに差し替えられるよう関数として独立させている。
enum ProbabilityEstimator {

    struct Input {
        var requiredHand: Int?    // 必要な手（候補内の値。nil = 候補超＝役満超）
        var winType: WinType
        var isDealer: Bool        // 自分が親か
        var isDirectOnly: Bool    // 直撃しか手段がない（他家ロン不可）
        var remainingRounds: Int  // 残り局数（オーラス=0）
    }

    /// 0〜100 の概算スコア
    static func feasibility(_ input: Input) -> Int {
        guard let hand = input.requiredHand else { return 2 } // 役満超は極小
        let candidates = ScoringEngine.handCandidates(isDealer: input.isDealer, winType: input.winType)
        guard let idx = candidates.firstIndex(of: hand), candidates.count > 1 else { return 50 }

        // 必要打点が候補の中でどれだけ高いか（0=最安, 1=最高）
        let frac = Double(idx) / Double(candidates.count - 1)
        var score = 88.0 - frac * 80.0                       // 8〜88

        if input.isDealer { score += 6 }                     // 親番は上げる
        score += Double(min(input.remainingRounds, 6)) * 3   // 残り局数は上げる
        if input.winType == .tsumo { score -= 7 }            // ツモ限定は下げる
        if input.isDirectOnly { score -= 14 }                // 直撃限定は下げる

        return Int(min(96, max(2, score)).rounded())
    }

    static func isManganOrAbove(hand: Int, isDealer: Bool, winType: WinType) -> Bool {
        hand >= threshold(.mangan, isDealer: isDealer, winType: winType)
    }
    static func isHaneOrAbove(hand: Int, isDealer: Bool, winType: WinType) -> Bool {
        hand >= threshold(.hane, isDealer: isDealer, winType: winType)
    }

    private enum Tier { case mangan, hane }
    private static func threshold(_ t: Tier, isDealer: Bool, winType: WinType) -> Int {
        switch t {
        case .mangan: return isDealer ? 12000 : 8000   // 親満貫=12000 / 子満貫=8000（ツモ合計も同値）
        case .hane:   return isDealer ? 18000 : 12000  // 親跳満=18000 / 子跳満=12000
        }
    }
}
