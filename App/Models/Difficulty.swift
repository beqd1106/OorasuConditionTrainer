import SwiftUI

/// 難易度4段階。
/// 出題の「選択肢の近さ」と「点差の際どさ（トラップ性）」を制御する。
enum Difficulty: String, Codable, CaseIterable, Identifiable {
    case easy   // 簡単
    case normal // 普通
    case hard   // 難しい
    case oni    // 鬼

    var id: String { rawValue }

    var title: String {
        switch self {
        case .easy:   return "簡単"
        case .normal: return "普通"
        case .hard:   return "難しい"
        case .oni:    return "鬼"
        }
    }

    /// ひとことの難易度説明
    var caption: String {
        switch self {
        case .easy:   return "選択肢に差があり選びやすい"
        case .normal: return "標準的な近さの4択"
        case .hard:   return "選択肢が近く際どい点差"
        case .oni:    return "同点トラップ＆隣接選択肢"
        }
    }

    var systemImage: String {
        switch self {
        case .easy:   return "leaf.fill"
        case .normal: return "circle.grid.2x2.fill"
        case .hard:   return "flame.fill"
        case .oni:    return "bolt.trianglebadge.exclamationmark.fill"
        }
    }

    var accent: Color {
        switch self {
        case .easy:   return Theme.correct
        case .normal: return Theme.felt
        case .hard:   return Theme.gold
        case .oni:    return Theme.accentRed
        }
    }
}
