@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAdaptiveRoundingMetricTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newAdaptiveRoundingMetric("code-839", title: "title-22")
        #expect(item.status == ClinicalOps.AdaptiveRoundingMetricStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = ClinicalOps.newAdaptiveRoundingMetric("code-839", title: "title-22")
        try item.moveTo(ClinicalOps.AdaptiveRoundingMetricStatus.active)
        #expect(item.status == ClinicalOps.AdaptiveRoundingMetricStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newAdaptiveRoundingMetric("code-839", title: "title-22")
        item.status = ClinicalOps.AdaptiveRoundingMetricStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.AdaptiveRoundingMetricStatus.draft) }
    }
}
