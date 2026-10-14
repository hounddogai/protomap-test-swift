@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrimaryModalityReviewTests {
    @Test func startsInOpen() throws {
        let item = Imaging.newPrimaryModalityReview("code-72", title: "title-285")
        #expect(item.status == Imaging.PrimaryModalityReviewStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Imaging.newPrimaryModalityReview("code-72", title: "title-285")
        try item.moveTo(Imaging.PrimaryModalityReviewStatus.inReview)
        #expect(item.status == Imaging.PrimaryModalityReviewStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Imaging.newPrimaryModalityReview("code-72", title: "title-285")
        item.status = Imaging.PrimaryModalityReviewStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PrimaryModalityReviewStatus.`open`) }
    }
}
