@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyReviewTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newStudyReview("code-27", title: "title-445")
        #expect(item.status == Imaging.StudyReviewStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Imaging.newStudyReview("code-27", title: "title-445")
        try item.moveTo(Imaging.StudyReviewStatus.published)
        #expect(item.status == Imaging.StudyReviewStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newStudyReview("code-27", title: "title-445")
        item.status = Imaging.StudyReviewStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.StudyReviewStatus.created) }
    }
}
