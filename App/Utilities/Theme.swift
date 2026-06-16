import SwiftUI

/// アプリ全体の配色。白い方眼ノート × 三原色アクセント（クリーン／フラット／ライトテーマ）。
/// 緑・和紙・金・木目などの「雀荘っぽさ」は排除。白・黒・ライトグレー中心に、
/// 赤・青・黄をポイント使い。
enum Theme {
    /// 背景・カード（白）
    static let bg = Color.white
    static let card = Color.white
    /// 方眼グリッド線（うっすらライトグレー）
    static let grid = Color(red: 0.902, green: 0.910, blue: 0.929)
    /// カード等の細い境界線
    static let line = Color(red: 0.886, green: 0.894, blue: 0.914)
    /// 文字（ほぼ黒）
    static let ink = Color(red: 0.106, green: 0.118, blue: 0.137)

    /// 三原色アクセント
    static let accentRed = Color(red: 0.886, green: 0.255, blue: 0.216)
    static let accentBlue = Color(red: 0.129, green: 0.420, blue: 0.918)
    static let accentYellow = Color(red: 0.960, green: 0.718, blue: 0.090)

    /// 正解=青／不正解=赤（緑は使わない）
    static let correct = accentBlue
    static let wrong = accentRed

    // MARK: - 互換トークン（既存コードから参照される名前）
    /// 旧プライマリ（緑）→ インク（黒に近い）。テキスト・アイコン・tint に使う。
    static let felt = ink
    static let feltDeep = Color(red: 0.180, green: 0.196, blue: 0.227)
    /// 旧ゴールド → 黄
    static let gold = accentYellow
    static let paper = bg
    static let paperDeep = grid
    static let background = bg

    /// ほぼ使わない（残存箇所用の控えめグラデーション）
    static let feltGradient = LinearGradient(
        colors: [Color(red: 0.145, green: 0.157, blue: 0.184), ink],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

/// 白地＋うっすら方眼グリッドの背景。
struct PaperBackground: View {
    var spacing: CGFloat = 26
    var body: some View {
        ZStack {
            Theme.bg
            Canvas { ctx, size in
                var path = Path()
                var x: CGFloat = 0
                while x <= size.width {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                    x += spacing
                }
                var y: CGFloat = 0
                while y <= size.height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    y += spacing
                }
                ctx.stroke(path, with: .color(Theme.grid), lineWidth: 0.5)
            }
        }
        .ignoresSafeArea()
    }
}

/// クリーンなカード装飾（白＋細い境界線、影なし）。
struct CardBackground: ViewModifier {
    var cornerRadius: CGFloat = 14
    func body(content: Content) -> some View {
        content
            .background(Theme.card, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Theme.line, lineWidth: 1)
            )
    }
}

extension View {
    /// 白カード＋細枠（影なし）
    func cardStyle(cornerRadius: CGFloat = 14) -> some View {
        modifier(CardBackground(cornerRadius: cornerRadius))
    }
}
