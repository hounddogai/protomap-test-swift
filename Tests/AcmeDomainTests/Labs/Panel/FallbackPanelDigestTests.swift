@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackPanelDigestTests {
    @Test func startsInNew() throws {
        let item = Labs.newFallbackPanelDigest("code-629", title: "title-634")
        #expect(item.status == Labs.FallbackPanelDigestStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = Labs.newFallbackPanelDigest("code-629", title: "title-634")
        try item.moveTo(Labs.FallbackPanelDigestStatus.failed)
        #expect(item.status == Labs.FallbackPanelDigestStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newFallbackPanelDigest("code-629", title: "title-634")
        item.status = Labs.FallbackPanelDigestStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.FallbackPanelDigestStatus.new) }
    }
}
