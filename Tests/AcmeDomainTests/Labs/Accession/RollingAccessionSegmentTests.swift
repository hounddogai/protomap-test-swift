@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingAccessionSegmentTests {
    @Test func startsInDraft() throws {
        let item = Labs.newRollingAccessionSegment("code-617", label: "label-608")
        #expect(item.status == Labs.RollingAccessionSegmentStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Labs.newRollingAccessionSegment("code-617", label: "label-608")
        try item.moveTo(Labs.RollingAccessionSegmentStatus.suspended)
        #expect(item.status == Labs.RollingAccessionSegmentStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newRollingAccessionSegment("code-617", label: "label-608")
        item.status = Labs.RollingAccessionSegmentStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.RollingAccessionSegmentStatus.draft) }
    }
}
