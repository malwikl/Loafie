import SwiftUI

struct ContentView: View {
    @StateObject private var model = WatchSessionModel()

    var body: some View {
        Group {
            if let snapshot = model.snapshot {
                WatchSessionView(snapshot: snapshot, model: model)
            } else {
                NoSessionView()
            }
        }
        .onAppear { model.activate() }
    }
}
