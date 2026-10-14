@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLegacyAccessionThresholdTests {
    @Test func startsInDraft() throws {
        let item = Labs.newLegacyAccessionThreshold("code-57", label: "label-584")
        #expect(item.status == Labs.LegacyAccessionThresholdStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Labs.newLegacyAccessionThreshold("code-57", label: "label-584")
        try item.moveTo(Labs.LegacyAccessionThresholdStatus.pending)
        #expect(item.status == Labs.LegacyAccessionThresholdStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newLegacyAccessionThreshold("code-57", label: "label-584")
        item.status = Labs.LegacyAccessionThresholdStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.LegacyAccessionThresholdStatus.draft) }
    }
}
