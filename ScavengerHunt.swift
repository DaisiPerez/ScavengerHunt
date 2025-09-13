import SwiftUI

@main
struct ScavengerHuntApp: App {
    @StateObject private var store = TaskStore()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                TaskListView()
                    .environmentObject(store)
            }
        }
    }
}
