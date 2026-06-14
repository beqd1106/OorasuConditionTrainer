import SwiftUI

/// アプリ全体の配色。緑・白・黒を基調に、アクセントで赤・金を使う。
/// 背景はシステムカラーを使い、ダークモードへ自動対応する。
enum Theme {
    /// 麻雀卓の緑（プライマリ）
    static let felt = Color(red: 0.05, green: 0.34, blue: 0.23)
    /// 濃い緑（グラデーション下端）
    static let feltDeep = Color(red: 0.03, green: 0.22, blue: 0.15)
    /// アクセントの赤
    static let accentRed = Color(red: 0.82, green: 0.20, blue: 0.20)
    /// アクセントの金
    static let gold = Color(red: 0.80, green: 0.66, blue: 0.34)

    /// 正解・不正解のフィードバック色
    static let correct = Color(red: 0.13, green: 0.55, blue: 0.33)
    static let wrong = accentRed

    /// ヘッダーなどに使う緑のグラデーション
    static let feltGradient = LinearGradient(
        colors: [felt, feltDeep],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // 背景・カード（ダークモード自動対応）
    static let background = Color(.systemGroupedBackground)
    static let card = Color(.secondarySystemGroupedBackground)
}
