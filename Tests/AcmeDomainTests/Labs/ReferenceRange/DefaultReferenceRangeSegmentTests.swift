@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsDefaultReferenceRangeSegmentTests {
    @Test func startsInPlanned() throws {
        let item = Labs.newDefaultReferenceRangeSegment("code-237", label: "label-245")
        #expect(item.status == Labs.DefaultReferenceRangeSegmentStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Labs.newDefaultReferenceRangeSegment("code-237", label: "label-245")
        try item.moveTo(Labs.DefaultReferenceRangeSegmentStatus.completed)
        #expect(item.status == Labs.DefaultReferenceRangeSegmentStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Labs.newDefaultReferenceRangeSegment("code-237", label: "label-245")
        item.status = Labs.DefaultReferenceRangeSegmentStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Labs.DefaultReferenceRangeSegmentStatus.planned) }
    }
}
