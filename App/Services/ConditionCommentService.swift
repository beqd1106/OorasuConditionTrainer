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

        // ① 条件の「打点難易度」（必要打点ベース。実現率%とは別物として扱う）
        let conditionPhrase: String
        if r.haneOrAbove {
            conditionPhrase = "跳満以上が必要で、打点的にかなり重い条件です"
        } else if r.manganOrAbove {
            conditionPhrase = "満貫が必要な条件です"
        } else {
            conditionPhrase = "満貫未満の手でも届く、打点は軽めの条件です"
        }
        var text = "\(r.targetLabel)は\(conditionPhrase)。"

        // ② 和了方法の制約
        if r.winType == .tsumo { text += " ツモでの条件です。" }
        if r.isDirectOnly { text += " 他家からのアガリでは届かず、対象者への直撃が必要です。" }

        // ③ 打点の出現率（重い条件のときに補足／軽い条件なら狙い方）
        if r.haneOrAbove {
            text += " 跳満以上は和了のうち数%ほどで、引き勝負になります。"
        } else if r.manganOrAbove {
            text += " 満貫以上は和了の約2割です。"
        } else {
            text += " リーチ・タンヤオ・ドラ絡みで十分届きます。"
        }

        // ④ 実現率（条件の難易度ではなく「実際に決まる確率」として正しく提示）
        if r.remainingRounds == 0 {
            text += " ただしオーラスは実質1局勝負で、和了できるか自体が大きく、決まる確率は約\(r.feasibility)%が目安です。"
        } else {
            text += " 残り\(r.remainingRounds)局ぶん試行でき、決まる確率は約\(r.feasibility)%が目安です。"
        }

        // ⑤ 親番の方針
        if r.isDealer {
            text += " 親番が残るなら、無理に決めず連荘を狙う手もあります。"
        }
        return text
    }
}
