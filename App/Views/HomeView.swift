import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var statsViewModel: StatsViewModel
    @EnvironmentObject private var settings: SettingsStore

    @State private var weakCount: Int = 0

    /// 日替わりのおすすめモード（日付で決まる）
    private var dailyMode: QuestionMode {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let modes = QuestionMode.allCases
        return modes[day % modes.count]
    }

    private var difficulty: Difficulty { settings.defaultDifficulty }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header
                difficultySection
                todaySection
                modeSection
                reviewSection
                toolSection
                statsSection
                footerLinks
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            statsViewModel.refresh()
            weakCount = WeakQuestionStore.shared.count
        }
    }

    // MARK: - ヘッダー

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

    // MARK: - 難易度

    private var difficultySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                sectionTitle("難易度")
                Spacer()
                Label(difficulty.caption, systemImage: difficulty.systemImage)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(difficulty.accent)
            }
            Picker("難易度", selection: $settings.defaultDifficulty) {
                ForEach(Difficulty.allCases) { d in
                    Text(d.title).tag(d)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - 今日の練習

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("今日の練習")
            NavigationLink(value: Route.quiz(dailyMode, difficulty)) {
                PrimaryButtonLabel(
                    title: "\(dailyMode.title) 10問",
                    subtitle: "\(dailyMode.summary)（\(difficulty.title)）",
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
                NavigationLink(value: Route.quiz(mode, difficulty)) {
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

    // MARK: - 苦手復習

    @ViewBuilder
    private var reviewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("苦手復習")
            if weakCount > 0 {
                NavigationLink(value: Route.review) {
                    PrimaryButtonLabel(
                        title: "苦手問題を復習（\(min(weakCount, 10))問）",
                        subtitle: "間違えた問題から出題。正解すると外れます",
                        systemImage: "arrow.uturn.backward.circle.fill",
                        background: Theme.gold
                    )
                }
                .buttonStyle(.plain)
            } else {
                HStack(spacing: 12) {
                    Image(systemName: "tray.fill")
                        .foregroundStyle(.secondary)
                    Text("間違えた問題がここに貯まります")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 0)
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }

    // MARK: - 実戦ツール（計算機）

    private var toolSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("実戦ツール")
            NavigationLink(value: Route.calculator) {
                PrimaryButtonLabel(
                    title: "条件計算機",
                    subtitle: "各家の点数を入力 → 逆転に必要な点を即算出",
                    systemImage: "function",
                    background: Theme.feltDeep
                )
            }
            .buttonStyle(.plain)
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

    // MARK: - フッターリンク（遊び方・設定）

    private var footerLinks: some View {
        VStack(spacing: 10) {
            NavigationLink(value: Route.howToPlay) {
                linkRow(title: "遊び方・条件の考え方", systemImage: "questionmark.circle.fill")
            }
            .buttonStyle(.plain)
            NavigationLink(value: Route.settings) {
                linkRow(title: "設定", systemImage: "gearshape.fill")
            }
            .buttonStyle(.plain)
        }
    }

    private func linkRow(title: String, systemImage: String) -> some View {
        HStack {
            Image(systemName: systemImage)
            Text(title)
                .font(.subheadline.weight(.semibold))
            Spacer()
            Image(systemName: "chevron.right").font(.caption.weight(.bold)).opacity(0.5)
        }
        .foregroundStyle(.primary)
        .padding(16)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - 共通

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.headline.weight(.bold))
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
