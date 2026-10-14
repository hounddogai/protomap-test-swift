@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackAccessionRollupTests {
    @Test func startsInDraft() throws {
        let item = Labs.newFallbackAccessionRollup("code-372", title: "title-477")
        #expect(item.status == Labs.FallbackAccessionRollupStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Labs.newFallbackAccessionRollup("code-372", title: "title-477")
        try item.moveTo(Labs.FallbackAccessionRollupStatus.pending)
        #expect(item.status == Labs.FallbackAccessionRollupStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newFallbackAccessionRollup("code-372", title: "title-477")
        item.status = Labs.FallbackAccessionRollupStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.FallbackAccessionRollupStatus.draft) }
    }
}
