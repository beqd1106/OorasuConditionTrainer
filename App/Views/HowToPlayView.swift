import SwiftUI

/// 遊び方とロン条件の考え方を説明する画面（独自表現）。
struct HowToPlayView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                intro

                section(
                    number: 1,
                    title: "このアプリでできること",
                    body: "オーラスや終盤で「あと何点アガれば順位が上がるか」を、クイズ形式で反復練習できます。答えを表示するだけの計算機ではなく、実戦で素早く条件を判断できる力を鍛えるための練習アプリです。"
                )

                section(
                    number: 2,
                    title: "3つの練習モード",
                    body: """
                    ・着順アップ：今より1つ上の順位に上がる最低ロン点を当てます。
                    ・ラス回避：4位から3位へ上がる条件を当てます。
                    ・トップ条件：2位・3位からトップをまくる条件を当てます。
                    """
                )

                section(
                    number: 3,
                    title: "遊び方",
                    body: "局面と順位表を見て、4つの選択肢から「上回るのに必要な最低ロン点」を選びます。回答するとすぐに正誤と解説が出ます。10問解くと正答率・平均回答時間・評価が表示されます。"
                )

                conditionSection
                ruleSection

                Text("※ 本アプリは特定の対局アプリや団体とは関係のない、独自の学習用アプリです。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
            .padding(20)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("遊び方")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("条件判断を、反射で。")
                .font(.title2.weight(.heavy))
                .foregroundStyle(.white)
            Text("「何点必要？」を一瞬で言えるようになるための練習アプリです。")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Theme.feltGradient, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    // 条件の考え方（具体例）
    private var conditionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("ロン条件の考え方", systemImage: "lightbulb.fill")
                .font(.headline.weight(.bold))
                .foregroundStyle(Theme.felt)

            Text("対象者以外からロンすると、増えるのは自分だけです。だから「自分の点数＋ロン点」が相手を上回ればOK。同点は逆転にならないので、ぴったりではなく上回る必要があります。")
                .font(.callout)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 4) {
                Text("例）あなた 31,800点 ／ トップ 34,200点")
                Text("差は 2,400点。")
                Text("31,800 ＋ 2,600 ＝ 34,400 → トップを200点上回る。")
                Text("2,000点では 33,800点で届かない。")
                Text("だから最低条件は 2,600点。")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.gold.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(18)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // 基本ルール
    private var ruleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("このアプリの基本ルール", systemImage: "list.bullet")
                .font(.headline.weight(.bold))
                .foregroundStyle(Theme.felt)
            VStack(alignment: .leading, spacing: 6) {
                bullet("4人麻雀・25,000点持ちのオーラス想定")
                bullet("本場・供託・トビは考慮しません")
                bullet("ウマ・オカは考慮しません")
                bullet("同点の場合は逆転できないものとして扱います")
                bullet("対象者以外からロンする場合の最低点を答えます")
            }
        }
        .padding(18)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "circle.fill")
                .font(.system(size: 6))
                .foregroundStyle(Theme.felt)
                .padding(.top, 6)
            Text(text)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func section(number: Int, title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Text("\(number)")
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(.white)
                    .frame(width: 26, height: 26)
                    .background(Theme.felt, in: Circle())
                Text(title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.primary)
            }
            Text(body)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
