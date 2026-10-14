@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrimaryStudyReviewTests {
    @Test func startsInIdle() throws {
        let item = Imaging.newPrimaryStudyReview("code-256", label: "label-867")
        #expect(item.status == Imaging.PrimaryStudyReviewStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Imaging.newPrimaryStudyReview("code-256", label: "label-867")
        try item.moveTo(Imaging.PrimaryStudyReviewStatus.draining)
        #expect(item.status == Imaging.PrimaryStudyReviewStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Imaging.newPrimaryStudyReview("code-256", label: "label-867")
        item.status = Imaging.PrimaryStudyReviewStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PrimaryStudyReviewStatus.idle) }
    }
}
