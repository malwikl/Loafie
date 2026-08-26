import SwiftUI

struct EmptyStateView: View {
    let systemImage: String
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    let actionTitle: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 56))
                .foregroundStyle(Color.crustGold)
            Text(title)
                .font(.title2.weight(.semibold))
            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button(actionTitle, action: action)
                .buttonStyle(LoafiePrimaryButtonStyle())
                .frame(maxWidth: 280)
        }
        .padding(LoafieDesign.screenPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.flourCream)
    }
}
