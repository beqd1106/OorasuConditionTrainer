import Foundation

/// 麻雀の概算統計値。
///
/// 4人打ち・赤あり東南戦の一般的傾向を土台にした概算値（公開されている大規模な
/// オンライン対局の牌譜解析の一般値を参考にした目安）：
///   ・和了率 ≈ 0.21 / 平均打点 ≈ 5,800（供託・本場込み）/ 立直率 ≈ 0.18 / 副露率 ≈ 0.33
///   ・ツモ／ロン比は概ね 45：55（門前ツモ・副露ツモを含む一般値）。
///
/// 数値は厳密な実戦確率ではなく「概算の目安」。打点出現率カーブは上記の
/// 平均打点（純粋な手の平均 ≈ 5,000〜5,200 点）に整合するよう較正している。
/// 後で実データへ差し替えやすいよう定数として独立させている。
enum MahjongStats {

    /// 1局あたりの自分の和了率（一般的な対局統計の約0.21を採用）。
    static let winRate = 0.21
    /// 親番のときの和了率（親は和了率が高い傾向。概算の上振せ）。
    static let winRateDealer = 0.25

    /// 和了のうちロン／ツモが占める割合（4人打ちの一般値）。
    static let ronShare = 0.55
    static let tsumoShare = 0.45

    /// 流局率（一般的な対局統計の約0.16）。
    static let drawRate = 0.16
    /// 1局あたり自分が振り込む確率＝放銃率（一般的な対局統計の約0.12）。
    static let dealInRate = 0.12

    /// 現在の着順による「押し引き傾向」の補正係数（概算モデル）。
    /// 統計的事実：トップ目は守備的で和了率が下がり流局が増える／ラス目は攻撃的で
    /// 和了率・放銃率が上がる（ラス回避麻雀の定石・各種戦術データの一般的傾向）。
    /// 厳密な着順別の実測テーブルは公開が乏しいため、基礎平均に方向性の補正を掛ける。
    private static func rankFactors(_ rank: Int) -> (win: Double, draw: Double) {
        switch rank {
        case 1:  return (0.82, 1.15)   // トップ目：守備的（和了↓・流局↑）
        case 2:  return (0.97, 1.03)
        case 3:  return (1.05, 0.96)
        default: return (1.12, 0.92)   // ラス目：攻撃的（和了↑・流局↓）
        }
    }

    /// この局の結果の見込み（自分の和了／他家の和了／流局）の確率内訳。
    /// 基礎値（和了率・流局率）は一般的な対局統計の平均、そこに現在の着順(rank=1〜4)の
    /// 押し引き傾向を補正して求める概算。他家(3人合計)は残り＝1−自分−流局。
    static func outcomeSplit(isDealer: Bool, rank: Int) -> (myWin: Double, othersWin: Double, draw: Double) {
        let f = rankFactors(rank)
        let myWin = min(0.45, (isDealer ? winRateDealer : winRate) * f.win)
        let draw  = min(0.30, drawRate * f.draw)
        let othersWin = max(0, 1 - myWin - draw)
        return (myWin, othersWin, draw)
    }

    /// 現在の着順に応じた自分の放銃率（概算）。トップ目は低く、ラス目は高い。
    static func dealInRateByRank(_ rank: Int) -> Double {
        switch rank {
        case 1:  return dealInRate * 0.80
        case 2:  return dealInRate * 0.97
        case 3:  return dealInRate * 1.05
        default: return dealInRate * 1.15
        }
    }

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
