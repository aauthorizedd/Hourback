import FamilyControls
import ManagedSettings

@MainActor
final class BlockingManager {
    private let store = ManagedSettingsStore()

    func apply(_ selection: FamilyActivitySelection) {
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        if selection.categoryTokens.isEmpty {
            store.shield.applicationCategories = nil
        } else {
            store.shield.applicationCategories = .specific(selection.categoryTokens, except: Set<ApplicationToken>())
        }
    }

    func clear() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
    }
}
