import SwiftUI

/// 条件計算機（1画面・スクロール不要）。
/// 席をタップして選び、万/千/百の位を±で直感的に調整できる。
struct CalculatorView: View {
    private let winds = Wind.allCases

    @State private var scores: [Int] = [33000, 25000, 22000, 20000]
    @State private var userIndex: Int = 1       // 自分（＝編集対象の席）
    @State private var dealerIndex: Int = 0     // 親（東家）
    @State private var winType: WinType = .ron
    @State private var honba: Int = 0
    @State private var perHonbaMode: PerHonbaMode = .standard
    @State private var customPerHonba: Int = 300
    @State private var sticks: Int = 0

    private let commentService: ConditionCommentService = LocalCommentService()
    private let aiService = RemoteAICommentService()

    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var usage: UsageLimitManager
    @State private var aiComment: String?
    @State private var aiSource: String?
    @State private var aiLoading = false
    @State private var aiNote: String?
    @State private var showExplain = false
    @State private var detailReq: ScoringEngine.Requirement?   // 実現率バッジのタップで内訳シート表示

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
    /// 自分の現在の着順（1〜4）。局の見込みの着順補正に使う。
    private var userRank: Int { 1 + scores.filter { $0 > scores[userIndex] }.count }

    /// 局面の識別キー（変化したらAI解説をクリアするのに使う）
    private var situationKey: String {
        "\(scores)-\(userIndex)-\(dealerIndex)-\(winType.rawValue)-\(honba)-\(sticks)-\(perHonba)"
    }

    var body: some View {
        // 通常は1画面に収まる。ラス目など条件が多いときだけスクロールできるようにして、
        // 「解説・方針を見る」ボタンが画面外に消えないようにする。
        ScrollView {
            VStack(spacing: 10) {
                seatGrid
                placeEditor
                controls
                resultCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 16)
        }
        .scrollBounceBehavior(.basedOnSize)
        .onChange(of: situationKey) { _, _ in
            aiComment = nil; aiSource = nil; aiNote = nil
        }
        .background(PaperBackground())
        .navigationTitle("条件計算機")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showExplain) {
            explainSheet
        }
        .sheet(item: $detailReq) { r in
            FeasibilityDetailView(
                targetRank: r.targetRank,
                gap: r.gap,
                feasibility: feasibility(r),
                requiredHand: primaryHand(r).hand,
                winType: winType,
                isDealer: userIsDealer,
                methodLabel: winType == .ron ? (primaryHand(r).directOnly ? "直撃" : "他家ロン") : "ツモ",
                valueRarityPercent: ProbabilityEstimator.valueRarityPercent(
                    requiredHand: primaryHand(r).hand, isDealer: userIsDealer, winType: winType),
                userRank: userRank
            )
        }
    }

    // MARK: - 席グリッド（2×2・タップで編集対象を選択）

    private var seatGrid: some View {
        let cols = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]
        return LazyVGrid(columns: cols, spacing: 8) {
            ForEach(Array(winds.enumerated()), id: \.offset) { index, wind in
                Button { userIndex = index } label: {
                    seatCell(index: index, wind: wind)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func seatCell(index: Int, wind: Wind) -> some View {
        let selected = index == userIndex
        return VStack(spacing: 4) {
            HStack(spacing: 5) {
                Text(wind.seatName).font(.subheadline.weight(.bold)).foregroundStyle(Theme.ink)
                if index == dealerIndex { miniBadge("親", Theme.accentYellow) }
                if index == userIndex { miniBadge("自分", Theme.accentBlue) }
                Spacer(minLength: 0)
            }
            Text(NumberFormatterUtility.scoreString(scores[index]))
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .monospacedDigit()
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(
            selected ? Theme.accentBlue.opacity(0.08) : Theme.card,
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(selected ? Theme.accentBlue : Theme.line, lineWidth: selected ? 1.6 : 1)
        )
    }

    // MARK: - 桁エディタ（万/千/百）

    private var placeEditor: some View {
        HStack(spacing: 8) {
            Text("\(winds[userIndex].seatName)（自分）")
                .font(.caption.weight(.bold)).foregroundStyle(Theme.felt)
                .frame(width: 78, alignment: .leading)
            placeColumn("万", place: 10000)
            placeColumn("千", place: 1000)
            placeColumn("百", place: 100)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .cardStyle(cornerRadius: 12)
    }

    private func placeColumn(_ label: String, place: Int) -> some View {
        VStack(spacing: 2) {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            Button { bump(userIndex, place: place, up: true) } label: {
                Image(systemName: "chevron.up.circle.fill").font(.title3)
            }
            .buttonStyle(.plain).foregroundStyle(Theme.correct)
            Text("\(digit(scores[userIndex], place: place))")
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .monospacedDigit()
            Button { bump(userIndex, place: place, up: false) } label: {
                Image(systemName: "chevron.down.circle.fill").font(.title3)
            }
            .buttonStyle(.plain).foregroundStyle(Theme.accentRed)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 条件コントロール（コンパクト）

    private var controls: some View {
        VStack(spacing: 8) {
            row("親", picker(selection: $dealerIndex) {
                ForEach(Array(winds.enumerated()), id: \.offset) { i, w in Text(w.seatName).tag(i) }
            })
            row("和了", picker(selection: $winType) {
                ForEach(WinType.allCases) { t in Text(t.title).tag(t) }
            })
            HStack(spacing: 8) {
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
        .cardStyle(cornerRadius: 12)
    }

    // MARK: - 実現可能性（概算）

    /// 表示中の和了種別での「最も実現しやすい手」と直撃限定フラグ
    private func primaryHand(_ r: ScoringEngine.Requirement) -> (hand: Int?, directOnly: Bool) {
        if winType == .ron {
            return (r.ronOther ?? r.ronDirect, r.ronOther == nil && r.ronDirect != nil)
        } else {
            return (r.tsumo, false)
        }
    }

    private func feasibility(_ r: ScoringEngine.Requirement) -> Int {
        let p = primaryHand(r)
        return ProbabilityEstimator.feasibility(.init(
            requiredHand: p.hand, winType: winType, isDealer: userIsDealer,
            isDirectOnly: p.directOnly))
    }

    private func feasibilityColor(_ value: Int) -> Color {
        switch value {
        case 55...:   return Theme.accentBlue
        case 30..<55: return Theme.accentYellow
        default:      return Theme.accentRed
        }
    }

    /// 一番上の目標（最上位）への解説コメント
    private var topComment: String? {
        guard let r = requirements.first else { return nil }
        let p = primaryHand(r)
        let mangan = p.hand.map { ProbabilityEstimator.isManganOrAbove(hand: $0, isDealer: userIsDealer, winType: winType) } ?? true
        let hane = p.hand.map { ProbabilityEstimator.isHaneOrAbove(hand: $0, isDealer: userIsDealer, winType: winType) } ?? true
        return commentService.comment(for: .init(
            targetLabel: "\(r.targetRank)位", feasibility: feasibility(r),
            requiredHand: p.hand, winType: winType, isDealer: userIsDealer,
            isDirectOnly: p.directOnly, manganOrAbove: mangan, haneOrAbove: hane,
            valueRarityPercent: ProbabilityEstimator.valueRarityPercent(
                requiredHand: p.hand, isDealer: userIsDealer, winType: winType)))
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
                if topComment != nil {
                    Button { showExplain = true } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "lightbulb.fill").font(.caption)
                            Text("解説・方針を見る").font(.caption.weight(.bold))
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption2).opacity(0.5)
                        }
                        .foregroundStyle(Theme.accentBlue)
                        .padding(.vertical, 8).padding(.horizontal, 10)
                        .frame(maxWidth: .infinity)
                        .background(Theme.accentBlue.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 2)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(cornerRadius: 12)
    }

    // MARK: - 解説シート（メインを圧迫しないよう別画面に）

    private var explainSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if let topComment {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("解説", systemImage: "lightbulb.fill")
                                .font(.headline.weight(.bold)).foregroundStyle(Theme.felt)
                            Text(topComment)
                                .font(.callout).foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("※ 実現率は概算（一般的な対局データの和了率・打点別の出現率に基づく「この手1回」での統計推定）")
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                        .padding(14).frame(maxWidth: .infinity, alignment: .leading).cardStyle(cornerRadius: 14)
                    }
                    aiSection
                    Spacer(minLength: 0)
                }
                .padding(16)
            }
            .background(PaperBackground())
            .navigationTitle("解説・方針")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") { showExplain = false }
                }
            }
        }
    }

    private func resultRow(_ r: ScoringEngine.Requirement) -> some View {
        let fz = feasibility(r)
        return HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(r.targetRank)位を抜く").font(.caption.weight(.bold))
                Text("差\(NumberFormatterUtility.scoreString(r.gap))").font(.caption2).foregroundStyle(.secondary)
                Button { detailReq = r } label: {
                    HStack(spacing: 3) {
                        Text("実現 \(fz)%").font(.caption2.weight(.bold))
                        Image(systemName: "chart.bar.fill").font(.system(size: 8))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(feasibilityColor(fz), in: Capsule())
                }
                .buttonStyle(.plain)
            }
            .frame(width: 80, alignment: .leading)
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
                if tsumo {
                    // ツモは「3000-6000」「6000オール」のような分配表記（大きく見やすく）
                    Text(HanFuReference.tsumoSplitCompact(total: value, isDealer: userIsDealer))
                        .font(.system(size: 27, weight: .heavy, design: .rounded)).monospacedDigit()
                        .lineLimit(1).minimumScaleFactor(0.5)
                    Text(HanFuReference.tsumoName(total: value, isDealer: userIsDealer))
                        .font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
                        .lineLimit(1).minimumScaleFactor(0.7)
                } else {
                    Text("\(NumberFormatterUtility.scoreString(value))点")
                        .font(.headline.weight(.bold)).monospacedDigit()
                    Text(HanFuReference.hint(forRon: value, isDealer: userIsDealer) ?? "")
                        .font(.caption2).foregroundStyle(.secondary).lineLimit(1).minimumScaleFactor(0.7)
                }
            } else {
                Text("役満超").font(.subheadline.weight(.bold)).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    // MARK: - AI解説（オンデマンド）

    private var aiSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("AI方針アドバイス（実験的）", systemImage: "sparkles")
                    .font(.subheadline.weight(.bold)).foregroundStyle(Theme.accentBlue)
                Spacer()
                if settings.aiEnabled {
                    Text("本日 残り\(usage.remainingToday)回")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }

            if !settings.aiEnabled {
                Text("設定で「AI解説」をONにすると、いまの局面と条件をもとに、この局の打ち方の方針をAIがアドバイスします（実験的）。正確な数値・条件は上の結果が基準です。")
                    .font(.caption).foregroundStyle(.secondary)
            } else if let aiComment {
                Text(aiComment)
                    .font(.callout).foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("※ AIによる方針アドバイス（実験的）。正確な数値・条件は上の結果をご確認ください。")
                    .font(.caption2).foregroundStyle(.secondary)
                HStack {
                    Text(sourceLabel(aiSource))
                        .font(.caption2).foregroundStyle(.secondary)
                    Spacer()
                    Button { Task { await fetchAI() } } label: {
                        Label("もう一度", systemImage: "arrow.clockwise").font(.caption)
                    }
                    .disabled(aiLoading || !usage.canUseToday)
                }
            } else {
                Button { Task { await fetchAI() } } label: {
                    HStack(spacing: 8) {
                        if aiLoading { ProgressView().tint(.white) }
                        Text(aiLoading ? "生成中…" : "AIに方針を相談する").font(.subheadline.weight(.bold))
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent).tint(Theme.accentBlue)
                .disabled(aiLoading || !usage.canUseToday)
                if !usage.canUseToday {
                    Text("本日のAI解説の利用上限に達しました。計算は引き続き使えます。")
                        .font(.caption2).foregroundStyle(Theme.accentRed)
                }
            }
            if let aiNote {
                Text(aiNote).font(.caption2).foregroundStyle(Theme.accentRed)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(cornerRadius: 12)
    }

    private func sourceLabel(_ s: String?) -> String {
        switch s {
        case "gemini":      return "Gemini による解説（目安）"
        case "workers-ai":  return "AI による解説（目安）"
        case "local":       return "簡易解説（オフライン）"
        default:            return "AI解説（目安）"
        }
    }

    @MainActor
    private func fetchAI() async {
        guard settings.aiEnabled, usage.canUseToday else { return }
        // 局面全体の確定ファクト＋アプリの方針をまとめて渡し、打ち方の方針を具体化させる。
        // 数値はアプリ側で確定済み。AIには解釈・方針づけ（押し引き・狙う形・警戒点）を任せる。
        guard let local = topComment, !local.isEmpty else { return }
        let facts = buildFacts()
            + "\n\n【アプリの方針（数値は確定済み。これを基準に外れないこと）】\n" + local
            + "\n\n上記の局面と条件をふまえ、この局の打ち方の方針を具体的に助言してください。"
            + "（狙う打点・役、押し引き、対象者への直撃を狙うか、警戒すべき相手など。数値は変えないこと）"
        aiLoading = true; aiNote = nil
        defer { aiLoading = false }
        do {
            let r = try await aiService.comment(facts: facts)
            aiComment = r.text
            aiSource = r.source
            usage.record()
        } catch {
            // 取得失敗 → ローカル方針にフォールバック
            aiComment = local
            aiSource = "local"
            aiNote = "AI方針を取得できませんでした。アプリの方針を表示しています。"
        }
    }

    /// AIに渡す確定済みファクト（数値はアプリ側で計算済み）
    private func buildFacts() -> String {
        var lines: [String] = []
        lines.append("局面: 本場\(honba) 供託\(sticks)本 和了:\(winType.title)")
        let seats = winds.enumerated().map { i, w in
            "\(w.seatName)\(i == dealerIndex ? "(親)" : "")\(i == userIndex ? "[自分]" : "") \(scores[i])"
        }.joined(separator: " / ")
        lines.append("点数: " + seats)
        lines.append("自分は\(userIsDealer ? "親" : "子")。")
        lines.append("逆転条件:")
        for r in requirements {
            let f = feasibility(r)
            if winType == .ron {
                lines.append("・\(r.targetRank)位(\(r.targetScore))を抜く 差\(r.gap) / 他家ロン\(factLabel(r.ronOther, tsumo: false)) / 直撃\(factLabel(r.ronDirect, tsumo: false)) / 実現率\(f)%")
            } else {
                lines.append("・\(r.targetRank)位(\(r.targetScore))を抜く 差\(r.gap) / ツモ\(factLabel(r.tsumo, tsumo: true)) / 実現率\(f)%")
            }
        }
        return lines.joined(separator: "\n")
    }

    private func factLabel(_ value: Int?, tsumo: Bool) -> String {
        guard let value else { return "役満超" }
        if tsumo { return HanFuReference.tsumoDisplay(total: value, isDealer: userIsDealer) }
        return "\(value)点"
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

    // 桁表示は絶対値（符号は席セルの数値で表示）
    private func digit(_ score: Int, place: Int) -> Int { (abs(score) / place) % 10 }

    private func bump(_ index: Int, place: Int, up: Bool) {
        let delta = up ? place : -place
        // マイナス（トビ）も入力可能
        scores[index] = min(999_900, max(-99_900, scores[index] + delta))
    }
}

// .sheet(item:) で使うため。対象スコアは表示中の条件内で一意（同点は集約済み）。
extension ScoringEngine.Requirement: Identifiable {
    var id: Int { targetScore }
}
