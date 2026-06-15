import SwiftUI

/// 条件計算機。各家の点数を入力すると、逆転に必要な最低点を即算出する実戦ツール。
struct CalculatorView: View {
    // 席順は東南西北で固定
    private let winds = Wind.allCases

    @State private var scores: [Int] = [33000, 25000, 22000, 20000]
    @State private var userIndex: Int = 1   // 既定は南家
    @FocusState private var focusedSeat: Int?

    private var results: [ScoreCalculator.OvertakeResult] {
        ScoreCalculator.overtakeConditions(scores: scores, userIndex: userIndex)
    }

    private var totalScore: Int { scores.reduce(0, +) }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                intro
                seatInputs
                userPicker
                resultCard
            }
            .padding(20)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("条件計算機")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完了") { focusedSeat = nil }
            }
        }
    }

    // MARK: - 説明

    private var intro: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("各家の点数を入力")
                .font(.headline.weight(.bold))
            Text("自分より上の相手を逆転するのに必要な最低点を、他家ロン／直撃の両方で表示します。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - 点数入力

    private var seatInputs: some View {
        VStack(spacing: 10) {
            ForEach(Array(winds.enumerated()), id: \.offset) { index, wind in
                HStack(spacing: 12) {
                    Text(wind.seatName)
                        .font(.headline.weight(.bold))
                        .frame(width: 44, alignment: .leading)
                    if index == userIndex {
                        Text("あなた")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Theme.felt, in: Capsule())
                    }
                    Spacer(minLength: 0)
                    // ステッパー（±1000）
                    Button { adjust(index, by: -1000) } label: {
                        Image(systemName: "minus.circle.fill")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Theme.accentRed)

                    TextField("0", value: $scores[index], format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .frame(width: 96)
                        .focused($focusedSeat, equals: index)

                    Button { adjust(index, by: 1000) } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Theme.correct)
                }
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(
                    (index == userIndex ? Theme.felt.opacity(0.10) : Theme.card),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )
            }

            HStack {
                Image(systemName: totalScore == 100_000 ? "checkmark.circle.fill" : "exclamationmark.circle")
                    .foregroundStyle(totalScore == 100_000 ? Theme.correct : Theme.gold)
                Text("合計 \(NumberFormatterUtility.scoreString(totalScore))点")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if totalScore != 100_000 {
                    Text("通常は100,000点")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 2)
        }
    }

    // MARK: - 自分の席

    private var userPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("自分の席")
                .font(.subheadline.weight(.bold))
            Picker("自分の席", selection: $userIndex) {
                ForEach(Array(winds.enumerated()), id: \.offset) { index, wind in
                    Text(wind.seatName).tag(index)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - 結果

    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("逆転に必要な点", systemImage: "function")
                .font(.headline.weight(.bold))
                .foregroundStyle(Theme.felt)

            if results.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "crown.fill").foregroundStyle(Theme.gold)
                    Text("あなたは現在トップです。守り切りましょう。")
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(results, id: \.targetScore) { r in
                    resultRow(r)
                }
                Text("※ 符・翻は子（親以外）の手の目安です。")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func resultRow(_ r: ScoreCalculator.OvertakeResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(r.targetRank)位（\(NumberFormatterUtility.scoreString(r.targetScore))）を抜く")
                    .font(.subheadline.weight(.bold))
                Spacer()
                Text("差 \(NumberFormatterUtility.scoreString(r.gap))")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 10) {
                conditionChip(title: "他家ロン", value: r.ronOther, accent: Theme.felt)
                conditionChip(title: "直撃", value: r.ronDirect, accent: Theme.accentRed)
            }
        }
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) { Divider() }
    }

    private func conditionChip(title: String, value: Int?, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(accent)
            if let value {
                Text("\(NumberFormatterUtility.scoreString(value))点")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                if let hint = HanFuReference.hint(forRon: value) {
                    Text(hint)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("満貫超")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - 操作

    private func adjust(_ index: Int, by delta: Int) {
        scores[index] = max(0, scores[index] + delta)
    }
}
