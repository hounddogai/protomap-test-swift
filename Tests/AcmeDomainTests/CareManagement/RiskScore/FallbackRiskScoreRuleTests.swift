@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementFallbackRiskScoreRuleTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newFallbackRiskScoreRule("code-405", label: "label-313")
        #expect(item.status == CareManagement.FallbackRiskScoreRuleStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = CareManagement.newFallbackRiskScoreRule("code-405", label: "label-313")
        try item.moveTo(CareManagement.FallbackRiskScoreRuleStatus.suspended)
        #expect(item.status == CareManagement.FallbackRiskScoreRuleStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newFallbackRiskScoreRule("code-405", label: "label-313")
        item.status = CareManagement.FallbackRiskScoreRuleStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.FallbackRiskScoreRuleStatus.draft) }
    }
}
