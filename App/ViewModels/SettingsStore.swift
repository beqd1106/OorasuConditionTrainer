import Foundation

/// アプリ設定（効果音・振動・既定の難易度）。UserDefaults に保存。
@MainActor
final class SettingsStore: ObservableObject {
    private enum Keys {
        static let sound = "setting_sound_enabled"
        static let haptics = "setting_haptics_enabled"
        static let difficulty = "setting_default_difficulty"
        static let aiEnabled = "setting_ai_enabled"
    }

    private let defaults: UserDefaults

    @Published var soundEnabled: Bool {
        didSet { defaults.set(soundEnabled, forKey: Keys.sound) }
    }
    @Published var hapticsEnabled: Bool {
        didSet { defaults.set(hapticsEnabled, forKey: Keys.haptics) }
    }
    @Published var defaultDifficulty: Difficulty {
        didSet { defaults.set(defaultDifficulty.rawValue, forKey: Keys.difficulty) }
    }
    /// AI解説（オンデマンド）を使うか
    @Published var aiEnabled: Bool {
        didSet { defaults.set(aiEnabled, forKey: Keys.aiEnabled) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        // 既定値：効果音・振動 ON、難易度は普通、AI解説 ON
        self.soundEnabled = defaults.object(forKey: Keys.sound) as? Bool ?? true
        self.hapticsEnabled = defaults.object(forKey: Keys.haptics) as? Bool ?? true
        let raw = defaults.string(forKey: Keys.difficulty) ?? Difficulty.normal.rawValue
        self.defaultDifficulty = Difficulty(rawValue: raw) ?? .normal
        self.aiEnabled = defaults.object(forKey: Keys.aiEnabled) as? Bool ?? true
    }
}
