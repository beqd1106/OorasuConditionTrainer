import SwiftUI

/// アプリ全体の配色。クリーム×深緑の「和帳面」スタイル（ライトテーマ）。
enum Theme {
    /// 背景（クリーム／生成り）
    static let paper = Color(red: 0.949, green: 0.918, blue: 0.851)
    /// カード（ほぼ白の生成り）
    static let card = Color(red: 0.992, green: 0.976, blue: 0.937)
    /// 一段濃いクリーム（区切り・サブ背景）
    static let paperDeep = Color(red: 0.910, green: 0.870, blue: 0.788)

    /// 深緑（プライマリ）
    static let felt = Color(red: 0.176, green: 0.357, blue: 0.255)
    /// 濃い深緑
    static let feltDeep = Color(red: 0.118, green: 0.267, blue: 0.188)
    /// 真鍮・金
    static let gold = Color(red: 0.706, green: 0.557, blue: 0.314)
    /// 朱（アクセント）
    static let accentRed = Color(red: 0.722, green: 0.290, blue: 0.204)

    /// 正解・不正解
    static let correct = Color(red: 0.204, green: 0.471, blue: 0.302)
    static let wrong = accentRed

    /// 文字（墨）
    static let ink = Color(red: 0.165, green: 0.176, blue: 0.133)

    static let feltGradient = LinearGradient(
        colors: [felt, feltDeep], startPoint: .topLeading, endPoint: .bottomTrailing
    )

    /// 既存コード互換：背景
    static let background = paper
}

/// 和紙テクスチャの背景。restyle した画面で使う。
struct PaperBackground: View {
    var body: some View {
        ZStack {
            Theme.paper
            Image("WashiBG")
                .resizable()
                .scaledToFill()
                .opacity(0.85)
        }
        .ignoresSafeArea()
    }
}
