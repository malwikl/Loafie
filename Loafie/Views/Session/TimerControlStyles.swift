import SwiftUI

struct ExtendMenu: View {
    let step: SessionStep
    let action: (TimeInterval) -> Void

    var body: some View {
        Menu {
            Button("+5 min") { action(5 * 60) }
            Button("+15 min") { action(15 * 60) }
            Button("+30 min") { action(30 * 60) }
            Button("+1 h") { action(60 * 60) }
            if step.isColdStep {
                Button("+2 h") { action(2 * 3600) }
                Button("+4 h") { action(4 * 3600) }
            }
        } label: {
            Image(systemName: "plus.circle")
                .font(.system(size: 22, weight: .bold))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
        }
        .accessibilityLabel("Extend time")
        .modifier(TimerGlassButtonModifier(tint: .crustGold))
    }
}

struct TimerGlassButtonModifier: ViewModifier {
    let tint: Color
    let prominent: Bool

    init(tint: Color, prominent: Bool = false) {
        self.tint = tint
        self.prominent = prominent
    }

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            if prominent {
                content
                    .buttonStyle(.glassProminent)
                    .buttonBorderShape(.capsule)
                    .tint(tint)
            } else {
                content
                    .buttonStyle(.glass)
                    .buttonBorderShape(.capsule)
                    .tint(tint)
            }
        } else {
            content
                .foregroundStyle(tint)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(tint.opacity(0.22), lineWidth: 1)
                }
        }
    }
}
