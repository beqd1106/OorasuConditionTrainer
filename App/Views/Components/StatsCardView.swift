import SwiftUI

/// 小さな成績カード（数字＋ラベル）。白＋細枠のフラット。
struct StatsCardView: View {
    let value: String
    let label: String
    var systemImage: String? = nil
    var accent: Color = Theme.accentBlue

    var body: some View {
        VStack(spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(accent)
            }
            Text(value)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.ink)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .cardStyle(cornerRadius: 12)
    }
}
