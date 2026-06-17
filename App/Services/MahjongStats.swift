import Foundation

/// 麻雀の概算統計値。
///
/// 出典（4人打ち・赤あり東南戦の一般的傾向の土台）：
///   ・天鳳 鳳凰卓 2023年 牌譜統計（koba::blog）
///     https://blog.kobalab.net/entry/2024/11/04/215201
///     → 和了率 .211 / 平均打点 5,789（供託・本場込み）/ 立直率 .184 / 副露率 .326
///   ・ツモ／ロン比は4人打ちで概ね 45：55（門前清自摸和の出現や副露ツモを含む一般値）。
///
/// 数値は厳密な実戦確率ではなく「概算の目安」。打点出現率カーブは上記の
/// 平均打点（純粋な手の平均 ≈ 5,000〜5,200 点）に整合するよう較正している。
/// 後で実データへ差し替えやすいよう定数として独立させている。
enum MahjongStats {

    /// 1局あたりの自分の和了率。天鳳鳳凰卓2023の和了率 .211 を採用。
    static let winRate = 0.21
    /// 親番のときの和了率（親は和了率が高い傾向。概算の上振せ）。
    static let winRateDealer = 0.25

    /// 和了のうちロン／ツモが占める割合（4人打ちの一般値）。
    static let ronShare = 0.55
    static let tsumoShare = 0.45

    /// P(和了打点 >= しきい点 | 和了)。子ロン換算の代表点をキーにした概算の生存確率。
    /// 昇順テーブル。キー間は線形補間する。
    /// 較正の目安：このカーブの期待値 ≈ 4,800 点、満貫(8000)以上 ≈ 18%（赤ありで高打点が出やすい）。
    private static let survivalTable: [(points: Int, prob: Double)] = [
        (1000, 1.00), (1300, 0.91), (1600, 0.84), (2000, 0.78),
        (2600, 0.69), (3200, 0.60), (3900, 0.51), (5200, 0.40),
        (6400, 0.31), (7700, 0.24), (8000, 0.18),   // 満貫
        (12000, 0.08),   // 跳満
        (16000, 0.03),   // 倍満
        (24000, 0.008),  // 三倍満
        (32000, 0.002)   // 役満
    ]

    /// 和了したときの打点帯の分布 P(打点帯 = v | 和了)（昇順）。
    /// 生存確率の隣接差から求める。実現率の内訳チャート用。
    static func valueDistribution() -> [(points: Int, prob: Double)] {
        survivalTable.indices.map { i in
            let s = survivalTable[i].prob
            let sNext = (i + 1 < survivalTable.count) ? survivalTable[i + 1].prob : 0
            return (survivalTable[i].points, max(0, s - sNext))
        }
    }

    /// 子ロン換算の代表点における「その打点以上で和了する割合」。
    /// テーブルのキーに無い点数でもティア間を線形補間して滑らかに返す。
    static func valueSurvival(childRonEquivalent points: Int) -> Double {
        guard let first = survivalTable.first, let last = survivalTable.last else { return 0.002 }
        if points <= first.points { return first.prob }
        if points >= last.points { return last.prob }
        for i in 1..<survivalTable.count {
            let lo = survivalTable[i - 1], hi = survivalTable[i]
            if points <= hi.points {
                let t = Double(points - lo.points) / Double(hi.points - lo.points)
                return lo.prob + (hi.prob - lo.prob) * t
            }
        }
        return last.prob
    }
}
