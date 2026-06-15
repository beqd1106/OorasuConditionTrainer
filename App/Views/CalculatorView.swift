import SwiftUI

/// 条件計算機（1画面・スクロール不要）。
/// 席をタップして選び、万/千/百の位を±で直感的に調整できる。
struct CalculatorView: View {
    private let winds = Wind.allCases

    @State private var scores: [Int] = [33000, 25000, 22000, 20000]
    @State private var selectedSeat: Int = 1   // 点数編集中の席
    @State private var userIndex: Int = 1       // 自分（南家）
    @State private var dealerIndex: Int = 0     // 親（東家）
    @State private var winType: WinType = .ron
    @State private var honba: Int = 0
    @State private var perHonbaMode: PerHonbaMode = .standard
    @State private var customPerHonba: Int = 300
    @State private var sticks: Int = 0

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
    private var requirements: [ScoringEngine.Requirement] { ScoringEngine.requirements(for: situation) }
    private var userIsDealer: Bool { userIndex == dealerIndex }

    var body: some View {
        VStack(spacing: 10) {
            seatGrid
            placeEditor
            controls
            resultCard
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("条件計算機")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - 席グリッド（2×2・タップで編集対象を選択）

    private var seatGrid: some View {
        let cols = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]
        return LazyVGrid(columns: cols, spacing: 8) {
            ForEach(Array(winds.enumerated()), id: \.offset) { index, wind in
                Button { selectedSeat = index } label: {
                    seatCell(index: index, wind: wind)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func seatCell(index: Int, wind: Wind) -> some View {
        let selected = index == selectedSeat
        return VStack(spacing: 4) {
            HStack(spacing: 5) {
                Text(wind.seatName).font(.subheadline.weight(.bold))
                if index == dealerIndex { miniBadge("親", Theme.gold) }
                if index == userIndex { miniBadge("自分", Theme.felt) }
                Spacer(minLength: 0)
            }
            Text(NumberFormatterUtility.scoreString(scores[index]))
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .monospacedDigit()
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(
            selected ? Theme.felt.opacity(0.12) : Theme.card,
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(selected ? Theme.felt : .clear, lineWidth: 2)
        )
    }

    // MARK: - 桁エディタ（万/千/百）

    private var placeEditor: some View {
        HStack(spacing: 8) {
            Text("\(winds[selectedSeat].seatName)を編集")
                .font(.caption.weight(.bold)).foregroundStyle(Theme.felt)
                .frame(width: 78, alignment: .leading)
            placeColumn("万", place: 10000)
            placeColumn("千", place: 1000)
            placeColumn("百", place: 100)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func placeColumn(_ label: String, place: Int) -> some View {
        VStack(spacing: 2) {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            Button { bump(selectedSeat, place: place, up: true) } label: {
                Image(systemName: "chevron.up.circle.fill").font(.title3)
            }
            .buttonStyle(.plain).foregroundStyle(Theme.correct)
            Text("\(digit(scores[selectedSeat], place: place))")
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .monospacedDigit()
            Button { bump(selectedSeat, place: place, up: false) } label: {
                Image(systemName: "chevron.down.circle.fill").font(.title3)
            }
            .buttonStyle(.plain).foregroundStyle(Theme.accentRed)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 条件コントロール（コンパクト）

    private var controls: some View {
        VStack(spacing: 8) {
            row("自分", picker(selection: $userIndex) {
                ForEach(Array(winds.enumerated()), id: \.offset) { i, w in Text(w.seatName).tag(i) }
            })
            row("親", picker(selection: $dealerIndex) {
                ForEach(Array(winds.enumerated()), id: \.offset) { i, w in Text(w.seatName).tag(i) }
            })
            row("和了", picker(selection: $winType) {
                ForEach(WinType.allCases) { t in Text(t.title).tag(t) }
            })
            HStack(spacing: 10) {
                miniStepper("本場", value: $honba, range: 0...20)
                miniStepper("供託", value: $sticks, range: 0...10)
            }
            row("1本場", AnyView(
                HStack(spacing: 8) {
                    Picker("1本場", selection: $perHonbaMode) {
                        ForEach(PerHonbaMode.allCases) { m in Text(m.title).tag(m) }
                    }.pickerStyle(.segmented)
                    if perHonbaMode == .custom {
                        compactStepper(value: $customPerHonba, step: 100, range: 0...5000)
                    }
                }
            ))
        }
        .padding(12)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - 結果

    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("逆転に必要な手（\(winType.title)）", systemImage: "function")
                .font(.subheadline.weight(.bold)).foregroundStyle(Theme.felt)
            if requirements.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill").foregroundStyle(Theme.gold)
                    Text("あなたは現在トップです").font(.subheadline)
                }
            } else {
                ForEach(requirements, id: \.targetScore) { r in resultRow(r) }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func resultRow(_ r: ScoringEngine.Requirement) -> some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 1) {
                Text("\(r.targetRank)位を抜く").font(.caption.weight(.bold))
                Text("差\(NumberFormatterUtility.scoreString(r.gap))").font(.caption2).foregroundStyle(.secondary)
            }
            .frame(width: 76, alignment: .leading)
            if winType == .ron {
                chip("他家ロン", r.ronOther, Theme.felt, tsumo: false)
                chip("直撃", r.ronDirect, Theme.accentRed, tsumo: false)
            } else {
                chip("ツモ", r.tsumo, Theme.felt, tsumo: true)
            }
        }
        .padding(.vertical, 5)
    }

    private func chip(_ title: String, _ value: Int?, _ accent: Color, tsumo: Bool) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title).font(.caption2.weight(.bold)).foregroundStyle(accent)
            if let value {
                Text("\(NumberFormatterUtility.scoreString(value))").font(.headline.weight(.bold)).monospacedDigit()
                Text(tsumo
                     ? HanFuReference.tsumoSplitNote(total: value, isDealer: userIsDealer)
                     : (HanFuReference.hint(forRon: value, isDealer: userIsDealer) ?? ""))
                    .font(.caption2).foregroundStyle(.secondary).lineLimit(1).minimumScaleFactor(0.7)
            } else {
                Text("役満超").font(.subheadline.weight(.bold)).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    // MARK: - 小部品

    private func miniBadge(_ t: String, _ c: Color) -> some View {
        Text(t).font(.system(size: 9, weight: .bold)).foregroundStyle(.white)
            .padding(.horizontal, 5).padding(.vertical, 2)
            .background(c, in: Capsule())
    }

    private func row(_ label: String, _ content: some View) -> some View {
        HStack(spacing: 10) {
            Text(label).font(.caption.weight(.bold)).frame(width: 48, alignment: .leading)
            content
        }
    }

    private func picker<T: Hashable, C: View>(selection: Binding<T>, @ViewBuilder content: () -> C) -> some View {
        Picker("", selection: selection, content: content).pickerStyle(.segmented)
    }

    private func miniStepper(_ label: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        HStack(spacing: 6) {
            Text(label).font(.caption.weight(.bold))
            Button { value.wrappedValue = max(range.lowerBound, value.wrappedValue - 1) } label: {
                Image(systemName: "minus.circle.fill")
            }.buttonStyle(.plain).foregroundStyle(Theme.accentRed)
            Text("\(value.wrappedValue)").font(.subheadline.weight(.bold)).frame(minWidth: 18)
            Button { value.wrappedValue = min(range.upperBound, value.wrappedValue + 1) } label: {
                Image(systemName: "plus.circle.fill")
            }.buttonStyle(.plain).foregroundStyle(Theme.correct)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
    }

    private func compactStepper(value: Binding<Int>, step: Int, range: ClosedRange<Int>) -> some View {
        HStack(spacing: 6) {
            Button { value.wrappedValue = max(range.lowerBound, value.wrappedValue - step) } label: {
                Image(systemName: "minus.circle.fill")
            }.buttonStyle(.plain).foregroundStyle(Theme.accentRed)
            Text("\(value.wrappedValue)").font(.caption.weight(.bold)).frame(minWidth: 44)
            Button { value.wrappedValue = min(range.upperBound, value.wrappedValue + step) } label: {
                Image(systemName: "plus.circle.fill")
            }.buttonStyle(.plain).foregroundStyle(Theme.correct)
        }
    }

    // MARK: - 桁操作

    private func digit(_ score: Int, place: Int) -> Int { (score / place) % 10 }

    private func bump(_ index: Int, place: Int, up: Bool) {
        let delta = up ? place : -place
        scores[index] = min(99900, max(0, scores[index] + delta))
    }
}
