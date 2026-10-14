@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLegacyStudySegmentTests {
    @Test func startsInOpen() throws {
        let item = Imaging.newLegacyStudySegment("code-359", label: "label-12")
        #expect(item.status == Imaging.LegacyStudySegmentStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Imaging.newLegacyStudySegment("code-359", label: "label-12")
        try item.moveTo(Imaging.LegacyStudySegmentStatus.inReview)
        #expect(item.status == Imaging.LegacyStudySegmentStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Imaging.newLegacyStudySegment("code-359", label: "label-12")
        item.status = Imaging.LegacyStudySegmentStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.LegacyStudySegmentStatus.`open`) }
    }
}
