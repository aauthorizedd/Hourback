import SwiftUI

enum Route: Hashable {
    case activity
    case settings
    case rules
    case tags
    case emergency
    case account
    case about
}

struct RootView: View {
    let tagReader: TagReader
    @Environment(\.modelContext) private var modelContext
    @State private var model: AppModel?

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            if let model {
                AuthorizedFlow(model: model)
            }
        }
        .onAppear {
            if model == nil {
                model = AppModel(tagReader: tagReader, context: modelContext)
            } else {
                model?.refreshAuthorization()
            }
        }
    }
}

private struct AuthorizedFlow: View {
    var model: AppModel
    @State private var path = NavigationPath()

    var body: some View {
        Group {
            if model.authorizationStatus != .approved {
                AuthorizationView(model: model)
            } else {
                NavigationStack(path: $path) {
                    HomeView(model: model, path: $path)
                        .navigationDestination(for: Route.self) { route in
                            destination(route)
                        }
                }
            }
        }
        .task(id: model.isBlocking) {
            await model.trackLiveTotals()
        }
        .alert(
            model.alertMessage ?? "",
            isPresented: Binding(
                get: { model.alertMessage != nil },
                set: { if !$0 { model.alertMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        }
    }

    @ViewBuilder
    private func destination(_ route: Route) -> some View {
        switch route {
        case .activity:
            ActivityView(model: model)
        case .settings:
            SettingsView(model: model, path: $path)
        case .rules:
            RulesView(model: model)
        case .tags:
            TagsView(model: model)
        case .emergency:
            EmergencyUnlockView(model: model)
        case .account:
            AccountView(model: model)
        case .about:
            AboutView()
        }
    }
}
