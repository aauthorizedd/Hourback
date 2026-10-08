import SwiftUI

struct SettingsView: View {
    var model: AppModel
    @Binding var path: NavigationPath

    var body: some View {
        HourBackScreen {
            VStack(alignment: .leading, spacing: 0) {
                row("Rules · \(model.appCount) apps", route: .rules)
                row("Tags", route: .tags)
                row("Emergency Unlock", route: .emergency)
                row("Account", route: .account)
                row("About", route: .about)
            }
        }
        .navigationTitle("Settings")
    }

    private func row(_ title: String, route: Route) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(title) { path.append(route) }
                .font(Typography.body)
                .foregroundStyle(Color.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 16)
                .buttonStyle(.plain)
            Hairline()
        }
    }
}
