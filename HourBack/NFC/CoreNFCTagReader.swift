import CoreNFC
import Foundation

final class CoreNFCTagReader: NSObject, TagReader, NFCTagReaderSessionDelegate {
    private var session: NFCTagReaderSession?
    private var continuation: CheckedContinuation<Data, Error>?
    private let lock = NSLock()

    func readIdentifier(prompt: String) async throws -> Data {
        guard NFCTagReaderSession.readingAvailable else {
            throw TagReadError.unavailable
        }
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            guard let session = NFCTagReaderSession(pollingOption: .iso14443, delegate: self, queue: nil) else {
                self.finish(.failure(TagReadError.unavailable))
                return
            }
            session.alertMessage = prompt
            self.session = session
            session.begin()
        }
    }

    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {}

    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        let code = (error as? NFCReaderError)?.code
        if code == .readerSessionInvalidationErrorUserCanceled {
            finish(.failure(TagReadError.cancelled))
        } else {
            finish(.failure(error))
        }
    }

    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        guard let tag = tags.first else {
            session.invalidate(errorMessage: "Couldn't read that tag.")
            finish(.failure(TagReadError.unreadable))
            return
        }
        session.connect(to: tag) { [weak self] error in
            if error != nil {
                session.invalidate(errorMessage: "Couldn't read that tag.")
                self?.finish(.failure(TagReadError.unreadable))
                return
            }
            guard let identifier = Self.identifier(of: tag), !identifier.isEmpty else {
                session.invalidate(errorMessage: "Couldn't read that tag.")
                self?.finish(.failure(TagReadError.unreadable))
                return
            }
            session.alertMessage = "Tag read."
            self?.finish(.success(identifier))
            session.invalidate()
        }
    }

    private func finish(_ result: Result<Data, Error>) {
        lock.lock()
        let continuation = self.continuation
        self.continuation = nil
        lock.unlock()
        continuation?.resume(with: result)
    }

    private static func identifier(of tag: NFCTag) -> Data? {
        switch tag {
        case .miFare(let tag):
            return tag.identifier
        case .iso7816(let tag):
            return tag.identifier
        case .iso15693(let tag):
            return tag.identifier
        case .feliCa(let tag):
            return tag.currentIDm
        @unknown default:
            return nil
        }
    }
}
