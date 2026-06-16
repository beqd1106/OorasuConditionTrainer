import SwiftUI

/// 練習タブ（モード選択）。スクロール不要で全体が1画面に収まる。
struct ModeSelectView: View {
    @EnvironmentObject private var settings: SettingsStore

    private var difficulty: Difficulty { settings.defaultDifficulty }

    var body: some View {
        VStack(spacing: 14) {
            difficultySection
            VStack(spacing: 12) {
                ForEach(QuestionMode.allCases) { mode in
                    NavigationLink(value: Route.quiz(mode, difficulty)) {
                        modeCard(mode)
                    }
                    .buttonStyle(.plain)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .background(PaperBackground())
        .navigationTitle("練習")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - 難易度

    private var difficultySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("難易度")
                    .font(.subheadline.weight(.bold))
                Spacer()
                Label(difficulty.caption, systemImage: difficulty.systemImage)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(difficulty.accent)
            }
            Picker("難易度", selection: $settings.defaultDifficulty) {
                ForEach(Difficulty.allCases) { d in Text(d.title).tag(d) }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - モードカード（コンパクト）

    private func modeAccent(_ mode: QuestionMode) -> Color {
        switch mode {
        case .rankUp:    return Theme.accentBlue
        case .avoidLast: return Theme.accentRed
        case .top:       return Theme.accentYellow
        case .directHit: return Theme.ink
        }
    }

    private func modeCard(_ mode: QuestionMode) -> some View {
        let accent = modeAccent(mode)
        return HStack(spacing: 14) {
            Image(systemName: mode.systemImage)
                .font(.title2.weight(.semibold))
                .foregroundStyle(accent)
                .frame(width: 48, height: 48)
                .background(accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text("\(mode.title) 10問")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.primary)
                Text(mode.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .cardStyle(cornerRadius: 16)
    }
}
