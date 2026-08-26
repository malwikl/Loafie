import SwiftUI

struct NoSessionView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "bread.slices.fill")
                .font(.largeTitle)
                .foregroundStyle(Color(red: 0.831, green: 0.647, blue: 0.455))
            Text("No bake in progress")
                .font(.headline)
            Text("Choose a bake plan on your iPhone.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
