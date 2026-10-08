import SwiftData
import SwiftUI

@main
struct HourBackApp: App {
    private let container: ModelContainer

    init() {
        Typography.apply()
        container = HourBackStore.makeContainer()
    }

    var body: some Scene {
        WindowGroup {
            RootView(tagReader: CoreNFCTagReader())
                .tint(.primary)
        }
        .modelContainer(container)
    }
}
