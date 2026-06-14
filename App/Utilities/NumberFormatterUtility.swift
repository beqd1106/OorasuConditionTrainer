import Foundation

/// 点数を「31,800」のようにカンマ区切りで表示するためのユーティリティ。
enum NumberFormatterUtility {
    private static let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = ","
        f.groupingSize = 3
        return f
    }()

    /// 例: 31800 -> "31,800"
    static func scoreString(_ value: Int) -> String {
        formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
