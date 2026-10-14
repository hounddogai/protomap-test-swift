@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrioritySegmentTests {
    @Test func startsInOpen() throws {
        let item = Imaging.newPrioritySegment("code-539", name: "name-770")
        #expect(item.status == Imaging.PrioritySegmentStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Imaging.newPrioritySegment("code-539", name: "name-770")
        try item.moveTo(Imaging.PrioritySegmentStatus.inReview)
        #expect(item.status == Imaging.PrioritySegmentStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Imaging.newPrioritySegment("code-539", name: "name-770")
        item.status = Imaging.PrioritySegmentStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PrioritySegmentStatus.`open`) }
    }
}
