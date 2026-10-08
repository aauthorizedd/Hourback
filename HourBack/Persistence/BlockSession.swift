import Foundation
import SwiftData

@Model
final class BlockSession {
    @Attribute(.unique) var id: UUID
    var start: Date
    var end: Date?
    var endedByEmergency: Bool

    init(id: UUID = UUID(), start: Date, end: Date? = nil, endedByEmergency: Bool = false) {
        self.id = id
        self.start = start
        self.end = end
        self.endedByEmergency = endedByEmergency
    }
}
