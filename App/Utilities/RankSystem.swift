import Foundation

/// 段位・レーティングの算出。通算成績（正答率・回答数）から導く。
enum RankSystem {

    /// レーティング（おおよそ 1000〜2150）
    static func rating(for stats: UserStats) -> Int {
        guard stats.totalQuestions > 0 else { return 1000 }
        // 基礎1000 ＋ 正答率(最大600) ＋ 演習量(最大400)
        let acc = Double(stats.accuracyPercent) * 6.0
        let volume = Double(min(stats.totalQuestions, 400))
        return 1000 + Int(acc) + Int(volume)
    }

    /// 段位ラダー（しきい値レーティング, 名称）
    private static let ladder: [(threshold: Int, name: String)] = [
        (0, "無級"), (1100, "10級"), (1150, "9級"), (1200, "8級"),
        (1250, "7級"), (1300, "6級"), (1350, "5級"), (1400, "4級"),
        (1450, "3級"), (1480, "2級"), (1500, "1級"),
        (1520, "初段"), (1560, "二段"), (1600, "三段"), (1660, "四段"),
        (1720, "五段"), (1800, "六段"), (1880, "七段"), (1960, "八段"),
        (2050, "九段"), (2150, "十段")
    ]

    struct Standing {
        let rating: Int
        let name: String
        let currentThreshold: Int
        let nextThreshold: Int?   // nil = 最高段
        let nextName: String?
        /// 次の段位までの進捗（0〜1）
        var progress: Double {
            guard let next = nextThreshold, next > currentThreshold else { return 1 }
            return min(1, max(0, Double(rating - currentThreshold) / Double(next - currentThreshold)))
        }
    }

    static func standing(for stats: UserStats) -> Standing {
        let r = rating(for: stats)
        var idx = 0
        for (i, step) in ladder.enumerated() where r >= step.threshold { idx = i }
        let current = ladder[idx]
        let next = idx + 1 < ladder.count ? ladder[idx + 1] : nil
        return Standing(
            rating: r, name: current.name, currentThreshold: current.threshold,
            nextThreshold: next?.threshold, nextName: next?.name
        )
    }
}
