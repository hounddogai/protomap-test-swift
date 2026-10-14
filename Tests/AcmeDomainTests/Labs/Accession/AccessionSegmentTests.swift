@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionSegmentTests {
    @Test func startsInDraft() throws {
        let item = Labs.newAccessionSegment("code-814", label: "label-15")
        #expect(item.status == Labs.AccessionSegmentStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Labs.newAccessionSegment("code-814", label: "label-15")
        try item.moveTo(Labs.AccessionSegmentStatus.pending)
        #expect(item.status == Labs.AccessionSegmentStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newAccessionSegment("code-814", label: "label-15")
        item.status = Labs.AccessionSegmentStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.AccessionSegmentStatus.draft) }
    }
}
