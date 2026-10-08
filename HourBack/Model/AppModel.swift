import FamilyControls
import Foundation
import SwiftData

@MainActor
@Observable
final class AppModel {
    var isBlocking = false
    var isReadingTag = false
    var selection = FamilyActivitySelection()
    var tagHashes: [String] = []
    var emergencyRemaining = AppConfig.lifetimeEmergencyUnlocks
    var appleUserID: String?
    var displayName: String?
    var authorizationStatus: AuthorizationStatus = .notDetermined
    var alertMessage: String?
    var stats = StatsCalculator.snapshot(sessions: [], now: Date(), calendar: .current)

    var isSignedIn: Bool { appleUserID != nil }
    var appCount: Int { selection.applicationTokens.count }

    private let tagReader: TagReader
    private let secrets: SecretStore
    private let appGroup: AppGroupStore
    private let blocking = BlockingManager()
    private let context: ModelContext

    init(tagReader: TagReader, secrets: SecretStore = KeychainStore(), appGroup: AppGroupStore = AppGroupStore(), context: ModelContext) {
        self.tagReader = tagReader
        self.secrets = secrets
        self.appGroup = appGroup
        self.context = context
        authorizationStatus = AuthorizationCenter.shared.authorizationStatus
        tagHashes = secrets.pairedHashes
        emergencyRemaining = Self.remaining(used: secrets.emergencyUnlocksUsed)
        appleUserID = secrets.appleUserID
        displayName = secrets.displayName
        loadSelection()
        reconcile()
        refreshStats()
    }

    func refreshAuthorization() {
        authorizationStatus = AuthorizationCenter.shared.authorizationStatus
    }

    func requestScreenTime() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
        } catch {
            // Denial is reflected in authorizationStatus below.
        }
        refreshAuthorization()
    }

    func scanToToggle() async {
        guard let hash = await readHash() else { return }
        guard tagHashes.contains(hash) else {
            alertMessage = "This tag isn't paired."
            return
        }
        if isBlocking {
            _ = stopBlocking(emergency: false)
        } else if selection.applicationTokens.isEmpty && selection.categoryTokens.isEmpty {
            alertMessage = "Choose apps to block in Settings → Rules."
        } else {
            startBlocking()
        }
    }

    func pairTag() async {
        guard tagHashes.count < AppConfig.maxPairedTags else {
            alertMessage = "You can pair up to 3 tags."
            return
        }
        guard let hash = await readHash() else { return }
        guard !tagHashes.contains(hash) else {
            alertMessage = "This tag is already paired."
            return
        }
        tagHashes.append(hash)
        secrets.pairedHashes = tagHashes
    }

    func removeTag(hash: String) {
        guard !isBlocking else {
            alertMessage = "Turn blocking off before removing a tag."
            return
        }
        tagHashes.removeAll { $0 == hash }
        secrets.pairedHashes = tagHashes
    }

    func saveSelection(_ newValue: FamilyActivitySelection) {
        guard !isBlocking else { return }
        guard newValue.applicationTokens.count <= AppConfig.maxBlockedApps else { return }
        do {
            let payload = try PropertyListEncoder().encode(newValue)
            let rows = storedSelections()
            if let row = rows.first {
                row.payload = payload
                row.updatedAt = Date()
                for extra in rows.dropFirst() {
                    context.delete(extra)
                }
            } else {
                context.insert(StoredSelection(payload: payload, updatedAt: Date()))
            }
            try context.save()
            selection = newValue
        } catch {
            alertMessage = "Couldn't save these rules."
        }
    }

    func useEmergencyUnlock() {
        guard isBlocking, emergencyRemaining > 0 else { return }
        let previous = secrets.emergencyUnlocksUsed
        secrets.emergencyUnlocksUsed = previous + 1
        emergencyRemaining = Self.remaining(used: secrets.emergencyUnlocksUsed)
        guard stopBlocking(emergency: true) else {
            secrets.emergencyUnlocksUsed = previous
            emergencyRemaining = Self.remaining(used: previous)
            return
        }
    }

    func signIn(userID: String, name: String?) {
        secrets.appleUserID = userID
        appleUserID = userID
        if let name, !name.isEmpty {
            secrets.displayName = name
            displayName = name
        } else {
            displayName = secrets.displayName
        }
    }

    func signOut() {
        secrets.appleUserID = nil
        secrets.displayName = nil
        appleUserID = nil
        displayName = nil
    }

    func trackLiveTotals() async {
        refreshStats()
        guard isBlocking else { return }
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(60))
            if Task.isCancelled { return }
            refreshStats()
        }
    }

    func refreshStats() {
        let spans = allSessions().map { SessionSpan(start: $0.start, end: $0.end) }
        stats = StatsCalculator.snapshot(sessions: spans, now: Date(), calendar: .current)
    }

    private func readHash() async -> String? {
        guard !isReadingTag else { return nil }
        isReadingTag = true
        defer { isReadingTag = false }
        do {
            let identifier = try await tagReader.readIdentifier(prompt: AppConfig.scanPrompt)
            return TagHash.sha256Hex(identifier)
        } catch TagReadError.cancelled {
            return nil
        } catch TagReadError.unavailable {
            alertMessage = "NFC tag reading needs an iPhone."
            return nil
        } catch {
            alertMessage = "Couldn't read that tag."
            return nil
        }
    }

    private func startBlocking() {
        let session = BlockSession(start: Date())
        context.insert(session)
        do {
            try context.save()
        } catch {
            context.delete(session)
            alertMessage = "Couldn't start blocking."
            return
        }
        appGroup.recordBlocking(id: session.id, start: session.start)
        blocking.apply(selection)
        isBlocking = true
        refreshStats()
    }

    @discardableResult
    private func stopBlocking(emergency: Bool) -> Bool {
        let now = Date()
        let sessions = openSessions()
        for session in sessions {
            session.end = now
            session.endedByEmergency = emergency
        }
        do {
            try context.save()
        } catch {
            for session in sessions {
                session.end = nil
                session.endedByEmergency = false
            }
            alertMessage = "Couldn't save this session."
            return false
        }
        blocking.clear()
        appGroup.clearBlocking()
        isBlocking = false
        refreshStats()
        return true
    }

    private func reconcile() {
        var open = openSessions().sorted { $0.start < $1.start }
        if open.count > 1, let latest = open.last {
            for session in open.dropLast() {
                session.end = latest.start
                session.endedByEmergency = false
            }
            try? context.save()
            open = [latest]
        }

        if let session = open.first {
            if !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty {
                blocking.apply(selection)
            }
            appGroup.recordBlocking(id: session.id, start: session.start)
            isBlocking = true
            return
        }

        if appGroup.isBlocking, let id = appGroup.sessionID, let start = appGroup.sessionStart {
            let session = BlockSession(id: id, start: start)
            context.insert(session)
            try? context.save()
            if !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty {
                blocking.apply(selection)
            }
            isBlocking = true
            return
        }

        blocking.clear()
        appGroup.clearBlocking()
        isBlocking = false
    }

    private func loadSelection() {
        guard let row = storedSelections().first,
              let decoded = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: row.payload) else {
            selection = FamilyActivitySelection()
            return
        }
        selection = decoded
    }

    private func allSessions() -> [BlockSession] {
        (try? context.fetch(FetchDescriptor<BlockSession>())) ?? []
    }

    private func openSessions() -> [BlockSession] {
        allSessions().filter { $0.end == nil }
    }

    private func storedSelections() -> [StoredSelection] {
        (try? context.fetch(FetchDescriptor<StoredSelection>())) ?? []
    }

    private static func remaining(used: Int) -> Int {
        max(0, AppConfig.lifetimeEmergencyUnlocks - used)
    }
}
