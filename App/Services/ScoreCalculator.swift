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

    /// 正解より 1 つ下の候補（解説で「これでは届かない」と説明するのに使う）。
    static func candidateBelow(_ value: Int) -> Int? {
        ronPointCandidates.last { $0 < value }
    }

    /// 4 択を作る。正解＋近い候補3つ（低い側・高い側を混ぜる）を返す。
    static func makeChoices(correct: Int) -> [Int] {
        guard let i = ronPointCandidates.firstIndex(of: correct) else {
            return Array(ronPointCandidates.prefix(4))
        }
        // 正解の直下2つ（近い順）と直上2つを集める
        let below = Array(ronPointCandidates[..<i].suffix(2).reversed()) // 近い順
        let above = Array(ronPointCandidates[(i + 1)...].prefix(2))

        var others = below + above
        // 端の候補で3つに満たない場合は残りの候補から補充
        if others.count < 3 {
            let extra = ronPointCandidates.filter { $0 != correct && !others.contains($0) }
            others += extra
        }
        let picked = Array(others.prefix(3))
        return (picked + [correct]).shuffled()
    }
}
