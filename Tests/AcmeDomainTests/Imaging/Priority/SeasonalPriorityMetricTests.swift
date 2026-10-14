@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingSeasonalPriorityMetricTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newSeasonalPriorityMetric("code-982", label: "label-472")
        #expect(item.status == Imaging.SeasonalPriorityMetricStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Imaging.newSeasonalPriorityMetric("code-982", label: "label-472")
        try item.moveTo(Imaging.SeasonalPriorityMetricStatus.revoked)
        #expect(item.status == Imaging.SeasonalPriorityMetricStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newSeasonalPriorityMetric("code-982", label: "label-472")
        item.status = Imaging.SeasonalPriorityMetricStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.SeasonalPriorityMetricStatus.requested) }
    }
}
