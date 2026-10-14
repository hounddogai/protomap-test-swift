@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistReviewTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newWorklistReview("code-384", label: "label-216")
        #expect(item.status == Imaging.WorklistReviewStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = Imaging.newWorklistReview("code-384", label: "label-216")
        try item.moveTo(Imaging.WorklistReviewStatus.cancelled)
        #expect(item.status == Imaging.WorklistReviewStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newWorklistReview("code-384", label: "label-216")
        item.status = Imaging.WorklistReviewStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.WorklistReviewStatus.planned) }
    }
}
