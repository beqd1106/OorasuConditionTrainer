import SwiftUI

@main
struct OorasuConditionTrainerApp: App {
    @StateObject private var statsViewModel = StatsViewModel()
    @StateObject private var settings = SettingsStore()
    @StateObject private var usage = UsageLimitManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(statsViewModel)
                .environmentObject(settings)
                .environmentObject(usage)
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

/// Route → 画面
struct RouteDestination: View {
    let route: Route
    var body: some View {
        switch route {
        case .modeSelect:                 ModeSelectView()
        case .quiz(let mode, let diff):   QuizContainerView(mode: mode, difficulty: diff)
        case .review:                     QuizContainerView(reviewQuestions: WeakQuestionStore.shared.load())
        case .calculator:                 CalculatorView()
        case .settings:                   SettingsView()
        case .howToPlay:                  HowToPlayView()
        }
    }
}

extension View {
    /// 各 NavigationStack に Route の遷移先を登録する
    func appRoutes() -> some View {
        navigationDestination(for: Route.self) { RouteDestination(route: $0) }
    }
}

/// アプリのルート。ボトムタブで5画面を切り替える。
struct RootView: View {
    var body: some View {
        TabView {
            NavigationStack { HomeView().appRoutes() }
                .tabItem { Label("ホーム", systemImage: "house.fill") }
            NavigationStack { ModeSelectView().appRoutes() }
                .tabItem { Label("練習", systemImage: "square.grid.2x2.fill") }
            NavigationStack { CalculatorView() }
                .tabItem { Label("計算機", systemImage: "function") }
            NavigationStack { StatsView() }
                .tabItem { Label("成績", systemImage: "chart.bar.fill") }
            NavigationStack { SettingsView() }
                .tabItem { Label("設定", systemImage: "gearshape.fill") }
        }
        .tint(Theme.accentBlue)
        .preferredColorScheme(.light)
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
            case .question:    QuestionView(viewModel: viewModel)
            case .explanation: ExplanationView(viewModel: viewModel)
            case .finished:    ResultView(viewModel: viewModel, onExit: { dismiss() })
            }
        }
        .navigationTitle(viewModel.sessionTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)   // 出題中はタブバーを隠す（誤タップ防止・全画面）
        .onChange(of: viewModel.phase) { _, newPhase in
            if newPhase == .finished {
                // 復習はモード混在のためモード別は記録しない（mode=nil）
                statsViewModel.record(viewModel.results, mode: viewModel.isReview ? nil : viewModel.mode)
            }
        }
    }
}
