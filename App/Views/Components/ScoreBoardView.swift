import SwiftUI

/// 局面情報＋順位表＋目標との点差を表示するボード。
struct ScoreBoardView: View {
    let question: Question

    private var ranked: [Player] { question.rankedPlayers }
    private var user: Player { question.user }
    private var target: Player { ranked[question.targetRank - 1] }

    private var diffLabel: String {
        let diff = target.score - user.score
        let name: String
        switch question.mode {
        case .top:                  name = "トップ"
        case .avoidLast:            name = "3位"
        case .rankUp, .directHit:   name = "\(question.targetRank)位"
        }
        return "\(name)まで \(NumberFormatterUtility.scoreString(diff))点差"
    }

    var body: some View {
        VStack(spacing: 12) {
            // 局面ヘッダー
            HStack {
                Label("\(question.round) \(question.honba)本場 供託\(question.riichiSticks)",
                      systemImage: "mappin.and.ellipse")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("あなた：\(user.wind.seatName)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.felt)
            }

            // 順位表
            VStack(spacing: 4) {
                ForEach(Array(ranked.enumerated()), id: \.element.id) { index, player in
                    PlayerScoreRowView(
                        rank: index + 1,
                        player: player,
                        isTarget: player.id == target.id && !player.isUser
                    )
                }
            }

            // 目標との点差
            HStack(spacing: 8) {
                Image(systemName: "target")
                    .font(.subheadline.weight(.bold))
                Text(diffLabel)
                    .font(.subheadline.weight(.bold))
            }
            .foregroundStyle(.white)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(Theme.feltGradient, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .padding(16)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
