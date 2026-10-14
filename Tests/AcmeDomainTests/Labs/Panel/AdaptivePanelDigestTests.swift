@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAdaptivePanelDigestTests {
    @Test func startsInDraft() throws {
        let item = Labs.newAdaptivePanelDigest("code-810", title: "title-357")
        #expect(item.status == Labs.AdaptivePanelDigestStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Labs.newAdaptivePanelDigest("code-810", title: "title-357")
        try item.moveTo(Labs.AdaptivePanelDigestStatus.pending)
        #expect(item.status == Labs.AdaptivePanelDigestStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newAdaptivePanelDigest("code-810", title: "title-357")
        item.status = Labs.AdaptivePanelDigestStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.AdaptivePanelDigestStatus.draft) }
    }
}
