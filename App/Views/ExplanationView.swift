import SwiftUI

/// 解説画面。正誤判定・選択肢の答え合わせ・解説文・次へボタン。
struct ExplanationView: View {
    @ObservedObject var viewModel: QuizViewModel
    @EnvironmentObject private var settings: SettingsStore

    private var question: Question { viewModel.current }
    private var isCorrect: Bool { viewModel.lastResult?.isCorrect ?? false }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                resultBanner
                choicesReview
                explanationCard
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 110) // 下部ボタンと被らないよう余白
        }
        .background(PaperBackground())
        .safeAreaInset(edge: .bottom) { nextButton }
        .onAppear {
            // 効果音・振動（設定でON/OFF）
            Feedback.play(correct: isCorrect,
                          sound: settings.soundEnabled,
                          haptics: settings.hapticsEnabled)
        }
    }

    // MARK: - 正誤バナー

    private var resultBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 30, weight: .bold))
            VStack(alignment: .leading, spacing: 2) {
                Text(isCorrect ? "正解！" : "不正解")
                    .font(.title2.weight(.heavy))
                Text("正解：\(ChoiceLabel.full(points: question.correctAnswer, question: question))")
                    .font(.subheadline.weight(.semibold))
                    .opacity(0.95)
            }
            Spacer()
        }
        .foregroundStyle(.white)
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(isCorrect ? Theme.correct : Theme.wrong,
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - 選択肢の答え合わせ

    private var choicesReview: some View {
        VStack(spacing: 12) {
            ForEach(question.choices, id: \.self) { points in
                ChoiceButtonView(points: points, state: state(for: points),
                                 displayText: ChoiceLabel.main(points: points, question: question),
                                 subText: ChoiceLabel.sub(points: points, question: question), action: {})
            }
        }
    }

    private func state(for points: Int) -> ChoiceState {
        if points == question.correctAnswer { return .correct }
        if points == viewModel.lastSelected { return .wrong }
        return .dimmed
    }

    // MARK: - 解説文

    private var explanationCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("解説", systemImage: "text.book.closed.fill")
                .font(.headline.weight(.bold))
                .foregroundStyle(Theme.felt)
            Text(question.explanation)
                .font(.callout)
                .foregroundStyle(.primary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(18)
        .cardStyle(cornerRadius: 16)
    }

    // MARK: - 次へ

    private var nextButton: some View {
        PrimaryButton(
            title: viewModel.isLastQuestion ? "結果を見る" : "次の問題へ",
            systemImage: viewModel.isLastQuestion ? "flag.checkered" : "arrow.right",
            background: Theme.felt
        ) {
            viewModel.advance()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.bar)
    }
}
