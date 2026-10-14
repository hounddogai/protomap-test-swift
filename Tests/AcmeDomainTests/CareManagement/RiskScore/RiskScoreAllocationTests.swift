@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreAllocationTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newRiskScoreAllocation("code-869", title: "title-364")
        #expect(item.status == CareManagement.RiskScoreAllocationStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = CareManagement.newRiskScoreAllocation("code-869", title: "title-364")
        try item.moveTo(CareManagement.RiskScoreAllocationStatus.pending)
        #expect(item.status == CareManagement.RiskScoreAllocationStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newRiskScoreAllocation("code-869", title: "title-364")
        item.status = CareManagement.RiskScoreAllocationStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RiskScoreAllocationStatus.draft) }
    }
}
