import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var statsViewModel: StatsViewModel

    /// 日替わりのおすすめモード（日付で決まる）
    private var dailyMode: QuestionMode {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let modes = QuestionMode.allCases
        return modes[day % modes.count]
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header
                todaySection
                modeSection
                statsSection
                howToButton
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { statsViewModel.refresh() }
    }

    // MARK: - ヘッダー（アプリ名＋キャッチコピー）

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("オーラス条件トレーナー")
                .font(.system(size: 28, weight: .heavy))
                .foregroundStyle(.white)
            Text("「何点必要？」を一瞬でわかる麻雀力へ。")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(Theme.feltGradient, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(alignment: .topTrailing) {
            Image(systemName: "suit.club.fill")
                .font(.system(size: 60))
                .foregroundStyle(.white.opacity(0.08))
                .padding(12)
        }
        .padding(.top, 12)
    }

    // MARK: - 今日の練習

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("今日の練習")
            NavigationLink(value: Route.quiz(dailyMode)) {
                PrimaryButtonLabel(
                    title: "\(dailyMode.title) 10問",
                    subtitle: dailyMode.summary,
                    systemImage: dailyMode.systemImage,
                    background: Theme.accentRed
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - 各モード

    private var modeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("モードを選ぶ")
            ForEach(QuestionMode.allCases) { mode in
                NavigationLink(value: Route.quiz(mode)) {
                    PrimaryButtonLabel(
                        title: "\(mode.title) 10問",
                        subtitle: mode.summary,
                        systemImage: mode.systemImage,
                        background: Theme.felt
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - 成績

    private var statsSection: some View {
        let stats = statsViewModel.stats
        return VStack(alignment: .leading, spacing: 10) {
            sectionTitle("あなたの成績")
            HStack(spacing: 12) {
                StatsCardView(
                    value: stats.totalQuestions == 0 ? "—" : "\(stats.accuracyPercent)%",
                    label: "通算正答率",
                    systemImage: "checkmark.seal.fill",
                    accent: Theme.correct
                )
                StatsCardView(
                    value: stats.totalQuestions == 0 ? "—" : String(format: "%.1f秒", stats.averageResponseSeconds),
                    label: "平均回答時間",
                    systemImage: "timer",
                    accent: Theme.felt
                )
                StatsCardView(
                    value: "\(stats.totalQuestions)",
                    label: "累計回答数",
                    systemImage: "sum",
                    accent: Theme.gold
                )
            }
        }
    }

    // MARK: - 遊び方

    private var howToButton: some View {
        NavigationLink(value: Route.howToPlay) {
            HStack {
                Image(systemName: "questionmark.circle.fill")
                Text("遊び方・条件の考え方")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Image(systemName: "chevron.right").font(.caption.weight(.bold)).opacity(0.5)
            }
            .foregroundStyle(.primary)
            .padding(16)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - 共通

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.headline.weight(.bold))
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
