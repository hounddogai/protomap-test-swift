@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreMetricTests {
    @Test func startsInPlanned() throws {
        let item = CareManagement.newRiskScoreMetric("code-164", name: "name-890")
        #expect(item.status == CareManagement.RiskScoreMetricStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = CareManagement.newRiskScoreMetric("code-164", name: "name-890")
        try item.moveTo(CareManagement.RiskScoreMetricStatus.scheduled)
        #expect(item.status == CareManagement.RiskScoreMetricStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = CareManagement.newRiskScoreMetric("code-164", name: "name-890")
        item.status = CareManagement.RiskScoreMetricStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RiskScoreMetricStatus.planned) }
    }
}
