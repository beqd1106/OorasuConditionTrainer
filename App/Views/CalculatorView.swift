import SwiftUI

/// 条件計算機。各家の点数・和了種別・親子・本場・供託を入力すると、
/// 逆転に必要な最低手を即算出する実戦ツール。
struct CalculatorView: View {
    private let winds = Wind.allCases

    @State private var scores: [Int] = [33000, 25000, 22000, 20000]
    @State private var userIndex: Int = 1     // 既定は南家
    @State private var dealerIndex: Int = 0    // 既定は東家が親
    @State private var winType: WinType = .ron
    @State private var honba: Int = 0
    @State private var perHonbaMode: PerHonbaMode = .standard
    @State private var customPerHonba: Int = 300
    @State private var sticks: Int = 0
    @FocusState private var focusedSeat: Int?

    private enum PerHonbaMode: String, CaseIterable, Identifiable {
        case standard, big, custom
        var id: String { rawValue }
        var title: String {
            switch self {
            case .standard: return "300"
            case .big:      return "1500"
            case .custom:   return "自由"
            }
        }
    }

    private var perHonba: Int {
        switch perHonbaMode {
        case .standard: return 300
        case .big:      return 1500
        case .custom:   return max(0, customPerHonba)
        }
    }

    private var situation: ScoringEngine.Situation {
        ScoringEngine.Situation(
            scores: scores, dealerIndex: dealerIndex, userIndex: userIndex,
            winType: winType, honba: honba, perHonba: perHonba, sticks: sticks
        )
    }

    private var requirements: [ScoringEngine.Requirement] {
        ScoringEngine.requirements(for: situation)
    }

    private var userIsDealer: Bool { userIndex == dealerIndex }
    private var totalScore: Int { scores.reduce(0, +) }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                seatInputs
                conditionControls
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

    // MARK: - 点数入力

    private var seatInputs: some View {
        VStack(spacing: 10) {
            ForEach(Array(winds.enumerated()), id: \.offset) { index, wind in
                HStack(spacing: 10) {
                    Text(wind.seatName)
                        .font(.headline.weight(.bold))
                        .frame(width: 40, alignment: .leading)
                    if index == dealerIndex {
                        badge("親", color: Theme.gold)
                    }
                    if index == userIndex {
                        badge("あなた", color: Theme.felt)
                    }
                    Spacer(minLength: 0)
                    Button { adjust(index, by: -1000) } label: {
                        Image(systemName: "minus.circle.fill")
                    }
                    .buttonStyle(.plain).foregroundStyle(Theme.accentRed)

                    TextField("0", value: $scores[index], format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .frame(width: 88)
                        .focused($focusedSeat, equals: index)

                    Button { adjust(index, by: 1000) } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .buttonStyle(.plain).foregroundStyle(Theme.correct)
                }
                .padding(.horizontal, 12).padding(.vertical, 9)
                .background(
                    (index == userIndex ? Theme.felt.opacity(0.10) : Theme.card),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )
            }
            HStack {
                Image(systemName: totalScore == 100_000 ? "checkmark.circle.fill" : "exclamationmark.circle")
                    .foregroundStyle(totalScore == 100_000 ? Theme.correct : Theme.gold)
                Text("合計 \(NumberFormatterUtility.scoreString(totalScore))点")
                    .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                Spacer()
            }
        }
    }

    // MARK: - 条件（席・和了種別・本場・供託）

    private var conditionControls: some View {
        VStack(spacing: 14) {
            labeledPicker("自分の席", selection: $userIndex) {
                ForEach(Array(winds.enumerated()), id: \.offset) { i, w in Text(w.seatName).tag(i) }
            }
            labeledPicker("親（東家）", selection: $dealerIndex) {
                ForEach(Array(winds.enumerated()), id: \.offset) { i, w in Text(w.seatName).tag(i) }
            }
            labeledPicker("和了", selection: $winType) {
                ForEach(WinType.allCases) { t in Text(t.title).tag(t) }
            }

            // 本場
            HStack {
                Text("本場").font(.subheadline.weight(.bold)).frame(width: 64, alignment: .leading)
                stepper(value: $honba, range: 0...20, suffix: "本場")
            }
            HStack {
                Text("1本場").font(.subheadline.weight(.bold)).frame(width: 64, alignment: .leading)
                Picker("1本場", selection: $perHonbaMode) {
                    ForEach(PerHonbaMode.allCases) { m in Text(m.title).tag(m) }
                }
                .pickerStyle(.segmented)
                if perHonbaMode == .custom {
                    TextField("点", value: $customPerHonba, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 70)
                        .font(.subheadline.weight(.bold))
                        .focused($focusedSeat, equals: 99)
                }
            }
            // 供託
            HStack {
                Text("供託").font(.subheadline.weight(.bold)).frame(width: 64, alignment: .leading)
                stepper(value: $sticks, range: 0...10, suffix: "本(各1000)")
            }
        }
        .padding(16)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - 結果

    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("逆転に必要な手（\(winType.title)）", systemImage: "function")
                .font(.headline.weight(.bold)).foregroundStyle(Theme.felt)

            if requirements.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "crown.fill").foregroundStyle(Theme.gold)
                    Text("あなたは現在トップです。守り切りましょう。").font(.subheadline)
                }
            } else {
                ForEach(requirements, id: \.targetScore) { r in
                    resultRow(r)
                }
                Text("※ 親 \(winds[dealerIndex].seatName)・本場 \(honba)（1本場\(perHonba)）・供託 \(sticks)本 を反映。符翻は\(userIsDealer ? "親" : "子")の目安。")
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func resultRow(_ r: ScoringEngine.Requirement) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(r.targetRank)位（\(NumberFormatterUtility.scoreString(r.targetScore))）を抜く")
                    .font(.subheadline.weight(.bold))
                Spacer()
                Text("差 \(NumberFormatterUtility.scoreString(r.gap))")
                    .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            }
            HStack(spacing: 10) {
                if winType == .ron {
                    conditionChip(title: "他家ロン", value: r.ronOther, accent: Theme.felt, tsumo: false)
                    conditionChip(title: "直撃", value: r.ronDirect, accent: Theme.accentRed, tsumo: false)
                } else {
                    conditionChip(title: "ツモ", value: r.tsumo, accent: Theme.felt, tsumo: true)
                }
            }
        }
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) { Divider() }
    }

    private func conditionChip(title: String, value: Int?, accent: Color, tsumo: Bool) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption2.weight(.bold)).foregroundStyle(accent)
            if let value {
                Text("\(NumberFormatterUtility.scoreString(value))点")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                if tsumo {
                    Text(HanFuReference.tsumoSplitNote(total: value, isDealer: userIsDealer))
                        .font(.caption2).foregroundStyle(.secondary)
                } else if let hint = HanFuReference.hint(forRon: value, isDealer: userIsDealer) {
                    Text(hint).font(.caption2).foregroundStyle(.secondary)
                }
            } else {
                Text("役満超").font(.subheadline.weight(.bold)).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - 部品

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.bold)).foregroundStyle(.white)
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(color, in: Capsule())
    }

    private func labeledPicker<Content: View, T: Hashable>(
        _ title: String, selection: Binding<T>, @ViewBuilder content: () -> Content
    ) -> some View {
        HStack {
            Text(title).font(.subheadline.weight(.bold)).frame(width: 80, alignment: .leading)
            Picker(title, selection: selection, content: content)
                .pickerStyle(.segmented)
        }
    }

    private func stepper(value: Binding<Int>, range: ClosedRange<Int>, suffix: String) -> some View {
        HStack(spacing: 12) {
            Button { value.wrappedValue = max(range.lowerBound, value.wrappedValue - 1) } label: {
                Image(systemName: "minus.circle.fill")
            }.buttonStyle(.plain).foregroundStyle(Theme.accentRed)
            Text("\(value.wrappedValue) \(suffix)")
                .font(.subheadline.weight(.bold)).frame(minWidth: 90)
            Button { value.wrappedValue = min(range.upperBound, value.wrappedValue + 1) } label: {
                Image(systemName: "plus.circle.fill")
            }.buttonStyle(.plain).foregroundStyle(Theme.correct)
            Spacer()
        }
    }

    private func adjust(_ index: Int, by delta: Int) {
        scores[index] = max(0, scores[index] + delta)
    }
}
