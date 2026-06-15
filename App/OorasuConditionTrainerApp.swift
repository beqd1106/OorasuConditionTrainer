import SwiftUI

@main
struct OorasuConditionTrainerApp: App {
    @StateObject private var statsViewModel = StatsViewModel()
    @StateObject private var settings = SettingsStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(statsViewModel)
                .environmentObject(settings)
        }
    }
}

/// ナビゲーションの遷移先。
enum Route: Hashable {
    case modeSelect
    case quiz(QuestionMode, Difficulty)
    case review
    case calculator
    case settings
    case howToPlay
}

/// アプリのルート。NavigationStack を1つだけ持ち、遷移先をここで集中管理する。
struct RootView: View {
    var body: some View {
        NavigationStack {
            HomeView()
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .modeSelect:
                        ModeSelectView()
                    case .quiz(let mode, let difficulty):
                        QuizContainerView(mode: mode, difficulty: difficulty)
                    case .review:
                        QuizContainerView(reviewQuestions: WeakQuestionStore.shared.load())
                    case .calculator:
                        CalculatorView()
                    case .settings:
                        SettingsView()
                    case .howToPlay:
                        HowToPlayView()
                    }
                }
        }
        .tint(Theme.felt)
    }
}

/// 10問セッションの入れ物。フェーズに応じて出題／解説／結果を切り替える。
struct QuizContainerView: View {
    @StateObject private var viewModel: QuizViewModel
    @EnvironmentObject private var statsViewModel: StatsViewModel
    @Environment(\.dismiss) private var dismiss

    init(mode: QuestionMode, difficulty: Difficulty) {
        _viewModel = StateObject(wrappedValue: QuizViewModel(mode: mode, difficulty: difficulty))
    }

    init(reviewQuestions: [Question]) {
        _viewModel = StateObject(wrappedValue: QuizViewModel(reviewQuestions: reviewQuestions))
    }

    var body: some View {
        Group {
            switch viewModel.phase {
            case .question:
                QuestionView(viewModel: viewModel)
            case .explanation:
                ExplanationView(viewModel: viewModel)
            case .finished:
                ResultView(viewModel: viewModel, onExit: { dismiss() })
            }
        }
        .navigationTitle(viewModel.sessionTitle)
        .navigationBarTitleDisplayMode(.inline)
        // 全問終了時に1回だけ成績を保存
        .onChange(of: viewModel.phase) { _, newPhase in
            if newPhase == .finished {
                statsViewModel.record(viewModel.results)
            }
        }
    }
}
