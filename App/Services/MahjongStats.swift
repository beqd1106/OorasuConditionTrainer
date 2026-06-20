import Foundation

/// 麻雀の概算統計値。
///
/// 4人打ち・赤あり東南戦の大規模な牌譜統計（公開されている実測値）を土台にした概算。
/// 実測アンカー（ファクトチェック済み 2026-06-20）：
///   ・和了率 ≈ .211（全席平均）/ 放銃率 ≈ .124 / 流局率 ≈ .162
///   ・平均和了点 ≈ 5,789（供託・本場込み。純粋な手の平均は ≈ 5,000〜5,200）
///   ・立直率 ≈ .184 / 副露率 ≈ .326 / 門前自摸の出現 ≈ 和了の約25%
/// 親/子別の和了率・ツモ比・打点分布は実測の公開テーブルが乏しいため、上記の実測
/// アンカーと整合するよう導出・較正した概算（厳密な実戦確率ではない）。
/// 着順別の押し引き補正は方向性のみのモデル（公開実測なし）。
/// 後で実データへ差し替えやすいよう定数として独立させている。
enum MahjongStats {

    /// 1局あたりの自分（子）の和了率。全席平均 .211 を席重み（親1/4・子3/4）で分け、
    /// 親が約1.3倍高い傾向に合わせて配分した概算（子≈.20・親≈.26、加重≈.21）。
    static let winRate = 0.20
    /// 親番のときの和了率（親は明確に高い）。上記の配分による概算。
    static let winRateDealer = 0.26

    /// 和了のうちロン／ツモが占める割合。門前自摸が和了の約25%（実測）、副露ツモを
    /// 加えて総ツモ ≈ 43%、残りロン ≈ 57%（4人打ち・赤ありの概算）。
    static let ronShare = 0.57
    static let tsumoShare = 0.43

    /// 流局率（実測 ≈ .162）。
    static let drawRate = 0.16
    /// 1局あたり自分が振り込む確率＝放銃率（実測 ≈ .124）。
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
    /// 較正の目安：このカーブの期待値 ≈ 4,900 点、満貫(8000)以上 ≈ 19%（赤ありで高打点が出やすい）。
    /// 実測の平均和了点（純手 ≈ 5,000〜5,200）に整合させた概算。個別ティアの割合は公開実測なし。
    private static let survivalTable: [(points: Int, prob: Double)] = [
        (1000, 1.00), (1300, 0.90), (1600, 0.83), (2000, 0.77),
        (2600, 0.69), (3200, 0.61), (3900, 0.53), (5200, 0.43),
        (6400, 0.33), (7700, 0.25), (8000, 0.19),   // 満貫
        (12000, 0.085),  // 跳満
        (16000, 0.032),  // 倍満
        (24000, 0.009),  // 三倍満
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
