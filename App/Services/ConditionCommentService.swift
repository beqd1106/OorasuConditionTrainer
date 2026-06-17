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
    var valueRarityPercent: Int?  // その打点以上で和了する割合(%)。nil=役満超
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
            return "\(r.targetLabel)は役満を超える打点が必要で、現実的にはほぼ不可能です。この相手は諦め、他の着順を狙う方が分があります。"
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
        if r.isDirectOnly { text += " 他家からのアガリでは届かず、対象者への直撃が必要です（相手が振り込む必要があり、難度はさらに上がります）。" }

        // ③ 打点の出現率（統計由来の実数で提示。実現率%とは別の指標）
        if let rarity = r.valueRarityPercent {
            text += " この打点以上で和了できるのは、和了したうち約\(rarity)%です。"
        }

        // ④ 実現率（条件の難易度ではなく「この手1回で決まる確率」）＋ティア別の方針
        switch r.feasibility {
        case 55...:
            text += " この手で決められる確率は約\(r.feasibility)%。十分に狙える条件です。リーチや仕掛けで素直にアガリへ向かいましょう。"
        case 25..<55:
            let route = r.haneOrAbove
                ? "ドラ・裏ドラ・一発まで含めた高打点ルートを意識しましょう。"
                : "打点より先に、まずアガれる形を最優先に組み立てましょう。"
            text += " この手で決められる確率は約\(r.feasibility)%。簡単ではありませんが、手が育てば届きます。\(route)"
        default:
            text += " この手で決められる確率は約\(r.feasibility)%とかなり苦しい条件です。無理押しは失点リスクが高いので、条件が軽い別の着順や、他家の直撃・横移動による着順変動も視野に入れましょう。"
        }

        // ⑤ 親番の方針
        if r.isDealer {
            text += " 親番が残るなら、無理に決め切らず連荘でチャンスを増やす選択もあります。"
        }
        return text
    }
}
