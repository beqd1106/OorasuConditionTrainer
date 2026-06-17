import Foundation

/// 条件コメント生成への入力。
struct ConditionCommentInput {
    var targetLabel: String       // 例: "1位" / "トップ"
    var feasibility: Int          // 0〜100
    var requiredHand: Int?        // nil = 役満超
    var winType: WinType
    var isDealer: Bool
    var isDirectOnly: Bool
    var manganOrAbove: Bool
    var haneOrAbove: Bool
    var remainingRounds: Int
}

/// 条件の自然文コメントを生成するサービス（抽象）。
/// `LocalCommentService` はルールベース（API不要・無料）。
/// 将来 `RemoteAICommentService`（バックエンド経由のLLM）に差し替え可能。
protocol ConditionCommentService {
    func comment(for input: ConditionCommentInput) -> String
}

/// ルールベースの自然文コメント（API不要・費用ゼロ）。
struct LocalCommentService: ConditionCommentService {
    func comment(for r: ConditionCommentInput) -> String {
        guard r.requiredHand != nil else {
            return "\(r.targetLabel)は役満を超える打点が必要で、現実的にはほぼ不可能です。別の着順を狙う方がよいでしょう。"
        }

        let level: String
        switch r.feasibility {
        case 65...:   level = "現実的に狙えます"
        case 40..<65: level = "やや厳しめですが狙えます"
        case 20..<40: level = "厳しめです"
        default:      level = "かなり厳しい条件です"
        }

        var reasons: [String] = []
        if r.haneOrAbove { reasons.append("跳満以上が必要") }
        else if r.manganOrAbove { reasons.append("満貫が必要") }
        if r.winType == .tsumo { reasons.append("ツモ条件") }
        if r.isDirectOnly { reasons.append("直撃限定なのでただアガるだけでは届きません") }

        var text = "\(r.targetLabel)は"
        if !reasons.isEmpty { text += reasons.joined(separator: "・") + "で、" }
        text += "\(level)。"

        if r.isDealer {
            text += " 親番が残っているので、無理せず連荘を狙う選択もあります。"
        } else if r.remainingRounds > 0 {
            text += " まだ局が残っているので、押し引きは慎重に。"
        }
        if !r.manganOrAbove && r.feasibility >= 55 {
            text += " リーチ・タンヤオ・ドラ絡みで十分届く範囲です。"
        }
        return text
    }
}
