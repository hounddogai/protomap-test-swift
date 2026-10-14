@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRollingRiskScoreRuleTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newRollingRiskScoreRule("code-879", title: "title-348")
        #expect(item.status == CareManagement.RollingRiskScoreRuleStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = CareManagement.newRollingRiskScoreRule("code-879", title: "title-348")
        try item.moveTo(CareManagement.RollingRiskScoreRuleStatus.queued)
        #expect(item.status == CareManagement.RollingRiskScoreRuleStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newRollingRiskScoreRule("code-879", title: "title-348")
        item.status = CareManagement.RollingRiskScoreRuleStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RollingRiskScoreRuleStatus.new) }
    }
}
