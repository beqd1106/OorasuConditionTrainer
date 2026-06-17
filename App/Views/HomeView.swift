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
            VStack(spacing: 22) {
                header
                difficultySection
                todaySection
                modeSection
                reviewSection
                footerLinks
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(PaperBackground())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            statsViewModel.refresh()
            weakCount = WeakQuestionStore.shared.count
        }
    }

    // MARK: - ヘッダー

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 三原色のドット（控えめなアクセント）
            HStack(spacing: 6) {
                Circle().fill(Theme.accentRed).frame(width: 8, height: 8)
                Circle().fill(Theme.accentBlue).frame(width: 8, height: 8)
                Circle().fill(Theme.accentYellow).frame(width: 8, height: 8)
            }
            Text("テンパス")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(Theme.ink)
            Text("「何点必要？」を一瞬でわかる麻雀力へ。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .cardStyle(cornerRadius: 18)
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
                .cardStyle(cornerRadius: 14)
            }
        }
    }

    // MARK: - フッターリンク（遊び方）

    private var footerLinks: some View {
        NavigationLink(value: Route.howToPlay) {
            linkRow(title: "遊び方・条件の考え方", systemImage: "questionmark.circle.fill")
        }
        .buttonStyle(.plain)
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
        .cardStyle(cornerRadius: 14)
    }

    // MARK: - 共通

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.headline.weight(.bold))
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
