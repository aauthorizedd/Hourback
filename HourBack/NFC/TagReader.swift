import CryptoKit
import Foundation

enum TagReadError: Error {
    case cancelled
    case unavailable
    case unreadable
}

protocol TagReader: AnyObject {
    func readIdentifier(prompt: String) async throws -> Data
}

enum TagHash {
    static func sha256Hex(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}
