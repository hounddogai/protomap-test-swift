@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedResultSegmentTests {
    @Test func startsInIdle() throws {
        let item = Labs.newCappedResultSegment("code-493", label: "label-917")
        #expect(item.status == Labs.CappedResultSegmentStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Labs.newCappedResultSegment("code-493", label: "label-917")
        try item.moveTo(Labs.CappedResultSegmentStatus.draining)
        #expect(item.status == Labs.CappedResultSegmentStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newCappedResultSegment("code-493", label: "label-917")
        item.status = Labs.CappedResultSegmentStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.CappedResultSegmentStatus.idle) }
    }
}
