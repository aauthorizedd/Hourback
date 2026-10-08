import SwiftUI
import UIKit

struct AuthorizationView: View {
    var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            HStack(spacing: 10) {
                HourBackMark(side: 22)
                Text("HourBack")
                    .font(Typography.wordmark)
            }
            if model.authorizationStatus == .denied {
                Text("HourBack can't block apps without Screen Time access.")
                    .font(Typography.body)
                OutlineButton(title: "Open Settings") {
                    openSettings()
                }
            } else {
                Text("HourBack needs Screen Time access to block apps.")
                    .font(Typography.body)
                OutlineButton(title: "Continue") {
                    Task { await model.requestScreenTime() }
                }
            }
            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .onAppear { model.refreshAuthorization() }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
