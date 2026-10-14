@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingSeasonalModalityReviewTests {
    @Test func startsInOpen() throws {
        let item = Imaging.newSeasonalModalityReview("code-3", name: "name-107")
        #expect(item.status == Imaging.SeasonalModalityReviewStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Imaging.newSeasonalModalityReview("code-3", name: "name-107")
        try item.moveTo(Imaging.SeasonalModalityReviewStatus.reopened)
        #expect(item.status == Imaging.SeasonalModalityReviewStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Imaging.newSeasonalModalityReview("code-3", name: "name-107")
        item.status = Imaging.SeasonalModalityReviewStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.SeasonalModalityReviewStatus.`open`) }
    }
}
