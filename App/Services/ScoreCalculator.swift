import Foundation

/// 点数条件の判定ロジック。
/// 「対象順位を上回るために必要な最低ロン点」を、実戦でよく使う点数候補の中から求める。
enum ScoreCalculator {

    /// 回答候補に使う代表的なロン点（昇順）。
    static let ronPointCandidates: [Int] = [
        1000, 1300, 1600, 2000, 2600, 3200, 3900,
        5200, 6400, 7700, 8000, 12000, 16000, 24000, 32000
    ]

    /// 点差 gap（対象者の点数 − 自分の点数, gap > 0）を逆転するのに必要な最低ロン点。
    ///
    /// ロン（対象者以外から）すると自分だけが加点されるため、
    /// 「自分 + ロン点 > 対象者」を満たす必要がある（同点は逆転不可なので厳密に上回る）。
    /// → ロン点 > gap を満たす最小の候補を返す。候補内に存在しなければ nil。
    static func minimumRonToOvertake(gap: Int) -> Int? {
        guard gap > 0 else { return nil }
        return ronPointCandidates.first { $0 > gap }
    }

    /// 直撃（対象者から直接ロン）で逆転するのに必要な最低ロン点。
    ///
    /// 直撃すると自分が +ロン点、対象者が -ロン点 となり点差が2倍動く。
    /// 「自分 + ロン点 > 対象者 - ロン点」→「2 × ロン点 > gap」を満たす最小候補を返す。
    static func minimumDirectHitToOvertake(gap: Int) -> Int? {
        guard gap > 0 else { return nil }
        return ronPointCandidates.first { 2 * $0 > gap }
    }

    /// 正解より 1 つ下の候補（解説で「これでは届かない」と説明するのに使う）。
    static func candidateBelow(_ value: Int) -> Int? {
        ronPointCandidates.last { $0 < value }
    }

    /// 4 択を作る（難易度で選択肢の近さを変える）。
    /// easy=候補を離して選びやすく、normal/hard/oni=近い候補で迷わせる。
    static func makeChoices(correct: Int, difficulty: Difficulty = .normal) -> [Int] {
        guard let i = ronPointCandidates.firstIndex(of: correct) else {
            return Array(ronPointCandidates.prefix(4))
        }

        // 難易度ごとの「正解からの距離（インデックス差）」候補
        let offsets: [Int]
        switch difficulty {
        case .easy:   offsets = [-4, -2, 2, 4]   // 離れた候補＝選びやすい
        case .normal: offsets = [-2, -1, 1, 2]
        case .hard:   offsets = [-1, 1, 2, -2]   // 近接
        case .oni:    offsets = [-1, 1, -2, 2]   // 直下（同点トラップ）を必ず含む
        }

        var others: [Int] = []
        for off in offsets where others.count < 3 {
            let j = i + off
            if j >= 0, j < ronPointCandidates.count {
                let v = ronPointCandidates[j]
                if v != correct, !others.contains(v) { others.append(v) }
            }
        }
        // 端で3つに満たない場合は近い候補から補充
        if others.count < 3 {
            let extra = ronPointCandidates.filter { $0 != correct && !others.contains($0) }
            others += extra
        }
        let picked = Array(others.prefix(3))
        return (picked + [correct]).shuffled()
    }

    // MARK: - 計算機モード用

    /// 計算機モードの1件の結果（ある順位を上回るための条件）。
    struct OvertakeResult {
        let targetRank: Int       // 上回りたい相手の順位
        let targetScore: Int
        let gap: Int              // 相手 − 自分（>0）
        let ronOther: Int?        // 他家ロンの最低点（nil=候補内に無い＝要満貫超）
        let ronDirect: Int?       // 直撃の最低点
    }

    /// 計算機モード：自分が上回る必要のある相手ごとに逆転条件を算出する。
    /// 同点の相手も対象（同点は逆転扱いにならないため、1,000点以上が必要）。
    /// - Parameters:
    ///   - scores: 4人の点数（席順など固定順で渡す）
    ///   - userIndex: 自分の席のインデックス
    static func overtakeConditions(scores: [Int], userIndex: Int) -> [OvertakeResult] {
        guard scores.indices.contains(userIndex) else { return [] }
        let userScore = scores[userIndex]
        var seenScores = Set<Int>()
        var results: [OvertakeResult] = []

        for (i, s) in scores.enumerated() where i != userIndex {
            guard s >= userScore else { continue }   // すでに自分が上＝対象外
            guard !seenScores.contains(s) else { continue }
            seenScores.insert(s)

            let gap = s - userScore                  // >= 0（同点なら0）
            let rank = 1 + scores.filter { $0 > s }.count
            // gap=0（同点）でも厳密に上回る必要があるため「> gap」で判定。
            let ronOther = ronPointCandidates.first { $0 > gap }
            let ronDirect = ronPointCandidates.first { 2 * $0 > gap }
            results.append(
                OvertakeResult(
                    targetRank: rank,
                    targetScore: s,
                    gap: gap,
                    ronOther: ronOther,
                    ronDirect: ronDirect
                )
            )
        }
        return results.sorted { $0.targetScore > $1.targetScore }
    }
}
