@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreRuleTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newRiskScoreRule("code-538", label: "label-633")
        #expect(item.status == CareManagement.RiskScoreRuleStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = CareManagement.newRiskScoreRule("code-538", label: "label-633")
        try item.moveTo(CareManagement.RiskScoreRuleStatus.queued)
        #expect(item.status == CareManagement.RiskScoreRuleStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newRiskScoreRule("code-538", label: "label-633")
        item.status = CareManagement.RiskScoreRuleStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RiskScoreRuleStatus.new) }
    }
}
