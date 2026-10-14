@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeRollupTests {
    @Test func startsInDraft() throws {
        let item = Labs.newReferenceRangeRollup("code-311", label: "label-490")
        #expect(item.status == Labs.ReferenceRangeRollupStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Labs.newReferenceRangeRollup("code-311", label: "label-490")
        try item.moveTo(Labs.ReferenceRangeRollupStatus.pending)
        #expect(item.status == Labs.ReferenceRangeRollupStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newReferenceRangeRollup("code-311", label: "label-490")
        item.status = Labs.ReferenceRangeRollupStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ReferenceRangeRollupStatus.draft) }
    }
}
