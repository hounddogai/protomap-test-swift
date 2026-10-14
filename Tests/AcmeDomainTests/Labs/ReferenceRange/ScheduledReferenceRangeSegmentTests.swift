@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsScheduledReferenceRangeSegmentTests {
    @Test func startsInNew() throws {
        let item = Labs.newScheduledReferenceRangeSegment("code-32", name: "name-372")
        #expect(item.status == Labs.ScheduledReferenceRangeSegmentStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Labs.newScheduledReferenceRangeSegment("code-32", name: "name-372")
        try item.moveTo(Labs.ScheduledReferenceRangeSegmentStatus.queued)
        #expect(item.status == Labs.ScheduledReferenceRangeSegmentStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newScheduledReferenceRangeSegment("code-32", name: "name-372")
        item.status = Labs.ScheduledReferenceRangeSegmentStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ScheduledReferenceRangeSegmentStatus.new) }
    }
}
