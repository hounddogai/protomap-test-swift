@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeManifestTests {
    @Test func startsInNew() throws {
        let item = Labs.newReferenceRangeManifest("code-512", name: "name-245")
        #expect(item.status == Labs.ReferenceRangeManifestStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = Labs.newReferenceRangeManifest("code-512", name: "name-245")
        try item.moveTo(Labs.ReferenceRangeManifestStatus.failed)
        #expect(item.status == Labs.ReferenceRangeManifestStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newReferenceRangeManifest("code-512", name: "name-245")
        item.status = Labs.ReferenceRangeManifestStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ReferenceRangeManifestStatus.new) }
    }
}
