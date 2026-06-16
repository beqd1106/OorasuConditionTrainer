import SwiftUI

/// 成績タブ。段位・レーティングと通算成績を表示。
struct StatsView: View {
    @EnvironmentObject private var statsViewModel: StatsViewModel

    private var standing: RankSystem.Standing { RankSystem.standing(for: statsViewModel.stats) }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                rankCard
                statsRow
                modeBreakdown
                emptyHint
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(PaperBackground())
        .navigationTitle("成績")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { statsViewModel.refresh() }
    }

    // MARK: - 段位カード

    private var rankCard: some View {
        VStack(spacing: 14) {
            Text("段位")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.85))
            Text(standing.name)
                .font(.system(size: 44, weight: .heavy, design: .serif))
                .foregroundStyle(.white)
            HStack(spacing: 6) {
                Image(systemName: "rosette").font(.caption)
                Text("レーティング \(standing.rating)")
                    .font(.subheadline.weight(.bold))
            }
            .foregroundStyle(Theme.gold)

            // 次の段位への進捗
            if let nextName = standing.nextName {
                VStack(spacing: 4) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(.white.opacity(0.25))
                            Capsule().fill(Theme.gold)
                                .frame(width: geo.size.width * standing.progress)
                        }
                    }
                    .frame(height: 8)
                    Text("次は \(nextName)（あと \(max(0, (standing.nextThreshold ?? standing.rating) - standing.rating)) pt）")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.8))
                }
            } else {
                Text("最高段位に到達！")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.gold)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Theme.feltGradient, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(alignment: .topTrailing) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 54))
                .foregroundStyle(.white.opacity(0.07))
                .padding(14)
        }
    }

    // MARK: - 通算成績

    private var statsRow: some View {
        let s = statsViewModel.stats
        return HStack(spacing: 12) {
            StatsCardView(
                value: s.totalQuestions == 0 ? "—" : "\(s.accuracyPercent)%",
                label: "通算正答率", systemImage: "checkmark.seal.fill", accent: Theme.correct
            )
            StatsCardView(
                value: s.totalQuestions == 0 ? "—" : String(format: "%.1f秒", s.averageResponseSeconds),
                label: "平均回答時間", systemImage: "timer", accent: Theme.felt
            )
            StatsCardView(
                value: "\(s.totalQuestions)",
                label: "累計回答数", systemImage: "sum", accent: Theme.gold
            )
        }
    }

    // MARK: - モード別正答率

    private var modeBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("モード別正答率", systemImage: "chart.bar.fill")
                .font(.headline.weight(.bold))
                .foregroundStyle(Theme.felt)
            ForEach(QuestionMode.allCases) { mode in
                modeBar(mode: mode, stats: statsViewModel.modeStats[mode])
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func modeBar(mode: QuestionMode, stats: UserStats?) -> some View {
        let total = stats?.totalQuestions ?? 0
        let percent = stats?.accuracyPercent ?? 0
        let ratio = total == 0 ? 0 : Double(percent) / 100.0
        return VStack(spacing: 4) {
            HStack {
                Label(mode.title, systemImage: mode.systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
                Text(total == 0 ? "—" : "\(percent)%（\(total)問）")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(total == 0 ? .secondary : Theme.felt)
                    .monospacedDigit()
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.paperDeep)
                    Capsule().fill(Theme.felt)
                        .frame(width: geo.size.width * ratio)
                }
            }
            .frame(height: 8)
        }
    }

    @ViewBuilder
    private var emptyHint: some View {
        if statsViewModel.stats.totalQuestions == 0 {
            VStack(spacing: 6) {
                Image(systemName: "sparkles").font(.title2).foregroundStyle(Theme.gold)
                Text("練習すると段位が上がります")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
        }
    }
}
