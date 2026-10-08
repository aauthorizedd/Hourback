import Foundation
import SwiftData

enum HourBackStore {
    static func makeContainer(inMemory: Bool = false) -> ModelContainer {
        let schema = Schema([BlockSession.self, StoredSelection.self])
        // TODO: iCloud sync (CloudKit private database)
        // When a paid Apple Developer account is available, switch cloudKitDatabase
        // to .private("iCloud.com.aauthorizedd.hourback").
        // Do not sync the emergency-unlock counter or paired tag hashes. Those stay in Keychain.
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: .none
        )
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("HourBack could not open its local store: \(error)")
        }
    }
}
