@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingResultSegmentTests {
    @Test func startsInDraft() throws {
        let item = Labs.newPendingResultSegment("code-541", title: "title-352")
        #expect(item.status == Labs.PendingResultSegmentStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Labs.newPendingResultSegment("code-541", title: "title-352")
        try item.moveTo(Labs.PendingResultSegmentStatus.pending)
        #expect(item.status == Labs.PendingResultSegmentStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newPendingResultSegment("code-541", title: "title-352")
        item.status = Labs.PendingResultSegmentStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PendingResultSegmentStatus.draft) }
    }
}
