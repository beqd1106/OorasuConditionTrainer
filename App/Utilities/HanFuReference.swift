import Foundation

/// ロン点 → 代表的な符・翻の目安。計算機モードで「最低◯◯点（目安：◯符◯翻）」を示す。
/// 厳密な点数計算ではなく、実戦でよく使う代表値の対応。
enum HanFuReference {
    /// 子（非親）ロン
    private static let childRon: [Int: String] = [
        1000: "30符1翻", 1300: "40符1翻", 1600: "50符1翻",
        2000: "30符2翻", 2600: "40符2翻", 3200: "50符2翻",
        3900: "30符3翻", 5200: "40符3翻", 6400: "50符3翻",
        7700: "30符4翻", 8000: "満貫", 12000: "跳満",
        16000: "倍満", 24000: "三倍満", 32000: "役満"
    ]

    /// 親（ディーラー）ロン
    private static let dealerRon: [Int: String] = [
        1500: "30符1翻", 2000: "40符1翻", 2400: "50符1翻",
        2900: "30符2翻", 3400: "40符2翻", 3900: "50符2翻",
        4800: "30符3翻", 5800: "40符3翻", 7700: "50符3翻",
        8700: "30符4翻", 9600: "40符4翻", 11600: "50符4翻",
        12000: "満貫", 18000: "跳満", 24000: "倍満",
        36000: "三倍満", 48000: "役満"
    ]

    /// ロン点の符翻目安
    static func hint(forRon points: Int, isDealer: Bool) -> String? {
        (isDealer ? dealerRon : childRon)[points]
    }

    /// ツモ合計点 → 各家の支払い表記（実値テーブル参照）。
    /// 例：子ツモ2700 → "子700 / 親1300"、親ツモ12000 → "各4000"。
    static func tsumoSplitNote(total: Int, isDealer: Bool) -> String {
        if isDealer {
            if let e = ScoringEngine.dealerTsumoTable.first(where: { $0.total == total }) {
                return "各\(NumberFormatterUtility.scoreString(e.each))"
            }
        } else {
            if let e = ScoringEngine.childTsumoTable.first(where: { $0.total == total }) {
                return "子\(NumberFormatterUtility.scoreString(e.child)) / 親\(NumberFormatterUtility.scoreString(e.dealer))"
            }
        }
        return ""
    }

    /// ツモの分配（コンパクト表記、カンマなし）。
    /// 子ツモ → "3000-6000"、親ツモ → "6000オール"
    static func tsumoSplitCompact(total: Int, isDealer: Bool) -> String {
        if isDealer {
            if let e = ScoringEngine.dealerTsumoTable.first(where: { $0.total == total }) {
                return "\(e.each)オール"
            }
        } else if let e = ScoringEngine.childTsumoTable.first(where: { $0.total == total }) {
            return "\(e.child)-\(e.dealer)"
        }
        return "\(total)"
    }

    private static let namedRanks: Set<String> = ["満貫", "跳満", "倍満", "三倍満", "役満"]

    /// ツモの表示（分配＋満貫以上なら役名）。
    /// 例：子2700 → "700-1300"、子12000 → "3000-6000（跳満）"、親18000 → "6000オール（跳満）"
    static func tsumoDisplay(total: Int, isDealer: Bool) -> String {
        let split = tsumoSplitCompact(total: total, isDealer: isDealer)
        let name = tsumoName(total: total, isDealer: isDealer)
        return namedRanks.contains(name) ? "\(split)（\(name)）" : split
    }

    // ツモの手の名称（満貫等 or 符翻）
    private static let childTsumoName: [Int: String] = [
        1100: "30符1翻", 1500: "40符1翻", 2000: "30符2翻", 2700: "40符2翻",
        3200: "50符2翻", 4000: "30符3翻", 5200: "40符3翻", 6400: "50符3翻",
        7900: "30符4翻", 8000: "満貫", 12000: "跳満", 16000: "倍満",
        24000: "三倍満", 32000: "役満"
    ]
    private static let dealerTsumoName: [Int: String] = [
        1500: "30符1翻", 2100: "40符1翻", 3000: "30符2翻", 3900: "40符2翻",
        4800: "50符2翻", 6000: "30符3翻", 7800: "40符3翻", 9600: "50符3翻",
        11700: "30符4翻", 12000: "満貫", 18000: "跳満", 24000: "倍満",
        36000: "三倍満", 48000: "役満"
    ]

    /// ツモの手の名称（例：12000 → "跳満"）
    static func tsumoName(total: Int, isDealer: Bool) -> String {
        (isDealer ? dealerTsumoName : childTsumoName)[total] ?? ""
    }
}
