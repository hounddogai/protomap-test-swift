@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityReviewTests {
    @Test func startsInDraft() throws {
        let item = Imaging.newModalityReview("code-761", title: "title-759")
        #expect(item.status == Imaging.ModalityReviewStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Imaging.newModalityReview("code-761", title: "title-759")
        try item.moveTo(Imaging.ModalityReviewStatus.suspended)
        #expect(item.status == Imaging.ModalityReviewStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Imaging.newModalityReview("code-761", title: "title-759")
        item.status = Imaging.ModalityReviewStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ModalityReviewStatus.draft) }
    }
}
