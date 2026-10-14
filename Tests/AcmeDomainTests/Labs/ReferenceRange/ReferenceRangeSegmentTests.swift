@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeSegmentTests {
    @Test func startsInDraft() throws {
        let item = Labs.newReferenceRangeSegment("code-667", name: "name-414")
        #expect(item.status == Labs.ReferenceRangeSegmentStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Labs.newReferenceRangeSegment("code-667", name: "name-414")
        try item.moveTo(Labs.ReferenceRangeSegmentStatus.pending)
        #expect(item.status == Labs.ReferenceRangeSegmentStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newReferenceRangeSegment("code-667", name: "name-414")
        item.status = Labs.ReferenceRangeSegmentStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ReferenceRangeSegmentStatus.draft) }
    }
}
