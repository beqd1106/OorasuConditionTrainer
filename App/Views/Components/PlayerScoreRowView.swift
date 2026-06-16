import SwiftUI

/// 順位表の1行（順位・席・点数・バッジ）。白地・フラット・三原色アクセント。
struct PlayerScoreRowView: View {
    let rank: Int
    let player: Player
    let isTarget: Bool
    var isDealer: Bool = false

    private var rankColor: Color {
        switch rank {
        case 1:  return Theme.accentBlue
        case 4:  return Theme.accentRed
        default: return Color.secondary
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // 順位（数字＋小さな下線アクセント）
            Text("\(rank)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(rankColor, in: RoundedRectangle(cornerRadius: 7, style: .continuous))

            Text(player.wind.seatName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.ink)

            if isDealer { outlineBadge("親", Theme.accentYellow) }
            if player.isUser {
                outlineBadge("あなた", Theme.accentBlue)
            } else if isTarget {
                outlineBadge("目標", Theme.accentRed)
            }

            Spacer(minLength: 0)

            Text(NumberFormatterUtility.scoreString(player.score))
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.ink)
                .monospacedDigit()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            player.isUser ? Theme.accentBlue.opacity(0.06) : Color.clear,
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
    }

    private func outlineBadge(_ text: String, _ color: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.bold))
            .foregroundStyle(color)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .overlay(Capsule().strokeBorder(color, lineWidth: 1))
    }
}
