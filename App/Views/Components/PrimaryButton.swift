import SwiftUI

/// 大きめのメインボタンの見た目。
/// Button からも NavigationLink からも使えるよう、ラベル部分を独立させている。
struct PrimaryButtonLabel: View {
    let title: String
    var subtitle: String? = nil
    var systemImage: String? = nil
    var background: Color = Theme.felt
    var foreground: Color = .white

    var body: some View {
        HStack(spacing: 14) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.title2.weight(.semibold))
                    .frame(width: 28)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline.weight(.bold))
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(foreground.opacity(0.85))
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.semibold))
                .opacity(0.6)
        }
        .foregroundStyle(foreground)
        .padding(.vertical, 18)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: background.opacity(0.25), radius: 8, x: 0, y: 4)
    }
}

/// タップアクション付きのメインボタン
struct PrimaryButton: View {
    let title: String
    var subtitle: String? = nil
    var systemImage: String? = nil
    var background: Color = Theme.felt
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            PrimaryButtonLabel(title: title, subtitle: subtitle,
                               systemImage: systemImage, background: background)
        }
        .buttonStyle(.plain)
    }
}
