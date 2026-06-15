import SwiftUI

/// モード選択画面（ホームからも直接モードへ飛べるが、一覧として独立して用意）。
struct ModeSelectView: View {
    @EnvironmentObject private var settings: SettingsStore

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(QuestionMode.allCases) { mode in
                    NavigationLink(value: Route.quiz(mode, settings.defaultDifficulty)) {
                        modeCard(mode)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("練習モード")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func modeCard(_ mode: QuestionMode) -> some View {
        HStack(spacing: 16) {
            Image(systemName: mode.systemImage)
                .font(.title.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Theme.feltGradient, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(mode.title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.primary)
                Text(mode.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
