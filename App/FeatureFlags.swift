import Foundation

/// 機能フラグ。リリース版で見せる機能を切り替える。
enum FeatureFlags {
    /// AI方針アドバイス（局面情報をサーバー経由でAIに送信する任意機能）。
    /// 1.0.1 は「完全オフライン・データ収集なし」で審査を通すため OFF。
    /// 次バージョンでプライバシー申告を整えて再投入する。
    static let aiAdvice = false
}
