import Foundation

final class AppGroupStore {
    private let defaults: UserDefaults

    init(suite: String = AppConfig.appGroupIdentifier) {
        defaults = UserDefaults(suiteName: suite) ?? .standard
    }

    var isBlocking: Bool {
        defaults.bool(forKey: "blockingOn")
    }

    var sessionID: UUID? {
        guard let raw = defaults.string(forKey: "sessionID") else { return nil }
        return UUID(uuidString: raw)
    }

    var sessionStart: Date? {
        let interval = defaults.double(forKey: "sessionStart")
        guard interval > 0 else { return nil }
        return Date(timeIntervalSince1970: interval)
    }

    func recordBlocking(id: UUID, start: Date) {
        defaults.set(true, forKey: "blockingOn")
        defaults.set(id.uuidString, forKey: "sessionID")
        defaults.set(start.timeIntervalSince1970, forKey: "sessionStart")
    }

    func clearBlocking() {
        defaults.set(false, forKey: "blockingOn")
        defaults.removeObject(forKey: "sessionID")
        defaults.removeObject(forKey: "sessionStart")
    }
}
