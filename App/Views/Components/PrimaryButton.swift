import SwiftUI

/// 大きめのメインボタンの見た目（白カード＋細枠＋アクセントのアイコンチップ・影なし）。
struct PrimaryButtonLabel: View {
    let title: String
    var subtitle: String? = nil
    var systemImage: String? = nil
    /// アクセント色（アイコンチップ等に少量だけ使う）
    var background: Color = Theme.accentBlue
    var foreground: Color = Theme.ink

    var body: some View {
        HStack(spacing: 14) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(background)
                    .frame(width: 38, height: 38)
                    .background(background.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.secondary.opacity(0.6))
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .cardStyle(cornerRadius: 14)
    }
}

/// タップアクション付きのメインボタン
struct PrimaryButton: View {
    let title: String
    var subtitle: String? = nil
    var systemImage: String? = nil
    var background: Color = Theme.accentBlue
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            PrimaryButtonLabel(title: title, subtitle: subtitle,
                               systemImage: systemImage, background: background)
        }
        .buttonStyle(.plain)
    }
}
