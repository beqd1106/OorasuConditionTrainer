import SwiftUI

/// 選択肢ボタンの表示状態。
enum ChoiceState {
    case idle    // 回答前（タップ可能）
    case correct // 正解として強調
    case wrong   // 自分が選んだ不正解
    case dimmed  // 解説時のその他
}

/// 大きな4択ボタン。片手でも押しやすいサイズにしている。
struct ChoiceButtonView: View {
    let points: Int
    let state: ChoiceState
    let action: () -> Void

    private var background: Color {
        switch state {
        case .idle:    return Theme.card
        case .correct: return Theme.correct
        case .wrong:   return Theme.wrong
        case .dimmed:  return Theme.card
        }
    }

    private var foreground: Color {
        switch state {
        case .correct, .wrong: return .white
        case .idle:            return .primary
        case .dimmed:          return .secondary
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
                Text("\(NumberFormatterUtility.scoreString(points))点")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Spacer()
                if let icon {
                    Image(systemName: icon)
                        .font(.title3.weight(.bold))
                }
            }
            .foregroundStyle(foreground)
            .padding(.vertical, 20)
            .padding(.horizontal, 22)
            .frame(maxWidth: .infinity)
            .background(background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(state == .idle ? Theme.felt.opacity(0.25) : .clear, lineWidth: 1.5)
            )
            .opacity(state == .dimmed ? 0.5 : 1)
        }
        .buttonStyle(.plain)
        .disabled(state != .idle)
    }
}
