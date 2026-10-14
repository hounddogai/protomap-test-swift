@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLegacyModalityReviewTests {
    @Test func startsInProposed() throws {
        let item = Imaging.newLegacyModalityReview("code-133", label: "label-58")
        #expect(item.status == Imaging.LegacyModalityReviewStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = Imaging.newLegacyModalityReview("code-133", label: "label-58")
        try item.moveTo(Imaging.LegacyModalityReviewStatus.withdrawn)
        #expect(item.status == Imaging.LegacyModalityReviewStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Imaging.newLegacyModalityReview("code-133", label: "label-58")
        item.status = Imaging.LegacyModalityReviewStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.LegacyModalityReviewStatus.proposed) }
    }
}
