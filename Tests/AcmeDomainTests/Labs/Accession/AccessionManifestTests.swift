@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionManifestTests {
    @Test func startsInRequested() throws {
        let item = Labs.newAccessionManifest("code-73", label: "label-195")
        #expect(item.status == Labs.AccessionManifestStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Labs.newAccessionManifest("code-73", label: "label-195")
        try item.moveTo(Labs.AccessionManifestStatus.revoked)
        #expect(item.status == Labs.AccessionManifestStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Labs.newAccessionManifest("code-73", label: "label-195")
        item.status = Labs.AccessionManifestStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.AccessionManifestStatus.requested) }
    }
}
