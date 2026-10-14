@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingSeasonalStudyMetricTests {
    @Test func startsInOpen() throws {
        let item = Imaging.newSeasonalStudyMetric("code-411", label: "label-585")
        #expect(item.status == Imaging.SeasonalStudyMetricStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Imaging.newSeasonalStudyMetric("code-411", label: "label-585")
        try item.moveTo(Imaging.SeasonalStudyMetricStatus.inReview)
        #expect(item.status == Imaging.SeasonalStudyMetricStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Imaging.newSeasonalStudyMetric("code-411", label: "label-585")
        item.status = Imaging.SeasonalStudyMetricStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.SeasonalStudyMetricStatus.`open`) }
    }
}
