@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyAdjustmentTests {
    @Test func startsInOpen() throws {
        let item = Imaging.newStudyAdjustment("code-353", title: "title-402")
        #expect(item.status == Imaging.StudyAdjustmentStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Imaging.newStudyAdjustment("code-353", title: "title-402")
        try item.moveTo(Imaging.StudyAdjustmentStatus.inReview)
        #expect(item.status == Imaging.StudyAdjustmentStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Imaging.newStudyAdjustment("code-353", title: "title-402")
        item.status = Imaging.StudyAdjustmentStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.StudyAdjustmentStatus.`open`) }
    }
}
