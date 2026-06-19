import SwiftUI
import Charts

/// 「実現○%」をタップしたときに出る内訳シート。
/// 和了したときの打点帯の出現率を棒グラフで示し、どの打点なら逆転できるかを色分けする。
struct FeasibilityDetailView: View {
    let targetRank: Int
    let gap: Int
    let feasibility: Int
    let requiredHand: Int?      // 主たる和了方法での必要最低手（合計点）。nil = 役満超
    let winType: WinType
    let isDealer: Bool
    let methodLabel: String     // "他家ロン" / "直撃" / "ツモ"
    let valueRarityPercent: Int?  // 必要打点以上で和了する割合(%)
    let userRank: Int           // 自分の現在の着順(1〜4)。局の見込みの着順補正に使う

    @Environment(\.dismiss) private var dismiss

    /// 打点帯の状態
    private enum Reach { case clear, partial, fail }

    private struct Bucket: Identifiable {
        let id = UUID()
        let label: String
        let prob: Double      // P(この帯 | 和了)
        let reach: Reach
    }

    /// 必要打点の子ロン換算（しきい値）。nil=役満超で到達不能。
    private var thresholdEq: Int? {
        guard let h = requiredHand else { return nil }
        return ProbabilityEstimator.childRonEquivalent(hand: h, isDealer: isDealer, winType: winType)
    }

    /// 6帯に集計したチャート用データ。
    private var buckets: [Bucket] {
        let dist = MahjongStats.valueDistribution()   // [(childRon点, P)]
        let defs: [(String, ClosedRange<Int>)] = [
            ("〜2000",     1000...2000),
            ("2600〜3900", 2600...3900),
            ("5200〜7700", 5200...7700),
            ("満貫",        8000...8000),
            ("跳満",        12000...12000),
            ("倍満以上",    16000...32000)
        ]
        return defs.map { (label, range) in
            let prob = dist.filter { range.contains($0.points) }.reduce(0) { $0 + $1.prob }
            let reach: Reach
            if let t = thresholdEq {
                if range.lowerBound >= t { reach = .clear }
                else if range.upperBound >= t { reach = .partial }
                else { reach = .fail }
            } else {
                reach = .fail   // 役満超：どの帯でも届かない
            }
            return Bucket(label: label, prob: prob, reach: reach)
        }
    }

    /// 実現率の大きさで色分け（計算機の resultRow と同じ基準）。
    private var feasibilityColor: Color {
        switch feasibility {
        case 55...:   return Theme.accentBlue
        case 25..<55: return Theme.accentYellow
        default:      return Theme.accentRed
        }
    }

    private func color(_ reach: Reach) -> Color {
        switch reach {
        case .clear:   return Theme.accentBlue
        case .partial: return Theme.accentYellow
        case .fail:    return Theme.line
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    summaryCard
                    chartCard
                    legendCard
                    outcomeCard
                    statsCard
                    Text("※ 出現率・確率は天鳳鳳凰卓の統計をもとにした概算です。実際は手牌・場況により変わります。")
                        .font(.caption2).foregroundStyle(.secondary)
                }
                .padding(16)
            }
            .background(PaperBackground())
            .navigationTitle("\(targetRank)位を抜く可能性")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }

    // MARK: - サマリー

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("実現")
                    .font(.subheadline.weight(.bold)).foregroundStyle(Theme.felt)
                Text("\(feasibility)%")
                    .font(.system(size: 38, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(feasibilityColor)
                Spacer()
                Text("差 \(NumberFormatterUtility.scoreString(gap))")
                    .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            }
            if let _ = requiredHand, let rarity = valueRarityPercent {
                Text("\(methodLabel)でこの手を決めるには、必要打点以上で和了する必要があり、和了したうち約\(rarity)%がその打点です。さらに「和了できるか」を掛け合わせると、この手で決まる確率は約\(feasibility)%になります。")
                    .font(.callout).foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("役満を超える打点が必要で、現実的にはほぼ不可能です。別の着順を狙う方が分があります。")
                    .font(.callout).foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading).cardStyle(cornerRadius: 14)
    }

    // MARK: - チャート

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("和了したときの打点の出やすさ", systemImage: "chart.bar.fill")
                .font(.subheadline.weight(.bold)).foregroundStyle(Theme.felt)
            Chart(buckets) { b in
                BarMark(
                    x: .value("出現率", b.prob * 100),
                    y: .value("打点", b.label)
                )
                .foregroundStyle(color(b.reach))
                .cornerRadius(4)
                .annotation(position: .trailing, alignment: .leading) {
                    Text("\(Int((b.prob * 100).rounded()))%")
                        .font(.caption2.weight(.bold)).foregroundStyle(.secondary)
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let v = value.as(Double.self) { Text("\(Int(v))%") }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(preset: .aligned, position: .leading) { _ in
                    AxisValueLabel()
                }
            }
            // 打点が安い順→高い順で固定（アルファベット整列を防ぐ）
            .chartYScale(domain: buckets.map { $0.label })
            .frame(height: 220)
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading).cardStyle(cornerRadius: 14)
    }

    // MARK: - 凡例

    private var legendCard: some View {
        HStack(spacing: 16) {
            legendItem(.clear, "逆転できる打点")
            legendItem(.partial, "一部届く")
            legendItem(.fail, "届かない")
            Spacer(minLength: 0)
        }
        .font(.caption2)
        .padding(12).frame(maxWidth: .infinity, alignment: .leading).cardStyle(cornerRadius: 12)
    }

    private func legendItem(_ reach: Reach, _ label: String) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 3).fill(color(reach)).frame(width: 12, height: 12)
            Text(label).foregroundStyle(.secondary)
        }
    }

    // MARK: - この局の結果の見込み（自分和了／他家和了／流局）

    private struct Outcome: Identifiable {
        let id = UUID()
        let label: String
        let value: Double
        let color: Color
    }

    private var outcomes: [Outcome] {
        let s = MahjongStats.outcomeSplit(isDealer: isDealer, rank: userRank)
        return [
            Outcome(label: "自分が和了", value: s.myWin,     color: Theme.accentBlue),
            Outcome(label: "他家が和了", value: s.othersWin, color: Theme.accentRed),
            Outcome(label: "流局",       value: s.draw,      color: Theme.accentYellow)
        ]
    }

    private func pct(_ v: Double) -> Int { Int((v * 100).rounded()) }

    private var rankLabel: String {
        switch userRank {
        case 1:  return "トップ目"
        case 2:  return "2番手"
        case 3:  return "3番手"
        default: return "ラス目"
        }
    }

    private var outcomeCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Label("この局の結果の見込み", systemImage: "chart.pie.fill")
                    .font(.subheadline.weight(.bold)).foregroundStyle(Theme.felt)
                Text(rankLabel)
                    .font(.caption2.weight(.bold)).foregroundStyle(.white)
                    .padding(.horizontal, 7).padding(.vertical, 2)
                    .background(Theme.felt, in: Capsule())
            }
            HStack(spacing: 18) {
                Chart(outcomes) { o in
                    SectorMark(angle: .value("割合", o.value), innerRadius: .ratio(0.58), angularInset: 1.5)
                        .foregroundStyle(o.color)
                        .cornerRadius(3)
                }
                .frame(width: 140, height: 140)
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(outcomes) { o in
                        HStack(spacing: 6) {
                            Circle().fill(o.color).frame(width: 10, height: 10)
                            Text(o.label).font(.caption)
                            Spacer(minLength: 8)
                            Text("\(pct(o.value))%").font(.caption.weight(.bold)).monospacedDigit()
                        }
                    }
                }
            }
            Text("多くの局は他家の和了か流局で終わります。逆転はまず自分が和了できることが前提です。\(rankLabel)の押し引き傾向（トップ目は守備的・ラス目は攻撃的）を反映した概算で、基礎値は天鳳鳳凰卓の平均です。")
                .font(.caption2).foregroundStyle(.secondary)
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading).cardStyle(cornerRadius: 14)
    }

    // MARK: - 参考データ

    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("参考データ（\(rankLabel)・概算）", systemImage: "tablecells")
                .font(.subheadline.weight(.bold)).foregroundStyle(Theme.felt)
            let split = MahjongStats.outcomeSplit(isDealer: isDealer, rank: userRank)
            statRow("自分の和了率", "約\(pct(split.myWin))%\(isDealer ? "（親）" : "")")
            statRow("自分の放銃率", "約\(pct(MahjongStats.dealInRateByRank(userRank)))%")
            statRow("和了の内訳（ツモ:ロン）", "約\(pct(MahjongStats.tsumoShare)):\(pct(MahjongStats.ronShare))")
            statRow("流局率", "約\(pct(split.draw))%")
            Text("基礎値の出典：天鳳 鳳凰卓 2023年 牌譜統計ほか。着順別は押し引き傾向を反映した概算。")
                .font(.caption2).foregroundStyle(.secondary).padding(.top, 2)
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading).cardStyle(cornerRadius: 14)
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Spacer(minLength: 8)
            Text(value).font(.subheadline.weight(.bold)).monospacedDigit()
        }
    }
}
