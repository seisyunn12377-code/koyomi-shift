import SwiftUI

@main
struct MetaboCalendarApp: App {
    @StateObject private var store = WorkStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
        }
    }
}
