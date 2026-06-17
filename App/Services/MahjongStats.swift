import Foundation

/// 麻雀の概算統計値（公開されている天鳳/雀魂などの大規模データの一般的傾向に基づく目安）。
/// 厳密値ではなく「概算」。実現率推定の土台にし、後で実データへ差し替え可能にする。
enum MahjongStats {

    /// 1局あたりの自分の和了率（概算）。オーラスは押すので少し高めに見る。
    static let winRate = 0.22
    /// 親番のときの和了率（やや高い）
    static let winRateDealer = 0.25

    /// 和了のうちロン／ツモが占める割合（概算）
    static let ronShare = 0.55
    static let tsumoShare = 0.45

    /// P(和了打点 >= しきい点 | 和了)。子ロン換算の代表点をキーにした概算の生存確率。
    /// 例：和了したうち、満貫(8000)以上は約2割。
    private static let valueSurvival: [Int: Double] = [
        1000: 1.00, 1300: 0.92, 1600: 0.85, 2000: 0.80,
        2600: 0.66, 3200: 0.58, 3900: 0.50, 5200: 0.40,
        6400: 0.32, 7700: 0.24, 8000: 0.20,   // 満貫
        12000: 0.07,   // 跳満
        16000: 0.025,  // 倍満
        24000: 0.008,  // 三倍満
        32000: 0.002   // 役満
    ]

    /// 子ロン換算の代表点における「その打点以上で和了する割合」
    static func valueSurvival(childRonEquivalent points: Int) -> Double {
        if let p = valueSurvival[points] { return p }
        return points <= 1000 ? 1.0 : 0.002
    }
}
