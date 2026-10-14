@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreTargetTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newRiskScoreTarget("code-264", label: "label-507")
        #expect(item.status == CareManagement.RiskScoreTargetStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = CareManagement.newRiskScoreTarget("code-264", label: "label-507")
        try item.moveTo(CareManagement.RiskScoreTargetStatus.pending)
        #expect(item.status == CareManagement.RiskScoreTargetStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newRiskScoreTarget("code-264", label: "label-507")
        item.status = CareManagement.RiskScoreTargetStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RiskScoreTargetStatus.draft) }
    }
}
