import SwiftData
import SwiftUI

struct HomeView: View {
    var model: AppModel
    @Binding var path: NavigationPath

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                HourBackMark(side: 22)
                Text("HourBack")
                    .font(Typography.wordmark)
            }

            Spacer(minLength: 32)

            VStack(alignment: .leading, spacing: 20) {
                BlockMark(isOn: model.isBlocking)
                Text(model.isBlocking ? "Blocking" : "Not blocking")
                    .font(Typography.body)
                Text("Today · \(StatsCalculator.format(model.stats.today))")
                    .font(Typography.body)
                OutlineButton(title: "Scan tag") {
                    Task { await model.scanToToggle() }
                }
                .padding(.top, 8)
            }

            Spacer(minLength: 32)

            HStack(spacing: 6) {
                Button("Activity") { path.append(Route.activity) }
                Text("·")
                Button("Settings") { path.append(Route.settings) }
            }
            .font(Typography.small)
            .buttonStyle(.plain)
            .foregroundStyle(Color.primary)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview {
    HomePreview()
}

private struct HomePreview: View {
    private let container: ModelContainer
    private let model: AppModel
    @State private var path = NavigationPath()

    init() {
        let container = HourBackStore.makeContainer(inMemory: true)
        let context = container.mainContext
        let start = Date().addingTimeInterval(-3_600)
        context.insert(BlockSession(start: start, end: Date().addingTimeInterval(-600)))
        try? context.save()
        self.container = container
        model = AppModel(
            tagReader: MockTagReader(identifier: Data([0x01, 0x02])),
            secrets: MemorySecretStore(),
            context: context
        )
    }

    var body: some View {
        HomeView(model: model, path: $path)
    }
}
