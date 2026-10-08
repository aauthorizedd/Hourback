import FamilyControls
import SwiftUI

struct RulesView: View {
    var model: AppModel
    @State private var draft = FamilyActivitySelection()
    @State private var saved = FamilyActivitySelection()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if model.isBlocking {
                lockedList
            } else {
                FamilyActivityPicker(selection: $draft)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                selectionList
                    .frame(maxHeight: 240)
            }
        }
        .background(Color(.systemBackground))
        .navigationTitle("Rules")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            draft = model.selection
            saved = model.selection
        }
        .onChange(of: draft) { _, newValue in
            guard !model.isBlocking else {
                draft = saved
                return
            }
            if newValue.applicationTokens.count > AppConfig.maxBlockedApps {
                draft = saved
                model.alertMessage = "You can block up to 50 apps."
                return
            }
            saved = newValue
            model.saveSelection(newValue)
        }
    }

    private var lockedList: some View {
        HourBackScreen {
            Text("Rules are locked while blocking is on.")
                .font(Typography.body)
            selectionContent
        }
    }

    private var selectionList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                selectionContent
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
    }

    @ViewBuilder
    private var selectionContent: some View {
        if model.selection.applicationTokens.isEmpty && model.selection.categoryTokens.isEmpty {
            Text("No apps selected.")
                .font(Typography.body)
        }
        ForEach(Array(model.selection.applicationTokens), id: \.self) { token in
            Label(token)
                .font(Typography.body)
            Hairline()
        }
        if !model.selection.categoryTokens.isEmpty {
            Text("Categories")
                .font(Typography.small)
                .padding(.top, 8)
            ForEach(Array(model.selection.categoryTokens), id: \.self) { token in
                Label(token)
                    .font(Typography.body)
                Hairline()
            }
        }
    }
}
