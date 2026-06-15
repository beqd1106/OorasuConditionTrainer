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
}
