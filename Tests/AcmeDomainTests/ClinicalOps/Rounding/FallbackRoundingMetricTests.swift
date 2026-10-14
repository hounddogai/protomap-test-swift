@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsFallbackRoundingMetricTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newFallbackRoundingMetric("code-461", name: "name-372")
        #expect(item.status == ClinicalOps.FallbackRoundingMetricStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = ClinicalOps.newFallbackRoundingMetric("code-461", name: "name-372")
        try item.moveTo(ClinicalOps.FallbackRoundingMetricStatus.completed)
        #expect(item.status == ClinicalOps.FallbackRoundingMetricStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newFallbackRoundingMetric("code-461", name: "name-372")
        item.status = ClinicalOps.FallbackRoundingMetricStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.FallbackRoundingMetricStatus.planned) }
    }
}
