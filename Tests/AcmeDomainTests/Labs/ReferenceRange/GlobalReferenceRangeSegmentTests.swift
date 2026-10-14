@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsGlobalReferenceRangeSegmentTests {
    @Test func startsInIdle() throws {
        let item = Labs.newGlobalReferenceRangeSegment("code-324", label: "label-439")
        #expect(item.status == Labs.GlobalReferenceRangeSegmentStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = Labs.newGlobalReferenceRangeSegment("code-324", label: "label-439")
        try item.moveTo(Labs.GlobalReferenceRangeSegmentStatus.stopped)
        #expect(item.status == Labs.GlobalReferenceRangeSegmentStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newGlobalReferenceRangeSegment("code-324", label: "label-439")
        item.status = Labs.GlobalReferenceRangeSegmentStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.GlobalReferenceRangeSegmentStatus.idle) }
    }
}
