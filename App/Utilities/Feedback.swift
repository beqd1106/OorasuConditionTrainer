import UIKit
import AudioToolbox

/// 正誤時の効果音・触覚フィードバック。設定でON/OFFできる。
/// 効果音はシステムサウンドを使うため、音声ファイルの同梱は不要。
enum Feedback {
    /// 正解／不正解のフィードバックを再生する。
    /// - Parameters:
    ///   - correct: 正解なら true
    ///   - sound: 効果音を鳴らすか
    ///   - haptics: 振動（触覚）を出すか
    @MainActor
    static func play(correct: Bool, sound: Bool, haptics: Bool) {
        if haptics {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(correct ? .success : .error)
        }
        if sound {
            // システムサウンドID（正解=軽い確定音、不正解=低めのエラー音）
            AudioServicesPlaySystemSound(correct ? 1057 : 1053)
        }
    }
}
