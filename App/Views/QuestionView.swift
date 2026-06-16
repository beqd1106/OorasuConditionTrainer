import SwiftUI

/// 出題画面。局面・問題文・4択・経過時間を表示する。
struct QuestionView: View {
    @ObservedObject var viewModel: QuizViewModel

    var body: some View {
        let question = viewModel.current

        ScrollView {
            VStack(spacing: 20) {
                progressHeader
                ScoreBoardView(question: question)
                questionPrompt(question)
                choices(question)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
        .background(PaperBackground())
        .onAppear { viewModel.startQuestionTimer() }
    }

    // MARK: - 進捗＋経過時間

    private var progressHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Text("第\(viewModel.questionNumber)問 / \(viewModel.total)問")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)
                Spacer()
                // 0.1秒ごとに更新される経過時間
                TimelineView(.periodic(from: .now, by: 0.1)) { context in
                    let elapsed = max(0, context.date.timeIntervalSince(viewModel.questionStart))
                    Label(String(format: "%.1f秒", elapsed), systemImage: "timer")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
            ProgressView(value: Double(viewModel.questionNumber), total: Double(viewModel.total))
                .tint(Theme.felt)
        }
        .padding(.top, 8)
    }

    // MARK: - 問題文

    private func questionPrompt(_ question: Question) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "questionmark.circle.fill")
                .font(.title3.weight(.bold))
                .foregroundStyle(Theme.accentRed)
            Text(question.questionText)
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.gold.opacity(0.14), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - 4択

    private func choices(_ question: Question) -> some View {
        VStack(spacing: 12) {
            ForEach(question.choices, id: \.self) { points in
                ChoiceButtonView(points: points, state: .idle,
                                 displayText: ChoiceLabel.text(points: points, question: question)) {
                    viewModel.submit(points)
                }
            }
        }
    }
}

/// 選択肢/正解の表示テキスト。ツモは分配＋役名、それ以外は「◯◯点」。
enum ChoiceLabel {
    static func text(points: Int, question: Question) -> String? {
        guard question.winType == .tsumo else { return nil }
        let isDealer = question.user.wind == question.dealerWind
        return HanFuReference.tsumoDisplay(total: points, isDealer: isDealer)
    }
}
