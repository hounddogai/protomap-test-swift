@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLegacyStudyEstimateTests {
    @Test func startsInOpen() throws {
        let item = Imaging.newLegacyStudyEstimate("code-628", title: "title-983")
        #expect(item.status == Imaging.LegacyStudyEstimateStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Imaging.newLegacyStudyEstimate("code-628", title: "title-983")
        try item.moveTo(Imaging.LegacyStudyEstimateStatus.inReview)
        #expect(item.status == Imaging.LegacyStudyEstimateStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Imaging.newLegacyStudyEstimate("code-628", title: "title-983")
        item.status = Imaging.LegacyStudyEstimateStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.LegacyStudyEstimateStatus.`open`) }
    }
}
