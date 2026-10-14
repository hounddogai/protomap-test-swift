@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsWeightedCourierSegmentTests {
    @Test func startsInOpen() throws {
        let item = Labs.newWeightedCourierSegment("code-212", label: "label-800")
        #expect(item.status == Labs.WeightedCourierSegmentStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Labs.newWeightedCourierSegment("code-212", label: "label-800")
        try item.moveTo(Labs.WeightedCourierSegmentStatus.resolved)
        #expect(item.status == Labs.WeightedCourierSegmentStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Labs.newWeightedCourierSegment("code-212", label: "label-800")
        item.status = Labs.WeightedCourierSegmentStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Labs.WeightedCourierSegmentStatus.`open`) }
    }
}
