import Foundation

/// 練習モード。
/// 将来モードを追加する場合はここに case を足し、QuestionGenerator / 表示拡張に対応を加えるだけでよい。
enum QuestionMode: String, Codable, CaseIterable, Identifiable {
    case rankUp     // 着順アップ：1つ上の順位へ
    case avoidLast  // ラス回避：4位 → 3位
    case top        // トップ条件：2/3位 → トップ

    var id: String { rawValue }

    /// 画面に出すモード名
    var title: String {
        switch self {
        case .rankUp:    return "着順アップ"
        case .avoidLast: return "ラス回避"
        case .top:       return "トップ条件"
        }
    }

    /// モード選択画面などで使う短い説明
    var summary: String {
        switch self {
        case .rankUp:    return "1つ上の順位に上がる最低ロン点を当てる"
        case .avoidLast: return "4位から3位へ。ラスを回避する条件を当てる"
        case .top:       return "2位・3位からトップをまくる条件を当てる"
        }
    }

    /// SF Symbols のアイコン名（絵文字は使わない）
    var systemImage: String {
        switch self {
        case .rankUp:    return "arrow.up.circle.fill"
        case .avoidLast: return "shield.lefthalf.filled"
        case .top:       return "crown.fill"
        }
    }
}

/// 1問分のデータ。問題文・選択肢・正解・解説まで自己完結して持つ。
struct Question: Identifiable, Codable, Hashable {
    let id: UUID
    let mode: QuestionMode
    let round: String          // 例: "南4局"
    let honba: Int             // 本場（MVPは0固定）
    let riichiSticks: Int      // 供託（MVPは0固定）
    let players: [Player]
    let userPlayerId: UUID
    let targetRank: Int        // 上回りたい相手の順位（1〜）
    let questionText: String
    let choices: [Int]
    let correctAnswer: Int
    let explanation: String

    /// 自分のプレイヤー
    var user: Player {
        players.first { $0.id == userPlayerId } ?? players[0]
    }

    /// 点数の高い順に並べたプレイヤー（順位表示用）
    var rankedPlayers: [Player] {
        players.sorted { $0.score > $1.score }
    }
}
