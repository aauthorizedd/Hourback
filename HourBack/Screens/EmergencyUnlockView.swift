import SwiftUI

struct EmergencyUnlockView: View {
    var model: AppModel
    @State private var confirming = false

    var body: some View {
        HourBackScreen {
            if model.emergencyRemaining == 0 {
                if let url = URL(string: "mailto:\(AppConfig.supportEmail)") {
                    Link(destination: url) {
                        Text("No emergency unlocks left. Contact \(AppConfig.supportEmail).")
                            .font(Typography.body)
                            .foregroundStyle(Color.primary)
                    }
                }
            } else {
                Text("\(model.emergencyRemaining) of \(AppConfig.lifetimeEmergencyUnlocks) remaining")
                    .font(Typography.body)
                OutlineButton(title: "Use emergency unlock") {
                    guard model.isBlocking else { return }
                    confirming = true
                }
                if !model.isBlocking {
                    Text("Emergency unlock is available while blocking is on.")
                        .font(Typography.small)
                }
            }
        }
        .navigationTitle("Emergency Unlock")
        .alert(
            "Use an emergency unlock? You have \(model.emergencyRemaining) left. This can't be undone.",
            isPresented: $confirming
        ) {
            Button("Use unlock") { model.useEmergencyUnlock() }
            Button("Cancel", role: .cancel) {}
        }
    }
}
