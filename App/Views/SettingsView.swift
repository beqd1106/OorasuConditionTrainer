import SwiftUI

/// 設定画面。効果音・振動・既定難易度の切替、成績・苦手リストのリセット。
struct SettingsView: View {
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var statsViewModel: StatsViewModel
    @EnvironmentObject private var usage: UsageLimitManager

    @State private var showResetStatsAlert = false
    @State private var showClearWeakAlert = false
    @State private var weakCount = 0

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    var body: some View {
        Form {
            Section("フィードバック") {
                Toggle(isOn: $settings.soundEnabled) {
                    Label("効果音", systemImage: "speaker.wave.2.fill")
                }
                Toggle(isOn: $settings.hapticsEnabled) {
                    Label("振動（触覚）", systemImage: "iphone.radiowaves.left.and.right")
                }
            }

            if FeatureFlags.aiAdvice {
                Section {
                    Toggle(isOn: $settings.aiEnabled) {
                        Label("AI解説", systemImage: "sparkles")
                    }
                    LabeledContent("今日の利用", value: "\(usage.todayCount) / \(usage.dailyLimit) 回")
                    LabeledContent("今月の利用", value: "\(usage.monthCount) 回")
                } header: {
                    Text("AI解説")
                } footer: {
                    Text("計算機で「AIに解説してもらう」を押した時だけ呼び出します（同じ局面はキャッシュ）。1日\(usage.dailyLimit)回まで。取得できない時は無料の簡易解説に切り替わります。")
                }
            }

            Section("出題") {
                Picker(selection: $settings.defaultDifficulty) {
                    ForEach(Difficulty.allCases) { d in
                        Text(d.title).tag(d)
                    }
                } label: {
                    Label("既定の難易度", systemImage: "slider.horizontal.3")
                }
            }

            Section("データ") {
                Button(role: .destructive) {
                    showResetStatsAlert = true
                } label: {
                    Label("通算成績をリセット", systemImage: "trash")
                }
                Button(role: .destructive) {
                    showClearWeakAlert = true
                } label: {
                    Label("苦手リストを削除（\(weakCount)問）", systemImage: "xmark.bin")
                }
                .disabled(weakCount == 0)
            }

            Section {
                LabeledContent("バージョン", value: appVersion)
            } footer: {
                Text("このアプリは通信・ログイン不要で、データは端末内にのみ保存されます。")
            }
        }
        .navigationTitle("設定")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { weakCount = WeakQuestionStore.shared.count }
        .alert("通算成績をリセットしますか？", isPresented: $showResetStatsAlert) {
            Button("キャンセル", role: .cancel) {}
            Button("リセット", role: .destructive) { statsViewModel.reset() }
        } message: {
            Text("正答率・平均回答時間・累計回答数が消去されます。")
        }
        .alert("苦手リストを削除しますか？", isPresented: $showClearWeakAlert) {
            Button("キャンセル", role: .cancel) {}
            Button("削除", role: .destructive) {
                WeakQuestionStore.shared.clear()
                weakCount = 0
            }
        }
    }
}
