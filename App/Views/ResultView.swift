import SwiftUI

/// 10問終了後の結果画面。評価ランク付き。
struct ResultView: View {
    @ObservedObject var viewModel: QuizViewModel
    let onExit: () -> Void

    // 評価ランク（今回の正答率で判定）
    private struct Grade {
        let letter: String
        let title: String
        let color: Color
    }

    private var grade: Grade {
        let acc = viewModel.total == 0 ? 0 : Double(viewModel.correctCount) / Double(viewModel.total)
        switch acc {
        case 0.9...:      return Grade(letter: "S", title: "条件計算マスター", color: Theme.gold)
        case 0.7..<0.9:   return Grade(letter: "A", title: "かなり実戦的", color: Theme.correct)
        case 0.5..<0.7:   return Grade(letter: "B", title: "あと少し", color: Theme.felt)
        default:          return Grade(letter: "C", title: "基礎練習しよう", color: Theme.accentRed)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                gradeBadge
                summaryCards
                actions
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 32)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - 評価バッジ

    private var gradeBadge: some View {
        VStack(spacing: 14) {
            Text(grade.letter)
                .font(.system(size: 64, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 120, height: 120)
                .background(grade.color, in: Circle())
                .overlay(Circle().strokeBorder(.white.opacity(0.4), lineWidth: 3))
                .shadow(color: grade.color.opacity(0.4), radius: 12, y: 6)

            Text(grade.title)
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)

            Text("\(viewModel.total)問中 \(viewModel.correctCount)問 正解")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }

    // MARK: - サマリー

    private var summaryCards: some View {
        let acc = viewModel.total == 0 ? 0 : Int((Double(viewModel.correctCount) / Double(viewModel.total) * 100).rounded())
        return HStack(spacing: 12) {
            StatsCardView(value: "\(viewModel.correctCount)/\(viewModel.total)",
                          label: "正解数", systemImage: "checkmark.seal.fill", accent: Theme.correct)
            StatsCardView(value: "\(acc)%",
                          label: "正答率", systemImage: "percent", accent: Theme.felt)
            StatsCardView(value: String(format: "%.1f秒", viewModel.averageResponseSeconds),
                          label: "平均時間", systemImage: "timer", accent: Theme.gold)
        }
    }

    // MARK: - アクション

    private var actions: some View {
        VStack(spacing: 12) {
            PrimaryButton(title: "もう一度練習", systemImage: "arrow.clockwise", background: Theme.felt) {
                viewModel.restart()
            }
            PrimaryButton(title: "ホームに戻る", systemImage: "house.fill", background: Theme.accentRed) {
                onExit()
            }
        }
        .padding(.top, 4)
    }
}
