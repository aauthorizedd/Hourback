import Foundation

final class MockTagReader: TagReader {
    var identifier: Data
    var error: Error?

    init(identifier: Data, error: Error? = nil) {
        self.identifier = identifier
        self.error = error
    }

    func readIdentifier(prompt: String) async throws -> Data {
        if let error {
            throw error
        }
        return identifier
    }
}
