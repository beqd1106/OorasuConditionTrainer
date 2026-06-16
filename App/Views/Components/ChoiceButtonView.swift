import SwiftUI

/// 選択肢ボタンの表示状態。
enum ChoiceState {
    case idle    // 回答前（タップ可能）
    case correct // 正解として強調
    case wrong   // 自分が選んだ不正解
    case dimmed  // 解説時のその他
}

/// 大きな4択ボタン（白＋細枠ベース、正解=青／不正解=赤のフラット）。
struct ChoiceButtonView: View {
    let points: Int
    let state: ChoiceState
    /// 表示テキスト（nil なら「◯◯点」。ツモは "3000-6000（跳満）" などを渡す）
    var displayText: String? = nil
    let action: () -> Void

    private var accent: Color {
        switch state {
        case .correct: return Theme.accentBlue
        case .wrong:   return Theme.accentRed
        default:       return Theme.line
        }
    }
    private var textColor: Color {
        switch state {
        case .correct: return Theme.accentBlue
        case .wrong:   return Theme.accentRed
        case .idle:    return Theme.ink
        case .dimmed:  return .secondary
        }
    }
    private var fill: Color {
        switch state {
        case .correct: return Theme.accentBlue.opacity(0.08)
        case .wrong:   return Theme.accentRed.opacity(0.08)
        default:       return Theme.card
        }
    }
    private var icon: String? {
        switch state {
        case .correct: return "checkmark.circle.fill"
        case .wrong:   return "xmark.circle.fill"
        default:       return nil
        }
    }

    var body: some View {
        Button(action: action) {
            HStack {
                Text(displayText ?? "\(NumberFormatterUtility.scoreString(points))点")
                    .font(.system(size: displayText == nil ? 24 : 21, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Spacer()
                if let icon {
                    Image(systemName: icon)
                        .font(.title3.weight(.bold))
                }
            }
            .foregroundStyle(textColor)
            .padding(.vertical, 20)
            .padding(.horizontal, 22)
            .frame(maxWidth: .infinity)
            .background(fill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(accent, lineWidth: (state == .idle || state == .dimmed) ? 1 : 1.6)
            )
            .opacity(state == .dimmed ? 0.5 : 1)
        }
        .buttonStyle(.plain)
        .disabled(state != .idle)
    }
}
