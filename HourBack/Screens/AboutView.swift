import SwiftUI

struct AboutView: View {
    var body: some View {
        HourBackScreen {
            Text(version)
                .font(Typography.body)
        }
        .navigationTitle("About")
    }

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }
}
