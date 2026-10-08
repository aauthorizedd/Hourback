import Foundation
import SwiftData

@Model
final class StoredSelection {
    var payload: Data
    var updatedAt: Date

    init(payload: Data, updatedAt: Date) {
        self.payload = payload
        self.updatedAt = updatedAt
    }
}
