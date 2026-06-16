import SwiftUI

/// 順位表の1行（順位・席・点数・自分バッジ）。
struct PlayerScoreRowView: View {
    let rank: Int
    let player: Player
    let isTarget: Bool   // 上回りたい相手かどうか（強調用）
    var isDealer: Bool = false  // 親（東家）

    private var rankColor: Color {
        switch rank {
        case 1:  return Theme.gold
        case 4:  return Theme.accentRed
        default: return .secondary
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // 順位
            Text("\(rank)")
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(rankColor, in: Circle())

            // 席
            Text(player.wind.seatName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            if isDealer {
                Text("親")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Theme.gold, in: Capsule())
            }

            if player.isUser {
                Text("あなた")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Theme.felt, in: Capsule())
            } else if isTarget {
                Text("目標")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Theme.accentRed, in: Capsule())
            }

            Spacer(minLength: 0)

            // 点数
            Text(NumberFormatterUtility.scoreString(player.score))
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .monospacedDigit()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(
            (player.isUser ? Theme.felt.opacity(0.10) : Color.clear),
            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
        )
    }
}
