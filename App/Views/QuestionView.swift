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
                                 displayText: ChoiceLabel.main(points: points, question: question),
                                 subText: ChoiceLabel.sub(points: points, question: question)) {
                    viewModel.submit(points)
                }
            }
        }
    }
}

/// 選択肢/正解の表示テキスト。
/// ツモはメイン＝分配（大きく）／サブ＝役名（小さく）に分け、可読性を確保する。
enum ChoiceLabel {
    private static let namedRanks: Set<String> = ["満貫", "跳満", "倍満", "三倍満", "役満"]
    private static func isTsumo(_ q: Question) -> Bool { q.winType == .tsumo }
    private static func dealer(_ q: Question) -> Bool { q.user.wind == q.dealerWind }

    /// ボタンのメイン表示（ロンは nil＝「◯◯点」、ツモは分配）
    static func main(points: Int, question: Question) -> String? {
        guard isTsumo(question) else { return nil }
        return HanFuReference.tsumoSplitCompact(total: points, isDealer: dealer(question))
    }

    /// ボタンのサブ表示（満貫以上の役名のみ。なければ nil）
    static func sub(points: Int, question: Question) -> String? {
        guard isTsumo(question) else { return nil }
        let name = HanFuReference.tsumoName(total: points, isDealer: dealer(question))
        return namedRanks.contains(name) ? name : nil
    }

    /// バナー・解説用の1行表記（分配＋役名 or 「◯◯点」）
    static func full(points: Int, question: Question) -> String {
        isTsumo(question)
            ? HanFuReference.tsumoDisplay(total: points, isDealer: dealer(question))
            : "\(NumberFormatterUtility.scoreString(points))点"
    }
}
